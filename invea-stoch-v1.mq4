//+------------------------------------------------------------------+
//|     基于stoch指标
//|     1、水平线高点85以上，地点15以下寻找入场时机                                        
//|     2、假设买入，入场时判断当前价格距离前两个柱子最高点差值应该小于2.2点，止损6点左右
//|     3、假设持有buy单，当stoch绿线值处于85以上并下穿下来则考虑卖出，否则尝试持续持有
//|     4、假设持有sell单，如果stoch绿线从中途cross红线，如果损失在2-3点内，则考虑止损
//|     5、TODO 如果上一个up止损出局，那必须得下次开up单的时候判断前多少时间内至少up上去到超买区一次，以防趋势。
//|     6、TODO 可以采用如up单如果处于超买区，但是没正式下来到某一level水平就不平，综合可以参考PA价格一起判断。             
//|     7、bug ## 等待与high最高点差2.5点准备开sell单的时候，信号线和main先在底部交叉回来了，所以要加判断
//+------------------------------------------------------------------+
#property copyright "xiaoxin003"
#property link      "yangjx009@139.com"
#property version   "1.0"
#property strict

#include <Arrays\ArrayInt.mqh>
#include "inc\dictionary.mqh" //keyvalue数据字典类
#include "inc\trademgr.mqh"   //交易工具类
#include "inc\citems.mqh"     //交易组item


extern int       MagicNumber     = 20180602;
extern double    Lots            = 0.3;
extern double    TPinMoney       = 45;          //Net TP (money)
extern int       intSL           = 6;            //止损点数，不用加0
extern double    distance        = 5;   //加仓间隔点数

extern double    levelHigh      = 85;
extern double    levelLow       = 15;


int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM1,CheckTimeM5;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CDictionary *objDict = NULL;     //订单数据字典类
int tmp = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   Print("begin");
   if(Digits==2 || Digits==4) Pip = Point;
   else if(Digits==3 || Digits==5) Pip = 10*Point;
   else if(Digits==6) Pip = 100*Point;
   if(objDict == NULL){
      objDict = new CDictionary();
      objCTradeMgr = new CTradeMgr(MagicNumber, Pip, NumberOfTries, Slippage);
   }
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("deinit");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

string strSignal = "none";
int intTrigger = 0;   //产生信号过多少分钟
bool isSignalOpenOrder = false;  //当前信号是否已开单
void OnTick()
{
     subPrintDetails();
     doTrade();
     //M1产生交易
     if(CheckTimeM1==iTime(NULL,PERIOD_M1,0)){
         
     } else {
         string strSg = signal();
         if(strSg != "none"){
            //等于0表示趋势改变
            strSignal = strSg;
            intTrigger = 0;
            isSignalOpenOrder = false;
         }else{
            intTrigger += 1;
         }
         CheckTimeM1 = iTime(NULL,PERIOD_M1,0);
         tpMgr();
         
     }
 }


 //信号检测
string signal()
{

   double fast = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double fast_pre = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   double fast_pre3 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 3);
   
   double slow = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1);
   double slow_pre = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 2);
   double slow_pre3 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 3);

   if((fast_pre >= levelHigh || fast_pre3>= levelHigh ) && fast_pre>slow_pre && fast<slow && (slow - fast >=2.5 || fast_pre - fast >= 5)){
      Print("signal=>down");
      return "down";
   }
   
   if((fast_pre <= levelLow || fast_pre3<= levelLow ) && fast_pre<slow_pre && fast>slow && (fast - slow >=2.5 || fast - fast_pre >= 5)){
      Print("signal=>up");
      return "up";
   }
   
   return "none";
}

void tpMgr(){
   if(objCTradeMgr.Total()<=0)return ;
   int tradeType,tradeTicket;
   double tradePrice,tradeProfit;
   datetime dt,dtNow;
   for(int cnt=0;cnt<OrdersTotal();cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL &&
         OrderSymbol()==Symbol() &&
         OrderMagicNumber()==MagicNumber)
      {
         dt = OrderOpenTime();
         tradeType = OrderType();
         tradePrice = OrderOpenPrice();
         tradeTicket = OrderTicket();
         tradeProfit = OrderProfit();
         dtNow = iTime(NULL,PERIOD_M1,1);
         if(tradeType == OP_BUY){
            if(tradeProfit >= TPinMoney){
               objCTradeMgr.Close(tradeTicket);
            }else if((dtNow-dt)/(PERIOD_M1*60) >=25 && tradeProfit>0 && tradeProfit<=2*Lots*10){
               objCTradeMgr.Close(tradeTicket);
            }else {
               double fast = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
               double fast_pre = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
               
               double slow = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1);
               double slow_pre = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 2);
               if(fast_pre > slow_pre && fast < slow && fast<20){
                  if(tradeProfit<0 && tradeProfit>=-1*2.5*Lots*10){
                     objCTradeMgr.Close(tradeTicket);
                  }
               }
               if(fast <levelLow && tradeProfit >= 3*Lots*10){
                  objCTradeMgr.Close(tradeTicket);
               }
               if(strSignal == "down" && tradeProfit >= 3*Lots*10){
                  objCTradeMgr.Close(tradeTicket);
               }
            }
            
            
         }
         if(tradeType == OP_SELL){
            if(tradeProfit >= TPinMoney){
               objCTradeMgr.Close(tradeTicket);
            }else if((dtNow-dt)/(PERIOD_M1*60) >=25 && tradeProfit>0 && tradeProfit<=2*Lots*10){
               objCTradeMgr.Close(tradeTicket);
            }else {
               double fast = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
               double fast_pre = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
               
               double slow = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1);
               double slow_pre = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 2);
               if(fast_pre < slow_pre && fast > slow && fast > 80){
                  if(tradeProfit<0 && tradeProfit>=-1*2.5*Lots*10){
                     objCTradeMgr.Close(tradeTicket);
                  }
               }
               if(fast >levelHigh && tradeProfit >= 3*Lots*10){
                  objCTradeMgr.Close(tradeTicket);
               }
               if(strSignal == "up" && tradeProfit >= 3*Lots*10){
                  objCTradeMgr.Close(tradeTicket);
               }
            }
         }
         
         
      }         
   }
}


//交易判断
void doTrade(){
   if(isSignalOpenOrder)return;
   if(strSignal == "up" && intTrigger<=3){
      Print("doTrade:up");
      int low_index=iLowest(NULL,0,MODE_LOW,5,1);
      if(low_index!=-1){
          double val=Low[low_index];
          Print("doTrade:low value =",val,";Ask=",Ask,";diff=",(Ask - val));
          if(Ask - val >= 0 && Ask - val <= 2.5*Pip){
              Print("doTrade:up < 2.5 pip");
              checkTradeM1(strSignal);
          }
      }else{
         Print("doTrade:low_index is -1");
      }
   }
   
   if(strSignal == "down" && intTrigger<=3){
      Print("doTrade:down");
      int high_index=iHighest(NULL,0,MODE_HIGH,5,1);
      if(high_index!=-1){
          double val=High[high_index];
          if(val - Bid >= 0 && val - Bid <= 2.5*Pip){
               Print("doTrade:down < 2.5 pip");
              checkTradeM1(strSignal);
          }
      }else{
         Print("doTrade:high_index is -1");
      }
   }
}

void checkTradeM1(string type){
   if(isSignalOpenOrder)return;
   if(objCTradeMgr.Total()>0)return ;
   int t;
   if(strSignal == "up"){
      Print("checkTradeM1:up");
      t = objCTradeMgr.Buy(Lots, intSL, 0, "up");
      if(t != 0){
         isSignalOpenOrder = true;
         
      }
   }else if(strSignal == "down"){
      Print("checkTradeM1:down");
      t = objCTradeMgr.Sell(Lots, intSL, 0, "down");
      if(t != 0){
         isSignalOpenOrder = true;
         
      }
   }
}



void subPrintDetails()
{
   //
   string sComment   = "";
   string sp         = "----------------------------------------\n";
   string NL         = "\n";

   sComment = sp;
   sComment = sComment + "Net = " + TotalNetProfit() + NL; 
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,2) + NL;
   Comment(sComment);
}

double TotalNetProfit()
{
     double op = 0;
     for(int cnt=0;cnt<OrdersTotal();cnt++)
      {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()<=OP_SELL &&
            OrderSymbol()==Symbol() &&
            OrderMagicNumber()==MagicNumber)
         {
            op = op + OrderProfit();
         }         
      }
      return op;
}


