//+------------------------------------------------------------------+
//|                                                    CStrategy.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                                                antekov.yandex.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

#include <Object.mqh>

//+------------------------------------------------------------------+
//| Trading strategy base class                                      |
//+------------------------------------------------------------------+
class CStrategy : public CObject {
protected:
   ulong             m_magic;          // Magic
   string            m_symbol;         // Symbol (trading instrument)
   ENUM_TIMEFRAMES   m_timeframe;      // Chart period (timeframe)
   double            m_fixedLot;       // Size of opened positions (fixed)

public:
   // Constructor
   CStrategy(ulong p_magic,
             string p_symbol,
             ENUM_TIMEFRAMES p_timeframe,
             double p_fixedLot);

   virtual int       Init() = 0; // Strategy initialization - handling OnInit events
   virtual void      Tick() = 0; // Main method - handling OnTick events
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStrategy::CStrategy(
   ulong p_magic,
   string p_symbol,
   ENUM_TIMEFRAMES p_timeframe,
   double p_fixedLot) :
// Initialization list
   m_magic(p_magic),
   m_symbol(p_symbol),
   m_timeframe(p_timeframe),
   m_fixedLot(p_fixedLot)
{}
//+------------------------------------------------------------------+
