//+------------------------------------------------------------------+
//|                                           DayTraderPro_v7.mqh    |
//|                         Day Trader Pro v7 - MT5 Expert Advisor   |
//|                    Converted from Pine Script v7 (TradingView)   |
//|                                                                  |
//|  DESCRIPTION:                                                    |
//|    Header file containing all enums, structs, constants and      |
//|    inline utility functions shared across the EA.                |
//|                                                                  |
//|  USAGE:                                                          |
//|    Place this file in:                                           |
//|      MQL5/Include/DayTraderPro_v7.mqh                           |
//|    The main EA (DayTraderPro_v7.mq5) will #include it.          |
//+------------------------------------------------------------------+
#property copyright "Day Trader Pro v7"
#property version   "7.00"
#property strict

//+------------------------------------------------------------------+
//|  CONSTANTS                                                       |
//+------------------------------------------------------------------+

// Magic number — uniquely identifies orders placed by this EA
#define DTP_MAGIC              20250001

// Maximum number of open positions this EA manages simultaneously
#define DTP_MAX_POSITIONS      3

// Comment prefix stamped on every order for easy filtering
#define DTP_ORDER_COMMENT      "DTP_v7"

// Minimum score thresholds (mirrored from Pine Script inputs)
#define DTP_STRONG_SCORE       70
#define DTP_MODERATE_SCORE     45

// ATR multiplier for stop-loss distance (2× ATR)
#define DTP_ATR_SL_MULT        2.0

// Pending order expiry in hours (0 = GTC)
#define DTP_PENDING_EXPIRY_HR  4

//+------------------------------------------------------------------+
//|  ENUMERATIONS                                                    |
//+------------------------------------------------------------------+

// Trading session filter
enum ENUM_DTP_SESSION
  {
   SESSION_ALL      = 0,   // All sessions
   SESSION_REGULAR  = 1,   // Regular hours only  (09:30 – 16:00)
   SESSION_EXTENDED = 2    // Extended hours only (04:00 – 09:30 / 16:00 – 20:00)
  };

// Order entry mode
enum ENUM_DTP_ORDER_MODE
  {
   ORDER_MODE_MARKET  = 0,  // Market orders only
   ORDER_MODE_LIMIT   = 1,  // Limit orders (place below/above signal bar)
   ORDER_MODE_STOP    = 2,  // Stop orders  (breakout confirmation entry)
   ORDER_MODE_BOTH    = 3   // Market for strong, Limit for moderate
  };

// Signal strength level
enum ENUM_DTP_SIGNAL
  {
   SIGNAL_NONE     = 0,
   SIGNAL_MOD_BUY  = 1,
   SIGNAL_STR_BUY  = 2,
   SIGNAL_MOD_SELL = 3,
   SIGNAL_STR_SELL = 4
  };

// Trailing stop mode
enum ENUM_DTP_TRAIL
  {
   TRAIL_NONE   = 0,   // No trailing stop
   TRAIL_ATR    = 1,   // Trail by ATR multiple
   TRAIL_FIXED  = 2    // Trail by fixed pip distance
  };

//+------------------------------------------------------------------+
//|  STRUCTS                                                         |
//+------------------------------------------------------------------+

// Holds all indicator values for the current evaluation bar
struct DTP_BarData
  {
   // Price
   double         close;
   double         high;
   double         low;
   double         open;
   double         volume;

   // ATR
   double         atr;
   double         atr_pct;        // atr / close * 100

   // EMA
   double         ema_fast;
   double         ema_slow;
   double         ema_fast_prev;  // [2] bar (for crossover detection)
   double         ema_slow_prev;

   // RSI
   double         rsi;
   double         rsi_prev;       // [2] bar

   // MACD
   double         macd_main;
   double         macd_signal;
   double         macd_hist;
   double         macd_hist_prev; // [2] bar histogram

   // ADX / DMI
   double         adx;
   double         di_plus;
   double         di_minus;

   // Volume MA
   double         vol_ma;

   // VWAP (daily rolling)
   double         vwap;

   // Candle metrics
   double         body_ratio;     // abs(close-open)/(high-low)
   bool           is_bull_candle;
   bool           is_bear_candle;
   bool           bull_engulf;
   bool           bear_engulf;
   bool           breakout_bull;
   bool           breakout_bear;
   bool           new_high;
   bool           new_low;

   // Computed scores (0-100)
   int            buy_score;
   int            sell_score;

   // Final signal
   ENUM_DTP_SIGNAL signal;
  };

// Risk parameters derived per-signal
struct DTP_TradeParams
  {
   double         entry_price;    // Intended entry
   double         stop_loss;      // SL price
   double         take_profit;    // TP price
   double         lot_size;       // Calculated lot size
   double         risk_amount;    // Risk in account currency
   double         stop_distance;  // SL distance in points
   double         rr_ratio;       // Actual R:R
   ENUM_ORDER_TYPE order_type;    // MT5 order type
  };

// Tracks an open managed position
struct DTP_Position
  {
   ulong          ticket;
   ENUM_DTP_SIGNAL signal_type;
   double         entry_price;
   double         stop_loss;
   double         take_profit;
   double         trail_sl;       // Current trailing SL
   datetime       open_time;
   bool           be_triggered;   // Breakeven already moved?
  };

//+------------------------------------------------------------------+
//|  INLINE UTILITY FUNCTIONS                                        |
//+------------------------------------------------------------------+

//--- Normalise a price to the symbol's tick size
inline double NormalisePrice(double price, const string symbol = NULL)
  {
   string sym = (symbol == NULL) ? _Symbol : symbol;
   double tick = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(tick <= 0) return(NormalizeDouble(price, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)));
   return(NormalizeDouble(MathRound(price / tick) * tick,
                          (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)));
  }

//--- Convert pip count to price distance
inline double PipsToPrice(double pips, const string symbol = NULL)
  {
   string sym = (symbol == NULL) ? _Symbol : symbol;
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   // 5-digit / 3-digit brokers: 1 pip = 10 points
   double mult = (dg == 5 || dg == 3) ? 10.0 : 1.0;
   return(pips * pt * mult);
  }

//--- Convert price distance to pips
inline double PriceToPoints(double price_dist, const string symbol = NULL)
  {
   string sym = (symbol == NULL) ? _Symbol : symbol;
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(pt <= 0) return(0);
   return(price_dist / pt);
  }

//--- ATR-based lot size calculator (risk-based position sizing)
//    risk_pct : fraction of balance to risk (e.g. 0.01 = 1%)
//    sl_price_dist : SL distance in price (not pips)
inline double CalcLotSize(double risk_pct, double sl_price_dist, const string symbol = NULL)
  {
   if(sl_price_dist <= 0) return(0);
   string sym         = (symbol == NULL) ? _Symbol : symbol;
   double balance     = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount = balance * risk_pct;
   double tick_val    = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double tick_sz     = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(tick_sz <= 0 || tick_val <= 0) return(0);
   double val_per_lot = (sl_price_dist / tick_sz) * tick_val;
   if(val_per_lot <= 0) return(0);
   double raw_lot = risk_amount / val_per_lot;
   double min_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double step    = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   double lot     = MathFloor(raw_lot / step) * step;
   return(MathMax(min_lot, MathMin(max_lot, lot)));
  }

//--- Check whether current server time falls within a session window
inline bool IsInSession(ENUM_DTP_SESSION session)
  {
   if(session == SESSION_ALL) return(true);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int mins = dt.hour * 60 + dt.min;
   bool regular  = (mins >= 9 * 60 + 30 && mins <= 16 * 60);
   bool extended = (mins >= 4 * 60 && mins < 9 * 60 + 30) ||
                   (mins > 16 * 60 && mins < 20 * 60);
   if(session == SESSION_REGULAR)  return(regular);
   if(session == SESSION_EXTENDED) return(extended);
   return(true);
  }

//--- Returns true if the EA already has an open position for this symbol
inline bool HasOpenPosition(ulong magic, const string symbol = NULL)
  {
   string sym = (symbol == NULL) ? _Symbol : symbol;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetString(POSITION_SYMBOL) == sym &&
            PositionGetInteger(POSITION_MAGIC) == (long)magic)
            return(true);
     }
   return(false);
  }

//--- Returns true if there is a pending order from this EA for this symbol
inline bool HasPendingOrder(ulong magic, const string symbol = NULL)
  {
   string sym = (symbol == NULL) ? _Symbol : symbol;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket))
         if(OrderGetString(ORDER_SYMBOL) == sym &&
            OrderGetInteger(ORDER_MAGIC) == (long)magic)
            return(true);
     }
   return(false);
  }

//--- Count total open positions managed by this EA
inline int CountManagedPositions(ulong magic, const string symbol = NULL)
  {
   string sym = (symbol == NULL) ? _Symbol : symbol;
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetString(POSITION_SYMBOL) == sym &&
            PositionGetInteger(POSITION_MAGIC) == (long)magic)
            count++;
     }
   return(count);
  }

//--- Log helper with timestamp prefix
inline void DTP_Log(const string msg, const string level = "INFO")
  {
   PrintFormat("[DTP_v7][%s][%s] %s",
               level,
               TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS),
               msg);
  }

//--- Signal name as readable string
inline string SignalName(ENUM_DTP_SIGNAL s)
  {
   switch(s)
     {
      case SIGNAL_STR_BUY:  return("STRONG BUY");
      case SIGNAL_MOD_BUY:  return("MODERATE BUY");
      case SIGNAL_STR_SELL: return("STRONG SELL");
      case SIGNAL_MOD_SELL: return("MODERATE SELL");
      default:              return("NONE");
     }
  }

//+------------------------------------------------------------------+
//|  END OF HEADER                                                   |
//+------------------------------------------------------------------+