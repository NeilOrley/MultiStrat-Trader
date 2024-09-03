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
                         magic_ + 1, "EURUSD", PERIOD_H1,
                         NormalizeDouble(0.34 * depoPart_, 2),
                         28, 2.2, 0.3, 79, 60, 490, 3000, 3)
                     );
   expert.AddStrategy(new CSimpleVolumeStrategy(
                         magic_ + 2, "EURUSD", PERIOD_H1,
                         NormalizeDouble(0.10 * depoPart_, 2),
                         328, 2.2, 0.2, 67, 180, 430, 2700, 3)
                     );
   expert.AddStrategy(new CSimpleVolumeStrategy(
                         magic_ + 3, "GBPUSD", PERIOD_H1,
                         NormalizeDouble(0.10 * depoPart_, 2),
                         328, 2.2, 0.2, 67, 180, 430, 2700, 3)
                     );
   expert.AddStrategy(new CSimpleVolumeStrategy(
                         magic_ + 4, "AUDUSD", PERIOD_H1,
                         NormalizeDouble(0.10 * depoPart_, 2),
                         328, 2.2, 0.2, 67, 180, 430, 2700, 3)
                     );
   expert.AddStrategy(new CSimpleVolumeStrategy(
                         magic_ + 5, "EURUSD", PERIOD_H1,
                         NormalizeDouble(0.10 * depoPart_, 2),
                         18, 0.4, 0.1, 79, 150, 150, 1020, 3)
                     );
   expert.AddStrategy(new CSimpleVolumeStrategy(
                         magic_ + 6, "GBPUSD", PERIOD_H1,
                         NormalizeDouble(0.10 * depoPart_, 2),
                         314, 0.6, 0.2, 108, 480, 490, 1200, 3)
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
