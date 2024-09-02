//+------------------------------------------------------------------+
//|                                                     Strategy.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.03"

//+------------------------------------------------------------------+
//| Trading strategy base class                                      |
//+------------------------------------------------------------------+
class CStrategy {
public:
   virtual void      Tick() = 0; // Handle OnTick events
};
//+------------------------------------------------------------------+
