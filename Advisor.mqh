//+------------------------------------------------------------------+
//|                                                      Advisor.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.03"

#include "Macros.mqh"
#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| EA base class                                                    |
//+------------------------------------------------------------------+
class CAdvisor {
protected:
   CStrategy         *m_strategies[];  // Array of trading strategies
public:
                    ~CAdvisor();                // Destructor
   virtual void      Tick();                    // OnTick event handler
   virtual void      Add(CStrategy *strategy);  // Method for adding a strategy
};

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CAdvisor::~CAdvisor() {
// Delete all strategy objects
   FOREACH(m_strategies, delete m_strategies[i]);
}

//+------------------------------------------------------------------+
//| OnTick event handler                                             |
//+------------------------------------------------------------------+
void CAdvisor::Tick(void) {
// Call OnTick handling for all strategies
   FOREACH(m_strategies, m_strategies[i].Tick());
}

//+------------------------------------------------------------------+
//| Strategy adding method                                           |
//+------------------------------------------------------------------+
void CAdvisor::Add(CStrategy *strategy) {
   APPEND(m_strategies, strategy);  // Add the strategy to the end of the array
}
//+------------------------------------------------------------------+
