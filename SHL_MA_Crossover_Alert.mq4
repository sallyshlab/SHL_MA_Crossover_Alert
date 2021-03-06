//+------------------------------------------------------------------+
//|                                       SHL_MA_Crossover_Alert.mq4 |
//|                             Copyright 2020, Sally's Holiday Lab. |
//|                                    https://sallys-holiday-lab.jp |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Sally's Holiday Lab."
#property link      "https://sallys-holiday-lab.jp"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot Soon
#property indicator_label1  "Soon"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrDeepPink
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Done
#property indicator_label2  "Done"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrLime
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      ma_short_period=5; //短期移動平均線の設定値
input int      ma_medium_period=20; //中期移動平均線の設定値
input int      ma_long_period=50; //長期移動平均線の設定値
input int      ma_method=MODE_SMA; //移動平均線の種類
input int      applied_price=PRICE_CLOSE; //移動平均の計算に適用する価格タイプ
input double allowable_width_pips=5.0; //クロスしそうだと判断する許容pips
//--- indicator buffers
double         SoonBuffer[];
double         DoneBuffer[];
//--- other
const string script_name="SHL_MA_Crossover_Alert";
const string status_soon="SOON";
const string status_done="DONE";
const string po_status_none="NONE";
const string po_status_up="UP";
const string po_status_down="DOWN";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SoonBuffer);
   SetIndexBuffer(1,DoneBuffer);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,159);
   PlotIndexSetInteger(1,PLOT_ARROW,159);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   static datetime dt=Time[0];
   if(Time[0]!=dt)
   {
      dt=Time[0];
      const double ma_short_current=iMA(NULL,PERIOD_CURRENT,ma_short_period,0,ma_method,applied_price,0);
      const double ma_medium_current=iMA(NULL,PERIOD_CURRENT,ma_medium_period,0,ma_method,applied_price,0);
      const double ma_long_current=iMA(NULL,PERIOD_CURRENT,ma_long_period,0,ma_method,applied_price,0);
      const double ma_short_prev=iMA(NULL,PERIOD_CURRENT,ma_short_period,0,ma_method,applied_price,1);
      const double ma_medium_prev=iMA(NULL,PERIOD_CURRENT,ma_medium_period,0,ma_method,applied_price,1);
      const double ma_long_prev=iMA(NULL,PERIOD_CURRENT,ma_long_period,0,ma_method,applied_price,1);
      const bool crossover_soon_judgement=CrossoverSoonJudgement(ma_short_current,
         ma_medium_current,
         ma_long_current);
      const bool crossover_done_judgement=CrossoverDoneJudgement(ma_short_current,
         ma_medium_current,
         ma_long_current,
         ma_short_prev,
         ma_medium_prev,
         ma_long_prev);
      if(crossover_soon_judgement||crossover_done_judgement)
      {
         const int perfect_order_judgement=PerfectOrderJudgement(ma_short_current,
            ma_medium_current,
            ma_long_current);
         if(crossover_done_judgement)
         {
            SendCustomMail(status_done,GetPerfectOrderResult(perfect_order_judgement));
         }
         else if(crossover_soon_judgement)
         {
            SendCustomMail(status_soon,GetPerfectOrderResult(perfect_order_judgement));
         }
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| 1.交差しそうか？                                                   |
//| 　2つのMAがNpips以内に近づいた場合       |
//| 　※何度もアラートが飛ばないように終値で判断       |
//+------------------------------------------------------------------+
bool CrossoverSoonJudgement(const double ma_short,
  const double ma_medium,
  const double ma_long)
  {
//---
   double allowable_width_pips_tmp=allowable_width_pips/2;
   if(allowable_width_pips_tmp<0)
   {
      allowable_width_pips_tmp=-allowable_width_pips_tmp;
   }
   double diff_short_medium=PriceToPips(ma_short-ma_medium);
   double diff_short_long=PriceToPips(ma_short-ma_long);
   double diff_medium_long=PriceToPips(ma_medium-ma_long);
   if((-allowable_width_pips_tmp<diff_short_medium&&diff_short_medium<allowable_width_pips_tmp)||
   (-allowable_width_pips_tmp<diff_short_long&&diff_short_long<allowable_width_pips_tmp)||
   (-allowable_width_pips_tmp<diff_medium_long&&diff_medium_long<allowable_width_pips_tmp))
   {
      Print("CrossoverSoonJudgement: true");
      return(true);
   }
   Print("CrossoverSoonJudgement: false");
   return(false);
  }
//+------------------------------------------------------------------+
//| 価格をpipsに換算する関数
//| (C) https://minagachi.com/price-to-pips
//+------------------------------------------------------------------+
double PriceToPips(double price)
{
   double pips = 0;

   // 現在の通貨ペアの小数点以下の桁数を取得
   int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);

   // 3桁・5桁のFXブローカーの場合
   if(digits == 3 || digits == 5){
     pips = price * MathPow(10, digits) / 10;
   }
   // 2桁・4桁のFXブローカーの場合
   if(digits == 2 || digits == 4){
     pips = price * MathPow(10, digits);
   }
   // 少数点以下を１桁に丸める（目的によって桁数は変更する）
   pips = NormalizeDouble(pips, 1);

   return(pips);
}
//+------------------------------------------------------------------+
//| 2.交差し終えたか？                                                   |
//| 　1つ前のローソク足上のMAと順番が入れ替わった場合       |
//| 　※何度もアラートが飛ばないように終値で判断       |
//+------------------------------------------------------------------+
bool CrossoverDoneJudgement(const double ma_short_current,
   const double ma_medium_current,
   const double ma_long_current,
   const double ma_short_prev,
   const double ma_medium_prev,
   const double ma_long_prev)
  {
//---
   double current[3][2];
   current[0][0]=ma_short_current;
   current[0][1]=0;
   current[1][0]=ma_medium_current;
   current[1][1]=1;
   current[2][0]=ma_long_current;
   current[2][1]=2;
   double prev[3][2];
   prev[0][0]=ma_short_prev;
   prev[0][1]=0;
   prev[1][0]=ma_medium_prev;
   prev[1][1]=1;
   prev[2][0]=ma_long_prev;
   prev[2][1]=2;
   ArraySort(current);
   ArraySort(prev);
   for(int i=0; i<ArrayRange(current,0); i++)
   {
      if(current[i][1]!=prev[i][1])
      {
         Print("CrossoverDoneJudgement: true");
         return(true);
      }
   }
   Print("CrossoverDoneJudgement: false");
   return(false);
  }
//+------------------------------------------------------------------+
//| フラグ.パーフェクトオーダー                                                   |
//| 　単にMAの本数の昇降順だけを見る       |
//| 　※1:上昇,2:下降,0:どちらでもない       |
//+------------------------------------------------------------------+
int PerfectOrderJudgement(const double ma_short,
  const double ma_medium,
  const double ma_long)
  {
//---
   Print("MA SHORT: "+DoubleToStr(ma_short,3)+", MA MEDIUM: "+DoubleToStr(ma_medium,3)+", MA LONG: "+DoubleToStr(ma_long,3));
   if(ma_short>ma_medium&&ma_medium>ma_long)
   {
      return(1);
   }
   else if(ma_short<ma_medium&&ma_medium<ma_long)
   {
      return(2);
   }
   else
   {
      return(0);
   }
  }
string GetPerfectOrderResult(const int perfect_order_judgement)
  {
//---
   switch(perfect_order_judgement)
   {
      case 0:
         Print("GetPerfectOrderResult: none");
         return(po_status_none);
      case 1:
         Print("GetPerfectOrderResult: up");
         return(po_status_up);
      case 2:
         Print("GetPerfectOrderResult: down");
         return(po_status_down);
      default:
         Print("GetPerfectOrderResult: none");
         return(po_status_none);
   }
  }
//+------------------------------------------------------------------+
//| アラートメール送信                                                   |
//+------------------------------------------------------------------+
void SendCustomMail(const string stauts,
  const string perfect_order_result)
  {
//---
   const string subject=script_name+": "+Symbol()+" "+stauts;
   const string content="Perfect Order: "+perfect_order_result;
   SendMail(subject,content);
   Print("Sended Mail.");
  }
//+------------------------------------------------------------------+
