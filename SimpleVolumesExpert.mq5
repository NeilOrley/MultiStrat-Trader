//+------------------------------------------------------------------+
//|                                          SimpleVolumesExpert.mq5 |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/articles/14148"
#property description "The EA opens a market or pending order when"
#property description "the candle tick volume exceeds the average volume in the direction of the current candle."
#property description "If orders have not yet turned into positions, they are deleted at expiration time."
#property description "Open positions are closed only by SL or TP."

#include "SimpleVolumesStrategy.mqh"
#include "VirtualAdvisor.mqh"

input double depoPart_     = 1.0;      // Part of the deposit for one strategy
input ulong  magic_        = 27182;    // Magic

CAdvisor     *expert;                  // EA object

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
// Create and fill the array of strategy instances
   CStrategy *strategies[9];
   strategies[0] = new CSimpleVolumesStrategy(
      "EURGBP", PERIOD_H1,
      NormalizeDouble(0.01 / 0.16 * depoPart_, 2),
      13, 0.3, 1.0, 0, 10500, 465, 1000, 3);
   strategies[1] = new CSimpleVolumesStrategy(
      "EURGBP", PERIOD_H1,
      NormalizeDouble(0.01 / 0.09 * depoPart_, 2),
      17, 1.7, 0.5, 0, 16500, 220, 1000, 3);
   strategies[2] = new CSimpleVolumesStrategy(
      "EURGBP", PERIOD_H1,
      NormalizeDouble(0.01 / 0.16 * depoPart_, 2),
      51, 0.5, 1.1, 0, 19500, 370, 22000, 3);
   strategies[3] = new CSimpleVolumesStrategy(
      "GBPUSD", PERIOD_H1,
      NormalizeDouble(0.01 / 0.25 * depoPart_, 2),
      80, 1.1, 0.2, 0, 6000, 1190, 1000, 3);
   strategies[4] = new CSimpleVolumesStrategy(
      "GBPUSD", PERIOD_H1,
      NormalizeDouble(0.01 / 0.09 * depoPart_, 2),
      128, 2.0, 0.9, 0, 2000, 1170, 1000, 3);
   strategies[5] = new CSimpleVolumesStrategy(
      "GBPUSD", PERIOD_H1,
      NormalizeDouble(0.01 / 0.14 * depoPart_, 2),
      13, 1.5, 0.8, 0, 2500, 1375, 1000, 3);
   strategies[6] = new CSimpleVolumesStrategy(
      "EURUSD", PERIOD_H1,
      NormalizeDouble(0.01 / 0.23 * depoPart_, 2),
      24, 0.1, 0.3, 0, 7500, 2400, 24000, 3);
   strategies[7] = new CSimpleVolumesStrategy(
      "EURUSD", PERIOD_H1,
      NormalizeDouble(0.01 / 0.20 * depoPart_, 2),
      18, 0.2, 0.4, 0, 19500, 1480, 6000, 3);
   strategies[8] = new CSimpleVolumesStrategy(
      "EURUSD", PERIOD_H1,
      NormalizeDouble(0.01 / 0.22 * depoPart_, 2),
      128, 0.7, 0.3, 0, 3000, 170, 42000, 3);

// Create an EA handling virtual positions
   expert = new CVirtualAdvisor(magic_);

// Add strategies to the EA
   FOREACH(strategies, expert.Add(strategies[i]));

   return(INIT_SUCCEEDED);
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
   delete expert;
}
//+------------------------------------------------------------------+
