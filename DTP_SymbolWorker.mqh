//+------------------------------------------------------------------+
//|                    DTP_SymbolWorker.mqh                          |
//|               Per-Symbol Concurrent Trading Engine               |
//+------------------------------------------------------------------+
#property copyright "Day Trader Pro v7 - Concurrent"
#property version   "7.10"

#include <Trade\Trade.mqh>
#include "DayTraderPro_v7_GUI.mqh"

//+------------------------------------------------------------------+
//| SYMBOL WORKER CLASS - Each symbol runs independently            |
//+------------------------------------------------------------------+
class CDTPSymbolWorker
  {
private:
   string            m_symbol;
   int               m_magic_base;
   int               m_magic;
   CTrade            m_trade;
   
   // Indicator handles (symbol-specific)
   int               m_h_ema_fast;
   int               m_h_ema_slow;
   int               m_h_rsi;
   int               m_h_macd;
   int               m_h_adx;
   int               m_h_atr;
   
   // State tracking
   datetime          m_last_bar_time;
   datetime          m_last_calc_time;
   bool              m_is_initialized;
   
   // Current signal data
   ENUM_DTP_SIGNAL   m_signal;
   int               m_buy_score;
   int               m_sell_score;
   double            m_adx;
   double            m_rsi;
   double            m_atr;
   double            m_current_price;
   
   // Methods
   bool              InitIndicators();
   void              ReleaseIndicators();
   bool              IsNewBar();
   void              CalculateSignal();
   void              ManagePositions();
   void              CheckCounterSignal();
   void              ExecuteTrade(bool is_buy);
   int               CountMyPositions();
   bool              HasPendingOrder();
   double            GetPipSize();
   double            NormalisePrice(double price);
   
public:
                     CDTPSymbolWorker();
                    ~CDTPSymbolWorker();
   
   bool              Init(string symbol, int magic_base);
   void              Deinit();
   void              OnTick();        // Called for this symbol
   void              UpdateGUI();      // Send data to main GUI
   
   // Getters for GUI
   string            GetSymbol()        { return m_symbol; }
   ENUM_DTP_SIGNAL   GetSignal()        { return m_signal; }
   int               GetBuyScore()      { return m_buy_score; }
   int               GetSellScore()     { return m_sell_score; }
   double            GetADX()           { return m_adx; }
   double            GetRSI()           { return m_rsi; }
   double            GetPrice()         { return m_current_price; }
   bool              IsInitialized()    { return m_is_initialized; }
  };

//+------------------------------------------------------------------+
//| CONSTRUCTOR                                                      |
//+------------------------------------------------------------------+
CDTPSymbolWorker::CDTPSymbolWorker()
  {
   m_symbol = "";
   m_magic_base = 20250000;
   m_magic = 0;
   m_h_ema_fast = INVALID_HANDLE;
   m_h_ema_slow = INVALID_HANDLE;
   m_h_rsi = INVALID_HANDLE;
   m_h_macd = INVALID_HANDLE;
   m_h_adx = INVALID_HANDLE;
   m_h_atr = INVALID_HANDLE;
   m_last_bar_time = 0;
   m_last_calc_time = 0;
   m_is_initialized = false;
   m_signal = SIGNAL_NONE;
   m_buy_score = 0;
   m_sell_score = 0;
   m_adx = 0;
   m_rsi = 50;
   m_atr = 0;
   m_current_price = 0;
   m_trade.SetDeviationInPoints(10);
  }

//+------------------------------------------------------------------+
//| DESTRUCTOR                                                       |
//+------------------------------------------------------------------+
CDTPSymbolWorker::~CDTPSymbolWorker()
  {
   Deinit();
  }

//+------------------------------------------------------------------+
//| INIT - Setup indicators for this symbol                          |
//+------------------------------------------------------------------+
bool CDTPSymbolWorker::Init(string symbol, int magic_base)
  {
   m_symbol = symbol;
   m_magic_base = magic_base;
   m_magic = m_magic_base + StringHash(m_symbol) % 10000;
   
   m_trade.SetExpertMagicNumber(m_magic);
   
   if(!InitIndicators())
     {
      Print("[DTP] Failed to initialize indicators for ", m_symbol);
      return false;
     }
   
   m_is_initialized = true;
   Print("[DTP] Worker initialized for ", m_symbol, " Magic=", m_magic);
   return true;
  }

//+------------------------------------------------------------------+
//| INIT INDICATORS - Create all handles for this symbol             |
//+------------------------------------------------------------------+
bool CDTPSymbolWorker::InitIndicators()
  {
   // Use external input parameters (passed via global settings)
   int ema_fast = 9;
   int ema_slow = 21;
   int rsi_len = 14;
   int macd_fast = 12;
   int macd_slow = 26;
   int macd_signal = 9;
   int adx_len = 14;
   int atr_len = 14;
   
   m_h_ema_fast = iMA(m_symbol, PERIOD_M5, ema_fast, 0, MODE_EMA, PRICE_CLOSE);
   m_h_ema_slow = iMA(m_symbol, PERIOD_M5, ema_slow, 0, MODE_EMA, PRICE_CLOSE);
   m_h_rsi = iRSI(m_symbol, PERIOD_M5, rsi_len, PRICE_CLOSE);
   m_h_macd = iMACD(m_symbol, PERIOD_M5, macd_fast, macd_slow, macd_signal, PRICE_CLOSE);
   m_h_adx = iADXWilder(m_symbol, PERIOD_M5, adx_len);
   m_h_atr = iATR(m_symbol, PERIOD_M5, atr_len);
   
   if(m_h_ema_fast == INVALID_HANDLE || m_h_ema_slow == INVALID_HANDLE ||
      m_h_rsi == INVALID_HANDLE || m_h_macd == INVALID_HANDLE ||
      m_h_adx == INVALID_HANDLE || m_h_atr == INVALID_HANDLE)
     return false;
     
   return true;
  }

//+------------------------------------------------------------------+
//| CHECK NEW BAR - Independent per symbol                           |
//+------------------------------------------------------------------+
bool CDTPSymbolWorker::IsNewBar()
  {
   datetime bar_time = iTime(m_symbol, PERIOD_M5, 0);
   if(bar_time != m_last_bar_time)
     {
      m_last_bar_time = bar_time;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| CALCULATE SIGNAL - Runs independently for this symbol           |
//+------------------------------------------------------------------+
void CDTPSymbolWorker::CalculateSignal()
  {
   // Get current price
   m_current_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   // Buffers for indicators
   double ema_fast[2], ema_slow[2];
   double rsi_val[2];
   double macd_main[2], macd_signal[2];
   double adx_val[2], di_plus[2], di_minus[2];
   double atr_val[2];
   
   // Copy data
   if(CopyBuffer(m_h_ema_fast, 0, 1, 2, ema_fast) < 2) return;
   if(CopyBuffer(m_h_ema_slow, 0, 1, 2, ema_slow) < 2) return;
   if(CopyBuffer(m_h_rsi, 0, 1, 2, rsi_val) < 2) return;
   if(CopyBuffer(m_h_macd, 0, 1, 2, macd_main) < 2) return;
   if(CopyBuffer(m_h_macd, 1, 1, 2, macd_signal) < 2) return;
   if(CopyBuffer(m_h_adx, 0, 1, 2, adx_val) < 2) return;
   if(CopyBuffer(m_h_adx, 1, 1, 2, di_plus) < 2) return;
   if(CopyBuffer(m_h_adx, 2, 1, 2, di_minus) < 2) return;
   if(CopyBuffer(m_h_atr, 0, 1, 2, atr_val) < 2) return;
   
   m_atr = atr_val[0];
   m_adx = adx_val[0];
   m_rsi = rsi_val[0];
   
   // Get OHLC for pattern recognition
   MqlRates rates[2];
   if(CopyRates(m_symbol, PERIOD_M5, 1, 2, rates) < 2) return;
   
   // Calculate scores (simplified - use full logic from original)
   m_buy_score = 0;
   m_sell_score = 0;
   
   // EMA condition
   bool ema_bull = ema_fast[0] > ema_slow[0];
   bool ema_cross_up = ema_bull && (ema_fast[1] <= ema_slow[1]);
   bool ema_cross_dn = !ema_bull && (ema_fast[1] >= ema_slow[1]);
   
   if(ema_bull) m_buy_score += 10;
   if(ema_cross_up) m_buy_score += 10;
  if(!ema_bull) m_sell_score += 10;
   if(ema_cross_dn) m_sell_score += 10;
   
   // RSI conditions
   if(rsi_val[0] < 30) m_buy_score += 15;
   else if(rsi_val[0] > 70) m_sell_score += 15;
   else if(rsi_val[0] > 50) m_buy_score += 5;
   else if(rsi_val[0] < 50) m_sell_score += 5;
   
   // MACD conditions
   bool macd_bull = macd_main[0] > macd_signal[0];
   bool macd_cross_up = macd_bull && (macd_main[1] <= macd_signal[1]);
   bool macd_cross_dn = !macd_bull && (macd_main[1] >= macd_signal[1]);
   
   if(macd_bull) m_buy_score += 10;
   if(macd_cross_up) m_buy_score += 10;
   if(!macd_bull) m_sell_score += 10;
   if(macd_cross_dn) m_sell_score += 10;
   
   // ADX trend strength
   if(adx_val[0] >= 20)
     {
      if(di_plus[0] > di_minus[0]) m_buy_score += 10;
      if(di_minus[0] > di_plus[0]) m_sell_score += 10;
     }
   
   // Determine final signal
   if(m_buy_score >= 70) m_signal = SIGNAL_STR_BUY;
   else if(m_buy_score >= 45) m_signal = SIGNAL_MOD_BUY;
   else if(m_sell_score >= 70) m_signal = SIGNAL_STR_SELL;
   else if(m_sell_score >= 45) m_signal = SIGNAL_MOD_SELL;
   else m_signal = SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| ON TICK - Called independently for this symbol                   |
//| THIS RUNS CONCURRENTLY WITH OTHER SYMBOLS!                       |
//+------------------------------------------------------------------+
void CDTPSymbolWorker::OnTick()
  {
   if(!m_is_initialized) return;
   
   // Update price every tick
   m_current_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   // Manage existing positions (runs every tick - concurrent!)
   ManagePositions();
   
   // Check counter-signal (runs every tick - concurrent!)
   CheckCounterSignal();
   
   // New bar logic (only on bar close)
   if(!IsNewBar()) return;
   
   // Calculate new signal
   CalculateSignal();
   
   // Check if we should trade
   if(CountMyPositions() > 0) return;
   if(HasPendingOrder()) return;
   
   // Execute trade
   if(m_signal == SIGNAL_STR_BUY || m_signal == SIGNAL_MOD_BUY)
     ExecuteTrade(true);
   else if(m_signal == SIGNAL_STR_SELL || m_signal == SIGNAL_MOD_SELL)
     ExecuteTrade(false);
  }

//+------------------------------------------------------------------+
//| MANAGE POSITIONS - Trailing stops, breakeven (runs every tick)  |
//+------------------------------------------------------------------+
void CDTPSymbolWorker::ManagePositions()
  {
   double trail_dist = m_atr * 1.5;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
      
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_tp = PositionGetDouble(POSITION_TP);
      int type = (int)PositionGetInteger(POSITION_TYPE);
      
      double cur_price = (type == POSITION_TYPE_BUY) ? 
                         SymbolInfoDouble(m_symbol, SYMBOL_BID) :
                         SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      
      double profit_dist = (type == POSITION_TYPE_BUY) ? 
                           (cur_price - open) : (open - cur_price);
      
      // Breakeven
      if(profit_dist >= m_atr)
        {
         double be_sl = open + ((type == POSITION_TYPE_BUY) ? 2 : -2) * GetPipSize();
         if((type == POSITION_TYPE_BUY && current_sl < be_sl) ||
            (type == POSITION_TYPE_SELL && current_sl > be_sl))
           {
            m_trade.PositionModify(ticket, be_sl, current_tp);
           }
        }
      
      // Trailing stop
      double new_sl = (type == POSITION_TYPE_BUY) ?
                      cur_price - trail_dist :
                      cur_price + trail_dist;
      
      if((type == POSITION_TYPE_BUY && new_sl > current_sl) ||
         (type == POSITION_TYPE_SELL && new_sl < current_sl))
        {
         m_trade.PositionModify(ticket, new_sl, current_tp);
        }
     }
  }

//+------------------------------------------------------------------+
//| CHECK COUNTER SIGNAL - Close on opposite strong signal          |
//+------------------------------------------------------------------+
void CDTPSymbolWorker::CheckCounterSignal()
  {
   if(m_signal != SIGNAL_STR_BUY && m_signal != SIGNAL_STR_SELL) return;
   
   bool close_buys = (m_signal == SIGNAL_STR_SELL);
   bool close_sells = (m_signal == SIGNAL_STR_BUY);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
      
      int type = (int)PositionGetInteger(POSITION_TYPE);
      if((close_buys && type == POSITION_TYPE_BUY) ||
         (close_sells && type == POSITION_TYPE_SELL))
        {
         m_trade.PositionClose(ticket);
         Print("[DTP] Counter-signal close on ", m_symbol);
        }
     }
  }

//+------------------------------------------------------------------+
//| EXECUTE TRADE                                                    |
//+------------------------------------------------------------------+
void CDTPSymbolWorker::ExecuteTrade(bool is_buy)
  {
   double price = is_buy ? 
                  SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                  SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   double sl_dist = m_atr * 2.0;
   double tp_dist = sl_dist * 1.5;
   
   double sl_price = is_buy ? price - sl_dist : price + sl_dist;
   double tp_price = is_buy ? price + tp_dist : price - tp_dist;
   
   // Calculate lot size based on risk
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount = account_balance * 0.01; // 1% risk
   double tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double lot_size = risk_amount / (sl_dist / GetPipSize() * tick_value);
   lot_size = NormalizeDouble(lot_size, 2);
   lot_size = MathMax(lot_size, 0.01);
   lot_size = MathMin(lot_size, 1.0);
   
   string comment = StringFormat("DTP_%s_%d", m_symbol, m_signal);
   
   bool result = is_buy ? 
                 m_trade.Buy(lot_size, m_symbol, price, sl_price, tp_price, comment) :
                 m_trade.Sell(lot_size, m_symbol, price, sl_price, tp_price, comment);
   
   if(result)
     Print("[DTP] Trade opened on ", m_symbol, " ", (is_buy ? "BUY" : "SELL"), 
           " Lots=", lot_size, " Score=", is_buy ? m_buy_score : m_sell_score);
  }

//+------------------------------------------------------------------+
//| HELPER FUNCTIONS                                                 |
//+------------------------------------------------------------------+
int CDTPSymbolWorker::CountMyPositions()
  {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magic)
           count++;
        }
     }
   return count;
  }

bool CDTPSymbolWorker::HasPendingOrder()
  {
   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket))
        {
         if(OrderGetString(ORDER_SYMBOL) == m_symbol &&
            OrderGetInteger(ORDER_MAGIC) == m_magic)
           return true;
        }
     }
   return false;
  }

double CDTPSymbolWorker::GetPipSize()
  {
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   return (digits == 3 || digits == 5) ? point * 10.0 : point;
  }

double CDTPSymbolWorker::NormalisePrice(double price)
  {
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
  }

void CDTPSymbolWorker::Deinit()
  {
   if(m_h_ema_fast != INVALID_HANDLE) IndicatorRelease(m_h_ema_fast);
   if(m_h_ema_slow != INVALID_HANDLE) IndicatorRelease(m_h_ema_slow);
   if(m_h_rsi != INVALID_HANDLE) IndicatorRelease(m_h_rsi);
   if(m_h_macd != INVALID_HANDLE) IndicatorRelease(m_h_macd);
   if(m_h_adx != INVALID_HANDLE) IndicatorRelease(m_h_adx);
   if(m_h_atr != INVALID_HANDLE) IndicatorRelease(m_h_atr);
   m_is_initialized = false;
  }

//+------------------------------------------------------------------+
//| UPDATE GUI - Send data to main display                          |
//+------------------------------------------------------------------+
void CDTPSymbolWorker::UpdateGUI()
  {
   // Data is read by main EA for display
   // Main EA calls GetSignal(), GetBuyScore(), etc.
  }