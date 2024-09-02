//+------------------------------------------------------------------+
//|                                              VirtualStrategy.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.01"

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
};

//+------------------------------------------------------------------+
//| Counting open virtual positions and orders                       |
//+------------------------------------------------------------------+
void CVirtualStrategy::CountOrders() {
   m_ordersTotal = 0;
   FOREACH(m_orders, if(m_orders[i].IsOpen()) { m_ordersTotal += 1; })
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
