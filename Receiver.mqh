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
   static ulong      s_magic;       // Magic

public:
   virtual bool      Correct() = 0; // Adjustment of open volumes
};

ulong CReceiver::s_magic = 0;
