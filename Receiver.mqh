//+------------------------------------------------------------------+
//|                                                     Receiver.mqh |
//|                                 Copyright 2022-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.03"

//+------------------------------------------------------------------+
//| Base class for converting open volumes into market positions     |
//+------------------------------------------------------------------+
class CReceiver {
protected:
   ulong             m_magic;       // Magic

public:
                     CReceiver(ulong p_magic = 1);    // Constructor
   virtual bool      Correct() = 0; // Adjustment of open volumes
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CReceiver::CReceiver(ulong p_magic) : m_magic(p_magic) {
}
//+------------------------------------------------------------------+
