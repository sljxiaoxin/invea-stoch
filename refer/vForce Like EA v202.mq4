//+------------------------------------------------------------------+
//|                                            vForce Like EA v2.mq4 |
//|                              Copyright ?2009, TradingSytemForex |
//|                                http://www.tradingsystemforex.com |
//     refer : https://www.tradingsystemforex.com/expert-advisors-backtesting/1086-vforce-like-ea-33.html#post13486
//+------------------------------------------------------------------+

#property copyright "Copyright ?2009, TradingSytemForex"
#property link "http://www.tradingsystemforex.com"

//|----------------------------------------------you can modify this expert
//|----------------------------------------------you can change the name
//|----------------------------------------------you can add "modified by you"
//|----------------------------------------------but you are not allowed to erase the copyrights

#define EAName "vForce Like EA v2"

extern string S1="---------------- Entry Settings";

extern int StochKPeriod=5;
extern int StochDPeriod=3;
extern int StochSlowing=3;
extern int RSIPeriod=2;
extern int BearsPeriod=12;
extern double Step=0.003;
extern double Maximum=0.018;
extern int FastMAPeriod=19;
extern int SlowMAPeriod=50;
extern bool PriceActionFilter=false;

extern string S2="---------------- Money Management";

extern double Lots=0.1;//|-----------------------lots size
extern double LotsPercent1=80;
extern double LotsPercent2=20;
extern bool RiskMM=false;//|---------------------risk management
extern double RiskPercent=1;//|------------------risk percentage
extern double MinLots=0.01;//|-------------------minlots
extern double MaxLots=100;//|--------------------maxlots

/*
extern bool BasketProfitLoss=false;//|-----------use basket loss/profit
extern int BasketProfit=100000;//|---------------if equity reaches this level, close trades
extern int BasketLoss=9999;//|-------------------if equity reaches this negative level, close trades
*/

extern string S3="---------------- Order Management";

extern int MarginPips=23;
extern int StopLoss=69;//|------------------------stop loss
extern int TakeProfit=24;//|---------------------take profit
extern int ATRTSTimeFrame=1;//|------------------trailing stop timeframe
extern int ATRTSPeriod=14;//|--------------------trailing stop
extern double ATRTSFactor=7;//|------------------trailing stop factor
extern int MaxOrders=100;//|---------------------maximum orders allowed
extern int Slippage=3;//|------------------------slippage
extern int Magic1=20091;//|----------------------magic number
extern int Magic2=20092;//|----------------------magic number

/*
extern string S5="---------------- Time Filter";

extern bool TradeOnSunday=true;//|---------------time filter on sunday
extern bool MondayToThursdayTimeFilter=false;//|-time filter the week
extern int MondayToThursdayStartHour=0;//|-------start hour time filter the week
extern int MondayToThursdayEndHour=24;//|--------end hour time filter the week
extern bool FridayTimeFilter=false;//|-----------time filter on friday
extern int FridayStartHour=0;//|-----------------start hour time filter on friday
extern int FridayEndHour=21;//|------------------end hour time filter on friday
*/

extern string S6="---------------- Extras";

extern bool ReverseSystem=false;//|--------------buy instead of sell, sell instead of buy
extern int Expiration=20160;//|--------------------expiration in minute for the reverse pending order

datetime PreviousBarTime1;
datetime PreviousBarTime2;

double maxEquity,minEquity,Balance=0.0;
double LotsFactor=1;
double InitialLotsFactor=1;

int digits;
double point;

//|---------initialization

int init()
{
   digits=Digits;
   point=GetPoints();
   
   return(0);
}

//|---------x digits broker

double GetPoints()
{
   if(Digits==3 || Digits==5)point=Point*10;
   else point=Point;
   return(point);
}

//|---------deinitialization

/*int deinit()
{
  return(0);
}*/

int start()
{

//|---------trailing stop

   if(ATRTSPeriod>0)MoveTrailingStop();
   
/*
//|---------basket profit loss

   if(BasketProfitLoss)
   {
      double CurrentProfit=0,CurrentBasket=0;
      CurrentBasket=AccountEquity()-AccountBalance();
      if(CurrentBasket>maxEquity)maxEquity=CurrentBasket;
      if(CurrentBasket<minEquity)minEquity=CurrentBasket;
      if(CurrentBasket>=BasketProfit||CurrentBasket<=(BasketLoss*(-1)))
      {
         CloseBuyOrders(Magic);
         CloseSellOrders(Magic);
         return(0);
      }
   }
*/

/*
//|---------time filter

   if((TradeOnSunday==false&&DayOfWeek()==0)||(MondayToThursdayTimeFilter&&DayOfWeek()>=1&&DayOfWeek()<=4&&!(Hour()>=MondayToThursdayStartHour&&Hour()<MondayToThursdayEndHour))||(FridayTimeFilter&&DayOfWeek()==5&&!(Hour()>=FridayStartHour&&Hour()<FridayEndHour)))
   {
      CloseBuyOrders(Magic);
      CloseSellOrders(Magic);
      return(0);
   }
*/

//|---------signal conditions

   int limit=1;
   for(int i=1;i<=limit;i++)
   {
   
/*
   //|---------last price
   
      double LastBuyOpenPrice=0;
      double LastSellOpenPrice=0;
      int BuyOpenPosition=0;
      int SellOpenPosition=0;
      int TotalOpenPosition=0;
      int cnt=0;

      for(cnt=0;cnt<OrdersTotal();cnt++) 
      {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol()&&OrderMagicNumber()==Magic&&OrderCloseTime()==0) 
         {
            TotalOpenPosition++;
            if(OrderType()==OP_BUY) 
            {
               BuyOpenPosition++;
               LastBuyOpenPrice=OrderOpenPrice();
            }
            if(OrderType()==OP_SELL) 
            {
               SellOpenPosition++;
               LastSellOpenPrice=OrderOpenPrice();
            }
         }
      }
*/
   //|---------main signal
 
      double StoMa=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_MAIN,i+1);
      double StoSa=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_SIGNAL,i+1);
      double StoM=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_MAIN,i);
      double StoS=iStochastic(NULL,0,StochKPeriod,StochDPeriod,StochSlowing,MODE_SMA,0,MODE_SIGNAL,i);
      
      double RSIa=iRSI(NULL,0,RSIPeriod,PRICE_CLOSE,i+1);
      double RSI=iRSI(NULL,0,RSIPeriod,PRICE_CLOSE,i);
      
      double Bearsa=iBearsPower(NULL,0,BearsPeriod,PRICE_CLOSE,i+1);
      double Bears=iBearsPower(NULL,0,BearsPeriod,PRICE_CLOSE,i);
      
      double SARa=iSAR(NULL,0,Step,Maximum,i+1);
      double SAR=iSAR(NULL,0,Step,Maximum,i);

      
      
      string BUY="false";
      string SELL="false";

      if(
      (StoM>StoS)
      && (RSI>50)
      && (Bears>0)
      && (Open[i]>SAR)
      && (iMA(Symbol(),0,FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,i)>iMA(Symbol(),0,SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,i+1))
      && (PriceActionFilter==false || (PriceActionFilter && Close[0]>Open[0]))
      )BUY="true";
      if(
      (StoM<StoS)
      && (RSI<50)
      && (Bears<0)
      && (Open[i]<SAR)
      && (iMA(Symbol(),0,FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,i)<iMA(Symbol(),0,SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,i+1))
      && (PriceActionFilter==false || (PriceActionFilter && Close[0]<Open[0]))
      )SELL="true";
      
      string SignalBUY="false";
      string SignalSELL="false";
      
      if(BUY=="true")if(ReverseSystem)SignalSELL="true";else SignalBUY="true";
      if(SELL=="true")if(ReverseSystem)SignalBUY="true";else SignalSELL="true";
      
   }

//|---------risk management

   if(RiskMM)CalculateMM();

//|---------open orders

   double SL,TP,SLH,TPH,SLP,TPP,OPP,ILots,ILots1,ILots2;
   int Ticket1,Ticket2,TicketH,TicketP,Expire=0;
   if(Expiration>0)Expire=TimeCurrent()+(Expiration*60)-5;
   
   if((CountOrders(OP_BUY,Magic1)+CountOrders(OP_SELL,Magic1)+CountOrders(OP_BUY,Magic2)+CountOrders(OP_SELL,Magic2))<MaxOrders)
   {  
      if(SignalBUY=="true"&&NewBarBuy())
      {
         if(StopLoss>0){SL=Low[i]-(MarginPips+StopLoss)*point-NormalizeDouble((iATR(NULL,0,14,1)/10)*0.5,digits);}else {SL=0;}
         if(TakeProfit>0){TP=High[i]+(MarginPips+TakeProfit)*point;}else {TP=0;}
         
         ILots=Lots;
         if(ILots<MinLots)ILots=MinLots;if(ILots>MaxLots)ILots=MaxLots;
         ILots1=NormalizeDouble(ILots*(LotsPercent1/100),2);
         ILots2=NormalizeDouble(ILots*(LotsPercent2/100),2);
         
         Ticket1=OrderSend(Symbol(),OP_BUYSTOP,ILots1,High[i]+MarginPips*point,Slippage,SL,TP,EAName,Magic1,Expire,Blue);
         Ticket2=OrderSend(Symbol(),OP_BUYSTOP,ILots2,High[i]+MarginPips*point,Slippage,SL,0,EAName,Magic2,Expire,Blue);
      }
      if(SignalSELL=="true"&&NewBarSell())
      {
         if(StopLoss>0){SL=High[i]+(MarginPips+StopLoss)*point+NormalizeDouble((iATR(NULL,0,14,1)/10)*0.5,digits);}else {SL=0;}
         if(TakeProfit>0){TP=Low[i]-(MarginPips+TakeProfit)*point;}else {TP=0;}
         
         ILots=Lots;
         if(ILots<MinLots)ILots=MinLots;if(ILots>MaxLots)ILots=MaxLots;
         ILots1=NormalizeDouble(ILots*(LotsPercent1/100),2);
         ILots2=NormalizeDouble(ILots*(LotsPercent2/100),2);
         
         Ticket1=OrderSend(Symbol(),OP_SELLSTOP,ILots1,Low[i]-MarginPips*point,Slippage,SL,TP,EAName,Magic1,Expire,Red);
         Ticket2=OrderSend(Symbol(),OP_SELLSTOP,ILots2,Low[i]-MarginPips*point,Slippage,SL,0,EAName,Magic2,Expire,Red);
      }
   }

//|---------not enough money warning

   int err=0;
   if(Ticket1<0&&Ticket2<0)
   {
      if(GetLastError()==134)
      {
         err=1;
         Print("Not enough money!");
      }
      return (-1);
   }

   return(0);
}

//|---------count orders

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

//|---------trailing stop

void MoveTrailingStop()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&((OrderMagicNumber()==Magic2)))
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

//|---------allow one action per bar

bool NewBarBuy()
{
   if(PreviousBarTime1<Time[0])
   {
      PreviousBarTime1=Time[0];
      return(true);
   }
   return(false);
}

bool NewBarSell()
{
   if(PreviousBarTime2<Time[0])
   {
      PreviousBarTime2=Time[0];
      return(true);
   }
   return(false);
}

//|---------calculate money management

void CalculateMM()
{
   double MinLots=MarketInfo(Symbol(),MODE_MINLOT);
   double MaxLots=MarketInfo(Symbol(),MODE_MAXLOT);
   Lots=AccountFreeMargin()/100000*RiskPercent;
   Lots=MathMin(MaxLots,MathMax(MinLots,Lots));
   if(MinLots<0.1)Lots=NormalizeDouble(Lots,2);
   else
   {
     if(MinLots<1)Lots=NormalizeDouble(Lots,1);
     else Lots=NormalizeDouble(Lots,0);
   }
   if(Lots<MinLots)Lots=MinLots;
   if(Lots>MaxLots)Lots=MaxLots;
   return(0);
}