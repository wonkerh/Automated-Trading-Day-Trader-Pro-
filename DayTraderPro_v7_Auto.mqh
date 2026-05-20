//+------------------------------------------------------------------+
//|                                     DayTraderPro_v7_Auto.mqh    |
//|              Auto Trading Module - Snap-Back Strategy v3         |
//|              FIXED: 6 bugs corrected (see change log below)     |
//+------------------------------------------------------------------+
//  CHANGE LOG v3 (all fixes):
//
//  FIX 1 — Confirmations re-evaluated every tick while waiting
//           (was: snapshot at first tick only, never rechecked)
//
//  FIX 2 — watch_type preserved after _ResetWatch() via
//           m_trade_watch_type so _CheckExits can still close
//           positions opened by the now-cleared watch cycle
//           (was: m_watch_type zeroed by _ResetWatch, exits never fired)
//
//  FIX 3 — Per-position trail tracking: m_trail_sl_price removed;
//           broker's live POSITION_SL read per ticket inside loop
//           (was: single shared variable clobbered by 2nd position)
//
//  FIX 4 — m_breakeven_reached only cleared when ALL managed
//           positions are gone, not on every _CloseAll/_CloseByType
//           (was: wiped even when other positions were still open)
//
//  FIX 5 — Per-position time-stop: reads POSITION_TIME per ticket
//           instead of shared m_position_open_time
//           (was: new trade overwrote timer for all existing positions)
//
//  FIX 6 — ADX exit logic inverted for mean-reversion strategy:
//           close when high ADX (trend resuming against us), not low
//           (was: closed all when ADX<20 — the snap-back hunting zone)
//+------------------------------------------------------------------+
#property copyright "Day Trader Pro v7 — Auto Trading Module v3"
#property version   "7.00"

#include <Trade\Trade.mqh>
#include "DayTraderPro_v7.mqh"

class CAutoTrader
  {
private:
   double            m_adx_threshold;
   double            m_rsi_overbought;
   double            m_rsi_oversold;
   double            m_lot_size;
   int               m_max_positions;
   int               m_magic;
   bool              m_enabled;
   bool              m_close_on_neutral;

   int               m_buy_count;
   int               m_sell_count;
   datetime          m_last_trade_time;
   int               m_cooldown_minutes;

   // Watch phase
   bool              m_is_watching;
   int               m_watch_type;          // 1=oversold→BUY, 2=overbought→SELL
   int               m_trade_watch_type;    // FIX 2: preserved after _ResetWatch
   int               m_extreme_duration;
   double            m_extreme_deepest;
   int               m_extreme_touches;
   datetime          m_extreme_start_time;

   // Reversal detection
   bool              m_was_oversold;
   bool              m_was_overbought;
   bool              m_reversal_confirmed;
   bool              m_reversal_processed;
   int               m_confirmation_count;

   // Price tracking
   double            m_lowest_price;
   double            m_highest_price;
   double            m_prev_candle_high;
   double            m_prev_candle_low;
   double            m_avg_volume;

   // Trail / breakeven tracking
   // FIX 3: m_trail_sl_price removed — read POSITION_SL per ticket
   double            m_entry_price;         // kept for reference only
   bool              m_breakeven_reached;

   // Symbol & ATR handle
   string            m_symbol;
   double            m_pip_size;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_atr_handle;

   CTrade            m_trade;

   double            _GetATR();
   double            _GetAvgVolume(int periods);
   void              _CountPositions();
   void              _CloseAll();
   void              _CloseByType(ENUM_POSITION_TYPE type);
   void              _CloseOldest(ENUM_POSITION_TYPE type);
   bool              _OpenTrade(ENUM_ORDER_TYPE type, double lot);
   void              _UpdateWatch(double rsi);
   void              _ResetWatch();
   int               _CountBuyConf(double rsi, double adx);
   int               _CountSellConf(double rsi, double adx);
   bool              _HasHigherLow();
   bool              _HasLowerHigh();
   bool              _IsVolumeSpike();
   void              _ManageTrail(double adx, double rsi);
   void              _CheckExits(double adx, double rsi);

public:
                     CAutoTrader();
                    ~CAutoTrader();

   void              Init(string symbol, int magic=20250002);
   void              SetParameters(double adx_thresh, double rsi_ob, double rsi_os,
                                   double lots, int max_pos, int cooldown, bool close_neutral);
   void              Enable();
   void              Disable();
   bool              IsEnabled()             { return m_enabled; }
   void              OnTick(double adx, double rsi);

   int               GetBuyPositions()       { _CountPositions(); return m_buy_count;  }
   int               GetSellPositions()      { _CountPositions(); return m_sell_count; }
   int               GetTotalPositions()     { return GetBuyPositions()+GetSellPositions(); }

   bool              IsWatching()            { return m_is_watching; }
   int               GetWatchType()          { return m_watch_type; }
   int               GetExtremeDuration()    { return m_extreme_duration; }
   double            GetExtremeDepth()       { return m_extreme_deepest; }
   int               GetExtremeTouches()     { return m_extreme_touches; }
   int               GetConfirmationCount()  { return m_confirmation_count; }
   bool              IsReversalConfirmed()   { return m_reversal_confirmed; }
   bool              IsBreakevenReached()    { return m_breakeven_reached; }
   string            GetCurrentStage();
  };

//+------------------------------------------------------------------+
CAutoTrader::CAutoTrader()
  {
   m_adx_threshold       = 25.0;
   m_rsi_overbought      = 70.0;
   m_rsi_oversold        = 30.0;
   m_lot_size            = 0.02;
   m_max_positions       = 2;
   m_magic               = 20250002;
   m_enabled             = false;
   m_close_on_neutral    = false;
   m_buy_count           = 0;
   m_sell_count          = 0;
   m_last_trade_time     = 0;
   m_cooldown_minutes    = 5;
   m_is_watching         = false;
   m_watch_type          = 0;
   m_trade_watch_type    = 0;   // FIX 2
   m_extreme_duration    = 0;
   m_extreme_deepest     = 0;
   m_extreme_touches     = 0;
   m_extreme_start_time  = 0;
   m_was_oversold        = false;
   m_was_overbought      = false;
   m_reversal_confirmed  = false;
   m_reversal_processed  = false;
   m_confirmation_count  = 0;
   m_lowest_price        = DBL_MAX;
   m_highest_price       = 0;
   m_prev_candle_high    = 0;
   m_prev_candle_low     = 0;
   m_avg_volume          = 0;
   m_entry_price         = 0;
   m_breakeven_reached   = false;
   m_symbol              = "";
   m_pip_size            = 0;
   m_timeframe           = PERIOD_M5;
   m_atr_handle          = INVALID_HANDLE;
  }

CAutoTrader::~CAutoTrader()
  {
   if(m_atr_handle != INVALID_HANDLE)
     { IndicatorRelease(m_atr_handle); m_atr_handle = INVALID_HANDLE; }
  }

void CAutoTrader::Init(string symbol, int magic=20250002)
  {
   m_symbol    = symbol;
   m_magic     = magic;
   m_timeframe = PERIOD_M5;

   double pt = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    dg = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   m_pip_size = (dg==5||dg==3) ? pt*10.0 : pt;

   if(m_atr_handle != INVALID_HANDLE) IndicatorRelease(m_atr_handle);
   m_atr_handle = iATR(m_symbol, m_timeframe, 14);

   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetDeviationInPoints(20);
   m_trade.SetTypeFilling(ORDER_FILLING_FOK);
  }

void CAutoTrader::SetParameters(double adx_thresh, double rsi_ob, double rsi_os,
                                double lots, int max_pos, int cooldown, bool close_neutral)
  {
   m_adx_threshold    = adx_thresh;
   m_rsi_overbought   = rsi_ob;
   m_rsi_oversold     = rsi_os;
   m_lot_size         = lots;
   m_max_positions    = max_pos;
   m_cooldown_minutes = cooldown;
   m_close_on_neutral = close_neutral;
  }

void CAutoTrader::Enable()
  {
   if(!m_enabled)
     { m_enabled=true; _ResetWatch(); DTP_Log("Auto Trading ENABLED — Snap-Back Strategy Active"); }
  }

void CAutoTrader::Disable()
  {
   if(m_enabled)
     { m_enabled=false; _CloseAll(); _ResetWatch(); DTP_Log("Auto Trading DISABLED"); }
  }

double CAutoTrader::_GetATR()
  {
   if(m_atr_handle==INVALID_HANDLE) return m_pip_size*50;
   double atr[1];
   if(CopyBuffer(m_atr_handle,0,0,1,atr)!=1) return m_pip_size*50;
   return (atr[0]>0) ? atr[0] : m_pip_size*50;
  }

double CAutoTrader::_GetAvgVolume(int periods)
  {
   long volumes[];
   int copied=CopyTickVolume(m_symbol,m_timeframe,0,periods,volumes);
   if(copied<periods) return 0;
   double sum=0;
   for(int i=0;i<periods;i++) sum+=(double)volumes[i];
   return sum/periods;
  }

void CAutoTrader::_CountPositions()
  {
   m_buy_count=0; m_sell_count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) m_buy_count++;
      else m_sell_count++;
     }
  }

//+------------------------------------------------------------------+
// FIX 4: Only clear m_breakeven_reached when NO positions remain
//+------------------------------------------------------------------+
void CAutoTrader::_CloseAll()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;
      if(m_trade.PositionClose(tk))
         DTP_Log(StringFormat("Auto Close: #%llu",tk));
     }
   // FIX 4: recount before clearing breakeven flag
   _CountPositions();
   if(m_buy_count==0 && m_sell_count==0)
      m_breakeven_reached=false;
  }

//+------------------------------------------------------------------+
// FIX 4: _CloseByType — same scoped breakeven reset
//+------------------------------------------------------------------+
void CAutoTrader::_CloseByType(ENUM_POSITION_TYPE type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;
      if(PositionGetInteger(POSITION_TYPE)!=(int)type) continue;
      if(m_trade.PositionClose(tk))
         DTP_Log(StringFormat("Auto Close %s: #%llu",(type==POSITION_TYPE_BUY)?"BUY":"SELL",tk));
     }
   // FIX 4: only clear breakeven when truly no positions left
   _CountPositions();
   if(m_buy_count==0 && m_sell_count==0)
      m_breakeven_reached=false;
  }

void CAutoTrader::_CloseOldest(ENUM_POSITION_TYPE type)
  {
   datetime oldest=INT_MAX; ulong oldest_tk=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;
      if(PositionGetInteger(POSITION_TYPE)!=(int)type) continue;
      datetime ot=(datetime)PositionGetInteger(POSITION_TIME);
      if(ot<oldest){ oldest=ot; oldest_tk=tk; }
     }
   if(oldest_tk!=0 && m_trade.PositionClose(oldest_tk))
     {
      DTP_Log(StringFormat("Partial Close %s: #%llu",(type==POSITION_TYPE_BUY)?"BUY":"SELL",oldest_tk));
      // FIX 4: only clear breakeven when no positions remain
      _CountPositions();
      if(m_buy_count==0 && m_sell_count==0)
         m_breakeven_reached=false;
     }
  }

bool CAutoTrader::_OpenTrade(ENUM_ORDER_TYPE type, double lot)
  {
   double min_lot=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MIN);
   double max_lot=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MAX);
   double step   =SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_STEP);
   lot=MathMax(min_lot,MathMin(max_lot,MathFloor(lot/step)*step));
   if(lot<min_lot){ DTP_Log("Lot too small","ERROR"); return false; }

   double atr=_GetATR();
   double price=(type==ORDER_TYPE_BUY)?
      SymbolInfoDouble(m_symbol,SYMBOL_ASK):SymbolInfoDouble(m_symbol,SYMBOL_BID);
   double sl=(type==ORDER_TYPE_BUY)?price-atr*2.5:price+atr*2.5;

   long stop_level=SymbolInfoInteger(m_symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double min_stop=stop_level*SymbolInfoDouble(m_symbol,SYMBOL_POINT);
   if(MathAbs(price-sl)<min_stop)
      sl=(type==ORDER_TYPE_BUY)?price-min_stop*2.5:price+min_stop*2.5;
   sl=NormalizeDouble(sl,_Digits);

   bool result=(type==ORDER_TYPE_BUY)?
      m_trade.Buy(lot,m_symbol,price,sl,0,"DTP7_AUTO_BUY"):
      m_trade.Sell(lot,m_symbol,price,sl,0,"DTP7_AUTO_SELL");

   if(result)
     {
      // FIX 3: m_trail_sl_price removed — SL tracked per ticket via broker
      // FIX 5: m_position_open_time removed — open time read per ticket via POSITION_TIME
      m_entry_price=price;
      DTP_Log(StringFormat("Auto Trade: %s %.2f @ %.5f SL=%.5f",
             (type==ORDER_TYPE_BUY)?"BUY":"SELL",lot,price,sl));
     }
   else
      DTP_Log(StringFormat("Auto Trade failed: error=%d",GetLastError()),"ERROR");

   return result;
  }

void CAutoTrader::_ResetWatch()
  {
   m_is_watching         = false;
   m_watch_type          = 0;
   // FIX 2: do NOT reset m_trade_watch_type here —
   //         _CheckExits still needs it for open positions
   m_extreme_duration    = 0;
   m_extreme_deepest     = 0;
   m_extreme_touches     = 0;
   m_extreme_start_time  = 0;
   m_reversal_confirmed  = false;
   m_reversal_processed  = false;
   m_confirmation_count  = 0;
   m_lowest_price        = DBL_MAX;
   m_highest_price       = 0;
  }

void CAutoTrader::_UpdateWatch(double rsi)
  {
   MqlRates rates[1];
   if(CopyRates(m_symbol,m_timeframe,0,1,rates)!=1) return;
   double cur_low=rates[0].low, cur_high=rates[0].high;

   // Entering oversold zone
   if(rsi<=m_rsi_oversold)
     {
      if(!m_is_watching||m_watch_type!=1)
        {
         _ResetWatch(); m_is_watching=true; m_watch_type=1;
         m_extreme_start_time=TimeCurrent(); m_extreme_deepest=rsi;
         m_lowest_price=cur_low; m_extreme_touches=1;
         DTP_Log(StringFormat("WATCHING: RSI oversold (%.1f) — waiting for reversal",rsi));
        }
      else
        {
         m_extreme_duration++;
         if(rsi<m_extreme_deepest) m_extreme_deepest=rsi;
         if(cur_low<m_lowest_price) m_lowest_price=cur_low;
         if(!m_was_oversold) m_extreme_touches++;
        }
     }
   // Entering overbought zone
   else if(rsi>=m_rsi_overbought)
     {
      if(!m_is_watching||m_watch_type!=2)
        {
         _ResetWatch(); m_is_watching=true; m_watch_type=2;
         m_extreme_start_time=TimeCurrent(); m_extreme_deepest=rsi;
         m_highest_price=cur_high; m_extreme_touches=1;
         DTP_Log(StringFormat("WATCHING: RSI overbought (%.1f) — waiting for reversal",rsi));
        }
      else
        {
         m_extreme_duration++;
         if(rsi>m_extreme_deepest) m_extreme_deepest=rsi;
         if(cur_high>m_highest_price) m_highest_price=cur_high;
         if(!m_was_overbought) m_extreme_touches++;
        }
     }
   // RSI exited extreme zone — detect reversal (once per cycle)
   else if(m_is_watching && !m_reversal_processed)
     {
      if(m_watch_type==1 && m_was_oversold)
        {
         m_reversal_confirmed = true;
         m_reversal_processed = true;
         m_prev_candle_high   = cur_high;
         m_prev_candle_low    = cur_low;
         m_avg_volume         = _GetAvgVolume(20);
         DTP_Log(StringFormat("OVERSOLD REVERSAL! RSI crossed above %.0f (now %.1f)",m_rsi_oversold,rsi));
        }
      else if(m_watch_type==2 && m_was_overbought)
        {
         m_reversal_confirmed = true;
         m_reversal_processed = true;
         m_prev_candle_high   = cur_high;
         m_prev_candle_low    = cur_low;
         m_avg_volume         = _GetAvgVolume(20);
         DTP_Log(StringFormat("OVERBOUGHT REVERSAL! RSI crossed below %.0f (now %.1f)",m_rsi_overbought,rsi));
        }
     }

   m_was_oversold   = (rsi<=m_rsi_oversold);
   m_was_overbought = (rsi>=m_rsi_overbought);
  }

bool CAutoTrader::_HasHigherLow()
  {
   MqlRates rates[2];
   if(CopyRates(m_symbol,m_timeframe,0,2,rates)!=2) return false;
   return(rates[0].low>m_lowest_price && rates[0].low>rates[1].low);
  }

bool CAutoTrader::_HasLowerHigh()
  {
   MqlRates rates[2];
   if(CopyRates(m_symbol,m_timeframe,0,2,rates)!=2) return false;
   return(rates[0].high<m_highest_price && rates[0].high<rates[1].high);
  }

bool CAutoTrader::_IsVolumeSpike()
  {
   long volumes[1];
   if(CopyTickVolume(m_symbol,m_timeframe,0,1,volumes)!=1) return false;
   return((double)volumes[0]>m_avg_volume*1.5);
  }

int CAutoTrader::_CountBuyConf(double rsi, double adx)
  {
   int count=0;
   if(_HasHigherLow())
     { count++; DTP_Log("  Conf: Higher Low"); }
   MqlRates rates[1];
   if(CopyRates(m_symbol,m_timeframe,0,1,rates)==1 && rates[0].close>m_prev_candle_high)
     { count++; DTP_Log("  Conf: Close above prev high"); }
   if(_IsVolumeSpike())
     { count++; DTP_Log("  Conf: Volume spike"); }
   if(adx>=20 && adx<=35)
     { count++; DTP_Log(StringFormat("  Conf: ADX in range (%.1f)",adx)); }
   if(m_extreme_touches>=2)
     { count++; DTP_Log(StringFormat("  Conf: Multiple touches (%d)",m_extreme_touches)); }
   return count;
  }

int CAutoTrader::_CountSellConf(double rsi, double adx)
  {
   int count=0;
   if(_HasLowerHigh())
     { count++; DTP_Log("  Conf: Lower High"); }
   MqlRates rates[1];
   if(CopyRates(m_symbol,m_timeframe,0,1,rates)==1 && rates[0].close<m_prev_candle_low)
     { count++; DTP_Log("  Conf: Close below prev low"); }
   if(_IsVolumeSpike())
     { count++; DTP_Log("  Conf: Volume spike"); }
   if(adx>=20 && adx<=35)
     { count++; DTP_Log(StringFormat("  Conf: ADX in range (%.1f)",adx)); }
   if(m_extreme_touches>=2)
     { count++; DTP_Log(StringFormat("  Conf: Multiple touches (%d)",m_extreme_touches)); }
   return count;
  }

//+------------------------------------------------------------------+
// FIX 3: Trail tracking reads POSITION_SL per ticket — no shared var
// FIX 4: Breakeven flag only cleared when all positions gone
// FIX 5: Time-stop reads POSITION_TIME per ticket — no shared var
//+------------------------------------------------------------------+
void CAutoTrader::_ManageTrail(double adx, double rsi)
  {
   if(m_buy_count==0 && m_sell_count==0) return;

   double atr        = _GetATR();
   double trail_dist = atr * 2.5;
   double be_trigger = atr * 2.5;

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;

      ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double open_price  = PositionGetDouble(POSITION_PRICE_OPEN);
      double current_sl  = PositionGetDouble(POSITION_SL);   // FIX 3: per-ticket SL
      double current_tp  = PositionGetDouble(POSITION_TP);
      double cur_price   = (ptype==POSITION_TYPE_BUY)?
                           SymbolInfoDouble(m_symbol,SYMBOL_BID):
                           SymbolInfoDouble(m_symbol,SYMBOL_ASK);
      double profit_dist = (ptype==POSITION_TYPE_BUY)?(cur_price-open_price):(open_price-cur_price);

      // ── Breakeven ────────────────────────────────────────────────
      if(!m_breakeven_reached && profit_dist>=be_trigger)
        {
         double pt    = SymbolInfoDouble(m_symbol,SYMBOL_POINT);
         double be_sl = NormalizeDouble(open_price+(ptype==POSITION_TYPE_BUY?pt:-pt),_Digits);
         bool need_be = (ptype==POSITION_TYPE_BUY  && current_sl<be_sl) ||
                        (ptype==POSITION_TYPE_SELL && current_sl>be_sl);
         if(need_be && m_trade.PositionModify(tk,be_sl,current_tp))
           {
            m_breakeven_reached = true;
            DTP_Log(StringFormat("BREAKEVEN: #%llu SL=%.5f",tk,be_sl));
           }
        }

      // ── Trail (only after breakeven, only when well in profit) ───
      if(m_breakeven_reached && profit_dist>=atr*3.0)
        {
         double pt=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
         if(ptype==POSITION_TYPE_BUY)
           {
            double new_sl=NormalizeDouble(cur_price-trail_dist,_Digits);
            if(new_sl>current_sl+pt)
               if(m_trade.PositionModify(tk,new_sl,current_tp))
                  DTP_Log(StringFormat("TRAIL UP: #%llu SL=%.5f",tk,new_sl));
                  // FIX 3: no m_trail_sl_price to update — broker holds it
           }
         else
           {
            double new_sl=NormalizeDouble(cur_price+trail_dist,_Digits);
            if(new_sl<current_sl-pt)
               if(m_trade.PositionModify(tk,new_sl,current_tp))
                  DTP_Log(StringFormat("TRAIL DN: #%llu SL=%.5f",tk,new_sl));
           }
        }
     }
  }

//+------------------------------------------------------------------+
// FIX 2: Use m_trade_watch_type (preserved) not m_watch_type (cleared)
// FIX 5: Per-position 8h time-stop via POSITION_TIME
// FIX 6: ADX exit logic inverted — close on HIGH ADX (trend resuming),
//         not low ADX (that is the snap-back hunting zone)
//+------------------------------------------------------------------+
void CAutoTrader::_CheckExits(double adx, double rsi)
  {
   if(m_buy_count==0 && m_sell_count==0) return;

   // ── Opposite-signal exit ─────────────────────────────────────────
   // FIX 2: m_trade_watch_type preserved across _ResetWatch
   if(m_reversal_confirmed && m_confirmation_count>=2)
     {
      if(m_trade_watch_type==2 && m_buy_count>0)
        { DTP_Log("Opposite SELL signal — closing BUYs"); _CloseByType(POSITION_TYPE_BUY); }
      if(m_trade_watch_type==1 && m_sell_count>0)
        { DTP_Log("Opposite BUY signal — closing SELLs"); _CloseByType(POSITION_TYPE_SELL); }
     }

   // ── Partial profit at opposite extreme ──────────────────────────
   if(m_buy_count>0 && rsi>=m_rsi_overbought)
     { DTP_Log(StringFormat("RSI overbought (%.1f) — partial BUY close",rsi)); _CloseOldest(POSITION_TYPE_BUY); }
   if(m_sell_count>0 && rsi<=m_rsi_oversold)
     { DTP_Log(StringFormat("RSI oversold (%.1f) — partial SELL close",rsi)); _CloseOldest(POSITION_TYPE_SELL); }

   // ── FIX 6: High-ADX trend-resumption exit ───────────────────────
   // Low ADX is the snap-back hunting zone — do NOT close there.
   // Exit when ADX spikes high (trend resuming, mean-reversion logic fails).
   double adx_exit_threshold = 40.0;
   if(adx > adx_exit_threshold)
     {
      // Close BUYs when strong downtrend resumes
      if(m_buy_count>0 && rsi<(100.0-m_rsi_overbought))
        {
         DTP_Log(StringFormat("ADX surge (%.1f) with bearish RSI — closing BUYs",adx));
         _CloseByType(POSITION_TYPE_BUY);
        }
      // Close SELLs when strong uptrend resumes
      if(m_sell_count>0 && rsi>m_rsi_overbought)
        {
         DTP_Log(StringFormat("ADX surge (%.1f) with bullish RSI — closing SELLs",adx));
         _CloseByType(POSITION_TYPE_SELL);
        }
     }

   // ── FIX 5: Per-position 8-hour time-stop ─────────────────────────
   // Read POSITION_TIME per ticket — no shared timer variable
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;
      datetime pos_open_time=(datetime)PositionGetInteger(POSITION_TIME);
      if(TimeCurrent()-pos_open_time > 8*3600)
        {
         DTP_Log(StringFormat("Time stop 8h: #%llu — closing",tk));
         if(m_trade.PositionClose(tk))
           {
            // FIX 4: only clear breakeven when truly empty
            _CountPositions();
            if(m_buy_count==0 && m_sell_count==0)
               m_breakeven_reached=false;
           }
        }
     }
  }

string CAutoTrader::GetCurrentStage()
  {
   if(!m_enabled)                                                      return "OFF";
   if(!m_is_watching)                                                  return "IDLE";
   if(m_is_watching && !m_reversal_confirmed)
     { return (m_watch_type==1)?"WATCHING: OVERSOLD":"WATCHING: OVERBOUGHT"; }
   if(m_reversal_confirmed && m_confirmation_count<2)                  return "WAITING: CONFIRMATION";
   if(m_reversal_confirmed && m_confirmation_count>=2
      && m_buy_count+m_sell_count>0)                                   return "TRADING";
   if(m_reversal_confirmed && m_confirmation_count>=2)                 return "SIGNAL READY";
   return "UNKNOWN";
  }

//+------------------------------------------------------------------+
// OnTick
// FIX 1: Confirmations re-evaluated every tick while reversal is
//         confirmed and no trade has fired yet (not just first tick)
// FIX 2: m_trade_watch_type saved before _ResetWatch so _CheckExits
//         can still reference the direction after the watch is cleared
//+------------------------------------------------------------------+
void CAutoTrader::OnTick(double adx, double rsi)
  {
   if(!m_enabled) return;
   _CountPositions();
   _UpdateWatch(rsi);
   _ManageTrail(adx,rsi);
   _CheckExits(adx,rsi);

   // ── FIX 1: Re-count confirmations every tick while pending ───────
   // Original code only counted when m_confirmation_count==0,
   // locking in a stale snapshot. Now we re-evaluate live each tick
   // so the threshold check always reflects current market conditions.
   if(m_reversal_confirmed)
     {
      if(m_watch_type==1)
        {
         m_confirmation_count=_CountBuyConf(rsi,adx);
         DTP_Log(StringFormat("BUY Confirmations (live): %d/5",m_confirmation_count));
        }
      else if(m_watch_type==2)
        {
         m_confirmation_count=_CountSellConf(rsi,adx);
         DTP_Log(StringFormat("SELL Confirmations (live): %d/5",m_confirmation_count));
        }
     }

   // ── Execute entry when confirmations met ─────────────────────────
   if(m_reversal_confirmed && m_confirmation_count>=2)
     {
      bool cooldown_ok=(m_cooldown_minutes<=0)||(m_last_trade_time==0)||
                       (TimeCurrent()-m_last_trade_time>=m_cooldown_minutes*60);
      if(!cooldown_ok) return;

      if(m_watch_type==1 && m_buy_count<m_max_positions)
        {
         int to_open=(m_confirmation_count>=3)?
            MathMin(2,m_max_positions-m_buy_count):MathMin(1,m_max_positions-m_buy_count);
         DTP_Log(StringFormat("EXECUTING: %d BUY — %d conf, ADX=%.1f, RSI=%.1f",
                to_open,m_confirmation_count,adx,rsi));
         for(int i=0;i<to_open;i++)
            if(_OpenTrade(ORDER_TYPE_BUY,m_lot_size)) m_last_trade_time=TimeCurrent();
         // FIX 2: save watch direction BEFORE reset so _CheckExits can use it
         m_trade_watch_type=m_watch_type;
         _ResetWatch();
        }
      else if(m_watch_type==2 && m_sell_count<m_max_positions)
        {
         int to_open=(m_confirmation_count>=3)?
            MathMin(2,m_max_positions-m_sell_count):MathMin(1,m_max_positions-m_sell_count);
         DTP_Log(StringFormat("EXECUTING: %d SELL — %d conf, ADX=%.1f, RSI=%.1f",
                to_open,m_confirmation_count,adx,rsi));
         for(int i=0;i<to_open;i++)
            if(_OpenTrade(ORDER_TYPE_SELL,m_lot_size)) m_last_trade_time=TimeCurrent();
         // FIX 2: save watch direction BEFORE reset
         m_trade_watch_type=m_watch_type;
         _ResetWatch();
        }
     }

   // ── Clear trade_watch_type when all positions are gone ───────────
   // FIX 2: once fully flat, the direction is no longer relevant
   if(m_buy_count==0 && m_sell_count==0)
      m_trade_watch_type=0;
  }
//+------------------------------------------------------------------+