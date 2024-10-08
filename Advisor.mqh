//+------------------------------------------------------------------+
//|                                                     CAdvisor.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"
#include <Object.mqh>

#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| EA base class                                                    |
//+------------------------------------------------------------------+
class CAdvisor : public CObject {
protected:
   CStrategy         *m_strategies[];  // Array of trading strategies
   int               m_strategiesCount;// Number of strategies

public:
   virtual int       Init();           // EA initialization method
   virtual void      Tick();           // OnTick event handler
   virtual void      Deinit();         // Deinitialization method

   void              AddStrategy(CStrategy &strategy);   // Strategy adding method
};

//+------------------------------------------------------------------+
//| EA initialization method                                         |
//+------------------------------------------------------------------+
int CAdvisor::Init() {
   // Initialize all strategies
   for(int i = 0; i < m_strategiesCount; i++) {
      m_strategies[i].Init();
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnTick event handler                                             |
//+------------------------------------------------------------------+
void CAdvisor::Tick(void) {
   // Call OnTick handling for all strategies
   for(int i = 0; i < m_strategiesCount; i++) {
      m_strategies[i].Tick();
   }
}

//+------------------------------------------------------------------+
//| Deinitialization method                                          |
//+------------------------------------------------------------------+
void CAdvisor::Deinit(void) {
   // Delete all strategy objects
   for(int i = 0; i < m_strategiesCount; i++) {
      delete m_strategies[i];
   }

   // Clear the array of pointers to strategy objects
   m_strategiesCount = 0;
   ArrayResize(m_strategies, m_strategiesCount);
}

//+------------------------------------------------------------------+
//| Strategy adding method                                           |
//+------------------------------------------------------------------+
void CAdvisor::AddStrategy(CStrategy &strategy) {
   // Increase the strategy number counter by 1
   m_strategiesCount = ArraySize(m_strategies) + 1;
   
   // Increase the size of the strategies array
   ArrayResize(m_strategies, m_strategiesCount);
   // Write a pointer to the strategy object to the last element
   m_strategies[m_strategiesCount - 1] = GetPointer(strategy);
}
//+------------------------------------------------------------------+
