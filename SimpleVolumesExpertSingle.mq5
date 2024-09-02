//+------------------------------------------------------------------+
//|                                    SimpleVolumesExpertSingle.mq5 |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/articles/14148"
#property description "The EA opens a market or pending order when"
#property description "the candle tick volume exceeds the average volume in the direction of the current candle."
#property description "If orders have not yet turned into positions, they are deleted at expiration time."
#property description "Open positions are closed only by SL or TP."

#include "VirtualAdvisor.mqh"
#include "SimpleVolumesStrategy.mqh"

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input string      symbol_              = "EURGBP";    // Trading instrument (symbol)
input
ENUM_TIMEFRAMES   timeframe_           = PERIOD_H1;   // Chart period

input group "===  Opening signal parameters"
input int         signalPeriod_        = 13;    // Number of candles for volume averaging
input double      signalDeviation_     = 0.3;   // Relative deviation from the average to open the first order
input double      signaAddlDeviation_  = 1.0;   // Relative deviation from the average for opening the second and subsequent orders

input group "===  Pending order parameters"
input int         openDistance_        = 0;     // Distance from price to pending order
input double      stopLevel_           = 10500; // Stop Loss (in points)
input double      takeLevel_           = 465;   // Take Profit (in points)
input int         ordersExpiration_    = 1000;  // Pending order expiration time (in minutes)

input group "===  Money management parameters"
input int         maxCountOfOrders_    = 3;     // Maximum number of simultaneously open orders
input double      fixedLot_            = 0.01;  // Single order volume

input group "===  EA parameters"
input ulong       magic_              = 27181; // Magic

CAdvisor     *expert;         // Pointer to the EA object

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
// Create an EA handling virtual positions
   expert = new CVirtualAdvisor(magic_);

   expert.Add(new CSimpleVolumesStrategy(
                 symbol_, timeframe_,
                 fixedLot_,
                 signalPeriod_, signalDeviation_, signaAddlDeviation_,
                 openDistance_, stopLevel_, takeLevel_, ordersExpiration_,
                 maxCountOfOrders_)
             );       // Add one strategy instance

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
