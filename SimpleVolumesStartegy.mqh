//+------------------------------------------------------------------+
//|                                        SimpleVolumesStrategy.mqh |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link "https://www.mql5.com/en/articles/14026"
#property description "The EA sets a pending order at the moment when the tick volume of the candle exceeds the average volume"
#property description "in the direction of the current candle."
#property description "If orders have not yet turned into positions, they are deleted at expiration time."
#property description "Open positions are closed only by SL or TP."
#property version "1.00"

#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>

#include "Strategy.mqh"

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

class CSimpleVolumeStrategy : public CStrategy {
private:
   //---  Open signal parameters
   int               signalPeriod_;       // Number of candles for volume averaging
   double            signalDeviation_;    // Relative deviation from the average to open the first order
   double            signaAddlDeviation_; // Relative deviation from the average for opening the second and subsequent orders

   //---  Pending order parameters
   int               openDistance_;       // Distance from price to pending order
   double            stopLevel_;          // Stop Loss (in points)
   double            takeLevel_;          // Take Profit (in points)
   int               ordersExpiration_;   // Pending order expiration time (in minutes)

   //---  Money management parameters
   int               maxCountOfOrders_;   // Maximum number of simultaneously open orders

   CTrade            trade;               // Object for performing trading operations

   COrderInfo        orderInfo;           // Object for receiving information about placed orders
   CPositionInfo     positionInfo;        // Object for receiving information about open positions

   int               countOrders;         // Number of placed pending orders
   int               countPositions;      // Number of open positions

   CSymbolInfo       symbolInfo;          // Object for obtaining data on the symbol properties

   int               iVolumesHandle;      // Tick volume indicator handle
   double            volumes[];           // Receiver array of indicator values (volumes themselves)

   //--- Methods
   void              UpdateCounts();      // Calculate the number of open orders and positions
   int               SignalForOpen();     // Signal for opening pending orders
   void              OpenBuyOrder();      // Open the BUY_STOP order
   void              OpenSellOrder();     // Open the SELL_STOP order
   double            ArrayAverage(
      const double &array[]);             // Average value of the number array

public:
   //--- Public methods
   CSimpleVolumeStrategy(
      ulong            p_magic,
      string           p_symbol,
      ENUM_TIMEFRAMES  p_timeframe,
      double           p_fixedLot,
      int              p_signalPeriod,
      double           p_signalDeviation,
      double           p_signaAddlDeviation,
      int              p_openDistance,
      double           p_stopLevel,
      double           p_takeLevel,
      int              p_ordersExpiration,
      int              p_maxCountOfOrders
   );                                     // Constructor

   virtual int       Init();              // Strategy initialization method
   virtual void      Tick();              // OnTick event handler
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSimpleVolumeStrategy::CSimpleVolumeStrategy(
   ulong            p_magic,
   string           p_symbol,
   ENUM_TIMEFRAMES  p_timeframe,
   double           p_fixedLot,
   int              p_signalPeriod,
   double           p_signalDeviation,
   double           p_signaAddlDeviation,
   int              p_openDistance,
   double           p_stopLevel,
   double           p_takeLevel,
   int              p_ordersExpiration,
   int              p_maxCountOfOrders) :
   // Initialization list
   CStrategy(p_magic, p_symbol, p_timeframe, p_fixedLot), // Call the base class constructor
   signalPeriod_(p_signalPeriod),
   signalDeviation_(p_signalDeviation),
   signaAddlDeviation_(p_signaAddlDeviation),
   openDistance_(p_openDistance),
   stopLevel_(p_stopLevel),
   takeLevel_(p_takeLevel),
   ordersExpiration_(p_ordersExpiration),
   maxCountOfOrders_(p_maxCountOfOrders)
{}

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int CSimpleVolumeStrategy::Init() {
// Load the indicator to get tick volumes
   iVolumesHandle = iVolumes(m_symbol, m_timeframe, VOLUME_TICK);

// Set the size of the tick volume receiving array and the required addressing
   ArrayResize(volumes, signalPeriod_);
   ArraySetAsSeries(volumes, true);

// Set Magic Number for placing orders via 'trade'
   trade.SetExpertMagicNumber(m_magic);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void CSimpleVolumeStrategy::Tick() {
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
void CSimpleVolumeStrategy::UpdateCounts() {
// Reset position and order counters
   countPositions = 0;
   countOrders = 0;

// Loop through all positions
   for(int i = 0; i < PositionsTotal(); i++) {
      // If the position with index i is selected successfully and its Magic is ours, then we count it
      if(positionInfo.SelectByIndex(i) && positionInfo.Magic() == m_magic) {
         countPositions++;
      }
   }

// Loop through all orders
   for(int i = 0; i < OrdersTotal(); i++) {
      // If the order with index i is selected successfully and its Magic is the one we need, then we consider it
      if(orderInfo.SelectByIndex(i) && orderInfo.Magic() == m_magic) {
         countOrders++;
      }
   }
}

//+------------------------------------------------------------------+
//| Signal for opening pending orders                                |
//+------------------------------------------------------------------+
int CSimpleVolumeStrategy::SignalForOpen() {
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
         if(iOpen(m_symbol, m_timeframe, 0) < iClose(m_symbol, m_timeframe, 0)) {
            signal = 1; // buy signal
         } else {
            signal = -1; // otherwise, sell signal
         }
      }
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Open the BUY_STOP order                                          |
//+------------------------------------------------------------------+
void CSimpleVolumeStrategy::OpenBuyOrder() {
// Update symbol current price data
   symbolInfo.Name(m_symbol);
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
   double lot = m_fixedLot;

// Set a pending order
   bool res = trade.BuyStop(lot,
                            NormalizeDouble(price, digits),
                            m_symbol,
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
void CSimpleVolumeStrategy::OpenSellOrder() {
// Update symbol current price data
   symbolInfo.Name(m_symbol);
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
   double lot = m_fixedLot;

// Set a pending order
   bool res = trade.SellStop(lot,
                             NormalizeDouble(price, digits),
                             m_symbol,
                             NormalizeDouble(sl, digits),
                             NormalizeDouble(tp, digits),
                             ORDER_TIME_SPECIFIED,
                             expiration);

   if(!res) {
      Print("Error opening order");
   }
}

//+------------------------------------------------------------------+
//| Number array average value                                       |
//+------------------------------------------------------------------+
double CSimpleVolumeStrategy::ArrayAverage(const double &array[]) {
   double s = 0;
   int total = ArraySize(array);
   for(int i = 0; i < total; i++) {
      s += array[i];
   }

   return s / MathMax(1, total);
}
//+------------------------------------------------------------------+
