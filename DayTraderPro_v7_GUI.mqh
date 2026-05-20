//+------------------------------------------------------------------+
//|                                     DayTraderPro_v7_GUI.mqh     |
//|              WONKERH Trading Novice — Professional Panel v7     |
//|                                                                  |
//|  UPDATED: Professional Snap-Back Strategy indicators            |
//+------------------------------------------------------------------+
#property copyright "Day Trader Pro v7 — WONKERH"
#property version   "7.00"

#define C_BASE           C'8,10,14'
#define C_SURFACE        C'12,14,20'
#define C_SURFACE_RAISED C'17,20,28'
#define C_SURFACE_HIGH   C'24,28,38'
#define C_OVERLAY        C'30,35,48'
#define C_LINE           C'34,38,52'
#define C_LINE_MID       C'50,56,74'
#define C_LINE_BRIGHT    C'72,80,104'
#define C_GOLD           C'212,175,55'
#define C_GOLD_DIM       C'140,115,36'
#define C_GOLD_PALE      C'255,220,130'
#define C_TEXT_BRIGHT    C'240,242,248'
#define C_TEXT_MID       C'180,185,200'
#define C_TEXT_DIM       C'100,106,124'
#define C_TEXT_GHOST     C'58,62,78'
#define C_BUY            C'32,210,120'
#define C_BUY_DIM        C'16,100,55'
#define C_BUY_GLOW       C'20,160,80'
#define C_SELL           C'255,72,72'
#define C_SELL_DIM       C'120,24,24'
#define C_SELL_GLOW      C'200,48,48'
#define C_PROFIT         C'30,200,110'
#define C_LOSS           C'240,65,65'
#define C_WARN           C'255,185,30'
#define C_NEUTRAL        C'120,128,150'
#define C_AUTO_BG        C'25,30,50'
#define C_AUTO_ACTIVE    C'50,200,120'
#define C_STAGE_WATCH    C'100,150,255'
#define C_STAGE_CONFIRM  C'255,200,50'
#define C_STAGE_TRADING  C'50,220,100'
#define C_INFO_BG        C'18,22,35'

#define GUI_PREFIX       "DTP7_"
#define GUI_W            450
#define GUI_H            850
#define GUI_HEADER_H     96
#define GUI_TAB_H        32
#define GUI_FOOTER_H     28
#define GUI_PAD          14
#define GUI_ROW          28
#define GUI_CONTENT_Y    (GUI_HEADER_H + GUI_TAB_H + 6)
#define GUI_IW           (GUI_W - GUI_PAD * 2)

enum ENUM_GUI_TAB   { TAB_TRADE=0, TAB_POSITIONS=1, TAB_SIGNALS=2, TAB_ACCOUNT=3 };
enum ENUM_GUI_ORDER { GORD_MARKET=0, GORD_LIMIT=1, GORD_STOP=2 };

struct GUIPosition
  {
   ulong   ticket;
   string  symbol;
   int     type;
   double  volume;
   double  open_price;
   double  current_price;
   double  sl, tp, profit, pips;
   color   profit_clr;
  };

class CGUIPanel
  {
private:
   int            m_x, m_y;
   ENUM_GUI_TAB   m_tab;
   ENUM_GUI_ORDER m_order_type;
   double         m_lots;
   int            m_sl_pips, m_tp_pips;
   int            m_signal, m_buy_score, m_sell_score;
   double         m_adx, m_rsi;
   double         m_balance, m_equity, m_profit, m_margin, m_margin_level;
   GUIPosition    m_pos[];
   int            m_pos_count;
   string         m_edit_lots, m_edit_sl, m_edit_tp;
   string         m_wl_sym[5];
   
   // Auto-trading state — Snap-Back Strategy
   bool           m_auto_enabled;
   int            m_auto_buy_pos;
   int            m_auto_sell_pos;
   
   // Watch phase
   bool           m_auto_watching;
   int            m_auto_watch_type;        // 1=oversold, 2=overbought
   int            m_auto_duration;          // Candles in extreme
   double         m_auto_depth;             // Deepest/highest RSI
   int            m_auto_touches;           // Level tests
   
   // Reversal & confirmation
   bool           m_auto_reversal;
   int            m_auto_confirmations;
   
   // Trade management
   bool           m_auto_breakeven;
   string         m_auto_stage;
   
   void   _Label(string nm,string txt,int x,int y,color clr,int sz=9,string font="Trebuchet MS",int anchor=ANCHOR_LEFT_UPPER);
   void   _Button(string nm,string txt,int x,int y,int w,int h,color bg,color border,color tc,int sz=9,string font="Trebuchet MS");
   void   _Edit(string nm,string val,int x,int y,int w,int h);
   void   _Rect(string nm,int x,int y,int w,int h,color bg,color border=clrNONE,bool back=true);
   void   _HLine(string nm,int x,int y,int w,color clr);
   void   _ScoreBar(string prefix,int x,int y,int w,int score);
   void   _MiniStat(string nm,string lbl,string val,color vc,int x,int y,int col_w);
   void   _ExecuteBuy();
   void   _ExecuteSell();
   void   _CloseAll();
   void   _DrawStatusDot(string nm, int x, int y, int size, bool active, color active_color);
   void   _DrawStatBox(string nm, string label, string value, color val_clr, int x, int y, int w, int h);
   void   _DrawInfoRow(string nm, string label, string value, color val_clr, int x, int y, int label_w);

   void   DrawShell();
   void   DrawHeader();
   void   DrawTabBar();
   void   DrawFooter();
   void   DrawWatermark();
   void   DrawTradeTab();
   void   DrawPositionsTab();
   void   DrawSignalsTab();
   void   DrawAccountTab();
   void   DrawAutoTradingSection();
   void   UpdateAutoTradingStatus();   // <-- Added this declaration

   void   _UpdateAccount();
   void   _UpdatePositions();
   double _PipSize();
   int    _ContentX() { return m_x + GUI_PAD; }
   int    _ContentY() { return m_y + GUI_CONTENT_Y; }

   string _N(string nm) { return GUI_PREFIX + nm; }

public:
        CGUIPanel();
       ~CGUIPanel();
   void Init(int x, int y);
   void Draw();
   void Update();
   void UpdateSignal(int sig,int bs,int ss,double adx,double rsi);
   void UpdateAutoState(bool enabled, int buy_pos, int sell_pos,
                        bool watching, int watch_type, int duration, double depth, int touches,
                        bool reversal, int confirmations, bool breakeven, string stage);
   void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp);
   void DeleteAll();
  };

//+------------------------------------------------------------------+
// Constructor
//+------------------------------------------------------------------+
CGUIPanel::CGUIPanel()
  {
   m_x=14; m_y=28;
   m_tab=TAB_TRADE; m_order_type=GORD_MARKET;
   m_lots=0.01; m_sl_pips=50; m_tp_pips=100;
   m_signal=0; m_buy_score=0; m_sell_score=0;
   m_adx=0; m_rsi=50;
   m_balance=0; m_equity=0; m_profit=0; m_margin=0; m_margin_level=0;
   m_pos_count=0;
   m_edit_lots = GUI_PREFIX+"E_LOTS";
   m_edit_sl   = GUI_PREFIX+"E_SL";
   m_edit_tp   = GUI_PREFIX+"E_TP";
   m_wl_sym[0]="EURUSD"; m_wl_sym[1]="GBPUSD"; m_wl_sym[2]="USDJPY";
   m_wl_sym[3]="XAUUSD"; m_wl_sym[4]="BTCUSD";
   
   m_auto_enabled      = false;
   m_auto_buy_pos      = 0;
   m_auto_sell_pos     = 0;
   m_auto_watching     = false;
   m_auto_watch_type   = 0;
   m_auto_duration     = 0;
   m_auto_depth        = 0;
   m_auto_touches      = 0;
   m_auto_reversal     = false;
   m_auto_confirmations = 0;
   m_auto_breakeven    = false;
   m_auto_stage        = "OFF";
  }

CGUIPanel::~CGUIPanel() { DeleteAll(); }

void CGUIPanel::Init(int x,int y) { m_x=14; m_y=y; }

void CGUIPanel::UpdateSignal(int sig,int bs,int ss,double adx,double rsi)
  { m_signal=sig; m_buy_score=bs; m_sell_score=ss; m_adx=adx; m_rsi=rsi; }

void CGUIPanel::UpdateAutoState(bool enabled, int buy_pos, int sell_pos,
                                bool watching, int watch_type, int duration, double depth, int touches,
                                bool reversal, int confirmations, bool breakeven, string stage)
  {
   m_auto_enabled      = enabled;
   m_auto_buy_pos      = buy_pos;
   m_auto_sell_pos     = sell_pos;
   m_auto_watching     = watching;
   m_auto_watch_type   = watch_type;
   m_auto_duration     = duration;
   m_auto_depth        = depth;
   m_auto_touches      = touches;
   m_auto_reversal     = reversal;
   m_auto_confirmations = confirmations;
   m_auto_breakeven    = breakeven;
   m_auto_stage        = stage;
  }

//+------------------------------------------------------------------+
// Helper: Status Dot
//+------------------------------------------------------------------+
void CGUIPanel::_DrawStatusDot(string nm,int x,int y,int size,bool active,color active_color)
  {
   _Rect(nm, x, y, size, size, active ? active_color : C'40,42,52', active ? active_color : C_LINE, false);
  }

//+------------------------------------------------------------------+
// Helper: Stat Box
//+------------------------------------------------------------------+
void CGUIPanel::_DrawStatBox(string nm,string label,string value,color val_clr,int x,int y,int w,int h)
  {
   _Rect(nm+"_BG", x, y, w, h, C_INFO_BG, C_LINE_MID, false);
   _Label(nm+"_LBL", label, x + 8, y + 5, C_TEXT_DIM, 6, "Trebuchet MS");
   _Label(nm+"_VAL", value, x + 8, y + 18, val_clr, 9, "Courier New");
  }

//+------------------------------------------------------------------+
// Helper: Info Row
//+------------------------------------------------------------------+
void CGUIPanel::_DrawInfoRow(string nm,string label,string value,color val_clr,int x,int y,int label_w)
  {
   _Label(nm+"_LBL", label, x, y, C_TEXT_DIM, 6, "Trebuchet MS");
   _Label(nm+"_VAL", value, x + label_w, y, val_clr, 7, "Courier New");
  }

//+------------------------------------------------------------------+
// UPDATE
//+------------------------------------------------------------------+
void CGUIPanel::Update()
  {
   _UpdateAccount();
   _UpdatePositions();

   string n=_N("HDR_PL_V");
   if(ObjectFind(0,n)>=0)
     {
      ObjectSetString (0,n,OBJPROP_TEXT, StringFormat("%+.2f",m_profit));
      ObjectSetInteger(0,n,OBJPROP_COLOR,m_profit>=0?C_PROFIT:C_LOSS);
     }
   n=_N("HDR_BAL_V");
   if(ObjectFind(0,n)>=0)
      ObjectSetString(0,n,OBJPROP_TEXT,
         StringFormat("%.2f %s",m_balance,AccountInfoString(ACCOUNT_CURRENCY)));

   if(m_tab==TAB_TRADE)
     {
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double spread=(ask-bid)/_PipSize();

      n=_N("TRD_BV"); if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,DoubleToString(bid,_Digits));
      n=_N("TRD_AV"); if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,DoubleToString(ask,_Digits));
      n=_N("BUY_PRC"); if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,DoubleToString(ask,_Digits));
      n=_N("SELL_PRC"); if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,DoubleToString(bid,_Digits));
      n=_N("TRD_SPR_V");
      if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("SPREAD %.1f",spread));
      n=_N("TRD_SPR_BG");
      if(ObjectFind(0,n)>=0) ObjectSetInteger(0,n,OBJPROP_BGCOLOR,spread>2.0?C_SELL_DIM:C_BUY_DIM);

      // ── Snap-Back Status Updates ──────────────────────────────────
      UpdateAutoTradingStatus();
     }

   // ── Signals tab ──────────────────────────────────────────────────
   if(m_tab==TAB_SIGNALS)
     {
      string adx_state;
      color  adxc;
      if(m_adx<20)       { adx_state="RANGING";        adxc=C_WARN;    }
      else if(m_adx<25)  { adx_state="WEAK TREND";     adxc=C_WARN;    }
      else if(m_adx<50)  { adx_state="STRONG TREND";   adxc=C_BUY;     }
      else               { adx_state="EXTREME TREND";  adxc=C_SELL;    }
      n=_N("ADX_VAL");
      if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%.1f",m_adx)); ObjectSetInteger(0,n,OBJPROP_COLOR,adxc);}
      n=_N("ADX_ST");
      if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,adx_state); ObjectSetInteger(0,n,OBJPROP_COLOR,adxc);}
      n=_N("ADX_BAR");
      if(ObjectFind(0,n)>=0) ObjectSetInteger(0,n,OBJPROP_BGCOLOR,adxc);

      string rsi_state;
      color  rsic;
      if(m_rsi<30)       { rsi_state="OVERSOLD";           rsic=C_BUY;     }
      else if(m_rsi<40)  { rsi_state="NEAR OVERSOLD";      rsic=C_BUY;     }
      else if(m_rsi<60)  { rsi_state="NEUTRAL";            rsic=C_WARN;    }
      else if(m_rsi<70)  { rsi_state="NEAR OVERBOUGHT";    rsic=C_WARN;    }
      else               { rsi_state="OVERBOUGHT";         rsic=C_SELL;    }
      n=_N("RSI_VAL");
      if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%.1f",m_rsi)); ObjectSetInteger(0,n,OBJPROP_COLOR,rsic);}
      n=_N("RSI_ST");
      if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,rsi_state); ObjectSetInteger(0,n,OBJPROP_COLOR,rsic);}
      n=_N("RSI_BAR");
      if(ObjectFind(0,n)>=0) ObjectSetInteger(0,n,OBJPROP_BGCOLOR,rsic);

      string sig_txt; color sig_clr;
      switch(m_signal)
        {
         case 1: sig_txt="STRONG BUY";    sig_clr=C_BUY;     break;
         case 2: sig_txt="MODERATE BUY";  sig_clr=C_BUY;     break;
         case 3: sig_txt="STRONG SELL";   sig_clr=C_SELL;    break;
         case 4: sig_txt="MODERATE SELL"; sig_clr=C_WARN;    break;
         default:sig_txt="NO SIGNAL";     sig_clr=C_NEUTRAL; break;
        }
      n=_N("SIG_TXT");
      if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,sig_txt); ObjectSetInteger(0,n,OBJPROP_COLOR,sig_clr);}
      string arrow=(m_signal==1||m_signal==2)?"▲":(m_signal==3||m_signal==4)?"▼":"–";
      n=_N("SIG_ARR");
      if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,arrow); ObjectSetInteger(0,n,OBJPROP_COLOR,sig_clr);}

      int score=(m_signal==1||m_signal==2)?m_buy_score:(m_signal==3||m_signal==4)?m_sell_score:0;
      int filled=(int)MathRound((double)score/10.0);
      for(int i=0;i<10;i++)
        {
         n=_N("SB_"+IntegerToString(i));
         if(ObjectFind(0,n)<0) continue;
         bool lit=(i<filled);
         color lit_clr=(i<=2)?C_LOSS:(i<=5)?C_WARN:C_BUY;
         ObjectSetInteger(0,n,OBJPROP_BGCOLOR, lit?lit_clr:C'20,22,30');
         ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,lit?lit_clr:C_LINE);
        }
      n=_N("SB_NUM");
      if(ObjectFind(0,n)>=0)
        {
         ObjectSetString(0,n,OBJPROP_TEXT,IntegerToString(score)+"/100");
         ObjectSetInteger(0,n,OBJPROP_COLOR,score>=70?C_BUY:score>=45?C_WARN:C_NEUTRAL);
        }
      string conf=score>=70?"HIGH CONFIDENCE":score>=45?"MODERATE CONFIDENCE":"";
      n=_N("SIG_CONF");
      if(conf!="")
        { if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,conf); }
      else
        { if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,""); }
     }

   if(m_tab==TAB_POSITIONS && m_pos_count>0)
     {
      double ps=_PipSize();
      for(int i=0;i<m_pos_count && i<7;i++)
        {
         if(!PositionSelectByTicket(m_pos[i].ticket)) continue;
         m_pos[i].profit=PositionGetDouble(POSITION_PROFIT);
         m_pos[i].current_price=(m_pos[i].type==0)?
            SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double rp=(m_pos[i].current_price-m_pos[i].open_price)/ps;
         m_pos[i].pips=(m_pos[i].type==1)?-rp:rp;
         m_pos[i].profit_clr=m_pos[i].profit>=0?C_PROFIT:C_LOSS;

         n=_N("PPL_"+IntegerToString(i));
         if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%+.2f",m_pos[i].profit)); ObjectSetInteger(0,n,OBJPROP_COLOR,m_pos[i].profit_clr);}
         n=_N("PPP_"+IntegerToString(i));
         if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%+.1f pips",m_pos[i].pips)); ObjectSetInteger(0,n,OBJPROP_COLOR,m_pos[i].pips>=0?C_PROFIT:C_LOSS);}
        }
     }

   if(m_tab==TAB_ACCOUNT)
     {
      string cur=AccountInfoString(ACCOUNT_CURRENCY);
      n=_N("AS_V_0"); if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%.2f  %s",m_balance,cur));
      n=_N("AS_V_1"); if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%.2f  %s",m_equity,cur));
      n=_N("AS_V_2");
      if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%+.2f  %s",m_profit,cur)); ObjectSetInteger(0,n,OBJPROP_COLOR,m_profit>=0?C_PROFIT:C_LOSS);}
      n=_N("AS_V_3"); if(ObjectFind(0,n)>=0) ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%.2f  %s",m_margin,cur));
      
      color ml_clr=m_margin_level>200?C_PROFIT:m_margin_level>100?C_WARN:C_LOSS;
      n=_N("ML_VAL"); if(ObjectFind(0,n)>=0){ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%.1f %%",m_margin_level)); ObjectSetInteger(0,n,OBJPROP_COLOR,ml_clr);}
      int tw=GUI_IW;
      int fw=(int)MathMin(MathMax(m_margin_level/400.0,0.0),1.0)*tw;
      n=_N("ML_FILL"); if(ObjectFind(0,n)>=0){ObjectSetInteger(0,n,OBJPROP_XSIZE,MathMax(fw,4)); ObjectSetInteger(0,n,OBJPROP_BGCOLOR,ml_clr);}
      n=_N("ML_LBL");
      if(ObjectFind(0,n)>=0)
        {
         ObjectSetString(0,n,OBJPROP_TEXT,m_margin_level>200?"SAFE":m_margin_level>100?"CAUTION":"MARGIN CALL RISK");
         ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_BRIGHT);
        }
      
      double risk_pct=m_balance>0?(m_margin/m_balance)*100.0:0;
      color rc=risk_pct<30?C_PROFIT:risk_pct<60?C_WARN:C_LOSS;
      int rfill=(int)MathMin(risk_pct/100.0,1.0)*tw;
      n=_N("RISK_FILL"); if(ObjectFind(0,n)>=0){ObjectSetInteger(0,n,OBJPROP_XSIZE,MathMax(rfill,4)); ObjectSetInteger(0,n,OBJPROP_BGCOLOR,rc);}
      n=_N("RISK_TXT");
      if(ObjectFind(0,n)>=0)
        {
         ObjectSetString(0,n,OBJPROP_TEXT,
            StringFormat("%.1f %%   %s",risk_pct,risk_pct<30?"LOW RISK":risk_pct<60?"MODERATE":"HIGH RISK"));
         ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_BRIGHT);
        }
     }

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
// UpdateAutoTradingStatus — Dynamic status updates
//+------------------------------------------------------------------+
void CGUIPanel::UpdateAutoTradingStatus()
  {
   // Main status
   string n = _N("AUTO_STATUS");
   if(ObjectFind(0,n)>=0)
     {
      if(!m_auto_enabled)
        { ObjectSetString(0,n,OBJPROP_TEXT,"OFF"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_DIM); }
      else if(m_auto_stage == "IDLE")
        { ObjectSetString(0,n,OBJPROP_TEXT,"IDLE"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_NEUTRAL); }
      else if(m_auto_watching)
        { ObjectSetString(0,n,OBJPROP_TEXT,"WATCHING"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_STAGE_WATCH); }
      else if(m_auto_reversal && m_auto_confirmations < 2)
        { ObjectSetString(0,n,OBJPROP_TEXT,"CONFIRMING"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_STAGE_CONFIRM); }
      else if(m_auto_buy_pos + m_auto_sell_pos > 0)
        { ObjectSetString(0,n,OBJPROP_TEXT,"TRADING"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_STAGE_TRADING); }
      else
        { ObjectSetString(0,n,OBJPROP_TEXT,"ACTIVE"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_AUTO_ACTIVE); }
     }

   // Status dot
   n = _N("AUTO_DOT");
   if(ObjectFind(0,n)>=0)
     {
      color dot_color;
      if(!m_auto_enabled) dot_color = C_TEXT_GHOST;
      else if(m_auto_stage == "IDLE") dot_color = C_NEUTRAL;
      else if(m_auto_watching) dot_color = C_STAGE_WATCH;
      else if(m_auto_reversal && m_auto_confirmations < 2) dot_color = C_STAGE_CONFIRM;
      else if(m_auto_buy_pos + m_auto_sell_pos > 0) dot_color = C_STAGE_TRADING;
      else dot_color = C_AUTO_ACTIVE;
      ObjectSetInteger(0,n,OBJPROP_BGCOLOR, dot_color);
      ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR, dot_color);
     }

   // Stage label
   n = _N("AUTO_STAGE_VAL");
   if(ObjectFind(0,n)>=0)
     {
      ObjectSetString(0,n,OBJPROP_TEXT, m_auto_stage);
      ObjectSetInteger(0,n,OBJPROP_COLOR, C_TEXT_MID);
     }

   // Watch type
   n = _N("AUTO_WATCH_VAL");
   if(ObjectFind(0,n)>=0)
     {
      if(m_auto_watching)
        {
         if(m_auto_watch_type == 1)
           { ObjectSetString(0,n,OBJPROP_TEXT,"OVERSOLD → BUY"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_BUY); }
         else if(m_auto_watch_type == 2)
           { ObjectSetString(0,n,OBJPROP_TEXT,"OVERBOUGHT → SELL"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_SELL); }
        }
      else
        { ObjectSetString(0,n,OBJPROP_TEXT,"—"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_GHOST); }
     }

   // Duration & Depth
   n = _N("AUTO_DD_VAL");
   if(ObjectFind(0,n)>=0)
     {
      if(m_auto_watching)
        { ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%d bars  |  %.1f RSI", m_auto_duration, m_auto_depth)); ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_BRIGHT); }
      else
        { ObjectSetString(0,n,OBJPROP_TEXT,"—"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_GHOST); }
     }

   // Touches & Confirmations
   n = _N("AUTO_TC_VAL");
   if(ObjectFind(0,n)>=0)
     {
      ObjectSetString(0,n,OBJPROP_TEXT, StringFormat("%d  |  %d/5", m_auto_touches, m_auto_confirmations));
      ObjectSetInteger(0,n,OBJPROP_COLOR, m_auto_reversal ? C_STAGE_CONFIRM : C_TEXT_GHOST);
     }

   // Direction
   n = _N("AUTO_DIR_VAL");
   if(ObjectFind(0,n)>=0)
     {
      if(m_auto_watching)
        { ObjectSetString(0,n,OBJPROP_TEXT, m_auto_watch_type == 1 ? "LONG" : "SHORT"); ObjectSetInteger(0,n,OBJPROP_COLOR, m_auto_watch_type == 1 ? C_BUY : C_SELL); }
      else
        { ObjectSetString(0,n,OBJPROP_TEXT,"—"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_GHOST); }
     }

   // Breakeven
   n = _N("AUTO_BE_VAL");
   if(ObjectFind(0,n)>=0)
     {
      if(m_auto_breakeven)
        { ObjectSetString(0,n,OBJPROP_TEXT,"ACTIVE"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_PROFIT); }
      else
        { ObjectSetString(0,n,OBJPROP_TEXT,"—"); ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_GHOST); }
     }

   // Position count
   n = _N("AUTO_POS_VAL");
   if(ObjectFind(0,n)>=0)
     {
      int total = m_auto_buy_pos + m_auto_sell_pos;
      ObjectSetString(0,n,OBJPROP_TEXT, StringFormat("BUY:%d  SELL:%d  TOTAL:%d", m_auto_buy_pos, m_auto_sell_pos, total));
      ObjectSetInteger(0,n,OBJPROP_COLOR, total > 0 ? C_GOLD : C_TEXT_DIM);
     }

   // Stage detail
   n = _N("AUTO_DETAIL_VAL");
   if(ObjectFind(0,n)>=0)
     {
      string stage_detail;
      if(!m_auto_enabled) stage_detail = "System disabled";
      else if(m_auto_stage == "IDLE") stage_detail = "Waiting for extreme conditions";
      else if(m_auto_watching) stage_detail = "Monitoring for reversal signals";
      else if(m_auto_reversal && m_auto_confirmations < 2) stage_detail = "Verifying reversal strength";
      else if(m_auto_buy_pos + m_auto_sell_pos > 0) stage_detail = "Managing active positions";
      else stage_detail = "Ready for next setup";
      ObjectSetString(0,n,OBJPROP_TEXT, stage_detail);
      ObjectSetInteger(0,n,OBJPROP_COLOR,C_TEXT_MID);
     }
  }

//+------------------------------------------------------------------+
// DRAW
//+------------------------------------------------------------------+
void CGUIPanel::Draw()
  {
   DeleteAll();
   _UpdateAccount();
   _UpdatePositions();
   DrawShell(); DrawWatermark(); DrawHeader(); DrawTabBar(); DrawFooter();
   
   switch(m_tab)
     {
      case TAB_TRADE:
         DrawTradeTab();
         DrawAutoTradingSection();
         break;
      case TAB_POSITIONS: DrawPositionsTab(); break;
      case TAB_SIGNALS:   DrawSignalsTab();   break;
      case TAB_ACCOUNT:   DrawAccountTab();   break;
     }
   ChartRedraw(0);
  }

void CGUIPanel::DeleteAll() { ObjectsDeleteAll(0,GUI_PREFIX); }

//+------------------------------------------------------------------+
// DRAW HELPERS
//+------------------------------------------------------------------+
void CGUIPanel::_Label(string nm,string txt,int x,int y,color clr,int sz,string font,int anchor)
  {
   string fn=_N(nm);
   if(ObjectFind(0,fn)>=0) ObjectDelete(0,fn);
   ObjectCreate(0,fn,OBJ_LABEL,0,0,0);
   ObjectSetString (0,fn,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,fn,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,fn,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,fn,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,fn,OBJPROP_FONTSIZE,sz);
   ObjectSetString (0,fn,OBJPROP_FONT,font);
   ObjectSetInteger(0,fn,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,fn,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,fn,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,fn,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,fn,OBJPROP_BACK,false);
   ObjectSetInteger(0,fn,OBJPROP_ZORDER,0);
  }

void CGUIPanel::_Button(string nm,string txt,int x,int y,int w,int h,color bg,color border,color tc,int sz,string font)
  {
   string fn=_N(nm);
   if(ObjectFind(0,fn)>=0) ObjectDelete(0,fn);
   ObjectCreate(0,fn,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,fn,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,fn,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,fn,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,fn,OBJPROP_YSIZE,h);
   ObjectSetString (0,fn,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,fn,OBJPROP_COLOR,tc);
   ObjectSetInteger(0,fn,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,fn,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,fn,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,fn,OBJPROP_FONTSIZE,sz);
   ObjectSetString (0,fn,OBJPROP_FONT,font);
   ObjectSetInteger(0,fn,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,fn,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,fn,OBJPROP_ZORDER,10);
  }

void CGUIPanel::_Edit(string nm,string val,int x,int y,int w,int h)
  {
   string fn=_N(nm);
   if(ObjectFind(0,fn)>=0) ObjectDelete(0,fn);
   ObjectCreate(0,fn,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,fn,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,fn,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,fn,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,fn,OBJPROP_YSIZE,h);
   ObjectSetString (0,fn,OBJPROP_TEXT,val);
   ObjectSetInteger(0,fn,OBJPROP_COLOR,C_TEXT_BRIGHT);
   ObjectSetInteger(0,fn,OBJPROP_BGCOLOR,C_OVERLAY);
   ObjectSetInteger(0,fn,OBJPROP_BORDER_COLOR,C_LINE_MID);
   ObjectSetInteger(0,fn,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,fn,OBJPROP_FONTSIZE,10);
   ObjectSetString (0,fn,OBJPROP_FONT,"Courier New");
   ObjectSetInteger(0,fn,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetInteger(0,fn,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,fn,OBJPROP_HIDDEN,true);
  }

void CGUIPanel::_Rect(string nm,int x,int y,int w,int h,color bg,color border,bool back)
  {
   string fn=_N(nm);
   if(ObjectFind(0,fn)>=0) ObjectDelete(0,fn);
   ObjectCreate(0,fn,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,fn,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,fn,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,fn,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,fn,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,fn,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,fn,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,fn,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,fn,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,fn,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,fn,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,fn,OBJPROP_BACK,back);
  }

void CGUIPanel::_HLine(string nm,int x,int y,int w,color clr) { _Rect(nm,x,y,w,1,clr,clrNONE,false); }

void CGUIPanel::_ScoreBar(string prefix,int x,int y,int w,int score)
  {
   int blocks=10,gap=2,bw=(w-gap*(blocks-1))/blocks,bh=10;
   int filled=(int)MathRound((double)score/10.0);
   for(int i=0;i<blocks;i++)
     {
      int bx=x+i*(bw+gap); bool lit=(i<filled);
      color lc=(i<=2)?C_LOSS:(i<=5)?C_WARN:C_BUY;
      _Rect(prefix+IntegerToString(i),bx,y,bw,bh,lit?lc:C'20,22,30',lit?lc:C_LINE,false);
     }
   _Label(prefix+"NUM",IntegerToString(score)+"/100",x+w+8,y,
          score>=70?C_BUY:score>=45?C_WARN:C_NEUTRAL,8,"Courier New");
  }

void CGUIPanel::_MiniStat(string nm,string lbl,string val,color vc,int x,int y,int col_w)
  {
   _Label(nm+"L",lbl,x,y,C_TEXT_DIM,7,"Trebuchet MS");
   _Label(nm+"V",val,x+col_w,y,vc,9,"Courier New");
  }

//+------------------------------------------------------------------+
// DrawShell, DrawWatermark, DrawHeader, DrawTabBar, DrawFooter
//+------------------------------------------------------------------+
void CGUIPanel::DrawShell()
  {
   int x=m_x,y=m_y,w=GUI_W,h=GUI_H;
   _Rect("SHADOW",x+4,y+4,w,h,C'0,0,0',clrNONE,true);
   _Rect("BODY",x,y,w,h,C_SURFACE,C_LINE,false);
   _Rect("GLOW",x+1,y+1,w-2,h-2,clrNONE,C_LINE_MID,false);
   _Rect("TOP_BAR",x+8,y+7,w-16,2,C_GOLD,clrNONE,false);
   _Rect("RAIL_L",x+5,y+14,2,h-28,C_GOLD_DIM,clrNONE,false);
  }

void CGUIPanel::DrawWatermark()
  {
   int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   int ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   int cx=cw/2,cy=ch/2; string p="WM_";
   _Label(p+"BRAND","WONKERH",cx,cy-28,C_TEXT_GHOST,36,"Arial Black",ANCHOR_CENTER);
   _Label(p+"TAGLINE","T R A D I N G   N O V I C E",cx,cy+12,C_TEXT_GHOST,9,"Trebuchet MS",ANCHOR_CENTER);
   _Label(p+"VER","v7.0  PRO",cx,cy+28,C_TEXT_GHOST,7,"Trebuchet MS",ANCHOR_CENTER);
   _HLine(p+"HL",cx-120,cy+2,100,C_GOLD_DIM); _HLine(p+"HR",cx+20,cy+2,100,C_GOLD_DIM);
   _Rect(p+"DL",cx-124,cy,5,5,C_GOLD_DIM,clrNONE,false); _Rect(p+"DR",cx+120,cy,5,5,C_GOLD_DIM,clrNONE,false);
  }

void CGUIPanel::DrawHeader()
  {
   int x=m_x,y=m_y,hw=GUI_W-16,headerY=y+14,headerH=GUI_HEADER_H-8;
   _Rect("HDR_BG",x+8,headerY,hw,headerH,C_SURFACE_HIGH,C_LINE,false);
   int logoX=x+20,logoY=headerY+10,logoW=52,logoH=52;
   _Rect("LOGO_BOX",logoX,logoY,logoW,logoH,C_BASE,C_GOLD_DIM,false);
   _Label("LOGO_W","W",logoX+logoW/2,logoY+20,C_GOLD,22,"Arial Black",ANCHOR_CENTER);
   _Label("LOGO_S","TPN",logoX+logoW/2,logoY+44,C_GOLD_DIM,7,"Trebuchet MS",ANCHOR_CENTER);
   _Rect("LOGO_TL",logoX,logoY,8,2,C_GOLD,clrNONE,false);
   _Rect("LOGO_TL2",logoX,logoY,2,8,C_GOLD,clrNONE,false);
   _Rect("LOGO_BR",logoX+logoW-8,logoY+logoH-2,8,2,C_GOLD,clrNONE,false);
   _Rect("LOGO_BR2",logoX+logoW-2,logoY+logoH-8,2,8,C_GOLD,clrNONE,false);
   int titleX=logoX+logoW+18;
   _Label("HDR_T1","DAY TRADER PRO",titleX,headerY+8,C_TEXT_BRIGHT,14,"Arial Black");
   _Label("HDR_T2","AUTOMATED EXPERT  /  v7.0",titleX,headerY+33,C_TEXT_DIM,8,"Trebuchet MS");
   _Label("HDR_T3","EXNESS  ·  MT5",titleX,headerY+47,C_GOLD_DIM,8,"Trebuchet MS");
   int acctRX=x+8+hw-10;
   _Label("HDR_BAL_L","BALANCE",acctRX,headerY+8,C_TEXT_DIM,7,"Trebuchet MS",ANCHOR_RIGHT_UPPER);
   _Label("HDR_BAL_V",StringFormat("%.2f %s",m_balance,AccountInfoString(ACCOUNT_CURRENCY)),
          acctRX,headerY+24,C_TEXT_BRIGHT,11,"Courier New",ANCHOR_RIGHT_UPPER);
   color pl_clr=m_profit>=0?C_PROFIT:C_LOSS;
   _Label("HDR_PL_L","FLOAT P/L",acctRX,headerY+44,C_TEXT_DIM,7,"Trebuchet MS",ANCHOR_RIGHT_UPPER);
   _Label("HDR_PL_V",StringFormat("%+.2f",m_profit),acctRX,headerY+60,pl_clr,11,"Courier New",ANCHOR_RIGHT_UPPER);
   _Rect("HDR_SEP",titleX+165,headerY+10,1,headerH-20,C_LINE_MID,clrNONE,false);
   _HLine("HDR_RULE",x+8,headerY+headerH+4,hw,C_LINE_MID);
  }

void CGUIPanel::DrawTabBar()
  {
   string labels[4]={"TRADE","POSITIONS","SIGNALS","ACCOUNT"};
   int tw=(GUI_W-16)/4,ty=m_y+GUI_HEADER_H+6,tx0=m_x+8;
   _Rect("TAB_BG",tx0,ty,GUI_W-16,GUI_TAB_H,C_BASE,C_LINE,false);
   for(int i=0;i<4;i++)
     {
      int bx=tx0+i*tw; bool act=(i==m_tab);
      color bg=act?C_SURFACE_HIGH:C_BASE,border=act?C_GOLD:C_LINE,tc=act?C_GOLD:C_TEXT_DIM;
      _Button("TAB_"+IntegerToString(i),labels[i],bx,ty,tw,GUI_TAB_H,bg,border,tc,9,"Trebuchet MS");
      if(act) _Rect("TAB_ACT_"+IntegerToString(i),bx+2,ty+GUI_TAB_H-2,tw-4,2,C_GOLD,clrNONE,false);
     }
  }

void CGUIPanel::DrawFooter()
  {
   int fy=m_y+GUI_H-GUI_FOOTER_H-4,fx=m_x+8,fw=GUI_W-16;
   _HLine("FTR_RULE",fx,fy-2,fw,C_LINE_MID);
   _Rect("FTR_BG",fx,fy,fw,GUI_FOOTER_H,C_BASE,clrNONE,true);
   bool ok=(TerminalInfoInteger(TERMINAL_CONNECTED)!=0);
   _Rect("FTR_DOT",fx+8,fy+10,7,7,ok?C_PROFIT:C_LOSS,clrNONE,false);
   _Label("FTR_CONN",ok?"CONNECTED":"OFFLINE",fx+20,fy+8,ok?C_PROFIT:C_LOSS,7,"Trebuchet MS");
   _Label("FTR_SYM",_Symbol,fx+fw/2,fy+8,C_TEXT_MID,7,"Trebuchet MS",ANCHOR_CENTER);
   _Label("FTR_MAGIC",StringFormat("MAGIC %d",20250001),fx+fw-4,fy+8,C_TEXT_DIM,7,"Trebuchet MS",ANCHOR_RIGHT_UPPER);
  }

//+------------------------------------------------------------------+
// DrawTradeTab
//+------------------------------------------------------------------+
void CGUIPanel::DrawTradeTab()
  {
   int cx=_ContentX(),cy=_ContentY(),cw=GUI_IW,y=cy;
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double spread=(ask-bid)/_PipSize();

   _Rect("TRD_PRICE_BG",cx-2,y,cw+4,78,C_SURFACE_RAISED,C_LINE,false);
   _Label("TRD_SYM",_Symbol,cx+8,y+8,C_GOLD,14,"Arial Black");
   int sprW=88,sprX=cx+cw-sprW;
   _Rect("TRD_SPR_BG",sprX,y+6,sprW,20,spread>2.0?C_SELL_DIM:C_BUY_DIM,C_LINE_MID,false);
   _Label("TRD_SPR_V",StringFormat("SPREAD %.1f",spread),sprX+sprW/2,y+14,C_TEXT_MID,8,"Courier New",ANCHOR_CENTER);
   _Label("TRD_BL","BID",cx+8,y+38,C_TEXT_DIM,8,"Trebuchet MS");
   _Label("TRD_BV",DoubleToString(bid,_Digits),cx+8,y+52,C_SELL,16,"Courier New");
   int askRX=cx+cw-4;
   _Label("TRD_AL","ASK",askRX,y+38,C_TEXT_DIM,8,"Trebuchet MS",ANCHOR_RIGHT_UPPER);
   _Label("TRD_AV",DoubleToString(ask,_Digits),askRX,y+52,C_BUY,16,"Courier New",ANCHOR_RIGHT_UPPER);

   y+=84; _HLine("TRD_R1",cx-2,y,cw+4,C_LINE); y+=12;

   int otw=(cw-4*2)/3;
   string otlbl[3]={"MARKET","LIMIT","STOP"};
   for(int i=0;i<3;i++)
     {
      bool sel=(i==m_order_type);
      _Button("BTN_OT_"+IntegerToString(i),otlbl[i],cx+i*(otw+4),y,otw,30,
              sel?C_SURFACE_HIGH:C_BASE,sel?C_GOLD:C_LINE,sel?C_GOLD:C_TEXT_DIM,9,"Trebuchet MS");
     }
   y+=38; _HLine("TRD_R2",cx-2,y,cw+4,C_LINE); y+=12;

   int lotLblW=68,editW=68,editX=cx+lotLblW+8,chipGap=4,chips=5;
   int chipsStartX=editX+editW+8;
   int chipW=(cx+cw-chipsStartX-(chips-1)*chipGap)/chips;
   _Label("TRD_LL","LOT SIZE",cx,y+7,C_TEXT_DIM,8,"Trebuchet MS");
   _Edit(m_edit_lots,DoubleToString(m_lots,2),editX,y,editW,28);
   double ql[5]={0.01,0.05,0.10,0.50,1.00}; string qs[5]={"0.01","0.05","0.10","0.50","1.00"};
   for(int i=0;i<chips;i++)
     {
      bool sel=MathAbs(m_lots-ql[i])<0.001;
      _Button("BTN_QL_"+IntegerToString(i),qs[i],chipsStartX+i*(chipW+chipGap),y,chipW,28,
              sel?C_SURFACE_HIGH:C_BASE,sel?C_GOLD:C_LINE,sel?C_GOLD:C_TEXT_DIM,8,"Courier New");
     }
   y+=36;

   int cardGap=10,cardW=(cw-cardGap)/2,slX=cx,tpX=cx+cardW+cardGap;
   _Rect("SL_CARD",slX,y,cardW,58,C_SURFACE_RAISED,C_LINE,false);
   _Rect("SL_TOP",slX,y,3,58,C_LOSS,clrNONE,false);
   _Label("SL_L","STOP LOSS",slX+12,y+6,C_LOSS,8,"Trebuchet MS");
   _Edit(m_edit_sl,IntegerToString(m_sl_pips),slX+10,y+24,cardW-46,26);
   _Label("SL_U","PIPS",slX+cardW-6,y+34,C_TEXT_DIM,7,"Trebuchet MS",ANCHOR_RIGHT_UPPER);
   _Rect("TP_CARD",tpX,y,cardW,58,C_SURFACE_RAISED,C_LINE,false);
   _Rect("TP_TOP",tpX,y,3,58,C_BUY,clrNONE,false);
   _Label("TP_L","TAKE PROFIT",tpX+12,y+6,C_BUY,8,"Trebuchet MS");
   _Edit(m_edit_tp,IntegerToString(m_tp_pips),tpX+10,y+24,cardW-46,26);
   _Label("TP_U","PIPS",tpX+cardW-6,y+34,C_TEXT_DIM,7,"Trebuchet MS",ANCHOR_RIGHT_UPPER);

   y+=64;
   double rr=m_sl_pips>0?(double)m_tp_pips/m_sl_pips:0;
   _Label("TRD_RR",StringFormat("RISK : REWARD   1 : %.2f",rr),cx+cw/2,y+4,rr>=1.5?C_BUY:C_WARN,9,"Courier New",ANCHOR_CENTER);
   y+=28; _HLine("TRD_R3",cx-2,y,cw+4,C_LINE); y+=12;

   int btnGap=10,btnW=(cw-btnGap)/2,btnH=68;
   _Button("BTN_BUY","",cx,y,btnW,btnH,C_BUY_DIM,C_BUY_GLOW,C_TEXT_BRIGHT);
   _Rect("BUY_ACCENT",cx,y,3,btnH,C_BUY,clrNONE,false);
   _Label("BUY_TXT","BUY",cx+btnW/2,y+26,C_TEXT_BRIGHT,22,"Arial Black",ANCHOR_CENTER);
   _Label("BUY_PRC",DoubleToString(ask,_Digits),cx+btnW/2,y+56,C_BUY,11,"Courier New",ANCHOR_CENTER);
   int sellX=cx+btnW+btnGap;
   _Button("BTN_SELL","",sellX,y,btnW,btnH,C_SELL_DIM,C_SELL_GLOW,C_TEXT_BRIGHT);
   _Rect("SELL_ACCENT",sellX,y,3,btnH,C_SELL,clrNONE,false);
   _Label("SELL_TXT","SELL",sellX+btnW/2,y+26,C_TEXT_BRIGHT,22,"Arial Black",ANCHOR_CENTER);
   _Label("SELL_PRC",DoubleToString(bid,_Digits),sellX+btnW/2,y+56,C_SELL,11,"Courier New",ANCHOR_CENTER);
   y+=btnH+14;
   _Button("BTN_CLOSE_ALL","CLOSE  ALL  POSITIONS",cx,y,cw,36,C_BASE,C_LINE_MID,C_TEXT_BRIGHT,9,"Trebuchet MS");
  }

//+------------------------------------------------------------------+
// DrawAutoTradingSection — Professional Redesign
//+------------------------------------------------------------------+
void CGUIPanel::DrawAutoTradingSection()
  {
   int cx = _ContentX();
   int cy = _ContentY();
   int cw = GUI_IW;
   
   // Calculate position after trade buttons
   int auto_y = cy + 84 + 12 + 38 + 12 + 36 + 64 + 28 + 68 + 14 + 36 + 20;
   
   // Section separator with gold accent
   _HLine("AUTO_SEP", cx - 2, auto_y, cw + 4, C_GOLD_DIM);
   auto_y += 12;
   
   // Main section background
   int section_h = 195;
   _Rect("AUTO_BG", cx - 2, auto_y, cw + 4, section_h, C_AUTO_BG, C_LINE, false);
   _Rect("AUTO_ACCENT", cx - 2, auto_y, 4, section_h, C_GOLD, clrNONE, false);
   
   // ── Header Row ──────────────────────────────────────────────────
   int header_y = auto_y + 8;
   _Label("AUTO_TITLE", "SNAP-BACK STRATEGY", cx + 14, header_y, C_GOLD, 10, "Arial Black");
   
   // Status indicator with dot
   string status_text;
   color status_color;
   if(!m_auto_enabled)
     { status_text = "OFF"; status_color = C_TEXT_DIM; }
   else if(m_auto_stage == "IDLE")
     { status_text = "IDLE"; status_color = C_NEUTRAL; }
   else if(m_auto_watching)
     { status_text = "WATCHING"; status_color = C_STAGE_WATCH; }
   else if(m_auto_reversal && m_auto_confirmations < 2)
     { status_text = "CONFIRMING"; status_color = C_STAGE_CONFIRM; }
   else if(m_auto_buy_pos + m_auto_sell_pos > 0)
     { status_text = "TRADING"; status_color = C_STAGE_TRADING; }
   else
     { status_text = "ACTIVE"; status_color = C_AUTO_ACTIVE; }
   
   int status_x = cx + cw - 14;
   _DrawStatusDot("AUTO_DOT", status_x - 80, header_y + 2, 8, m_auto_enabled, status_color);
   _Label("AUTO_STATUS", status_text, status_x - 66, header_y + 1, status_color, 9, "Arial Black", ANCHOR_LEFT_UPPER);
   _Label("AUTO_STAGE_LBL", "Stage:", status_x - 66, header_y + 16, C_TEXT_DIM, 6, "Trebuchet MS", ANCHOR_LEFT_UPPER);
   _Label("AUTO_STAGE_VAL", m_auto_stage, status_x, header_y + 15, C_TEXT_MID, 7, "Courier New", ANCHOR_RIGHT_UPPER);
   
   // ── Metric Cards Row ────────────────────────────────────────────
   int cards_y = header_y + 32;
   int card_w = (cw - 48) / 3;
   int card_h = 55;
   int card_gap = 8;
   
   // Card 1: Watch Status
   int card1_x = cx + 14;
   string watch_val = m_auto_watching ? (m_auto_watch_type == 1 ? "OVERSOLD" : "OVERBOUGHT") : "INACTIVE";
   color watch_clr = m_auto_watching ? (m_auto_watch_type == 1 ? C_BUY : C_SELL) : C_TEXT_GHOST;
   _DrawStatBox("AUTO_W", "WATCH STATUS", watch_val, watch_clr, card1_x, cards_y, card_w, card_h);
   
   // Card 2: Duration & Depth
   int card2_x = card1_x + card_w + card_gap;
   string dd_val = m_auto_watching ? StringFormat("%d bars  |  %.1f RSI", m_auto_duration, m_auto_depth) : "—";
   color dd_clr = m_auto_watching ? C_TEXT_BRIGHT : C_TEXT_GHOST;
   _DrawStatBox("AUTO_D", "DURATION / DEPTH", dd_val, dd_clr, card2_x, cards_y, card_w, card_h);
   
   // Card 3: Touches & Confirmations
   int card3_x = card2_x + card_w + card_gap;
   string tc_val = StringFormat("%d  |  %d/5", m_auto_touches, m_auto_confirmations);
   color tc_clr = m_auto_reversal ? C_STAGE_CONFIRM : C_TEXT_GHOST;
   _DrawStatBox("AUTO_C", "TOUCHES / CONFIRM", tc_val, tc_clr, card3_x, cards_y, card_w, card_h);
   
   // ── Detail Row ──────────────────────────────────────────────────
   int detail_y = cards_y + card_h + 10;
   _Rect("AUTO_DETAIL_BG", cx + 14, detail_y, cw - 28, 48, C_INFO_BG, C_LINE_MID, false);
   
   int detail_x = cx + 22;
   int detail_row_y = detail_y + 6;
   int label_w = 95;
   
   // Row 1: Direction + Breakeven
   string dir_val = m_auto_watching ? (m_auto_watch_type == 1 ? "LONG" : "SHORT") : "—";
   color dir_clr = m_auto_watching ? (m_auto_watch_type == 1 ? C_BUY : C_SELL) : C_TEXT_GHOST;
   _DrawInfoRow("AUTO_ROW1", "Direction:", dir_val, dir_clr, detail_x, detail_row_y, label_w);
   
   string be_val = m_auto_breakeven ? "ACTIVE" : "—";
   color be_clr = m_auto_breakeven ? C_PROFIT : C_TEXT_GHOST;
   _DrawInfoRow("AUTO_ROW1B", "Breakeven:", be_val, be_clr, detail_x + label_w + 80, detail_row_y, 55);
   
   detail_row_y += 16;
   
   // Row 2: Positions
   int total = m_auto_buy_pos + m_auto_sell_pos;
   string pos_val = StringFormat("BUY:%d  SELL:%d  TOTAL:%d", m_auto_buy_pos, m_auto_sell_pos, total);
   color pos_clr = total > 0 ? C_GOLD : C_TEXT_DIM;
   _DrawInfoRow("AUTO_ROW2", "Positions:", pos_val, pos_clr, detail_x, detail_row_y, label_w);
   
   detail_row_y += 16;
   
   // Row 3: Stage detail
   string stage_detail;
   if(!m_auto_enabled) stage_detail = "System disabled";
   else if(m_auto_stage == "IDLE") stage_detail = "Waiting for extreme conditions";
   else if(m_auto_watching) stage_detail = "Monitoring for reversal signals";
   else if(m_auto_reversal && m_auto_confirmations < 2) stage_detail = "Verifying reversal strength";
   else if(m_auto_buy_pos + m_auto_sell_pos > 0) stage_detail = "Managing active positions";
   else stage_detail = "Ready for next setup";
   
   _DrawInfoRow("AUTO_ROW3", "Status:", stage_detail, C_TEXT_MID, detail_x, detail_row_y, label_w);
   
   // ── Toggle Button ───────────────────────────────────────────────
   int btn_y = detail_y + 56;
   int btn_w = cw - 40;
   
   color btn_bg = m_auto_enabled ? C_SELL_DIM : C_BUY_DIM;
   color btn_border = m_auto_enabled ? C_SELL_GLOW : C_BUY_GLOW;
   string btn_text = m_auto_enabled ? "⏹  STOP  AUTO  TRADING" : "▶  START  AUTO  TRADING";
   
   _Button("AUTO_TOGGLE", btn_text, cx + 20, btn_y, btn_w, 32, btn_bg, btn_border, C_TEXT_BRIGHT, 9, "Trebuchet MS");
  }

//+------------------------------------------------------------------+
// DrawPositionsTab
//+------------------------------------------------------------------+
void CGUIPanel::DrawPositionsTab()
  {
   int cx=_ContentX(),cy=_ContentY(),cw=GUI_IW,y=cy;
   _Label("POS_TITLE",StringFormat("OPEN POSITIONS    %d",m_pos_count),cx,y,C_TEXT_BRIGHT,10,"Arial Black");
   y+=22; _HLine("POS_R0",cx-2,y,cw+4,C_LINE_MID); y+=4;
   if(m_pos_count==0)
     {
      _Label("POS_EMPTY1","NO OPEN POSITIONS",cx+cw/2,y+60,C_TEXT_DIM,11,"Trebuchet MS",ANCHOR_CENTER);
      _Label("POS_EMPTY2","Execute a trade from the TRADE tab",cx+cw/2,y+78,C_TEXT_GHOST,7,"Trebuchet MS",ANCHOR_CENTER);
      return;
     }
   int col[]={0,64,108,155,210,275};
   string hdr[]={"SYMBOL","TYPE","LOTS","P / L","ENTRY","CLOSE"};
   for(int i=0;i<6;i++) _Label("PH_"+IntegerToString(i),hdr[i],cx+col[i],y,C_GOLD_DIM,6,"Trebuchet MS");
   y+=14; _HLine("POS_R1",cx-2,y,cw+4,C_LINE); y+=2;
   int rh=38,maxsh=MathMin(m_pos_count,7);
   for(int i=0;i<maxsh;i++)
     {
      color rb=(i%2==0)?C_SURFACE_RAISED:C_BASE;
      _Rect("PR_"+IntegerToString(i),cx-2,y,cw+4,rh-1,rb,C_LINE,false);
      color tc=m_pos[i].type==0?C_BUY:C_SELL;
      _Rect("PT_"+IntegerToString(i),cx-2,y,3,rh-1,tc,clrNONE,false);
      _Label("PS_"+IntegerToString(i),m_pos[i].symbol,cx+6,y+5,C_TEXT_BRIGHT,8,"Trebuchet MS");
      _Label("PTT_"+IntegerToString(i),m_pos[i].type==0?"BUY":"SELL",cx+col[1],y+5,tc,8,"Arial Black");
      _Label("PL_"+IntegerToString(i),DoubleToString(m_pos[i].volume,2),cx+col[2],y+5,C_TEXT_MID,8,"Courier New");
      _Label("PPL_"+IntegerToString(i),StringFormat("%+.2f",m_pos[i].profit),cx+col[3],y+5,m_pos[i].profit_clr,8,"Courier New");
      _Label("PE_"+IntegerToString(i),DoubleToString(m_pos[i].open_price,_Digits),cx+col[4],y+5,C_TEXT_DIM,7,"Courier New");
      _Label("PPP_"+IntegerToString(i),StringFormat("%+.1f pips",m_pos[i].pips),cx+col[3],y+20,m_pos[i].pips>=0?C_PROFIT:C_LOSS,6,"Trebuchet MS");
      _Button("POS_CLOSE_"+IntegerToString(i),"X",cx+col[5],y+7,28,22,C_SELL_DIM,C_SELL_GLOW,C_TEXT_BRIGHT,10,"Arial Black");
      y+=rh;
     }
  }

//+------------------------------------------------------------------+
// DrawSignalsTab
//+------------------------------------------------------------------+
void CGUIPanel::DrawSignalsTab()
  {
   int cx=_ContentX(),cy=_ContentY(),cw=GUI_IW,y=cy;
   _Rect("SIG_HERO",cx-2,y,cw+4,88,C_SURFACE_RAISED,C_LINE,false);
   string sig_txt; color sig_clr; int score=0;
   switch(m_signal)
     {
      case 1:sig_txt="STRONG BUY";    sig_clr=C_BUY;     score=m_buy_score;  break;
      case 2:sig_txt="MODERATE BUY";  sig_clr=C_BUY;     score=m_buy_score;  break;
      case 3:sig_txt="STRONG SELL";   sig_clr=C_SELL;    score=m_sell_score; break;
      case 4:sig_txt="MODERATE SELL"; sig_clr=C_WARN;    score=m_sell_score; break;
      default:sig_txt="NO SIGNAL";    sig_clr=C_NEUTRAL; score=0;            break;
     }
   string arrow=(m_signal==1||m_signal==2)?"▲":(m_signal==3||m_signal==4)?"▼":"–";
   _Label("SIG_ARR",arrow,cx+12,y+14,sig_clr,30,"Arial Black");
   _Label("SIG_TXT",sig_txt,cx+54,y+16,sig_clr,16,"Arial Black");
   string conf=score>=70?"HIGH CONFIDENCE":score>=45?"MODERATE CONFIDENCE":"";
   if(conf!="") _Label("SIG_CONF",conf,cx+54,y+38,C_TEXT_DIM,7,"Trebuchet MS");
   _ScoreBar("SB_",cx+54,y+58,cw-104,score);
   _HLine("SIG_R1",cx-2,y+88,cw+4,C_LINE); y+=94;

   int hw=(cw-6)/2;
   string adx_state; color adxc;
   if(m_adx<20)       { adx_state="RANGING";       adxc=C_WARN; }
   else if(m_adx<25)  { adx_state="WEAK TREND";    adxc=C_WARN; }
   else if(m_adx<50)  { adx_state="STRONG TREND";  adxc=C_BUY;  }
   else               { adx_state="EXTREME TREND"; adxc=C_SELL; }
   _Rect("ADX_CARD",cx,y,hw,58,C_SURFACE_RAISED,C_LINE,false);
   _Label("ADX_LBL","ADX",cx+10,y+6,C_TEXT_DIM,7,"Trebuchet MS");
   _Label("ADX_VAL",StringFormat("%.1f",m_adx),cx+10,y+20,adxc,18,"Courier New");
   _Label("ADX_ST",adx_state,cx+10,y+44,adxc,7,"Trebuchet MS");
   _Rect("ADX_BAR",cx,y,3,58,adxc,clrNONE,false);

   string rsi_state; color rsic;
   if(m_rsi<30)       { rsi_state="OVERSOLD";        rsic=C_BUY;  }
   else if(m_rsi<40)  { rsi_state="NEAR OVERSOLD";   rsic=C_BUY;  }
   else if(m_rsi<60)  { rsi_state="NEUTRAL";         rsic=C_WARN; }
   else if(m_rsi<70)  { rsi_state="NEAR OVERBOUGHT"; rsic=C_WARN; }
   else               { rsi_state="OVERBOUGHT";      rsic=C_SELL; }
   _Rect("RSI_CARD",cx+hw+6,y,hw,58,C_SURFACE_RAISED,C_LINE,false);
   _Label("RSI_LBL","RSI",cx+hw+16,y+6,C_TEXT_DIM,7,"Trebuchet MS");
   _Label("RSI_VAL",StringFormat("%.1f",m_rsi),cx+hw+16,y+20,rsic,18,"Courier New");
   _Label("RSI_ST",rsi_state,cx+hw+16,y+44,rsic,7,"Trebuchet MS");
   _Rect("RSI_BAR",cx+hw+6,y,3,58,rsic,clrNONE,false);

   y+=66; _HLine("SIG_R2",cx-2,y,cw+4,C_LINE); y+=10;
   _Label("WL_HDR","QUICK TRADE  —  WATCHLIST",cx,y,C_TEXT_BRIGHT,9,"Arial Black");
   y+=20; _HLine("WL_R",cx-2,y,cw+4,C_LINE); y+=4;
   int bw2=54,rh=GUI_ROW;
   for(int i=0;i<5;i++)
     {
      color rb=(i%2==0)?C_SURFACE_RAISED:C_BASE;
      _Rect("WR_"+IntegerToString(i),cx-2,y,cw+4,rh-1,rb,C_LINE,false);
      _Label("WS_"+IntegerToString(i),m_wl_sym[i],cx+8,y+6,C_TEXT_BRIGHT,9,"Trebuchet MS");
      _Button("WL_B_"+IntegerToString(i),"BUY",cx+cw-118,y+2,bw2,rh-5,C_BUY_DIM,C_BUY_GLOW,C_BUY,8,"Trebuchet MS");
      _Button("WL_S_"+IntegerToString(i),"SELL",cx+cw-60,y+2,bw2,rh-5,C_SELL_DIM,C_SELL_GLOW,C_SELL,8,"Trebuchet MS");
      y+=rh;
     }
  }

//+------------------------------------------------------------------+
// DrawAccountTab
//+------------------------------------------------------------------+
void CGUIPanel::DrawAccountTab()
  {
   int cx=_ContentX(),cy=_ContentY(),cw=GUI_IW,y=cy,rh=GUI_ROW;
   _Label("ACC_HDR","ACCOUNT  SUMMARY",cx,y,C_TEXT_BRIGHT,10,"Arial Black");
   y+=22; _HLine("ACC_R0",cx-2,y,cw+4,C_LINE_MID); y+=8;
   struct AStat{string lbl,val; color vc;}; AStat stats[4];
   stats[0].lbl="BALANCE";    stats[0].val=StringFormat("%.2f  %s",m_balance,AccountInfoString(ACCOUNT_CURRENCY)); stats[0].vc=C_TEXT_BRIGHT;
   stats[1].lbl="EQUITY";     stats[1].val=StringFormat("%.2f  %s",m_equity, AccountInfoString(ACCOUNT_CURRENCY)); stats[1].vc=C_TEXT_BRIGHT;
   stats[2].lbl="FLOAT P / L";stats[2].val=StringFormat("%+.2f  %s",m_profit,AccountInfoString(ACCOUNT_CURRENCY)); stats[2].vc=m_profit>=0?C_PROFIT:C_LOSS;
   stats[3].lbl="MARGIN";     stats[3].val=StringFormat("%.2f  %s",m_margin, AccountInfoString(ACCOUNT_CURRENCY)); stats[3].vc=C_TEXT_MID;
   for(int i=0;i<4;i++)
     {
      color rb=(i%2==0)?C_SURFACE_RAISED:C_BASE;
      _Rect("AS_R_"+IntegerToString(i),cx-2,y,cw+4,rh,rb,C_LINE,false);
      _Rect("AS_S_"+IntegerToString(i),cx-2,y,3,rh,(i==2)?stats[i].vc:C_GOLD_DIM,clrNONE,false);
      _Label("AS_L_"+IntegerToString(i),stats[i].lbl,cx+10,y+5,C_TEXT_DIM,7,"Trebuchet MS");
      _Label("AS_V_"+IntegerToString(i),stats[i].val,cx+cw-6,y+5,stats[i].vc,10,"Courier New",ANCHOR_RIGHT_UPPER);
      y+=rh;
     }
   y+=8; _HLine("ACC_R1",cx-2,y,cw+4,C_LINE); y+=12;
   _Label("ML_HDR","MARGIN  LEVEL",cx,y,C_TEXT_BRIGHT,9,"Arial Black"); y+=20;
   color ml_clr=m_margin_level>200?C_PROFIT:m_margin_level>100?C_WARN:C_LOSS;
   _Label("ML_VAL",StringFormat("%.1f %%",m_margin_level),cx+cw-6,y,ml_clr,12,"Courier New",ANCHOR_RIGHT_UPPER);
   y+=20;
   int tw=cw,th=16;
   _Rect("ML_TRACK",cx,y,tw,th,C'20,22,30',C_LINE,false);
   int fw=(int)MathMin(MathMax(m_margin_level/400.0,0.0),1.0)*tw;
   _Rect("ML_FILL",cx,y,MathMax(fw,4),th,ml_clr,clrNONE,false);
   _Label("ML_LBL",m_margin_level>200?"SAFE":m_margin_level>100?"CAUTION":"MARGIN CALL RISK",
          cx+tw/2,y+th/2,C_TEXT_BRIGHT,7,"Trebuchet MS",ANCHOR_CENTER);
   y+=th+12; _HLine("ACC_R2",cx-2,y,cw+4,C_LINE); y+=12;
   _Label("RISK_HDR","RISK  EXPOSURE",cx,y,C_TEXT_BRIGHT,9,"Arial Black"); y+=20;
   double risk_pct=m_balance>0?(m_margin/m_balance)*100.0:0;
   int mh=16; color rc=risk_pct<30?C_PROFIT:risk_pct<60?C_WARN:C_LOSS;
   int rfill=(int)MathMin(risk_pct/100.0,1.0)*tw;
   _Rect("RISK_TRACK",cx,y,tw,mh,C'20,22,30',C_LINE,false);
   _Rect("RISK_FILL",cx,y,MathMax(rfill,4),mh,rc,clrNONE,false);
   _Label("RISK_TXT",StringFormat("%.1f %%   %s",risk_pct,risk_pct<30?"LOW RISK":risk_pct<60?"MODERATE":"HIGH RISK"),
          cx+tw/2,y+mh/2,C_TEXT_BRIGHT,7,"Trebuchet MS",ANCHOR_CENTER);
   y+=mh+12; _HLine("ACC_R3",cx-2,y,cw+4,C_LINE); y+=12;
   string broker=AccountInfoString(ACCOUNT_COMPANY),server=AccountInfoString(ACCOUNT_SERVER),cur=AccountInfoString(ACCOUNT_CURRENCY);
   long acct=AccountInfoInteger(ACCOUNT_LOGIN); int lev=(int)AccountInfoInteger(ACCOUNT_LEVERAGE);
   _MiniStat("AM_1","BROKER",broker,C_TEXT_MID,cx,y,90); y+=rh-4;
   _MiniStat("AM_2","SERVER",server,C_TEXT_MID,cx,y,90); y+=rh-4;
   _MiniStat("AM_3","ACCOUNT",IntegerToString(acct),C_GOLD,cx,y,90); y+=rh-4;
   _MiniStat("AM_4","CURRENCY",cur,C_TEXT_MID,cx,y,90); y+=rh-4;
   _MiniStat("AM_5","LEVERAGE",StringFormat("1 : %d",lev),C_WARN,cx,y,90);
  }

//+------------------------------------------------------------------+
// _UpdateAccount, _UpdatePositions, _PipSize
//+------------------------------------------------------------------+
void CGUIPanel::_UpdateAccount()
  {
   m_balance=AccountInfoDouble(ACCOUNT_BALANCE); m_equity=AccountInfoDouble(ACCOUNT_EQUITY);
   m_profit=AccountInfoDouble(ACCOUNT_PROFIT);   m_margin=AccountInfoDouble(ACCOUNT_MARGIN);
   m_margin_level=AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
  }

void CGUIPanel::_UpdatePositions()
  {
   ArrayResize(m_pos,20); m_pos_count=0;
   double ps=_PipSize();
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      m_pos[m_pos_count].ticket=tk;
      m_pos[m_pos_count].symbol=PositionGetString(POSITION_SYMBOL);
      m_pos[m_pos_count].type=(int)PositionGetInteger(POSITION_TYPE);
      m_pos[m_pos_count].volume=PositionGetDouble(POSITION_VOLUME);
      m_pos[m_pos_count].open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      m_pos[m_pos_count].sl=PositionGetDouble(POSITION_SL);
      m_pos[m_pos_count].tp=PositionGetDouble(POSITION_TP);
      m_pos[m_pos_count].profit=PositionGetDouble(POSITION_PROFIT);
      m_pos[m_pos_count].current_price=m_pos[m_pos_count].type==0?
         SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double rp=(m_pos[m_pos_count].current_price-m_pos[m_pos_count].open_price)/ps;
      m_pos[m_pos_count].pips=m_pos[m_pos_count].type==1?-rp:rp;
      m_pos[m_pos_count].profit_clr=m_pos[m_pos_count].profit>=0?C_PROFIT:C_LOSS;
      m_pos_count++;
     }
  }

double CGUIPanel::_PipSize()
  {
   double pt=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   int dg=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   return(dg==5||dg==3)?pt*10.0:pt;
  }

//+------------------------------------------------------------------+
// _ExecuteBuy, _ExecuteSell, _CloseAll
//+------------------------------------------------------------------+
void CGUIPanel::_ExecuteBuy()
  {
   string lots_str=ObjectGetString(0,m_edit_lots,OBJPROP_TEXT);
   string sl_str  =ObjectGetString(0,m_edit_sl,  OBJPROP_TEXT);
   string tp_str  =ObjectGetString(0,m_edit_tp,  OBJPROP_TEXT);
   m_lots   =StringToDouble(lots_str);
   m_sl_pips=(int)StringToInteger(sl_str);
   m_tp_pips=(int)StringToInteger(tp_str);
   double min_lot =SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double max_lot =SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   m_lots=MathMax(min_lot,MathMin(max_lot,MathRound(m_lots/step_lot)*step_lot));
   CTrade t; t.SetExpertMagicNumber(20250001);
   double price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double ps=_PipSize();
   long   stop_lvl=(long)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double min_dist=MathMax(m_sl_pips,stop_lvl+1)*ps;
   double sl=(m_sl_pips>0)?price-m_sl_pips*ps:0;
   double tp=(m_tp_pips>0)?price+m_tp_pips*ps:0;
   if(sl>0 && MathAbs(price-sl)<stop_lvl*ps) sl=price-min_dist;
   if(tp>0 && MathAbs(tp-price)<stop_lvl*ps) tp=price+min_dist*(m_tp_pips>0?(double)m_tp_pips/m_sl_pips:1.0);
   sl=NormalizeDouble(sl,_Digits); tp=NormalizeDouble(tp,_Digits);
   if(!t.Buy(m_lots,_Symbol,price,sl,tp,"DTP7_GUI_BUY"))
      PrintFormat("[DTP7][GUI] BUY failed — error %d",GetLastError());
   else
      PrintFormat("[DTP7][GUI] BUY %.2f @ %.5f  SL=%.5f  TP=%.5f",m_lots,price,sl,tp);
   Draw();
  }

void CGUIPanel::_ExecuteSell()
  {
   string lots_str=ObjectGetString(0,m_edit_lots,OBJPROP_TEXT);
   string sl_str  =ObjectGetString(0,m_edit_sl,  OBJPROP_TEXT);
   string tp_str  =ObjectGetString(0,m_edit_tp,  OBJPROP_TEXT);
   m_lots   =StringToDouble(lots_str);
   m_sl_pips=(int)StringToInteger(sl_str);
   m_tp_pips=(int)StringToInteger(tp_str);
   double min_lot =SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double max_lot =SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   m_lots=MathMax(min_lot,MathMin(max_lot,MathRound(m_lots/step_lot)*step_lot));
   CTrade t; t.SetExpertMagicNumber(20250001);
   double price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ps=_PipSize();
   long   stop_lvl=(long)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double min_dist=MathMax(m_sl_pips,stop_lvl+1)*ps;
   double sl=(m_sl_pips>0)?price+m_sl_pips*ps:0;
   double tp=(m_tp_pips>0)?price-m_tp_pips*ps:0;
   if(sl>0 && MathAbs(sl-price)<stop_lvl*ps) sl=price+min_dist;
   if(tp>0 && MathAbs(price-tp)<stop_lvl*ps) tp=price-min_dist*(m_tp_pips>0?(double)m_tp_pips/m_sl_pips:1.0);
   sl=NormalizeDouble(sl,_Digits); tp=NormalizeDouble(tp,_Digits);
   if(!t.Sell(m_lots,_Symbol,price,sl,tp,"DTP7_GUI_SELL"))
      PrintFormat("[DTP7][GUI] SELL failed — error %d",GetLastError());
   else
      PrintFormat("[DTP7][GUI] SELL %.2f @ %.5f  SL=%.5f  TP=%.5f",m_lots,price,sl,tp);
   Draw();
  }

void CGUIPanel::_CloseAll()
  {
   CTrade t;
   for(int i=PositionsTotal()-1;i>=0;i--)
     { ulong tk=PositionGetTicket(i); t.PositionClose(tk); }
   Print("[DTP7][GUI] Close-all executed.");
   Draw();
  }

//+------------------------------------------------------------------+
// OnChartEvent
//+------------------------------------------------------------------+
void CGUIPanel::OnChartEvent(const int id,const long &lp,const double &dp,const string &sp)
  {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(StringFind(sp,GUI_PREFIX)!=0) return;
   string nm=StringSubstr(sp,StringLen(GUI_PREFIX));

   for(int i=0;i<4;i++) if(nm=="TAB_"+IntegerToString(i)){m_tab=(ENUM_GUI_TAB)i;Draw();return;}
   for(int i=0;i<3;i++) if(nm=="BTN_OT_"+IntegerToString(i)){m_order_type=(ENUM_GUI_ORDER)i;Draw();return;}
   double ql[5]={0.01,0.05,0.10,0.50,1.00};
   for(int i=0;i<5;i++) if(nm=="BTN_QL_"+IntegerToString(i))
     {m_lots=ql[i];ObjectSetString(0,m_edit_lots,OBJPROP_TEXT,DoubleToString(m_lots,2));Draw();return;}
   if(nm=="BTN_BUY")  {_ExecuteBuy();  return;}
   if(nm=="BTN_SELL") {_ExecuteSell(); return;}
   if(nm=="BTN_CLOSE_ALL"){_CloseAll();return;}
   for(int i=0;i<m_pos_count;i++) if(nm=="POS_CLOSE_"+IntegerToString(i))
     {CTrade t;t.PositionClose(m_pos[i].ticket);Draw();return;}
   
   if(nm=="AUTO_TOGGLE")
     {
      EventChartCustom(0, 1001, m_auto_enabled ? 0 : 1, 0, "AUTO_TOGGLE");
      return;
     }
  }
//+------------------------------------------------------------------+