//Version: 11
//Last Update Date: May 23, 2011
//+------------------------------------------------------------------+
//|                       XP Moving Average                          | 
//|                                                         invea-xpMA.mq4 |
//|                                         Developed by Coders Guru |
//|                                            http://www.xpworx.com |
//+------------------------------------------------------------------+
#property link      "http://www.xpworx.com"
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Yellow
#property indicator_color2 Blue
#property indicator_color3 Red
#property indicator_width1 3
#property indicator_width2 3
#property indicator_width3 3
//+------------------------------------------------------------------+
/* Moving average types constants:
------------------------------------
MODE_SMA       0     Simple moving average, 
MODE_EMA       1     Exponential moving average, 
MODE_SMMA      2     Smoothed moving average, 
MODE_LWMA      3     Linear weighted moving average.
MODE_DEMA      4     Double Exponential Moving Average. 
MODE_TEMA      5     Triple Exponential Moving Average.
MODE_T3MA      6     T3 Moving Average. 
MODE_JMA       7     Jurik Moving Average. 
MODE_HMA       8     Hull Moving Average. 
MODE_DECEMA    9     DECEMA Moving Average. 
MODE_SALT      10    SALT Indicator. 
------------------------------------*/
#define MODE_DEMA    4
#define MODE_TEMA    5
/*
#define MODE_T3MA    6
#define MODE_JMA     7
#define MODE_HMA     8
#define MODE_DECEMA  9
#define MODE_SALT    10
*/
/* Applied price constants:
-------------------------------
PRICE_CLOSE    0     Close price. 
PRICE_OPEN     1     Open price. 
PRICE_HIGH     2     High price. 
PRICE_LOW      3     Low price. 
PRICE_MEDIAN   4     Median price, (high+low)/2. 
PRICE_TYPICAL  5     Typical price, (high+low+close)/3. 
PRICE_WEIGHTED 6     Weighted close price, (high+low+close+close)/4.
--------------------------------- */
extern   int      MA_Period               = 10;//25;
extern   int      MA_Type                 = MODE_TEMA;
extern   int      MA_Applied              = PRICE_CLOSE;
//extern   double   T3MA_VolumeFactor       = 0.8;
//extern   double   JMA_Phase               = 0;
extern   int      Step_Period             = 1;
//+------------------------------------------------------------------+
extern   int      BarsCount               = 200;
extern   bool     Alert_On                = false;//true;
extern   bool     Arrows_On               = true;
extern   bool     Email_On                = false;
//+------------------------------------------------------------------+
int      UpArrowCode             = 241;
int      DownArrowCode           = 242;
color    UpArrowColor            = Red;
color    DownArrowColor          = Blue;
int      UpArrowSize             = 3;
int      DownArrowSize           = 3;
//+------------------------------------------------------------------+
string   pro  = "xpMA v11";
string   ver  = "";
//+------------------------------------------------------------------+
double UpBuffer[];
double DownBuffer[];
double buf[];
double buffer[];
double tempbuffer[];
double matriple[];
double signal[];
//+------------------------------------------------------------------+
int    nShift;   
double point;
//+------------------------------------------------------------------+
int init()
{
   ver = GenVer();
   DeleteObjects();

   Stamp("ver",pro+" - "+ver,15,20);
   string copy = "C 2005-2011 XPWORX. All rights reserved.";
   copy = StringSetChar(copy,0,'?);
   Stamp("copyright",copy ,15,35);
   
   
   IndicatorBuffers(7); 

   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,2);
   SetIndexBuffer(2,UpBuffer);
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,2);
   SetIndexBuffer(1,DownBuffer);
   SetIndexStyle(0,DRAW_LINE,STYLE_DOT,2);
   SetIndexBuffer(0,buf);
   
   SetIndexBuffer(3,signal);
   SetIndexBuffer(4,buffer);
   SetIndexBuffer(5,tempbuffer);
   SetIndexBuffer(6,matriple);
   
   SetIndexLabel(0,"XP Moving Average");
   SetIndexLabel(1,"DownBuffer");
   SetIndexLabel(2,"UpBuffer");
   SetIndexLabel(3,"Signal");
   
   switch(Period())
   {
      case     1: nShift = 5;   break;    
      case     5: nShift = 7;   break; 
      case    15: nShift = 10;   break; 
      case    30: nShift = 15;  break; 
      case    60: nShift = 20;  break; 
      case   240: nShift = 30;  break; 
      case  1440: nShift = 80;  break; 
      case 10080: nShift = 150; break; 
      case 43200: nShift = 250; break;               
   }
      
   if(Digits==2 || Digits==3) point=0.01;
   if(Digits==4 || Digits==5) point=0.0001;

   return(0);
}

int deinit()
{
   DeleteObjects();
   return(0);
}

void start()
{   
   int limit;
   int counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
   
   switch (MA_Type)
   {
      case MODE_SMA:
      case MODE_EMA:
      case MODE_SMMA:
      case MODE_LWMA:
      {
         for(int i=0; i<limit; i++) buffer[i] = iMA(NULL,0,MA_Period,0,MA_Type,MA_Applied,i);
         break;
      }
      case MODE_DEMA:
      {
         for(i=0; i<limit; i++) tempbuffer[i] = iMA(NULL,0,MA_Period,0,MODE_EMA,MA_Applied,i);
         for(i=0; i<limit; i++) matriple[i] = iMAOnArray(tempbuffer,0,MA_Period,0,MODE_EMA,i);
         for(i=0; i<limit; i++) buffer[i] = iMAOnArray(matriple,0,MA_Period,0,MODE_EMA,i);
         break;
      }
      case MODE_TEMA:
      {
         for(i=0; i<limit; i++) tempbuffer[i] = iMA(NULL,0,MA_Period,0,MODE_EMA,MA_Applied,i);
         for(i=0; i<limit; i++) buffer[i] = iMAOnArray(tempbuffer,0,MA_Period,0,MODE_EMA,i);
         break;
      }
      /*
      case MODE_T3MA:
      {
         for(i=0; i<limit; i++) buffer[i] = iCustom(NULL,0,"T3MA",MA_Period,T3MA_VolumeFactor,0,i);
         break;
       }
      case MODE_JMA:
      {
         for(i=0; i<limit; i++) buffer[i] = iCustom(NULL,0,"JMA",MA_Period,JMA_Phase,0,i);
         break;
      }
      case MODE_HMA:
      {
         for(i=0; i<limit; i++) buffer[i] = iCustom(NULL,0,"HMA",MA_Period,0,i);
         break;
      }
      case MODE_DECEMA:
      {
         for(i=0; i<limit; i++) buffer[i] = iCustom(NULL,0,"DECEMA_v1",MA_Period,MA_Applied,0,i);
         break;
      }
      case MODE_SALT:
      {
         for(i=0; i<limit; i++) buffer[i] = iCustom(NULL,0,"SATL",0,i);
         break;
      }
      */
   }
   
   if(limit<BarsCount) BarsCount = limit;
   
   for(int shift=0; shift<BarsCount; shift++)
   {
       UpBuffer[shift] = buffer[shift];
       DownBuffer[shift] = buffer[shift];
       buf[shift] = buffer[shift];
   }                   
   
   for(shift=0; shift<BarsCount; shift++)
   {
      double dMA = 0;
      for(int k = shift+1; k <= shift+Step_Period; k++) dMA += buffer[k];
      dMA = dMA / Step_Period;

      if (buffer[shift] < dMA) UpBuffer[shift] = EMPTY_VALUE;
      else if (buffer[shift]>dMA) DownBuffer[shift] = EMPTY_VALUE;
      else
      {
         UpBuffer[shift] = EMPTY_VALUE;
         DownBuffer[shift] = EMPTY_VALUE;
      }
   }
   for(shift=0; shift<BarsCount-1; shift++)
   {
      signal[shift]=0;
      if(UpBuffer[shift+1] == EMPTY_VALUE &&  UpBuffer[shift] != EMPTY_VALUE && buf[shift+1] != UpBuffer[shift] )
      {
         if(Arrows_On && shift !=0) DrawObject(1,shift, buffer[shift] - nShift*point);
         if(Arrows_On && shift ==0) DrawOnce(1,shift, buffer[shift] - nShift*point,0);
         signal[shift] = 1;
      }
            
      if(DownBuffer[shift+1] == EMPTY_VALUE &&  DownBuffer[shift] != EMPTY_VALUE && buf[shift+1] != DownBuffer[shift])
      {
         if(Arrows_On && shift !=0) DrawObject(2,shift, buffer[shift] + nShift*point);
         if(Arrows_On && shift ==0) DrawOnce(2,shift, buffer[shift] + nShift*point,1);
         signal[shift] = -1;
      }
   }
   
   if(UpBuffer[1] == EMPTY_VALUE &&  UpBuffer[0] != EMPTY_VALUE && buf[1] != UpBuffer[0])
   {
      if(Alert_On) AlertOnce(Symbol()+ ":" + PeriodToText() + "  -  Up Signal",1);
      if(Email_On) SendMailOnce("xpMA Signal",Symbol()+ ":" + PeriodToText() + "  -  Up Signal",1);
   }
   if(DownBuffer[1] == EMPTY_VALUE &&  DownBuffer[0] != EMPTY_VALUE && buf[1] != DownBuffer[0]) 
   {
      if(Alert_On)  AlertOnce(Symbol()+ ":" + PeriodToText() + "  -  Down Signal",2);
      if(Email_On) SendMailOnce("xpMA Signal",Symbol()+ ":" + PeriodToText() + "  -  Down Signal",2);
   }
   
   return(0);
}

bool DrawOnce(int direction, int bar , double price, int ref)
{  
   static int LastDraw[10];
   
   if( LastDraw[ref] == 0 || LastDraw[ref] < Bars)
   {
      DrawObject(direction, bar , price);
      LastDraw[ref] = Bars;
      return (true);
   }
   return(false);
}

void DrawObject(int direction, int bar , double price)
{
   static int count = 0;
   count++;
   string Obj = "";
   if (direction==1) //up arrow
   {
      Obj = "xpMA_up_" + DoubleToStr(bar,0);
      ObjectCreate(Obj,OBJ_ARROW,0,Time[bar],price);
      ObjectSet(Obj,OBJPROP_COLOR,UpArrowColor);
      ObjectSet(Obj,OBJPROP_ARROWCODE,UpArrowCode);
      ObjectSet(Obj,OBJPROP_WIDTH,UpArrowSize);
   }
   if (direction==2) //down arrow
   {
      Obj = "xpMA_down_" + DoubleToStr(bar,0);
      ObjectCreate(Obj,OBJ_ARROW,0,Time[bar],price);
      ObjectSet(Obj,OBJPROP_COLOR,DownArrowColor);
      ObjectSet(Obj,OBJPROP_ARROWCODE,DownArrowCode);
      ObjectSet(Obj,OBJPROP_WIDTH,DownArrowSize);
   }
   WindowRedraw();
}

void DeleteObjects()
{
   int objs = ObjectsTotal();
   string name;
   for(int cnt=ObjectsTotal()-1;cnt>=0;cnt--)
   {
      name=ObjectName(cnt);
      if (StringFind(name,"xpMA",0)>-1) ObjectDelete(name);
      if (StringFind(name,"Stamp",0)>-1) ObjectDelete(name);
      WindowRedraw();
   }
}

bool AlertOnce(string msg, int ref)
{  
   static int LastAlert[10];
   
   if( LastAlert[ref] == 0 || LastAlert[ref] < Bars)
   {
      Alert(msg);
      LastAlert[ref] = Bars;
      return (true);
   }
   return(false);
}

bool SendMailOnce(string subject, string body, int ref)
{  
   static int LastAlert[10];
   
   if( LastAlert[ref] == 0 || LastAlert[ref] < Bars)
   {
      SendMail(subject,body);
      LastAlert[ref] = Bars;
      return (true);
   }
   return(false);
}

string PeriodToText()
{
   switch (Period())
   {
      case 1:
            return("M1");
            break;
      case 5:
            return("M5");
            break;
      case 15:
            return("M15");
            break;
      case 30:
            return("M30");
            break;
      case 60:
            return("H1");
            break;
      case 240:
            return("H4");
            break;
      case 1440:
            return("D1");
            break;
      case 10080:
            return("W1");
            break;
      case 43200:
            return("MN1");
            break;
   }
}

void Stamp(string objName , string text , int x , int y)
{
   string Obj="Stamp_" + objName;
   int objs = ObjectsTotal();
   string name;
  
   for(int cnt=0;cnt<ObjectsTotal();cnt++)
   {
      name=ObjectName(cnt);
      if (StringFind(name,Obj,0)>-1) 
      {
         ObjectSet(Obj,OBJPROP_XDISTANCE,x);
         ObjectSet(Obj,OBJPROP_YDISTANCE,y);
         WindowRedraw();
      }
      else
      {
         ObjectCreate(Obj,OBJ_LABEL,0,0,0);
         ObjectSetText(Obj,text,8,"arial",Orange);
         ObjectSet(Obj,OBJPROP_XDISTANCE,x);
         ObjectSet(Obj,OBJPROP_YDISTANCE,y);
         WindowRedraw();
      }
   }
   if (ObjectsTotal() == 0)
   {
         ObjectCreate(Obj,OBJ_LABEL,0,0,0);
         ObjectSetText(Obj,text,8,"arial",Orange);
         ObjectSet(Obj,OBJPROP_XDISTANCE,x);
         ObjectSet(Obj,OBJPROP_YDISTANCE,y);
         WindowRedraw();

   }
   
   return(0);
}


string GenVer()
{
   string method;
   if(MA_Type==0) method="SMA"; 
   if(MA_Type==1) method="EMA"; 
   if(MA_Type==2) method="SMMA"; 
   if(MA_Type==3) method="LWMA"; 
   if(MA_Type==4) method="DEMA"; 
   if(MA_Type==5) method="TEMA"; 
   if(MA_Type==6) method="T3MA"; 
   if(MA_Type==7) method="JMA"; 
   if(MA_Type==8) method="HMA";
   if(MA_Type==9) method="DECEMA";
   if(MA_Type==10) method="SALT";
   
   return (method+"("+MA_Period+")"); 
}








