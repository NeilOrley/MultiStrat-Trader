//+------------------------------------------------------------------+
//|                                              VirtualStrategy.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.02"

#include "Strategy.mqh"
#include "VirtualOrder.mqh"

//+------------------------------------------------------------------+
//| Class of a trading strategy with virtual positions               |
//+------------------------------------------------------------------+
class CVirtualStrategy : public CStrategy {
protected:
   CVirtualOrder     *m_orders[];   // Array of virtual positions (orders)
   int               m_ordersTotal; // Total number of open positions and orders

   virtual void      CountOrders(); // Calculate the number of open positions and orders

public:
   virtual void      OnOpen();      // Event handler for opening a virtual position (order)
   virtual void      OnClose();     // Event handler for closing a virtual position (order)

   virtual bool      Load(const int f);   // Load status
   virtual bool      Save(const int f);   // Save status

   string operator~();                    // Convert object to string
};

//+------------------------------------------------------------------+
//| Counting open virtual positions and orders                       |
//+------------------------------------------------------------------+
void CVirtualStrategy::CountOrders() {
   m_ordersTotal = 0;
   FOREACH(m_orders, m_ordersTotal += m_orders[i].IsOpen());
}

//+------------------------------------------------------------------+
//| Convert an object to a string                                    |
//+------------------------------------------------------------------+
string CVirtualStrategy::operator~() {
   return StringFormat("%s(%d)", typename(this), ArraySize(m_orders));
}

//+------------------------------------------------------------------+
//| Event handler for opening a virtual position (order)             |
//+------------------------------------------------------------------+
void CVirtualStrategy::OnOpen() {
   CountOrders();
}

//+------------------------------------------------------------------+
//| Event handler for closing a virtual position (order)             |
//+------------------------------------------------------------------+
void CVirtualStrategy::OnClose() {
   CountOrders();
}

//+------------------------------------------------------------------+
//| Load status                                                      |
//+------------------------------------------------------------------+
bool CVirtualStrategy::Load(const int f) {
   bool res = true;
   // Current parameters are equal to read parameters   
   res = (~this == FileReadString(f));
   
   // If yes, then load the virtual positions (orders) of the strategy
   if(res) {
      FOREACH(m_orders, res &= m_orders[i].Load(f));
   }

   return res;
}

//+------------------------------------------------------------------+
//| Save status                                                      |
//+------------------------------------------------------------------+
bool CVirtualStrategy::Save(const int f) {
   bool res = true;
   FileWrite(f, ~this); // Save parameters

   // Save virtual positions (orders) of the strategy
   FOREACH(m_orders, res &= m_orders[i].Save(f));

   return res;
}
//+------------------------------------------------------------------+
