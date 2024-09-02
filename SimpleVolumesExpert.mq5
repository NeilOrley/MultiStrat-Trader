//+------------------------------------------------------------------+
//|                                          SimpleVolumesExpert.mq5 |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/articles/14246"
#property description "The EA opens a market or pending order when"
#property description "the candle tick volume exceeds the average volume in the direction of the current candle."
#property description "If orders have not yet turned into positions, they are deleted at expiration time."
#property description "Open positions are closed only by SL or TP."

#define __VERSION__ "1.00"
#property version __VERSION__

#include "SimpleVolumesStrategy.mqh"
#include "VirtualAdvisor.mqh"

enum ENUM_VA_GROUP {
   VAG_EURGBP,          // Only EURGBP (3 items)
   VAG_EURUSD,          // Only EURUSD (3 items)
   VAG_GBPUSD,          // Only GBPUSD (3 items)
   VAG_EURGBPUSD_9,     // EUR-GBP-USD (9 items)
   VAG_EURGBPUSD_3_3_3  // EUR-GBP-USD (3+3+3 items)
};

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "::: Strategy groups"
input ENUM_VA_GROUP group_ = VAG_EURGBP;  // - Strategy group

input group "::: Money management"
input double expectedDrawdown_ = 10;      // - Maximum risk (%)
input double fixedBalance_ = 0;           // - Used deposit (0 - use all) in the account currency
input double scale_ = 1.0;                // - Group scaling multiplier

input group "::: Other parameters"
input ulong  magic_        = 27183;       // - Magic


CVirtualAdvisor     *expert;              // EA object


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // Set parameters in the money management class
   CMoney::DepoPart(expectedDrawdown_ / 10.0);
   CMoney::FixedBalance(fixedBalance_);

   // Create an EA handling virtual positions
   expert = new CVirtualAdvisor(magic_, "SimpleVolumes_" + EnumToString(group_));

   // Create and fill the array of all strategy instances
   CVirtualStrategy *strategies[] = {
      new CSimpleVolumesStrategy("EURGBP", PERIOD_H1,  13, 0.3, 1.0, 0, 10500,  465,  1000, 3, 1600),
      new CSimpleVolumesStrategy("EURGBP", PERIOD_H1,  17, 1.7, 0.5, 0, 16500,  220,  1000, 3,  900),
      new CSimpleVolumesStrategy("EURGBP", PERIOD_H1,  51, 0.5, 1.1, 0, 19500,  370, 22000, 3, 1600),

      new CSimpleVolumesStrategy("EURUSD", PERIOD_H1,  24, 0.1, 0.3, 0,  7500, 2400, 24000, 3, 2300),
      new CSimpleVolumesStrategy("EURUSD", PERIOD_H1,  18, 0.2, 0.4, 0, 19500, 1480,  6000, 3, 2000),
      new CSimpleVolumesStrategy("EURUSD", PERIOD_H1, 128, 0.7, 0.3, 0,  3000,  170, 42000, 3, 2200),

      new CSimpleVolumesStrategy("GBPUSD", PERIOD_H1,  80, 1.1, 0.2, 0,  6000, 1190,  1000, 3, 2500),
      new CSimpleVolumesStrategy("GBPUSD", PERIOD_H1, 128, 2.0, 0.9, 0,  2000, 1170,  1000, 3,  900),
      new CSimpleVolumesStrategy("GBPUSD", PERIOD_H1,  13, 1.5, 0.8, 0,  2500, 1375,  1000, 3, 1400),
   };

   // FOREACH(strategies, PrintFormat("%d: %.2f", i, strategies[i].FittedBalance()));

   // Create arrays of pointers to strategies, one symbol at a time, from the available strategies
   CVirtualStrategy *strategiesEG[] = {strategies[0], strategies[1], strategies[2]};
   CVirtualStrategy *strategiesEU[] = {strategies[3], strategies[4], strategies[5]};
   CVirtualStrategy *strategiesGU[] = {strategies[6], strategies[7], strategies[8]};

   // Create and add selected groups of strategies to the EA
   switch(group_) {
   case VAG_EURGBP: {
      expert.Add(CVirtualStrategyGroup(strategiesEG, scale_));
      FOREACH(strategiesEU, delete strategiesEU[i]);
      FOREACH(strategiesGU, delete strategiesGU[i]);
      break;
   }
   case VAG_EURUSD: {
      expert.Add(CVirtualStrategyGroup(strategiesEU, scale_));
      FOREACH(strategiesEG, delete strategiesEG[i]);
      FOREACH(strategiesGU, delete strategiesGU[i]);
      break;
   }
   case VAG_GBPUSD: {
      expert.Add(CVirtualStrategyGroup(strategiesGU, scale_));
      FOREACH(strategiesEU, delete strategiesEU[i]);
      FOREACH(strategiesEG, delete strategiesEG[i]);
      break;
   }
   case VAG_EURGBPUSD_9: {
      expert.Add(CVirtualStrategyGroup(strategies, scale_));
      break;
   }
   case VAG_EURGBPUSD_3_3_3: {
      // Create a group of three strategy groups
      CVirtualStrategyGroup *groups[] = {
         new CVirtualStrategyGroup(strategiesEG, 1.25),
         new CVirtualStrategyGroup(strategiesEU, 2.24),
         new CVirtualStrategyGroup(strategiesGU, 2.64)
      };

      expert.Add(CVirtualStrategyGroup(groups, scale_));
      break;
   }
   default:
      return(INIT_FAILED);
   }

// Load the previous state if available
   expert.Load();
   expert.Tick();

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
