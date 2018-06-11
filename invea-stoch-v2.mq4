//+------------------------------------------------------------------+
//|     基于stoch指标
//
//+------------------------------------------------------------------+
#property copyright "xiaoxin003"
#property link      "yangjx009@139.com"
#property version   "1.0"
#property strict

#include <Arrays\ArrayInt.mqh>
#include "inc\dictionary.mqh" //keyvalue数据字典类
#include "inc\trademgr.mqh"   //交易工具类
#include "inc\citems.mqh"     //交易组item


extern int       MagicNumber     = 201806;
extern int       MagicNumber2    = 201807;
extern double    Lots            = 0.02;
extern double    MaxLots         = 0.1;
//extern double    TPinMoney       = 30;          //Net TP (money)
extern int       intTP           = 6;
extern int       intSL           = 25;            //止损点数，不用加0
extern int       MarginPips      = 13;
extern double    distance        = 5;   //加仓间隔点数
extern int       MaxOrders       = 40;
extern double    levelHigh      = 90;
extern double    levelLow       = 10;

extern int       ATRTSTimeFrame=1;//|------------------trailing stop timeframe
extern int       ATRTSPeriod=14;//|--------------------trailing stop
extern double    ATRTSFactor=7;//|------------------trailing stop factor

int digits;
int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM1,CheckTimeM5;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CDictionary *objDict = NULL;     //订单数据字典类
int tmp = 0;

int    lastTicket    = -1;
int    lastTicketStatus = 2;    //0:持有中，1:止盈，-1：止损，2：不考虑了
int    lastTicketType = -1;     //上一单类型

int    currSignalOrders = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   Print("begin");
   digits=Digits;
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
     if(ATRTSPeriod>0)MoveTrailingStop();
     //updateLastTicketStatus();
     subPrintDetails();
     checkEntryStoch();
     //M1产生交易
     if(CheckTimeM1==iTime(NULL,PERIOD_M1,0)){
         
     } else {
         //////////////////////////
         string strSg = signal();
         if(strSg != "none"){
            //等于0表示趋势改变
            if(strSignal != strSg){
               currSignalOrders = 0;
            }
            strSignal = strSg;
            intTrigger = 0;
            isSignalOpenOrder = false;
         }else{
            intTrigger += 1;
         }
         CheckTimeM1 = iTime(NULL,PERIOD_M1,0);
         //tpMgr();
         //trailStop();
         
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
   if(fast[0]>89 && fast[1]<fast[0] && fast[2]<fast[1] && fast[2]<75){
         Print("signal=>down");
         return "down";
   }
   if(fast[0]<11 && fast[1]>fast[0] && fast[2]>fast[1] && fast[2]>25){
         Print("signal=>down");
         return "up";
   }
  
   return "none";
}


//交易判断
void checkEntryStoch(){
   if(isSignalOpenOrder)return;
   //if(lastTicketStatus == -1)return;   //最后一order在当前trend下发生了loss，则不open
   if(strSignal == "up" && intTrigger<1){
      Print("checkEntry:up");
      int low_index=iLowest(NULL,0,MODE_LOW,3,1);
      if(low_index!=-1){
          double val=Low[low_index];
          //Print("checkEntry:low value =",val,";Ask=",Ask,";diff=",(Ask - val));
          if(Ask - val >= 0.2*Pip && Ask - val <= 2.5*Pip){
              //Print("checkEntry:up < 2.5 pip");
              entry(strSignal);
          }
      }else{
         Print("checkEntry:low_index is -1");
      }
   }
   
   if(strSignal == "down" && intTrigger<1){
      Print("checkEntry:down");
      int high_index=iHighest(NULL,0,MODE_HIGH,3,1);
      if(high_index!=-1){
          double val=High[high_index];
          if(val - Bid >= 0.2*Pip && val - Bid <= 2.5*Pip){
               //Print("checkEntry:down < 2.5 pip");
              entry(strSignal);
          }
      }else{
         Print("checkEntry:high_index is -1");
      }
   }
}

//
void entry(string type){
   if(isSignalOpenOrder)return;
   if((CountOrders(OP_BUY,MagicNumber)+CountOrders(OP_SELL,MagicNumber)+CountOrders(OP_BUY,MagicNumber2)+CountOrders(OP_SELL,MagicNumber2))>=MaxOrders)return;
   int t;
   //intSL = (int)sl;
   if(strSignal == "up"){
      Print("entry:up");
      currSignalOrders += 1;
      t = Buy(getMagic(), getLots(), getSL(), getTP(), "up");
      if(t != 0){
         isSignalOpenOrder = true;
      }
   }else if(strSignal == "down"){
      Print("entry:down");
      currSignalOrders += 1;
      t = Sell(getMagic(), getLots(), getSL(), getTP(), "down");
      if(t != 0){
         isSignalOpenOrder = true;
      }
   }
}


double getLots(){
   if(currSignalOrders == 1){
      return Lots * 2;
   }else if(currSignalOrders == 2){
      return Lots;
   }else{
      double _lot = Lots * (currSignalOrders-1);
      if(_lot > MaxLots){
         _lot = MaxLots;
      }
      return _lot ;
   }
}

int getSL(){
  return intSL + MarginPips;
}

int getTP(){
   if(currSignalOrders%2==0){
      return 0;
   }else{
      return intTP;
   }
}

int getMagic(){
   if(currSignalOrders%2==0){
      return MagicNumber2;
   }else{
      return MagicNumber;
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
   //sComment = sComment + "Net = " + TotalNetProfit() + NL; 
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,2) + NL;
   //sComment = sComment + sp;
  // sComment = sComment + "TrendType=" + TrendType + NL;
   sComment = sComment + sp;
  // sComment = sComment + "lastTicketStatus=" + lastTicketStatus + NL;
   sComment = sComment + sp;
   sComment = sComment + "strSignal=" + strSignal +";" + "isSignalOpenOrder=" + isSignalOpenOrder +";" + "intTrigger=" + intTrigger + NL;
   
    
   
   Comment(sComment);
}



void MoveTrailingStop()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&((OrderMagicNumber()==MagicNumber2)))
      {
         if(OrderType()==OP_BUY&&NormalizeDouble((Ask-OrderOpenPrice()),digits)>NormalizeDouble(iATR(NULL,ATRTSTimeFrame,ATRTSPeriod,1)*ATRTSFactor,digits))
         {
            if(ATRTSPeriod>0&&Ask>NormalizeDouble(OrderOpenPrice(),digits))  
            {                 
               if((NormalizeDouble(OrderStopLoss(),digits)<NormalizeDouble(Bid-NormalizeDouble(iATR(NULL,ATRTSTimeFrame,ATRTSPeriod,1)*ATRTSFactor,digits),digits))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-NormalizeDouble(iATR(NULL,ATRTSTimeFrame,ATRTSPeriod,1)*ATRTSFactor,digits),digits),OrderTakeProfit(),0,Blue);
                  return(0);
               }
            }
         }
         if(OrderType()==OP_SELL&&NormalizeDouble((OrderOpenPrice()-Bid),digits)>NormalizeDouble(iATR(NULL,ATRTSTimeFrame,ATRTSPeriod,1)*ATRTSFactor,digits))
         {
            if(ATRTSPeriod>0&&Bid<NormalizeDouble(OrderOpenPrice(),digits))  
            {                 
               if((NormalizeDouble(OrderStopLoss(),digits)>(NormalizeDouble(Ask+NormalizeDouble(iATR(NULL,ATRTSTimeFrame,ATRTSPeriod,1)*ATRTSFactor,digits),digits)))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask+NormalizeDouble(iATR(NULL,ATRTSTimeFrame,ATRTSPeriod,1)*ATRTSFactor,digits),digits),OrderTakeProfit(),0,Red);
                  return(0);
               }
            }
         }
      }
   }
}




int Buy(int _Magic, double Lot, int SL, int TP, string TicketComment)
 {
   int ticket, 
       err = 0;
   double stopLoss = 0,
          takeProfit = 0;
   if(SL != 0)
   {
      stopLoss   = NormalizeDouble(Bid-SL*m_Pip,Digits);
   }
   
   if(TP != 0)
   {
      takeProfit = NormalizeDouble(Bid+TP*m_Pip,Digits);
   }
   for(int c=0;c<m_NumberOfTries;c++)
   {
      ticket = OrderSend(Symbol(),OP_BUY,Lot,Ask,5,stopLoss,takeProfit,TicketComment,_Magic,0,Green);
      err=GetLastError();
      if(err==0)
      { 
         if(ticket>0) break;
      }
      else
      {
         if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
         {
            Sleep(1000);
            continue;
         }
         else //normal error
         {
            if(ticket>0) break;
         }  
      }
   } 
   return(ticket);  
 }
 
 int Sell(int _Magic, double Lot, int SL, int TP, string TicketComment)
 {
   int ticket, 
       err = 0;
   double stopLoss = 0,
          takeProfit = 0;
   if(SL != 0)
   {
      stopLoss   = NormalizeDouble(Ask+SL*m_Pip,Digits);
   }
   
   if(TP != 0)
   {
      takeProfit = NormalizeDouble(Ask-TP*m_Pip,Digits);
   }
   for(int c=0;c<m_NumberOfTries;c++)
   {
      ticket = OrderSend(Symbol(),OP_SELL,Lot,Bid,5,stopLoss,takeProfit,TicketComment,_Magic,0,Red);
      err=GetLastError();
      if(err==0)
      { 
         if(ticket>0) break;
      }
      else
      {
         if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146) //Busy errors
         {
            Sleep(1000);
            continue;
         }
         else //normal error
         {
            if(ticket>0) break;
         }  
      }
   } 
   return(ticket);  
 }
 
 int CountOrders(int Type,int Magic)
{
   int _CountOrd;
   _CountOrd=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
      {
         if((OrderType()==Type&&(OrderMagicNumber()==Magic)||Magic==0))_CountOrd++;
      }
   }
   return(_CountOrd);
}