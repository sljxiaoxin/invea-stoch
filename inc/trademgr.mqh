//+------------------------------------------------------------------+
//|                                                  CTradeMgr.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015."
#property link      "http://www.mql5.com"

//交易类
 class CTradeMgr
 {
      private:
         int m_MagicNumber;
         int m_NumberOfTries;   //最大重试次数
         int m_Slippage;        //最大滑点
         double m_Pip;             //点值Point处理后
      public:
         CTradeMgr(){};
         CTradeMgr(int Magic, double Pip,int NumberOfTries, int Slippage){
            m_MagicNumber = Magic;
            m_Pip = Pip;
            m_NumberOfTries = NumberOfTries;
            m_Slippage = Slippage;
         };
         int Buy(double Lot, int SL, int TP, string TicketComment);
         int Sell(double Lot, int SL, int TP, string TicketComment);
         bool Close(int Ticket);
         bool Errors(int Error);
         int Total(void);
         double GetPip(void);
         bool isOrderClosed(int ticket);     //订单是否已关闭
         double GetOrderNetProfit(int ticket);
         
 };
 double CTradeMgr::GetPip(void)
 {
      return m_Pip;
 }
 int CTradeMgr::Buy(double Lot, int SL, int TP, string TicketComment)
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
      ticket = OrderSend(Symbol(),OP_BUY,Lot,Ask,m_Slippage,stopLoss,takeProfit,TicketComment,m_MagicNumber,0,Green);
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
 
 int CTradeMgr::Sell(double Lot, int SL, int TP, string TicketComment)
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
      ticket = OrderSend(Symbol(),OP_SELL,Lot,Bid,m_Slippage,stopLoss,takeProfit,TicketComment,m_MagicNumber,0,Red);
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
 bool CTradeMgr::Close(int Ticket)
 {
     bool  Ans = false;         
     double ClosePrice = 0.0;
     if(OrderSelect(Ticket,SELECT_BY_TICKET))
     {
          while(!Ans)    //Trying closing the order until successfuly
          {
               //-----------------------------------------------------------------------
               if ( OrderType() == OP_BUY )
               {
                    ClosePrice = NormalizeDouble(Bid,Digits);
                    Ans        = OrderClose(Ticket,OrderLots(),ClosePrice,m_Slippage,Green);
               }     
               if ( OrderType() == OP_SELL )
               {
                    ClosePrice = NormalizeDouble(Ask,Digits);
                    Ans = OrderClose(Ticket,OrderLots(),ClosePrice,m_Slippage,Red);
               }               
               //----------------------------------------------------------------------
               if(Ans == false)
               {
                    if ( Errors(GetLastError())==false )// If the error is ritical
                    {
                         return(false);
                    }
               }
          }
     }
     
     return(Ans); 
   
 };
 bool CTradeMgr::Errors(int Error)
 {
      // Error             // Error number  
   if(Error==0)
      return(false);                      // No Error
   //--------------------------------------------------------------- 3 --
   switch(Error)
     {   // Overcomeable errors:
      case 129:         // Wrong price
      case 135:         // Price changed
         RefreshRates();                  // Renew date
         return(true);                    // Error is overcomable
      case 136:         // No quotes. Waiting for the tick to come
      case 138:         // The price is outdated, need to be refresh
         while(RefreshRates()==false)     // Before new tick
            Sleep(1);                     // Delay in the cycle
         return(true);                    // Error is ovecomable
      case 146:         // The trade sybsystem is busy
         Sleep(500);                      // Simple solution
         RefreshRates();                  // Renew data
         return(true);                    // Error is overcomable
         // Critical errors:
      case 2 :          // Common error
      case 5 :          // Old version of the client terminal
      case 64:          // Account blocked
      case 133:         // Trading is prohibited
      default:          // Other variants
         return(false);                   // Critical error
     }
 }
 int CTradeMgr::Total(void)
 {
      int cnt;
      int total = 0;
      for(cnt=0;cnt<OrdersTotal();cnt++)
      {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()<=OP_SELL &&
            OrderSymbol()==Symbol() &&
            OrderMagicNumber()==m_MagicNumber) total++;
      }
      return(total);
 }
 
 bool CTradeMgr::isOrderClosed(int ticket)
 {
    if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
         datetime dtc = OrderCloseTime();
         if(dtc >0){
            return true;
         }else{
            return false;
         }
    }
    return false;
 } 
 
 double CTradeMgr::GetOrderNetProfit(int ticket)
 {
   double _net = 0;
   if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
      //原单利润
      _net = OrderProfit()- OrderCommission() - OrderSwap();
   }
   return _net;
 }