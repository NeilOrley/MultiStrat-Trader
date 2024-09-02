//+------------------------------------------------------------------+
//|                                        SimpleVolumesStrategy.mqh |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/articles/14148"
#property version "1.03"

#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>

#include "VirtualStrategy.mqh"

/** Strategy

Strategy input:
   - Symbol
   - Period
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
   - calculate the average tick volume for the last K closed candles, get the V_avr value.
   - If the V > V_avr * (1 + D + N * D_add) condition is met, then:
        - determine the direction of price change on the current candle: if the price has increased,
          set BUY, BUY_STOP or BUY_LIMIT, otherwise - SELL, SELL_STOP or SELL_LIMIT
        - set a market or pending order based on the distance
          (0 - market, >0 - pending stop, <0 - pending limit),
          of the expiration time and StopLoss/TakeProfit levels set in the parameters.
*/

//+------------------------------------------------------------------+
//| Trading strategy using tick volumes                              |
//+------------------------------------------------------------------+
class CSimpleVolumesStrategy : public CVirtualStrategy {
protected:
   string            m_symbol;         // Symbol (trading instrument)
   ENUM_TIMEFRAMES   m_timeframe;      // Chart period (timeframe)
   double            m_fixedLot;       // Size of opened positions (fixed)

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

   CSymbolInfo       m_symbolInfo;          // Object for obtaining data on the symbol properties

   int               m_iVolumesHandle;      // Tick volume indicator handle
   double            m_volumes[];           // Receiver array of indicator values (volumes themselves)

   //--- Methods
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
   m_symbol(p_symbol),
   m_timeframe(p_timeframe),
   m_fixedLot(p_fixedLot),
   m_signalPeriod(p_signalPeriod),
   m_signalDeviation(p_signalDeviation),
   m_signaAddlDeviation(p_signaAddlDeviation),
   m_openDistance(p_openDistance),
   m_stopLevel(p_stopLevel),
   m_takeLevel(p_takeLevel),
   m_ordersExpiration(p_ordersExpiration),
   m_maxCountOfOrders(p_maxCountOfOrders) {
   CVirtualReceiver::Get(GetPointer(this), m_orders, m_maxCountOfOrders);

// Load the indicator to get tick volumes
   m_iVolumesHandle = iVolumes(m_symbol, m_timeframe, VOLUME_TICK);

// Set the size of the tick volume receiving array and the required addressing
   ArrayResize(m_volumes, m_signalPeriod);
   ArraySetAsSeries(m_volumes, true);
}



//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void CSimpleVolumesStrategy::Tick() override {
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
   int res = CopyBuffer(m_iVolumesHandle, 0, 0, m_signalPeriod, m_volumes);

// If the required amount of numbers have been copied
   if(res == m_signalPeriod) {
      // Calculate their average value
      double avrVolume = ArrayAverage(m_volumes);

      // If the current volume exceeds the specified level, then
      if(m_volumes[0] > avrVolume * (1 + m_signalDeviation + m_ordersTotal * m_signaAddlDeviation)) {
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
   m_symbolInfo.Name(m_symbol);
   m_symbolInfo.RefreshRates();

// Retrieve the necessary symbol and price data
   double point = m_symbolInfo.Point();
   int digits = m_symbolInfo.Digits();
   double bid = m_symbolInfo.Bid();
   double ask = m_symbolInfo.Ask();
   int spread = m_symbolInfo.Spread();

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
}

//+------------------------------------------------------------------+
//| Open SELL order                                                  |
//+------------------------------------------------------------------+
void CSimpleVolumesStrategy::OpenSellOrder() {
// Update symbol current price data
   m_symbolInfo.Name(m_symbol);
   m_symbolInfo.RefreshRates();

// Retrieve the necessary symbol and price data
   double point = m_symbolInfo.Point();
   int digits = m_symbolInfo.Digits();
   double bid = m_symbolInfo.Bid();
   double ask = m_symbolInfo.Ask();
   int spread = m_symbolInfo.Spread();

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
