//+------------------------------------------------------------------+
//|     基于stoch指标
//|     1、水平线高点85以上，地点15以下寻找入场时机                                        
//|     2、假设买入，入场时判断当前价格距离前两个柱子最高点差值应该小于2.2点，止损6点左右
//|     3、假设持有buy单，当stoch绿线值处于85以上并下穿下来则考虑卖出，否则尝试持续持有
//|     4、假设持有sell单，如果stoch绿线从中途cross红线，如果损失在2-3点内，则考虑止损
//      5、open前检测lastOrder状态。
//      6、
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
extern double    TPinMoney       = 30;          //Net TP (money)
extern int       intSL           = 6;            //止损点数，不用加0
extern double    distance        = 5;   //加仓间隔点数

extern double    levelHigh      = 81;
extern double    levelLow       = 19;
extern bool      isTrailStop    = true;


int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM1,CheckTimeM5;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CDictionary *objDict = NULL;     //订单数据字典类
int tmp = 0;

string TrendType     = "none";
int    intTrendTrriger   = -1;   //第几根柱子发生的，0表示当前
bool   TrendLossed   = false; //当前趋势下发生了亏损

int    lastTicket    = -1;
int    lastTicketStatus = 2;    //0:持有中，1:止盈，-1：止损，2：不考虑了

double AO,AO2,AO3;
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
     updateLastTicketStatus();
     subPrintDetails();
     checkEntryStoch();
     //M1产生交易
     if(CheckTimeM1==iTime(NULL,PERIOD_M1,0)){
         
     } else {
         getTrend();
         getAO();
         //checkEntryTEMA();
         //////////////////////////
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
         trailStop();
         
     }
 }


 //信号检测
string signal()
{
   double fast[5];
   double slow[5];
   int j;
   for( j=0;j<5;j++) {
      fast[j] = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, j+1);
   }
   for( j=0;j<5;j++) {
      slow[j] = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, j+1);
   }
   /*
   double fast1 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double fast2 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   double fast3 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 3);
   double fast4 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 4);
   double fast5 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 5);
   
   double slow1 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1);
   double slow2 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 2);
   double slow3 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 3);
   double slow4 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 4);
   double slow5 = iStochastic(NULL, 0, 8, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 5);
   */
   double highest_fast=-1,highest_slow=-1;
   double lowest_fast=100,lowest_slow=100;
   int iH=-1,iL=-1,iOut=-1;
   if(fast[0] < 80 && fast[1] > 80){
      for( j=0;j<5;j++) {
         if(fast[j]>highest_fast){
            highest_fast=fast[j];
            iH = j;
         }
         if(slow[j] >highest_slow){
            highest_slow = slow[j];
         }
         if(fast[j] < 80 && j>1 && iOut == -1){
            iOut = j;
         }
      }
      if(iOut != -1 && highest_fast>=levelHigh && highest_slow>80){
         Print("signal=>down");
         return "down";
      }
   }
   if(fast[0] >20 && fast[1] < 20){
      for( j=0;j<5;j++) {
         if(fast[j]<lowest_fast){
            lowest_fast=fast[j];
            iH = j;
         }
         if(slow[j] <lowest_slow){
            lowest_slow = slow[j];
         }
         if(fast[j] > 20 && j>1 && iOut == -1){
            iOut = j;
         }
      }
      if(iOut != -1 && lowest_fast<=levelLow && lowest_slow<20){
        Print("signal=>up");
         return "up";
      }
   }
  
   return "none";
}


//交易判断
void checkEntryStoch(){
   if(isSignalOpenOrder)return;
   if(lastTicketStatus == -1)return;   //最后一order在当前trend下发生了loss，则不open
   if(strSignal == "up" && intTrigger<=2){
      Print("checkEntry:up");
      int low_index=iLowest(NULL,0,MODE_LOW,3,1);
      if(low_index!=-1){
          double val=Low[low_index];
          Print("checkEntry:low value =",val,";Ask=",Ask,";diff=",(Ask - val));
          if(Ask - val >= 0.2*Pip && Ask - val <= 5*Pip){
              Print("checkEntry:up < 2.5 pip");
              if(AO > AO2 && AO>AO3) 
              entry(strSignal, MathFloor((Ask - val)/Pip));
          }
      }else{
         Print("checkEntry:low_index is -1");
      }
   }
   
   if(strSignal == "down" && intTrigger<=2){
      Print("checkEntry:down");
      int high_index=iHighest(NULL,0,MODE_HIGH,3,1);
      if(high_index!=-1){
          double val=High[high_index];
          if(val - Bid >= 0.2*Pip && val - Bid <= 5*Pip){
               Print("checkEntry:down < 2.5 pip");
              if(AO < AO2 && AO<AO3) 
              entry(strSignal, MathFloor((val - Bid)/Pip));
          }
      }else{
         Print("checkEntry:high_index is -1");
      }
   }
}

void checkEntryTEMA(){
   if(TrendType == "long" && intTrendTrriger<=1){
      int low_index=iLowest(NULL,0,MODE_LOW,5,1);
      if(low_index!=-1){
          double val=Low[low_index];
          if(Ask - val >= 0 && Ask - val <= 6.5*Pip){
              if(AO > AO2 && AO>AO3) 
              entry("up", MathFloor((Ask - val)/Pip));
          }
      }else{
         Print("checkEntry:low_index is -1");
      }
   }
   if(TrendType == "short" && intTrendTrriger<=1){
      int high_index=iHighest(NULL,0,MODE_HIGH,5,1);
      if(high_index!=-1){
          double val=High[high_index];
          if(val - Bid >= 0 && val - Bid <= 6.5*Pip){
              if(AO < AO2 && AO<AO3) 
              entry("down", MathFloor((val - Bid)/Pip));
          }
      }else{
         Print("checkEntry:high_index is -1");
      }
   }
}

//
void entry(string type, double sl){
   if(isSignalOpenOrder)return;
   if(objCTradeMgr.Total()>0)return ;
   int t;
   //intSL = (int)sl;
   if(strSignal == "up"){
      Print("entry:up");
      t = objCTradeMgr.Buy(Lots, intSL, 0, "up");
      if(t != 0){
         isSignalOpenOrder = true;
         lastTicket = t;
         lastTicketStatus = 0;
      }
   }else if(strSignal == "down"){
      Print("entry:down");
      t = objCTradeMgr.Sell(Lots, intSL, 0, "down");
      if(t != 0){
         isSignalOpenOrder = true;
         lastTicket = t;
         lastTicketStatus = 0;
      }
   }
}




//check exit
void tpMgr(){
   if(objCTradeMgr.Total()<=0)return ;
   int tradeType,pass,tradeTicket;
   double tradePrice,tradeProfit;
   datetime dt,dtNow;
   for(int cnt=0;cnt<OrdersTotal();cnt++){
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL &&
         OrderSymbol()==Symbol() &&
         OrderMagicNumber()==MagicNumber){
            tradeTicket = OrderTicket();
            dt = OrderOpenTime();
            tradeType = OrderType();
            tradePrice = OrderOpenPrice();
            tradeProfit = OrderProfit()- OrderCommission() - OrderSwap(); //账面-手续费-库存费
            dtNow = iTime(NULL,PERIOD_M1,1);
            pass = (dtNow-dt)/(PERIOD_M1*60);
            if(tradeType == OP_BUY){
               //double tema = iTEMA(NULL, 0, 10, 1);
               //double ma = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,1);
               if(tradeProfit > TPinMoney ){  //&& Bid -ma>30*Pip
                  objCTradeMgr.Close(tradeTicket);
               }
            }
            if(tradeType == OP_SELL){
               //double tema = iTEMA(NULL, 0, 10, 1);
               //double ma = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,1);
               if(tradeProfit > TPinMoney ){  //&& ma - Ask>30*Pip
                  objCTradeMgr.Close(tradeTicket);
               }
            }
      }
   }
}


void getTrend(){
   intTrendTrriger += 1;
   double tema = iTEMA(NULL, 0, 10, 1);
   double tema_pre = iTEMA(NULL, 0, 10, 2);
   double ma = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,1);
   double ma_pre = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,2);
   string tt = "";
   if(ma_pre < tema_pre && ma > tema){
      tt = "long";
   }
   if(ma_pre > tema_pre && ma < tema){
      tt = "short";
   }
   if(tt != ""){
      if(TrendType == "none"){
         TrendType = tt;
         intTrendTrriger = 0;
         TrendLossed = false;
         lastTicketStatus = 2;
      }else{
         if(tt != TrendType){
            Print("Trend趋势变化，重置上一单状态为2");
            TrendType = tt;
            intTrendTrriger = 0;
            TrendLossed = false;
            lastTicketStatus = 2;   //trend发生变化，不考虑前一单什么状况
         }
      }
   }
}

double iTEMA(string symbol, int tf, int ma_period, int shift){
   return iCustom(symbol,tf,"invea-xpMA",ma_period,5,4,shift);  //5=>tema
}

//每次tick都要更新一下最后一个order的状态
void updateLastTicketStatus(){
   if(lastTicketStatus != 0)return;  //已经得出状态不重复计算
   if(lastTicket > 0){
      if(objCTradeMgr.isOrderClosed(lastTicket)){
         double net = objCTradeMgr.GetOrderNetProfit(lastTicket);
         if(net >=0){
            lastTicketStatus = 1;
         }else{
            lastTicketStatus = -1;
         }
      }
   }
}

void getAO(){
   AO = iAO(NULL,0,1);
   AO2 = iAO(NULL,0,2);
   AO3 = iAO(NULL,0,3);
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
   sComment = sComment + sp;
   sComment = sComment + "TrendType=" + TrendType + NL;
   sComment = sComment + sp;
   sComment = sComment + "lastTicketStatus=" + lastTicketStatus + NL;
   sComment = sComment + sp;
   sComment = sComment + "strSignal=" + strSignal +";" + "isSignalOpenOrder=" + isSignalOpenOrder +";" + "intTrigger=" + intTrigger + NL;
   
    
   
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


void trailStop(){
   if(isTrailStop){
     double newSL;
     double openPrice,myStopLoss;
     datetime dt,dtNow;
     for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {     
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()){
            if(OrderType() == OP_BUY ){
               dt = OrderOpenTime();
               dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               /*
               if(myStopLoss < openPrice && (dtNow-dt)/(PERIOD_M1*60) >1){
                  //刚开单后，每个柱子都移动止损，直至止损后有盈利则不进入
                  newSL = Low[1] - 3*Pip;
                  if(newSL > myStopLoss){
                     OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                  }
               }
               */
               if(TrendType == "long"){
                  //连续3个阳柱子移动止损
                  if(Close[3]>Open[3] && Close[2]>Open[2] && Close[1]>Open[1]){
                     newSL = Open[1] - 2*Pip;
                     if(newSL - openPrice>=2*Pip){
                        OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                     }
                  }else{
                     //过40个柱子，每2个阳柱可上移
                     if( (dtNow-dt)/(PERIOD_M1*60) >40 && Close[2]>Open[2] && Close[1]>Open[1]){
                        newSL = Open[1] - 2*Pip;
                        if(newSL - openPrice>=2*Pip){
                           OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                        }
                     }
                  }
               }
               //盈利超过2.5Pip则向上提止损
               if(myStopLoss - openPrice <2*Pip && Close[1] - openPrice > 2.5*Pip){
                  if(Open[1] - openPrice >0){
                     newSL = Open[1] - 2*Pip;
                     OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                  }else{
                  /*
                     newSL = myStopLoss + 3*Pip;
                     OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                     */
                  }
               }
               
               
            }
            if(OrderType() == OP_SELL){
               dt = OrderOpenTime();
               dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               /*
               if(myStopLoss > openPrice && (dtNow-dt)/(PERIOD_M1*60) >1){
                  //刚开单后，每个柱子都移动止损，直至止损后有盈利则不进入
                  
                  newSL = High[1] + 3*Pip;
                  if(newSL < myStopLoss){
                     OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                  }
               }
               */
               if(TrendType == "short"){
   	            if(Close[3]<Open[3] && Close[2]<Open[2] && Close[1]<Open[1]){
                     newSL = Open[1] + 2*Pip;
                     if(openPrice - newSL>=2*Pip){
                        OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                     }
                  }else{
                     //过40个柱子，每2个阳柱可上移
                     
                     if( (dtNow-dt)/(PERIOD_M1*60) >40 && Close[2]<Open[2] && Close[1]<Open[1]){
                        newSL = Open[1] + 2*Pip;
                        if(openPrice - newSL>=2*Pip){
                           OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                        }
                     }
                  }
               }
               if(openPrice - myStopLoss <2*Pip && openPrice - Close[1]  > 2.5*Pip){
                  if(openPrice - Open[1] >0){
                     newSL = Open[1] + 2*Pip;
                     OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                  }else{
                     /*
                     newSL = myStopLoss - 3*Pip;
                     OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
                     */
                  }
               }
            }
         }
      }
     }
   }
}