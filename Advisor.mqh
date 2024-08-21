//+------------------------------------------------------------------+
//|                                                     CAdvisor.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.01"

#include "Receiver.mqh"

//+------------------------------------------------------------------+
//| EA base class                                                    |
//+------------------------------------------------------------------+
class CAdvisor {
protected:
   CStrategy         *m_strategies[];  // Array of trading strategies
   CReceiver         *m_receiver;      // Object for bringing volumes opened by strategies to the market (volume recipient)
public:
   CAdvisor(CReceiver *p_receiver = NULL);      // Constructor
   ~CAdvisor();                                 // Destructor

   virtual void      Tick();                    // OnTick event handler
   virtual void      Add(CStrategy *strategy);  // Method for adding a strategy
};

CAdvisor::CAdvisor(CReceiver *p_receiver) : m_receiver(p_receiver) {
   if(!m_receiver) {                // If the volume recipient is not specified
      m_receiver = new CReceiver(); // Create an empty recipient
   }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CAdvisor::~CAdvisor() {
   for(int i = 0; i < ArraySize(m_strategies); i++) {
      delete m_strategies[i]; // Delete all strategy objects
   }

   delete m_receiver;         // Delete the recipient
}

//+------------------------------------------------------------------+
//| OnTick event handler                                             |
//+------------------------------------------------------------------+
void CAdvisor::Tick(void) {
   bool isChanged = false;

// Call OnTick handling for all strategies
   for(int i = 0; i < ArraySize(m_strategies); i++) {
      m_strategies[i].Tick();
      isChanged |= m_strategies[i].IsChanged();
   }

   if(isChanged) {
      if(m_receiver.Correct()) {
         for(int i = 0; i < ArraySize(m_strategies); i++) {
            m_strategies[i].ResetChanges();
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Strategy adding method                                           |
//+------------------------------------------------------------------+
void CAdvisor::Add(CStrategy *strategy) {
   APPEND(m_strategies, strategy);  // Add the strategy to the end of the array
   m_receiver.Add(strategy);        // Add it to the receiver of trading volumes
}
//+------------------------------------------------------------------+
