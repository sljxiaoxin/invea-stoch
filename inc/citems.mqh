//+------------------------------------------------------------------+
//|                                                  CTradeMgr.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015."
#property link      "http://www.mql5.com"

class CItems : public CObject
{
   private:
      int m_Ticket;        //当前的订单号
      string m_Type;       //策略类型：first,cross,rsi
      double m_TPMoney;    //止盈，first6倍，cross4倍，rsi1倍
      double m_Oop;        //开单价格
      bool m_IsHandClose;  //是否原单或对冲单有被手动关闭的，默认false
      int m_HandCloseMinutes; //从手动关闭到现在经过了多少分钟。
   public:
      int Hedg;          //对冲单
      CArrayInt *Marti;  //马丁单
      CItems(int ticket, string type, double tp, double oop){
	      m_Oop = oop;
         m_Ticket = ticket;
         m_Type = type;
         m_TPMoney = 1*tp;
         Hedg = 0;
         Marti = new CArrayInt;
         m_IsHandClose = false;
         m_HandCloseMinutes = 0;
      }
      string GetType(){return m_Type;}
      double GetTP(){return m_TPMoney;}
      int GetTicket(){return m_Ticket;}
      double GetOop(){return m_Oop;}
      bool IsHandClosed(){return m_IsHandClose;}
      void SetHandClosed(){m_IsHandClose = true;}
      int GetHandCloseMinutes(){return m_HandCloseMinutes;}
      void addHandCloseMinutes(int add){m_HandCloseMinutes += add;}
};