//+------------------------------------------------------------------+
//|                                          SimpleVolumesExpert.mq5 |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/articles/14026"
#property description "The EA sets a pending order at the moment when the tick volume of the candle exceeds the average volume"
#property description "in the direction of the current candle."
#property description "If orders have not yet turned into positions, they are deleted at expiration time."
#property description "Open positions are closed only by SL or TP."

#include "Advisor.mqh"
#include "SimpleVolumesStartegy.mqh"

input double depoPart_  = 0.8;      // Part of the deposit for one strategy
input ulong  magic_     = 27182;    // Magic

CAdvisor     expert;                // EA object

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   expert.AddStrategy(new CSimpleVolumeStrategy(
                         magic_ + 1, "EURGBP", PERIOD_H1,
                         NormalizeDouble(0.34 * depoPart_, 2),
                         130, 0.9, 1.4, 231, 3750, 50, 600, 3)
                     );
   expert.AddStrategy(new CSimpleVolumeStrategy(
                         magic_ + 2, "EURGBP", PERIOD_H1,
                         NormalizeDouble(0.10 * depoPart_, 2),
                         159, 1.7, 0.8, 248, 3600, 495, 39000, 3)
                     );

   int res = expert.Init();   // Initialization of all EA strategies

   return(res);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   expert.Tick();
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   expert.Deinit();
}
//+------------------------------------------------------------------+
