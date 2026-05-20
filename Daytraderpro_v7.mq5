//+------------------------------------------------------------------+
//|                                          DayTraderPro_v7.mq5    |
//|                        Day Trader Pro v7 - MT5 Expert Advisor   |
//|                   Converted from Pine Script v7 (TradingView)   |
//|                                                                  |
//|  UPDATED: Snap-Back Strategy integration                        |
//+------------------------------------------------------------------+
#property copyright  "Day Trader Pro v7"
#property link       ""
#property version    "7.00"
#property description "Day Trader Pro v7 — Automated EA for Exness MT5"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\Oscilators.mqh>

#include "DayTraderPro_v7.mqh"
#include "DayTraderPro_v7_GUI.mqh"
#include "DayTraderPro_v7_Auto.mqh"

//+------------------------------------------------------------------+
//|  INPUT PARAMETERS                                                |
//+------------------------------------------------------------------+

input group "═══ Timeframe ═══"
input ENUM_TIMEFRAMES  InpPrimaryTF        = PERIOD_M5;
input ENUM_TIMEFRAMES  InpConfirmTF        = PERIOD_M15;
input bool             InpUseMultiTF       = true;

input group "═══ Indicators ═══"
input int              InpEmaFast          = 9;
input int              InpEmaSlow          = 21;
input int              InpRsiLen           = 14;
input int              InpRsiOB            = 70;
input int              InpRsiOS            = 30;
input bool             InpUseRsi           = true;
input int              InpMacdFast         = 12;
input int              InpMacdSlow         = 26;
input int              InpMacdSignal       = 9;
input bool             InpUseMacd          = true;
input bool             InpUseVwap          = true;
input int              InpAdxLen           = 14;
input int              InpAdxThreshold     = 20;
input bool             InpUseAdx           = true;
input int              InpAtrLen           = 14;
input int              InpVolMaLen         = 20;
input double           InpMinVolMult       = 1.5;
input bool             InpUseVolFilter     = true;

input group "═══ Signal Quality ═══"
input int              InpMinScoreStrong   = 70;
input int              InpMinScoreModerate = 45;
input double           InpBodyRatioMin     = 0.50;
input double           InpMinAtrPct        = 0.10;
input bool             InpTradeStrong      = true;
input bool             InpTradeModerate    = false;

input group "═══ Order Management ═══"
input ENUM_DTP_ORDER_MODE InpOrderMode     = ORDER_MODE_MARKET;
input double           InpLimitOffsetPct   = 0.20;
input int              InpPendingExpiryH   = 4;
input int              InpMaxPositions     = 1;
input bool             InpCloseOnCounter   = true;
input bool             InpCloseOnSession   = false;

input group "═══ Risk Management ═══"
input double           InpRiskPct          = 1.0;
input double           InpRiskReward       = 1.5;
input double           InpAtrSlMult        = 2.0;
input double           InpMaxSpreadPts     = 30.0;
input double           InpMaxDailyDD       = 5.0;

input group "═══ Trailing Stop ═══"
input ENUM_DTP_TRAIL   InpTrailMode        = TRAIL_ATR;
input double           InpTrailAtrMult     = 1.5;
input double           InpTrailFixedPips   = 20.0;
input double           InpBreakevenAtrMult = 1.0;

input group "═══ Session Filter ═══"
input ENUM_DTP_SESSION InpSession          = SESSION_ALL;
input int              InpSessionEndH      = 16;
input int              InpSessionEndM      = 0;

input group "═══ AUTO TRADING — SNAP-BACK ═══"
input bool             InpAutoEnable       = true;
input double           InpAutoADX_Min      = 25.0;
input double           InpAutoRSI_OB       = 70.0;
input double           InpAutoRSI_OS       = 30.0;
input double           InpAutoLots         = 0.05;
input int              InpAutoMaxPos       = 2;
input int              InpAutoCooldown     = 5;
input bool             InpAutoCloseNeutral = false;

input group "═══ GUI Settings ═══"
input bool             InpShowGUI          = true;

input group "═══ Display ═══"
input bool             InpShowPanel        = false;
input bool             InpVerboseLog       = false;

//+------------------------------------------------------------------+
//|  GLOBAL VARIABLES                                                |
//+------------------------------------------------------------------+

CTrade        g_trade;
CPositionInfo g_pos;
COrderInfo    g_order;

int  h_ema_fast, h_ema_slow, h_rsi, h_macd, h_adx, h_atr;
int  h_ema_fast_htf, h_ema_slow_htf, h_rsi_htf, h_macd_htf, h_adx_htf;

datetime g_last_bar_time   = 0;
double   g_day_open_equity = 0;
datetime g_current_day     = 0;

CGUIPanel    g_gui;
CAutoTrader  g_auto_trader;

int             g_last_buy_score  = 0;
int             g_last_sell_score = 0;
ENUM_DTP_SIGNAL g_last_signal     = SIGNAL_NONE;

//+------------------------------------------------------------------+
//|  Volume MA helper                                                |
//+------------------------------------------------------------------+
double GetVolumeMA(int period)
  {
   long volumes[];
   int copied = CopyTickVolume(_Symbol, InpPrimaryTF, 1, period, volumes);
   if(copied < period) return(0);
   double sum = 0;
   for(int i = 0; i < period; i++) sum += (double)volumes[i];
   return(sum / period);
  }

//+------------------------------------------------------------------+
//|  OnInit                                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   DTP_Log("Initialising Day Trader Pro v7 — Snap-Back Strategy...");

   g_trade.SetExpertMagicNumber(DTP_MAGIC);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_FOK);

   h_ema_fast = iMA(_Symbol, InpPrimaryTF, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
   h_ema_slow = iMA(_Symbol, InpPrimaryTF, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi      = iRSI(_Symbol, InpPrimaryTF, InpRsiLen, PRICE_CLOSE);
   h_macd     = iMACD(_Symbol, InpPrimaryTF, InpMacdFast, InpMacdSlow, InpMacdSignal, PRICE_CLOSE);
   h_adx      = iADX(_Symbol, InpPrimaryTF, InpAdxLen);
   h_atr      = iATR(_Symbol, InpPrimaryTF, InpAtrLen);

   if(InpUseMultiTF)
     {
      h_ema_fast_htf = iMA(_Symbol, InpConfirmTF, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
      h_ema_slow_htf = iMA(_Symbol, InpConfirmTF, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
      h_rsi_htf      = iRSI(_Symbol, InpConfirmTF, InpRsiLen, PRICE_CLOSE);
      h_macd_htf     = iMACD(_Symbol, InpConfirmTF, InpMacdFast, InpMacdSlow, InpMacdSignal, PRICE_CLOSE);
      h_adx_htf      = iADX(_Symbol, InpConfirmTF, InpAdxLen);
     }

   if(h_ema_fast==INVALID_HANDLE || h_ema_slow==INVALID_HANDLE ||
      h_rsi==INVALID_HANDLE || h_macd==INVALID_HANDLE ||
      h_adx==INVALID_HANDLE || h_atr==INVALID_HANDLE)
     {
      DTP_Log("Failed to create indicator handles!", "ERROR");
      return(INIT_FAILED);
     }

   if(InpShowGUI)
     {
      g_gui.Init(14, 35);
      g_gui.Draw();
      DTP_Log("GUI Panel initialized.");
     }

   g_auto_trader.Init(_Symbol, 20250002);
   g_auto_trader.SetParameters(
      InpAutoADX_Min,
      InpAutoRSI_OB,
      InpAutoRSI_OS,
      InpAutoLots,
      InpAutoMaxPos,
      InpAutoCooldown,
      InpAutoCloseNeutral
   );
   
   if(InpAutoEnable)
     {
      g_auto_trader.Enable();
      DTP_Log("Snap-Back Auto Trading ENABLED");
     }
   else
     {
      g_auto_trader.Disable();
      DTP_Log("Snap-Back Auto Trading DISABLED");
     }

   g_day_open_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_current_day     = iTime(_Symbol, PERIOD_D1, 0);

   DTP_Log(StringFormat("EA ready. Symbol=%s  ManualMagic=%d  AutoMagic=%d  Risk=%.1f%%",
                        _Symbol, DTP_MAGIC, 20250002, InpRiskPct));

   if(InpShowPanel && !InpShowGUI)
      DrawPanel(SIGNAL_NONE, 0, 0, 0, 0);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|  OnDeinit                                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   g_auto_trader.Disable();
   
   IndicatorRelease(h_ema_fast); IndicatorRelease(h_ema_slow);
   IndicatorRelease(h_rsi);      IndicatorRelease(h_macd);
   IndicatorRelease(h_adx);      IndicatorRelease(h_atr);
   if(InpUseMultiTF)
     {
      IndicatorRelease(h_ema_fast_htf); IndicatorRelease(h_ema_slow_htf);
      IndicatorRelease(h_rsi_htf);      IndicatorRelease(h_macd_htf);
      IndicatorRelease(h_adx_htf);
     }
   g_gui.DeleteAll();
   ObjectsDeleteAll(0, "DTP7_LEGACY_");
   DTP_Log("EA deinitialised.");
  }

//+------------------------------------------------------------------+
//|  OnChartEvent                                                    |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_CUSTOM)
     {
      if(lparam == 1001)  // AUTO_TOGGLE
        {
         if(g_auto_trader.IsEnabled())
           {
            g_auto_trader.Disable();
            DTP_Log("Snap-Back Auto Trading DISABLED via GUI");
           }
         else
           {
            g_auto_trader.Enable();
            DTP_Log("Snap-Back Auto Trading ENABLED via GUI");
           }
         g_gui.Draw();
         return;
        }
     }
   
   if(InpShowGUI)
      g_gui.OnChartEvent(id, lparam, dparam, sparam);
  }

//+------------------------------------------------------------------+
//|  OnTick                                                          |
//+------------------------------------------------------------------+
void OnTick()
  {
   double adx_buf[1], rsi_buf[1];
   double live_adx = 0, live_rsi = 50;

   if(CopyBuffer(h_adx, 0, 0, 1, adx_buf) == 1) live_adx = adx_buf[0];
   if(CopyBuffer(h_rsi, 0, 0, 1, rsi_buf) == 1) live_rsi = rsi_buf[0];

   // ── Update GUI with Snap-Back states ──────────────────────────
   if(InpShowGUI)
     {
      g_gui.UpdateSignal((int)g_last_signal, g_last_buy_score,
                         g_last_sell_score, live_adx, live_rsi);
      
      // Pass ALL auto-trader states to GUI
      g_gui.UpdateAutoState(
         g_auto_trader.IsEnabled(),           // enabled
         g_auto_trader.GetBuyPositions(),     // buy_pos
         g_auto_trader.GetSellPositions(),    // sell_pos
         g_auto_trader.IsWatching(),          // watching
         g_auto_trader.GetWatchType(),        // watch_type (1=oversold, 2=overbought)
         g_auto_trader.GetExtremeDuration(),  // duration
         g_auto_trader.GetExtremeDepth(),     // depth
         g_auto_trader.GetExtremeTouches(),   // touches
         g_auto_trader.IsReversalConfirmed(), // reversal
         g_auto_trader.GetConfirmationCount(),// confirmations
         g_auto_trader.IsBreakevenReached(),  // breakeven
         g_auto_trader.GetCurrentStage()      // stage string
      );
      
      g_gui.Update();
     }

   // ── Run Snap-Back Auto Trader ──────────────────────────────────
   g_auto_trader.OnTick(live_adx, live_rsi);

   // ── New bar detection ─────────────────────────────────────────
   datetime bar_time = iTime(_Symbol, InpPrimaryTF, 0);
   bool new_bar = (bar_time != g_last_bar_time);
   if(new_bar)
     {
      g_last_bar_time = bar_time;
      OnNewBar();
     }

   // ── Daily reset ───────────────────────────────────────────────
   datetime today = iTime(_Symbol, PERIOD_D1, 0);
   if(today != g_current_day)
     {
      g_day_open_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_current_day     = today;
      DTP_Log("New day — equity reset: " + DoubleToString(g_day_open_equity, 2));
     }

   if(!CheckDailyDrawdown()) return;
   if(!CheckSpread())        return;
   if(!IsInSession(InpSession))
     { if(InpCloseOnSession) CloseAllOnSessionEnd(); return; }

   ManageOpenPositions();
   if(new_bar) ProcessTradingSignals();
  }

//+------------------------------------------------------------------+
//|  OnNewBar                                                        |
//+------------------------------------------------------------------+
void OnNewBar()
  {
   DTP_BarData bd;
   if(!BuildBarData(bd)) return;

   g_last_signal     = bd.signal;
   g_last_buy_score  = bd.buy_score;
   g_last_sell_score = bd.sell_score;

   if(InpVerboseLog)
      DTP_Log(StringFormat("Bar[%s] Signal=%s BuyScore=%d SellScore=%d ADX=%.1f RSI=%.1f",
              TimeToString(TimeCurrent()), SignalName(bd.signal),
              bd.buy_score, bd.sell_score, bd.adx, bd.rsi));

   if(InpShowPanel && !InpShowGUI)
      DrawPanel(bd.signal, bd.buy_score, bd.sell_score, bd.adx, bd.rsi);

   if(InpCloseOnCounter) CheckCounterSignalClose(bd.signal);

   if(CountManagedPositions(DTP_MAGIC) >= InpMaxPositions) return;
   if(HasPendingOrder(DTP_MAGIC)) return;

   bool is_buy  = (bd.signal==SIGNAL_STR_BUY  && InpTradeStrong)  ||
                  (bd.signal==SIGNAL_MOD_BUY  && InpTradeModerate);
   bool is_sell = (bd.signal==SIGNAL_STR_SELL && InpTradeStrong)  ||
                  (bd.signal==SIGNAL_MOD_SELL && InpTradeModerate);

   if(is_buy)  PlaceOrder(bd, true);
   if(is_sell) PlaceOrder(bd, false);
  }

//+------------------------------------------------------------------+
//|  ProcessTradingSignals                                           |
//+------------------------------------------------------------------+
void ProcessTradingSignals() {}

//+------------------------------------------------------------------+
//|  BuildBarData                                                    |
//+------------------------------------------------------------------+
bool BuildBarData(DTP_BarData &bd)
  {
   double buf_ema_fast[3], buf_ema_slow[3], buf_rsi[3];
   double buf_macd_main[3], buf_macd_sig[3], buf_macd_hist[3];
   double buf_adx[3], buf_di_plus[3], buf_di_minus[3], buf_atr[3];
   int bars_needed = 3;

   if(CopyBuffer(h_ema_fast, 0, 1, bars_needed, buf_ema_fast) < bars_needed) return(false);
   if(CopyBuffer(h_ema_slow, 0, 1, bars_needed, buf_ema_slow) < bars_needed) return(false);
   if(CopyBuffer(h_rsi,      0, 1, bars_needed, buf_rsi)      < bars_needed) return(false);
   if(CopyBuffer(h_macd, 0,  1, bars_needed, buf_macd_main)   < bars_needed) return(false);
   if(CopyBuffer(h_macd, 1,  1, bars_needed, buf_macd_sig)    < bars_needed) return(false);
   if(CopyBuffer(h_macd, 2,  1, bars_needed, buf_macd_hist)   < bars_needed) return(false);
   if(CopyBuffer(h_adx,  0,  1, bars_needed, buf_adx)         < bars_needed) return(false);
   if(CopyBuffer(h_adx,  1,  1, bars_needed, buf_di_plus)     < bars_needed) return(false);
   if(CopyBuffer(h_adx,  2,  1, bars_needed, buf_di_minus)    < bars_needed) return(false);
   if(CopyBuffer(h_atr,  0,  1, bars_needed, buf_atr)         < bars_needed) return(false);

   MqlRates rates[3];
   if(CopyRates(_Symbol, InpPrimaryTF, 1, 3, rates) < 3) return(false);

   bd.close  = rates[0].close; bd.high = rates[0].high;
   bd.low    = rates[0].low;   bd.open = rates[0].open;
   bd.volume = (double)rates[0].tick_volume;

   bd.atr     = buf_atr[0];
   bd.atr_pct = (bd.close > 0) ? (bd.atr / bd.close) * 100.0 : 0;

   bd.ema_fast      = buf_ema_fast[0]; bd.ema_slow      = buf_ema_slow[0];
   bd.ema_fast_prev = buf_ema_fast[1]; bd.ema_slow_prev = buf_ema_slow[1];

   bd.rsi = buf_rsi[0]; bd.rsi_prev = buf_rsi[1];

   bd.macd_main      = buf_macd_main[0]; bd.macd_signal    = buf_macd_sig[0];
   bd.macd_hist      = buf_macd_hist[0]; bd.macd_hist_prev = buf_macd_hist[1];

   bd.adx = buf_adx[0]; bd.di_plus = buf_di_plus[0]; bd.di_minus = buf_di_minus[0];

   bd.vol_ma = GetVolumeMA(InpVolMaLen);
   bd.vwap   = CalculateDailyVWAP();

   double rng = bd.high - bd.low, body = MathAbs(bd.close - bd.open);
   bd.body_ratio     = (rng > 0) ? body / rng : 0;
   bd.is_bull_candle = (bd.close > bd.open && bd.body_ratio >= InpBodyRatioMin);
   bd.is_bear_candle = (bd.close < bd.open && bd.body_ratio >= InpBodyRatioMin);

   bd.bull_engulf = (rates[1].close < rates[1].open) && (bd.close > bd.open) &&
                    (bd.close > rates[1].open) && (bd.open < rates[1].close) &&
                    bd.body_ratio >= InpBodyRatioMin;
   bd.bear_engulf = (rates[1].close > rates[1].open) && (bd.close < bd.open) &&
                    (bd.close < rates[1].open) && (bd.open > rates[1].close) &&
                    bd.body_ratio >= InpBodyRatioMin;

   double hi20=0, lo20=DBL_MAX; double hi_arr[20], lo_arr[20];
   if(CopyHigh(_Symbol,InpPrimaryTF,1,20,hi_arr)==20 && CopyLow(_Symbol,InpPrimaryTF,1,20,lo_arr)==20)
      for(int i=0;i<20;i++){if(hi_arr[i]>hi20)hi20=hi_arr[i]; if(lo_arr[i]<lo20)lo20=lo_arr[i];}
   double consol_range = hi20 - lo20;
   bd.breakout_bull = (bd.close > hi20 && consol_range >= bd.atr);
   bd.breakout_bear = (bd.close < lo20 && consol_range >= bd.atr);

   double hi10[10], lo10[10]; bd.new_high=false; bd.new_low=false;
   if(CopyHigh(_Symbol,InpPrimaryTF,1,10,hi10)==10 && CopyLow(_Symbol,InpPrimaryTF,1,10,lo10)==10)
     {
      double max10=hi10[0], min10=lo10[0];
      for(int i=1;i<10;i++){if(hi10[i]>max10)max10=hi10[i]; if(lo10[i]<min10)min10=lo10[i];}
      bd.new_high=(bd.high>=max10); bd.new_low=(bd.low<=min10);
     }

   bool htf_bull=false, htf_bear=false;
   if(InpUseMultiTF && h_ema_fast_htf!=INVALID_HANDLE)
     {
      double htf_ef[2],htf_es[2],htf_rsi[2],htf_mm[2],htf_ms[2];
      if(CopyBuffer(h_ema_fast_htf,0,1,2,htf_ef)==2 && CopyBuffer(h_ema_slow_htf,0,1,2,htf_es)==2 &&
         CopyBuffer(h_rsi_htf,0,1,2,htf_rsi)==2 && CopyBuffer(h_macd_htf,0,1,2,htf_mm)==2 &&
         CopyBuffer(h_macd_htf,1,1,2,htf_ms)==2)
        {
         htf_bull=(htf_ef[0]>htf_es[0])&&(htf_rsi[0]<65)&&(htf_mm[0]>htf_ms[0]);
         htf_bear=(htf_ef[0]<htf_es[0])&&(htf_rsi[0]>35)&&(htf_mm[0]<htf_ms[0]);
        }
     }

   bool ema_bullish  =(bd.ema_fast>bd.ema_slow);
   bool ema_cross_up =(bd.ema_fast>bd.ema_slow)&&(bd.ema_fast_prev<=bd.ema_slow_prev);
   bool ema_cross_dn =(bd.ema_fast<bd.ema_slow)&&(bd.ema_fast_prev>=bd.ema_slow_prev);
   bool vwap_bullish =(bd.close>bd.vwap);
   bool rsi_bullish  =(bd.rsi>50);
   bool rsi_oversold =(bd.rsi<InpRsiOS);
   bool rsi_overbought=(bd.rsi>InpRsiOB);
   bool rsi_div_bull =(bd.low<rates[1].low && bd.rsi>bd.rsi_prev);
   bool rsi_div_bear =(bd.high>rates[1].high && bd.rsi<bd.rsi_prev);
   bool macd_bullish =(bd.macd_main>bd.macd_signal);
   bool macd_cross_up=(bd.macd_main>bd.macd_signal)&&(buf_macd_main[1]<=buf_macd_sig[1]);
   bool macd_cross_dn=(bd.macd_main<bd.macd_signal)&&(buf_macd_main[1]>=buf_macd_sig[1]);
   bool hist_rising  =(bd.macd_hist>bd.macd_hist_prev);
   bool hist_falling =(bd.macd_hist<bd.macd_hist_prev);
   bool vol_spike    =(bd.volume>bd.vol_ma*InpMinVolMult);
   bool vol_trend_up =(bd.volume>rates[1].tick_volume)&&(rates[1].tick_volume>rates[2].tick_volume);
   bool adx_trending =(bd.adx>=InpAdxThreshold);
   bool di_bull      =(bd.di_plus>bd.di_minus);
   bool di_bear      =(bd.di_minus>bd.di_plus);
   bool vol_ok       =!InpUseVolFilter||(vol_spike||vol_trend_up);

   int bs=0;
   bs+= bd.is_bull_candle                            ?15:0;
   bs+= bd.bull_engulf                               ?10:0;
   bs+= ema_bullish                                  ?10:0;
   bs+= ema_cross_up                                 ?10:0;
   bs+=(InpUseVwap&&vwap_bullish)                    ?10:0;
   bs+=(InpUseRsi &&rsi_bullish)                     ? 5:0;
   bs+=(InpUseRsi &&(rsi_oversold||rsi_div_bull))    ?10:0;
   bs+=(InpUseMacd&&macd_bullish)                    ? 5:0;
   bs+=(InpUseMacd&&macd_cross_up)                   ?10:0;
   bs+=(InpUseMacd&&hist_rising)                     ? 5:0;
   bs+= vol_spike                                    ?10:0;
   bs+=(bd.breakout_bull||bd.new_high)               ? 5:0;
   bs+=(InpUseMultiTF&&htf_bull)                     ?10:0;
   bs+=(InpUseAdx&&adx_trending&&di_bull)            ?10:0;
   bs-=(InpUseMultiTF&&htf_bear)                     ?20:0;
   bs-=(InpUseAdx&&adx_trending&&di_bear)            ?15:0;
   bd.buy_score=MathMax(bs,0);

   int ss=0;
   ss+= bd.is_bear_candle                            ?15:0;
   ss+= bd.bear_engulf                               ?10:0;
   ss+=(!ema_bullish)                                ?10:0;
   ss+= ema_cross_dn                                 ?10:0;
   ss+=(InpUseVwap&&!vwap_bullish)                   ?10:0;
   ss+=(InpUseRsi &&!rsi_bullish)                    ? 5:0;
   ss+=(InpUseRsi &&(rsi_overbought||rsi_div_bear))  ?10:0;
   ss+=(InpUseMacd&&!macd_bullish)                   ? 5:0;
   ss+=(InpUseMacd&&macd_cross_dn)                   ?10:0;
   ss+=(InpUseMacd&&hist_falling)                    ? 5:0;
   ss+= vol_spike                                    ?10:0;
   ss+=(bd.breakout_bear||bd.new_low)                ? 5:0;
   ss+=(InpUseMultiTF&&htf_bear)                     ?10:0;
   ss+=(InpUseAdx&&adx_trending&&di_bear)            ?10:0;
   ss-=(InpUseMultiTF&&htf_bull)                     ?20:0;
   ss-=(InpUseAdx&&adx_trending&&di_bull)            ?15:0;
   bd.sell_score=MathMax(ss,0);

   bool hard_gate=(bd.atr_pct>=InpMinAtrPct)&&(!InpUseAdx||adx_trending)&&vol_ok;
   bd.signal=SIGNAL_NONE;
   if(hard_gate)
     {
      if     (bd.buy_score >=InpMinScoreStrong)   bd.signal=SIGNAL_STR_BUY;
      else if(bd.buy_score >=InpMinScoreModerate) bd.signal=SIGNAL_MOD_BUY;
      else if(bd.sell_score>=InpMinScoreStrong)   bd.signal=SIGNAL_STR_SELL;
      else if(bd.sell_score>=InpMinScoreModerate) bd.signal=SIGNAL_MOD_SELL;
     }
   return(true);
  }

//+------------------------------------------------------------------+
//|  VWAP                                                            |
//+------------------------------------------------------------------+
double CalculateDailyVWAP()
  {
   MqlRates daily_rates[];
   int copied=CopyRates(_Symbol,PERIOD_CURRENT,0,500,daily_rates);
   if(copied<=0) return(0);
   MqlDateTime now_dt; TimeToStruct(TimeCurrent(),now_dt);
   datetime day_start=StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",now_dt.year,now_dt.mon,now_dt.day));
   double cum_pv=0,cum_v=0;
   for(int i=0;i<copied;i++)
     {
      if(daily_rates[i].time<day_start) continue;
      double tp=(daily_rates[i].high+daily_rates[i].low+daily_rates[i].close)/3.0;
      double vol=(double)daily_rates[i].tick_volume;
      cum_pv+=tp*vol; cum_v+=vol;
     }
   return(cum_v>0?cum_pv/cum_v:0);
  }

//+------------------------------------------------------------------+
//|  PlaceOrder                                                      |
//+------------------------------------------------------------------+
void PlaceOrder(const DTP_BarData &bd, const bool is_buy)
  {
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double price=is_buy?ask:bid;
   double sl_dist=bd.atr*InpAtrSlMult;
   double tp_dist=sl_dist*InpRiskReward;
   double sl_price,tp_price,entry_price;
   ENUM_ORDER_TYPE order_type;

   switch(InpOrderMode)
     {
      case ORDER_MODE_LIMIT:
         if(is_buy){order_type=ORDER_TYPE_BUY_LIMIT;  entry_price=NormalisePrice(ask-bd.atr*InpLimitOffsetPct);}
         else      {order_type=ORDER_TYPE_SELL_LIMIT;  entry_price=NormalisePrice(bid+bd.atr*InpLimitOffsetPct);}
         break;
      case ORDER_MODE_STOP:
         if(is_buy){order_type=ORDER_TYPE_BUY_STOP;   entry_price=NormalisePrice(bd.high+SymbolInfoDouble(_Symbol,SYMBOL_POINT)*2);}
         else      {order_type=ORDER_TYPE_SELL_STOP;   entry_price=NormalisePrice(bd.low -SymbolInfoDouble(_Symbol,SYMBOL_POINT)*2);}
         break;
      default:
         order_type=is_buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL; entry_price=price; break;
     }

   sl_price=NormalisePrice(is_buy?entry_price-sl_dist:entry_price+sl_dist);
   tp_price=NormalisePrice(is_buy?entry_price+tp_dist:entry_price-tp_dist);

   long   stop_level=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double min_dist  =stop_level*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(MathAbs(entry_price-sl_price)<min_dist)
     {
      sl_price=NormalisePrice(is_buy?entry_price-min_dist*1.1:entry_price+min_dist*1.1);
      tp_price=NormalisePrice(is_buy?entry_price+MathAbs(entry_price-sl_price)*InpRiskReward
                                    :entry_price-MathAbs(entry_price-sl_price)*InpRiskReward);
      DTP_Log("SL adjusted for broker minimum stop level.","WARN");
     }

   double sl_price_dist=MathAbs(entry_price-sl_price);
   double lots=CalcLotSize(InpRiskPct/100.0,sl_price_dist);
   if(lots<=0){DTP_Log("Lot size 0 — order skipped.","WARN"); return;}

   g_trade.SetExpertMagicNumber(DTP_MAGIC);
   bool result=false;
   if(order_type==ORDER_TYPE_BUY||order_type==ORDER_TYPE_SELL)
     {
      result=is_buy?g_trade.Buy(lots,_Symbol,entry_price,sl_price,tp_price,DTP_ORDER_COMMENT)
                   :g_trade.Sell(lots,_Symbol,entry_price,sl_price,tp_price,DTP_ORDER_COMMENT);
     }
   else
     {
      datetime expiry=(InpPendingExpiryH>0)?TimeCurrent()+InpPendingExpiryH*3600:0;
      result=g_trade.OrderOpen(_Symbol,order_type,lots,entry_price,0,sl_price,tp_price,
             expiry>0?ORDER_TIME_SPECIFIED:ORDER_TIME_GTC,expiry,DTP_ORDER_COMMENT);
     }
   if(result)
      DTP_Log(StringFormat("Order placed: %s  Type=%s  Lots=%.2f  Entry=%.5f  SL=%.5f  TP=%.5f",
              SignalName(bd.signal),EnumToString(order_type),lots,entry_price,sl_price,tp_price));
   else
      DTP_Log(StringFormat("Order failed: %s  Error=%d",EnumToString(order_type),GetLastError()),"ERROR");
  }

//+------------------------------------------------------------------+
//|  ManageOpenPositions                                             |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   if(InpTrailMode==TRAIL_NONE && InpBreakevenAtrMult<=0) return;
   double atr_buf[2];
   if(CopyBuffer(h_atr,0,1,2,atr_buf)<2) return;
   double atr=atr_buf[0];

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=DTP_MAGIC) continue;

      double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      double current_sl=PositionGetDouble(POSITION_SL);
      double current_tp=PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE ptype=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double cur_price=(ptype==POSITION_TYPE_BUY)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double profit_dist=(ptype==POSITION_TYPE_BUY)?(cur_price-open_price):(open_price-cur_price);

      if(InpBreakevenAtrMult>0 && profit_dist>=atr*InpBreakevenAtrMult)
        {
         double be_sl=NormalisePrice(open_price+(ptype==POSITION_TYPE_BUY?
                      SymbolInfoDouble(_Symbol,SYMBOL_POINT)*2:-SymbolInfoDouble(_Symbol,SYMBOL_POINT)*2));
         bool need_be=(ptype==POSITION_TYPE_BUY&&current_sl<be_sl)||(ptype==POSITION_TYPE_SELL&&current_sl>be_sl);
         if(need_be){g_trade.PositionModify(ticket,be_sl,current_tp);
            if(InpVerboseLog) DTP_Log(StringFormat("Breakeven set: ticket=%llu  SL=%.5f",ticket,be_sl));}
        }

      if(InpTrailMode==TRAIL_NONE) continue;
      double trail_dist=(InpTrailMode==TRAIL_ATR)?atr*InpTrailAtrMult:PipsToPrice(InpTrailFixedPips);
      if(ptype==POSITION_TYPE_BUY)
        {
         double new_sl=NormalisePrice(cur_price-trail_dist);
         if(new_sl>current_sl+SymbolInfoDouble(_Symbol,SYMBOL_POINT))
           {g_trade.PositionModify(ticket,new_sl,current_tp);
            if(InpVerboseLog) DTP_Log(StringFormat("Trail UP: ticket=%llu  SL=%.5f->%.5f",ticket,current_sl,new_sl));}
        }
      else
        {
         double new_sl=NormalisePrice(cur_price+trail_dist);
         if(new_sl<current_sl-SymbolInfoDouble(_Symbol,SYMBOL_POINT))
           {g_trade.PositionModify(ticket,new_sl,current_tp);
            if(InpVerboseLog) DTP_Log(StringFormat("Trail DN: ticket=%llu  SL=%.5f->%.5f",ticket,current_sl,new_sl));}
        }
     }
  }

//+------------------------------------------------------------------+
//|  CheckCounterSignalClose                                         |
//+------------------------------------------------------------------+
void CheckCounterSignalClose(ENUM_DTP_SIGNAL sig)
  {
   if(sig==SIGNAL_NONE) return;
   bool close_buys =(sig==SIGNAL_STR_SELL||sig==SIGNAL_MOD_SELL);
   bool close_sells=(sig==SIGNAL_STR_BUY ||sig==SIGNAL_MOD_BUY);
   if(!close_buys&&!close_sells) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=DTP_MAGIC) continue;
      ENUM_POSITION_TYPE ptype=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if((close_buys&&ptype==POSITION_TYPE_BUY)||(close_sells&&ptype==POSITION_TYPE_SELL))
        {g_trade.PositionClose(ticket);
         DTP_Log(StringFormat("Counter-signal close: ticket=%llu  Signal=%s",ticket,SignalName(sig)));}
     }
  }

//+------------------------------------------------------------------+
//|  CloseAllOnSessionEnd                                            |
//+------------------------------------------------------------------+
void CloseAllOnSessionEnd()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   if(dt.hour!=InpSessionEndH||dt.min!=InpSessionEndM) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=DTP_MAGIC) continue;
      g_trade.PositionClose(ticket);
      DTP_Log(StringFormat("Session-end close: ticket=%llu",ticket));
     }
  }

//+------------------------------------------------------------------+
//|  CheckSpread                                                     |
//+------------------------------------------------------------------+
bool CheckSpread()
  {
   if(InpMaxSpreadPts<=0) return(true);
   double pt=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double spread_pts=(pt>0)?(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/pt:0;
   if(spread_pts>InpMaxSpreadPts)
     {if(InpVerboseLog) DTP_Log(StringFormat("Spread too wide: %.1f pts",spread_pts),"WARN"); return(false);}
   return(true);
  }

//+------------------------------------------------------------------+
//|  CheckDailyDrawdown                                              |
//+------------------------------------------------------------------+
bool CheckDailyDrawdown()
  {
   if(InpMaxDailyDD<=0) return(true);
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double dd_pct=((g_day_open_equity-equity)/g_day_open_equity)*100.0;
   if(dd_pct>=InpMaxDailyDD)
     {DTP_Log(StringFormat("Daily DD limit: %.2f%%. Trading halted.",dd_pct),"WARN"); return(false);}
   return(true);
  }

//+------------------------------------------------------------------+
//|  DrawPanel (legacy)                                              |
//+------------------------------------------------------------------+
void DrawPanel(ENUM_DTP_SIGNAL sig,int buy_score,int sell_score,double adx,double rsi)
  {
   ObjectsDeleteAll(0,"DTP7_LEGACY_");
   int x=15,y=30,w=220,lh=18;
   string bg_obj="DTP7_LEGACY_BG";
   ObjectCreate(0,bg_obj,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,bg_obj,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,bg_obj,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,bg_obj,OBJPROP_XSIZE,w);      ObjectSetInteger(0,bg_obj,OBJPROP_YSIZE,lh*10+12);
   ObjectSetInteger(0,bg_obj,OBJPROP_BGCOLOR,C'10,10,30');
   ObjectSetInteger(0,bg_obj,OBJPROP_BORDER_COLOR,C'40,100,200');
   ObjectSetInteger(0,bg_obj,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,bg_obj,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,bg_obj,OBJPROP_BACK,false); ObjectSetInteger(0,bg_obj,OBJPROP_SELECTABLE,false);
   #define ADD_LABEL(name,txt,clr,ypos) { \
      string _n="DTP7_LEGACY_"+name; ObjectCreate(0,_n,OBJ_LABEL,0,0,0); \
      ObjectSetString(0,_n,OBJPROP_TEXT,txt); ObjectSetInteger(0,_n,OBJPROP_XDISTANCE,x+8); \
      ObjectSetInteger(0,_n,OBJPROP_YDISTANCE,ypos); ObjectSetInteger(0,_n,OBJPROP_COLOR,clr); \
      ObjectSetInteger(0,_n,OBJPROP_FONTSIZE,8); ObjectSetString(0,_n,OBJPROP_FONT,"Courier New"); \
      ObjectSetInteger(0,_n,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,_n,OBJPROP_SELECTABLE,false); }
   ADD_LABEL("title","DAY TRADER PRO v7",C'100,180,255',y+4)
   string sig_txt; color sig_clr;
   switch(sig){
    case SIGNAL_STR_BUY: sig_txt="▲ STRONG BUY";   sig_clr=clrLime; break;
    case SIGNAL_MOD_BUY: sig_txt="△ MODERATE BUY"; sig_clr=clrMediumSeaGreen; break;
    case SIGNAL_STR_SELL:sig_txt="▼ STRONG SELL";  sig_clr=clrRed; break;
    case SIGNAL_MOD_SELL:sig_txt="▽ MODERATE SELL";sig_clr=clrOrange; break;
    default:             sig_txt="— WAIT";          sig_clr=clrSilver; break;}
   ADD_LABEL("sig","Signal : "+sig_txt,sig_clr,y+4+lh*1)
   int sc=(sig==SIGNAL_STR_BUY||sig==SIGNAL_MOD_BUY)?buy_score:sell_score;
   string bar10=""; int filled=(int)MathRound((double)sc/10.0);
   for(int i=0;i<10;i++) bar10+=(i<filled)?"█":"░";
   color sc_clr=(sc>=InpMinScoreStrong)?clrLime:(sc>=InpMinScoreModerate)?clrOrange:clrSilver;
   ADD_LABEL("score",StringFormat("Score  : %d/100 %s",sc,bar10),sc_clr,y+4+lh*2)
   ADD_LABEL("adx",StringFormat("ADX    : %.1f  %s",adx,adx>=InpAdxThreshold?"TRENDING":"RANGING"),
             adx>=InpAdxThreshold?clrLime:clrRed,y+4+lh*3)
   ADD_LABEL("rsi",StringFormat("RSI    : %.1f  %s",rsi,rsi>InpRsiOB?"OVERBOUGHT":rsi<InpRsiOS?"OVERSOLD":"NEUTRAL"),
             rsi>InpRsiOB?clrRed:rsi<InpRsiOS?clrLime:clrYellow,y+4+lh*4)
   ADD_LABEL("bal",StringFormat("Balance: %.2f %s",AccountInfoDouble(ACCOUNT_BALANCE),AccountInfoString(ACCOUNT_CURRENCY)),clrSilver,y+4+lh*5)
   ADD_LABEL("eq", StringFormat("Equity : %.2f %s",AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoString(ACCOUNT_CURRENCY)),clrSilver,y+4+lh*6)
   int n_pos=CountManagedPositions(DTP_MAGIC);
   ADD_LABEL("pos",StringFormat("Trades : %d / %d",n_pos,InpMaxPositions),n_pos>0?clrYellow:clrSilver,y+4+lh*7)
   ADD_LABEL("sess","Session: "+(IsInSession(InpSession)?"ACTIVE":"CLOSED"),IsInSession(InpSession)?clrLime:clrRed,y+4+lh*8)
   ADD_LABEL("sym","Symbol : "+_Symbol,C'80,80,120',y+4+lh*9)
   ChartRedraw(0);
   #undef ADD_LABEL
  }

//+------------------------------------------------------------------+
//|  OnTrade                                                         |
//+------------------------------------------------------------------+
void OnTrade()
  {
   for(int i=HistoryDealsTotal()-1;i>=MathMax(0,HistoryDealsTotal()-5);i--)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(deal,DEAL_MAGIC)!=DTP_MAGIC) continue;
      DTP_Log(StringFormat("Deal: #%llu  Type=%s  Lots=%.2f  Price=%.5f  Profit=%.2f",
              deal,EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE)),
              HistoryDealGetDouble(deal,DEAL_VOLUME),HistoryDealGetDouble(deal,DEAL_PRICE),
              HistoryDealGetDouble(deal,DEAL_PROFIT)));
     }
  }
//+------------------------------------------------------------------+