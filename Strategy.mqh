//+------------------------------------------------------------------+
//|                                                     Strategy.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                                                antekov.yandex.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.01"

#define APPEND(A, V) A[ArrayResize(A, ArraySize(A) + 1) - 1] = V;
#define FIND(A, V, I) { for(I=ArraySize(A)-1;I>=0;I--) { if(A[I]==V) break; } }
#define ADD(A, V) { int i; FIND(A, V, i) if(i==-1) { APPEND(A, V) } }

#include "VirtualOrder.mqh"

//+------------------------------------------------------------------+
//| Trading strategy base class                                      |
//+------------------------------------------------------------------+
class CStrategy {
protected:
   string            m_symbol;         // Symbol (trading instrument)
   ENUM_TIMEFRAMES   m_timeframe;      // Chart period (timeframe)
   double            m_fixedLot;       // Size of opened positions (fixed)

   CVirtualOrder     m_orders[];       // Array of virtual positions (orders)
   int               m_ordersTotal;    // Total number of open positions and orders
   double            m_volumeTotal;    // Total volume of open positions and orders

   bool              m_isChanged;      // Sign of changes in open virtual positions
   void              CountOrders();    // Calculate the number and volumes of open positions and orders

public:
   // Constructor
   CStrategy(string p_symbol = "",
             ENUM_TIMEFRAMES p_timeframe = PERIOD_CURRENT,
             double p_fixedLot = 0.01);

   virtual void      Tick();           // Main method - handling OnTick events
   virtual double    Volume();         // Total volume of virtual positions
   virtual string    Symbol();         // Strategy symbol (only one for a single strategy so far)
   virtual bool      IsChanged();      // Are there any changes in open virtual positions?
   virtual void      ResetChanges();   // Reset the sign of changes in open virtual positions
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStrategy::CStrategy(
   string p_symbol,
   ENUM_TIMEFRAMES p_timeframe,
   double p_fixedLot) :
// Initialization list
   m_symbol(p_symbol),
   m_timeframe(p_timeframe),
   m_fixedLot(p_fixedLot),
   m_isChanged(false)
{}

//+------------------------------------------------------------------+
//| Handle OnTick events                                             |
//+------------------------------------------------------------------+
void CStrategy::Tick() {
   m_isChanged = CVirtualOrder::Tick(m_orders);
   if (m_isChanged) {
      CountOrders();
   }
}

//+------------------------------------------------------------------+
//| Total volume of virtual positions                                |
//+------------------------------------------------------------------+
double CStrategy::Volume(void) {
   return m_volumeTotal;
}

//+------------------------------------------------------------------+
//| Strategy symbol                                                  |
//+------------------------------------------------------------------+
string CStrategy::Symbol() {
   return m_symbol;
}

//+------------------------------------------------------------------+
//| Are there any changes to open virtual positions?                 |
//+------------------------------------------------------------------+
bool CStrategy::IsChanged() {
   return m_isChanged;
}

//+------------------------------------------------------------------+
//| Reset the flag for changes in virtual positions                  |
//+------------------------------------------------------------------+
void CStrategy::ResetChanges() {
   m_isChanged = false;
}

//+------------------------------------------------------------------+
//| Calculate the number and volumes of open positions and orders    |
//+------------------------------------------------------------------+
void CStrategy::CountOrders() {
   m_ordersTotal = 0;
   m_volumeTotal = 0;

   for(int i = 0; i < ArraySize(m_orders); i++) {
      double volume = m_orders[i].Volume();
      if(m_orders[i].IsOpen()) {
         m_ordersTotal += 1;
         m_volumeTotal += volume;
      }
   }
}
//+------------------------------------------------------------------+
