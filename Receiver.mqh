//+------------------------------------------------------------------+
//|                                                     Receiver.mqh |
//|                                 Copyright 2022-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| Base class for converting open volumes into market positions     |
//+------------------------------------------------------------------+
class CReceiver {
protected:
   CStrategy         *m_strategies[];  // Array of strategies
   ulong             m_magic;          // Magic

public:
   CReceiver(ulong p_magic = 0);                // Constructor
   virtual void      Add(CStrategy *strategy);  // Add strategy
   virtual bool      Correct();                 // Adjustment of open volumes
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CReceiver::CReceiver(ulong p_magic) : m_magic(p_magic) {
   ArrayResize(m_strategies, 0, 128);
}

//+------------------------------------------------------------------+
//| Add strategy                                                     |
//+------------------------------------------------------------------+
void CReceiver::Add(CStrategy *strategy) {
   APPEND(m_strategies, strategy);
}

//+------------------------------------------------------------------+
//| Adjust open volumes                                              |
//+------------------------------------------------------------------+
bool CReceiver::Correct() {
   return true;
}
//+------------------------------------------------------------------+
