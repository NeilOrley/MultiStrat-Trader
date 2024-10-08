//+------------------------------------------------------------------+
//|                                                SimpleVolumes.mq5 |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/articles/14026"
#property description "The EA sets a pending order at the moment when the tick volume of the candle exceeds the average volume"
#property description "in the direction of the current candle."
#property description "If orders have not yet turned into positions, they are deleted at expiration time."
#property description "Open positions are closed only by SL or TP."

#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>

/**
The EA runs on a specific symbol and period (timeframe) on the Hedge account

Set the input:
   - Number of candles for volume averaging (K)
   - Relative deviation from the average for opening the first order (D)
   - Relative deviation from the average for opening the second and subsequent orders (D_add)
   - Distance from price to pending order
   - Stop Loss (in points)
   - Take Profit (in points)
   - Expiration time of pending orders (in minutes)
   - Maximum number of simultaneously open orders (N_max)
   - Single order volume
Find the number of open orders and positions (N).
If it is less than N_max, then:
        calculate the average tick volume for the last K closed candles, get the V_avr value.
        If the V > V_avr * (1 + D + N * D_add) condition is met, then:
                determine the direction of price change on the current candle: if the price has increased, then we will place a BUY_STOP pending order, otherwise - SELL_STOP
                place a pending order at the distance, expiration time, and StopLoss and TakeProfit levels specified in the parameters.
*/

input group "===  Opening signal parameters"
input int         signalPeriod_        = 48;    // Number of candles for volume averaging
input double      signalDeviation_     = 1.0;   // Relative deviation from the average to open the first order
input double      signaAddlDeviation_  = 1.0;   // Relative deviation from the average for opening the second and subsequent orders

input group "===  Pending order parameters"
input int         openDistance_        = 200;   // Distance from price to pending order
input double      stopLevel_           = 2000;  // Stop Loss (in points)
input double      takeLevel_           = 75;    // Take Profit (in points)
input int         ordersExpiration_    = 6000;  // Pending order expiration time (in minutes)

input group "===  Money management parameters"
input int         maxCountOfOrders_    = 3;     // Maximum number of simultaneously open orders
input double      fixedLot_            = 0.01;  // Single order volume

input group "===  EA parameters"
input ulong       magicN_              = 27181; // Magic


CTrade            trade;            // Object for performing trading operations

COrderInfo        orderInfo;        // Object for receiving information about placed orders
CPositionInfo     positionInfo;     // Object for receiving information about open positions

int               countOrders;      // Number of placed pending orders
int               countPositions;   // Number of open positions

CSymbolInfo       symbolInfo;       // Object for obtaining data on the symbol properties

int               iVolumesHandle;   // Tick volume indicator handle
double            volumes[];        // Receiver array of indicator values (volumes themselves)

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit() {
// Load the indicator to get tick volumes
   iVolumesHandle = iVolumes(Symbol(), PERIOD_CURRENT, VOLUME_TICK);

// Set the size of the tick volume receiving array and the required addressing
   ArrayResize(volumes, signalPeriod_);
   ArraySetAsSeries(volumes, true);

// Set Magic Number for placing orders via 'trade'
   trade.SetExpertMagicNumber(magicN_);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick() {
// Count open positions and orders
   UpdateCounts();

// If their number is less than allowed
   if(countOrders + countPositions < maxCountOfOrders_) {
      // Get an open signal
      int signal = SignalForOpen();

      if(signal == 1) {          // If there is a buy signal, then
         OpenBuyOrder();         // open the BUY_STOP order
      } else if(signal == -1) {  // If there is a sell signal, then
         OpenSellOrder();        // open the SELL_STOP order
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate the number of open orders and positions                |
//+------------------------------------------------------------------+
void UpdateCounts() {
// Reset position and order counters
   countPositions = 0;
   countOrders = 0;

// Loop through all positions
   for(int i = 0; i < PositionsTotal(); i++) {
      // If the position with index i is selected successfully and its Magic is ours, then we count it
      if(positionInfo.SelectByIndex(i) && positionInfo.Magic() == magicN_) {
         countPositions++;
      }
   }

// Loop through all orders
   for(int i = 0; i < OrdersTotal(); i++) {
      // If the order with index i is selected successfully and its Magic is the one we need, then we consider it
      if(orderInfo.SelectByIndex(i) && orderInfo.Magic() == magicN_) {
         countOrders++;
      }
   }
}

//+------------------------------------------------------------------+
//| Open the BUY_STOP order                                          |
//+------------------------------------------------------------------+
void OpenBuyOrder() {
// Update symbol current price data
   symbolInfo.Name(Symbol());
   symbolInfo.RefreshRates();

// Retrieve the necessary symbol and price data
   double point = symbolInfo.Point();
   int digits = symbolInfo.Digits();
   double bid = symbolInfo.Bid();
   double ask = symbolInfo.Ask();
   int spread = symbolInfo.Spread();

// Let's make sure that the opening distance is not less than the spread
   int distance = MathMax(openDistance_, spread);

// Opening price
   double price = ask + distance * point; 
   
// StopLoss and TakeProfit levels
   double sl = NormalizeDouble(price - stopLevel_ * point, digits);
   double tp = NormalizeDouble(price + (takeLevel_ + spread) * point, digits);
   
// Expiration time
   datetime expiration = TimeCurrent() + ordersExpiration_ * 60; 
   
// Order volume
   double lot = fixedLot_; 
   
// Set a pending order
   bool res = trade.BuyStop(lot,
                            NormalizeDouble(price, digits),
                            Symbol(),
                            NormalizeDouble(sl, digits),
                            NormalizeDouble(tp, digits),
                            ORDER_TIME_SPECIFIED,
                            expiration);

   if(!res) {
      Print("Error opening order");
   }
}

//+------------------------------------------------------------------+
//| Open the SELL_STOP order                                         |
//+------------------------------------------------------------------+
void OpenSellOrder() {
// Update symbol current price data
   symbolInfo.Name(Symbol());
   symbolInfo.RefreshRates();

// Retrieve the necessary symbol and price data
   double point = symbolInfo.Point();
   int digits = symbolInfo.Digits();
   double bid = symbolInfo.Bid();
   double ask = symbolInfo.Ask();
   int spread = symbolInfo.Spread();

// Let's make sure that the opening distance is not less than the spread
   int distance = MathMax(openDistance_, spread);

// Opening price
   double price = bid - distance * point;
   
// StopLoss and TakeProfit levels
   double sl = NormalizeDouble(price + stopLevel_ * point, digits);
   double tp = NormalizeDouble(price - (takeLevel_ + spread) * point, digits);

// Expiration time
   datetime expiration = TimeCurrent() + ordersExpiration_ * 60;

// Order volume
   double lot = fixedLot_;

// Set a pending order
   bool res = trade.SellStop(lot,
                             NormalizeDouble(price, digits),
                             Symbol(),
                             NormalizeDouble(sl, digits),
                             NormalizeDouble(tp, digits),
                             ORDER_TIME_SPECIFIED,
                             expiration);

   if(!res) {
      Print("Error opening order");
   }
}

//+------------------------------------------------------------------+
//| Signal for opening pending orders                                |
//+------------------------------------------------------------------+
int SignalForOpen() {
// By default, there is no signal
   int signal = 0;

// Copy volume values from the indicator buffer to the receiving array
   int res = CopyBuffer(iVolumesHandle, 0, 0, signalPeriod_, volumes);

// If the required amount of numbers have been copied
   if(res == signalPeriod_) {
      // Calculate their average value
      double avrVolume = ArrayAverage(volumes);

      // If the current volume exceeds the specified level, then
      if(volumes[0] > avrVolume * (1 + signalDeviation_ + (countOrders + countPositions) * signaAddlDeviation_)) {
         // if the opening price of the candle is less than the current (closing) price, then
         if(iOpen(Symbol(), PERIOD_CURRENT, 0) < iClose(Symbol(), PERIOD_CURRENT, 0)) {
            signal = 1; // buy signal
         } else {
            signal = -1; // otherwise, sell signal
         }
      }
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Number array average value                                       |
//+------------------------------------------------------------------+
double ArrayAverage(const double &array[]) {
   double s = 0;
   int total = ArraySize(array);
   for(int i = 0; i < total; i++) {
      s += array[i];
   }

   return s / MathMax(1, total);
}
//+------------------------------------------------------------------+
