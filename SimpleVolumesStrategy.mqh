//+------------------------------------------------------------------+
//|                                        SimpleVolumesStrategy.mqh |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/articles/14107"
#property description "The EA sets a pending order or a position at the moment when the tick volume of the candle"
#property description "exceeds the average volume in the direction of the current candle."
#property description "If orders have not yet turned into positions, they are deleted at expiration time."
#property description "Open positions are closed only by SL or TP."
#property version "1.02"

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

class CSimpleVolumesStrategy : public CStrategy {
private:
   //---  Open signal parameters
   int               m_signalPeriod;       // Number of candles for volume averaging
   double            m_signalDeviation;    // Relative deviation from the average to open the first order
   double            m_signaAddlDeviation; // Relative deviation from the average for opening the second and subsequent orders

   //---  Pending order parameters
   int               m_openDistance;       // Distance from price to pending order
   double            m_stopLevel;          // Stop Loss (in points)
   double            m_takeLevel;          // Take Profit (in points)
   int               m_ordersExpiration;   // Pending order expiration time (in minutes)

   //---  Money management parameters
   int               m_maxCountOfOrders;   // Max number of simultaneously open orders

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
   CSimpleVolumesStrategy(
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

   virtual void      Tick() override;     // OnTick event handler

   string            Symbol() {
      return m_symbol;
   }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSimpleVolumesStrategy::CSimpleVolumesStrategy(
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
   CStrategy(p_symbol, p_timeframe, p_fixedLot), // Call the base class constructor
   m_signalPeriod(p_signalPeriod),
   m_signalDeviation(p_signalDeviation),
   m_signaAddlDeviation(p_signaAddlDeviation),
   m_openDistance(p_openDistance),
   m_stopLevel(p_stopLevel),
   m_takeLevel(p_takeLevel),
   m_ordersExpiration(p_ordersExpiration),
   m_maxCountOfOrders(p_maxCountOfOrders) {
   ArrayResize(m_orders, m_maxCountOfOrders);

   // Load the indicator to get tick volumes
   iVolumesHandle = iVolumes(m_symbol, m_timeframe, VOLUME_TICK);

// Set the size of the tick volume receiving array and the required addressing
   ArrayResize(volumes, m_signalPeriod);
   ArraySetAsSeries(volumes, true);
}

//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void CSimpleVolumesStrategy::Tick() override {
   CStrategy::Tick();

// If their number is less than allowed
   if(m_ordersTotal < m_maxCountOfOrders) {
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
//| Signal for opening pending orders                                |
//+------------------------------------------------------------------+
int CSimpleVolumesStrategy::SignalForOpen() {
// By default, there is no signal
   int signal = 0;

// Copy volume values from the indicator buffer to the receiving array
   int res = CopyBuffer(iVolumesHandle, 0, 0, m_signalPeriod, volumes);

// If the required amount of numbers have been copied
   if(res == m_signalPeriod) {
      // Calculate their average value
      double avrVolume = ArrayAverage(volumes);

      // If the current volume exceeds the specified level, then
      if(volumes[0] > avrVolume * (1 + m_signalDeviation + m_ordersTotal * m_signaAddlDeviation)) {
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
//| Open BUY order                                                   |
//+------------------------------------------------------------------+
void CSimpleVolumesStrategy::OpenBuyOrder() {
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
   int distance = MathMax(m_openDistance, spread);

// Opening price
   double price = ask + distance * point;

// StopLoss and TakeProfit levels
   double sl = NormalizeDouble(price - m_stopLevel * point, digits);
   double tp = NormalizeDouble(price + (m_takeLevel + spread) * point, digits);

// Expiration time
   datetime expiration = TimeCurrent() + m_ordersExpiration * 60;

   bool res = false;
   if(m_openDistance > 0) {
      /* // Set BUY STOP pending order
         res = trade.BuyStop(lot,
                              NormalizeDouble(price, digits),
                              m_symbol,
                              NormalizeDouble(sl, digits),
                              NormalizeDouble(tp, digits),
                              ORDER_TIME_SPECIFIED,
                              expiration);
                              */
   } else if(m_openDistance < 0) {
      /* // Set BUY LIMIT pending order
         res = trade.BuyLimit(lot,
                             NormalizeDouble(price, digits),
                             m_symbol,
                             NormalizeDouble(sl, digits),
                             NormalizeDouble(tp, digits),
                             ORDER_TIME_SPECIFIED,
                             expiration);
                             */
   } else {
      // Open a virtual BUY position
      for(int i = 0; i < m_maxCountOfOrders; i++) {   // Iterate through all virtual positions
         if(!m_orders[i].IsOpen()) {                  // If we find one that is not open, then open it
            res = m_orders[i].Open(m_symbol, ORDER_TYPE_BUY, m_fixedLot,
                                   NormalizeDouble(sl, digits),
                                   NormalizeDouble(tp, digits));
            break;                                    // and exit
         }
      }
   }

   if(!res) {
      Print("Error opening BUY order");
   }

   m_isChanged = res;
   CountOrders();
}

//+------------------------------------------------------------------+
//| Open SELL order                                                  |
//+------------------------------------------------------------------+
void CSimpleVolumesStrategy::OpenSellOrder() {
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
   int distance = MathMax(m_openDistance, spread);

// Opening price
   double price = bid - distance * point;

// StopLoss and TakeProfit levels
   double sl = NormalizeDouble(price + m_stopLevel * point, digits);
   double tp = NormalizeDouble(price - (m_takeLevel + spread) * point, digits);

// Expiration time
   datetime expiration = TimeCurrent() + m_ordersExpiration * 60;

   bool res = false;
   if(m_openDistance > 0) {
      /* // Set SELL STOP pending order
      res = trade.SellStop(lot,
                           NormalizeDouble(price, digits),
                           m_symbol,
                           NormalizeDouble(sl, digits),
                           NormalizeDouble(tp, digits),
                           ORDER_TIME_SPECIFIED,
                           expiration);
                           */
   } else if(m_openDistance < 0) {
      /* // Set SELL LIMIT pending order
      res = trade.SellLimit(lot,
                               NormalizeDouble(price, digits),
                               m_symbol,
                               NormalizeDouble(sl, digits),
                               NormalizeDouble(tp, digits),
                               ORDER_TIME_SPECIFIED,
                               expiration);
                               */
   } else {
      // Open a virtual SELL position
      for(int i = 0; i < m_maxCountOfOrders; i++) {   // Iterate through all virtual positions
         if(!m_orders[i].IsOpen()) {                  // If we find one that is not open, then open it
            res = m_orders[i].Open(m_symbol, ORDER_TYPE_SELL, m_fixedLot,
                                   NormalizeDouble(sl, digits),
                                   NormalizeDouble(tp, digits));
            break;                                    // and exit
         }
      }
   }

   if(!res) {
      Print("Error opening SELL order");
   }

   m_isChanged = res;
   CountOrders();
}

//+------------------------------------------------------------------+
//| Number array average value                                       |
//+------------------------------------------------------------------+
double CSimpleVolumesStrategy::ArrayAverage(const double &array[]) {
   double s = 0;
   int total = ArraySize(array);
   for(int i = 0; i < total; i++) {
      s += array[i];
   }

   return s / MathMax(1, total);
}
//+------------------------------------------------------------------+
