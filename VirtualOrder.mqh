//+------------------------------------------------------------------+
//|                                                 VirtualOrder.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.01"

#include <Trade\SymbolInfo.mqh>

class CVirtualOrder;
class CVirtualReceiver;
class CVirtualStrategy;

#include "VirtualReceiver.mqh"
#include "VirtualStrategy.mqh"

//+------------------------------------------------------------------+
//| Class of virtual orders and positions                            |
//+------------------------------------------------------------------+
class CVirtualOrder {
private:
//--- Static fields
   static ulong      s_count;          // Counter of all created CVirtualOrder objects
   static
   CSymbolInfo       s_symbolInfo;     // Object for getting symbol properties

//--- Related recipient objects and strategies
   CVirtualReceiver  *m_receiver;
   CVirtualStrategy  *m_strategy;

//--- Order (position) properties
   ulong             m_id;             // ID
   string            m_symbol;         // Symbol
   double            m_lot;            // Volume
   ENUM_ORDER_TYPE   m_type;           // Type
   double            m_openPrice;      // Open price
   double            m_stopLoss;       // StopLoss level
   double            m_takeProfit;     // TakeProfit level
   string            m_comment;        // Comment

   datetime          m_openTime;       // Open time

//--- Closed order (position) properties
   double            m_closePrice;     // Close price
   datetime          m_closeTime;      // Close time
   string            m_closeReason;    // Closure reason

   double            m_point;          // Point value

   bool              m_isStopLoss;     // StopLoss activation property
   bool              m_isTakeProfit;   // TakeProfit activation property

//--- Private methods
   bool              CheckClose();     // Check closure conditions

public:
                     CVirtualOrder(
      CVirtualReceiver *p_receiver,
      CVirtualStrategy *p_strategy
   );                                  // Constructor

//--- Methods for checking the position (order) status
   bool              IsOpen() {        // Is the order open?
      return(this.m_openTime > 0 && this.m_closeTime == 0);
   };
   bool              IsMarketOrder() { // Is this a market position?
      return IsOpen() && (m_type == ORDER_TYPE_BUY || m_type == ORDER_TYPE_SELL);
   }
   bool              IsBuyOrder() {    // Is this an open BUY position?
      return IsOpen() && (m_type == ORDER_TYPE_BUY);
   }
   bool              IsSellOrder() {   // Is this an open SELL position?
      return IsOpen() && (m_type == ORDER_TYPE_SELL);
   }

//--- Methods for receiving position (order) properties
   ulong             Id() {            // ID
      return m_id;
   }
   double            Volume() {        // Volume with direction
      return IsBuyOrder() ? m_lot : (IsSellOrder() ? -m_lot : 0);
   }
   double            Profit();         // Current profit

   string            Symbol() {        // Symbol
      return m_symbol;
   }

//--- Methods for handling positions (orders)
   bool              Open(string symbol,
                          ENUM_ORDER_TYPE type,
                          double lot,
                          double sl = 0,
                          double tp = 0,
                          string comment = "",
                          bool inPoints = false
                         );      // Open position (order)

   void              Tick();     // Handle tick for position (order)
   void              Close();    // Close position (order)
};

// Initialize class static fields
CSymbolInfo          CVirtualOrder::s_symbolInfo;
ulong                CVirtualOrder::s_count = 0;

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVirtualOrder::CVirtualOrder(CVirtualReceiver *p_receiver, CVirtualStrategy *p_strategy) :
// Initialization list
   m_id(++s_count),  // New ID = object counter + 1
   m_receiver(p_receiver),
   m_strategy(p_strategy),
   m_symbol(""),
   m_lot(0),
   m_type(-1),
   m_openPrice(0),
   m_stopLoss(0),
   m_takeProfit(0),
   m_openTime(0),
   m_comment(""),
   m_closePrice(0),
   m_closeTime(0),
   m_closeReason(""),
   m_point(0) {
   PrintFormat(__FUNCTION__ + "#%d | CREATED VirtualOrder", m_id);
}

//+------------------------------------------------------------------+
//| Open a virtual position                                          |
//+------------------------------------------------------------------+
bool CVirtualOrder::Open(string symbol,         // Symbol
                         ENUM_ORDER_TYPE type,  // Type (BUY or SELL)
                         double lot,            // Volume
                         double sl = 0,         // StopLoss level (price or points)
                         double tp = 0,         // TakeProfit level (price or points)
                         string comment = "",   // Comment
                         bool inPoints = false  // Are the SL and TP levels set in points?
                        ) {
   if(IsOpen()) { // If the position is already open, then do nothing
      PrintFormat(__FUNCTION__ "#%d | ERROR: Order is opened already!", m_id);
      return false;
   }

   if(s_symbolInfo.Name(symbol)) {  // Select the desired symbol
      s_symbolInfo.RefreshRates();  // Update information about current prices

      // Initialize position properties
      m_symbol = symbol;
      m_lot = lot;
      m_openTime = TimeCurrent();
      m_closeTime = 0;
      m_type = type;
      m_comment = comment;

      // The position being opened is not closed by SL or TP
      m_isStopLoss = false;
      m_isTakeProfit = false;

      m_point = s_symbolInfo.Point();  // Save the point size for the symbol

      double spread = s_symbolInfo.Spread();

      // Depending on the direction, set the opening price, as well as the SL and TP levels.
      // If SL and TP are specified in points, then we first calculate their price levels
      // relative to the open price
      if(type == ORDER_TYPE_BUY) {
         m_openPrice = s_symbolInfo.Ask();

         m_stopLoss = (sl > 0 ? (inPoints ? m_openPrice - sl * m_point - spread * m_point : sl) : 0);
         m_takeProfit = (tp > 0 ? (inPoints ? m_openPrice + tp * m_point : tp) : 0);

      } else if(type == ORDER_TYPE_SELL) {
         m_openPrice = s_symbolInfo.Bid();

         m_stopLoss = (sl > 0 ? (inPoints ? m_openPrice + sl * m_point : sl) : 0);
         m_takeProfit = (tp > 0 ? (inPoints ? m_openPrice - tp * m_point - spread * m_point : tp) : 0);
      }

      // Notify the recipient and the strategy that the position (order) is open
      m_receiver.OnOpen(GetPointer(this));
      m_strategy.OnOpen();

      PrintFormat(__FUNCTION__ + "#%d | OPEN %s: %s %s %.2f | Price=%.5f | SL=%.5f | TP=%.5f | %s",
                  m_id, (IsMarketOrder() ? "Market" : "Pending"), StringSubstr(EnumToString(type), 11),
                  m_symbol, m_lot, m_openPrice, m_stopLoss, m_takeProfit, m_comment);

      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Close a position                                                 |
//+------------------------------------------------------------------+
void CVirtualOrder::Close() {
   if(IsOpen()) { // If the position is open
      // Define the closure reason to be displayed in the log
      string closeReason = "";

      if(m_isStopLoss) {
         closeReason += "[SL]";
      } else if(m_isTakeProfit) {
         closeReason += "[TP]";
      } else {
         closeReason += "[CL]";
      }

      PrintFormat(__FUNCTION__ + "#%d | CLOSE %s: %s %s %.2f | Profit=%.2f %s | %s",
                  m_id, (IsMarketOrder() ? "Market" : "Pending"), StringSubstr(EnumToString(m_type), 11),
                  m_symbol, m_lot, Profit(), closeReason, m_comment);

      m_closeTime = TimeCurrent();  // Position closing time

      // Save the close price depending on the type
      if(m_type == ORDER_TYPE_BUY) {
         m_closePrice = s_symbolInfo.Bid();
      } else if(m_type == ORDER_TYPE_SELL) {
         m_closePrice = s_symbolInfo.Ask();
      } else {
         m_closePrice = 0;
      }

      // Notify the recipient and the strategy that the position (order) is open
      m_receiver.OnClose(GetPointer(this));
      m_strategy.OnClose();
   }
}

//+------------------------------------------------------------------+
//| Calculate the current profit                                     |
//+------------------------------------------------------------------+
double CVirtualOrder::Profit() {
   double profit = 0;
   if(IsMarketOrder()) {   // If this is a market virtual position
      if(s_symbolInfo.Name(m_symbol)) {   // Select the desired symbol
         s_symbolInfo.RefreshRates();     // Update information about current prices

         // Current price, at which the position can be closed
         double closePrice = (m_type == ORDER_TYPE_BUY) ? s_symbolInfo.Bid() : s_symbolInfo.Ask();

         // Profit in the form of the difference between open and close
         if(m_type == ORDER_TYPE_BUY) {
            profit = closePrice - m_openPrice;
         } else {
            profit = m_openPrice - closePrice;
         }

         if(m_point > 1e-10) {   // If the point size is known, then
            // Recalculate the profit from the price difference into monetary terms for a volume of 1 lot
            if(profit > 0) {
               profit = profit / m_point * s_symbolInfo.TickValueProfit();
            } else {
               profit = profit / m_point * s_symbolInfo.TickValueLoss();
            }
         } else {
            PrintFormat(__FUNCTION__ + "#%d | ERROR: Point for %s is undefined", m_id, m_symbol);
            m_point = s_symbolInfo.Point();
         }
         // Recalculate profit for position volume
         profit *= m_lot;
      } else {
         PrintFormat(__FUNCTION__"#%d | ERROR: Can't select symbol %s", m_id, m_symbol);
      }
   }

   return profit;
}

//+------------------------------------------------------------------+
//| Check the need to close by SL or TP                              |
//+------------------------------------------------------------------+
bool CVirtualOrder::CheckClose() {
   if(IsMarketOrder()) {                  // If this is a market virtual position,
      if(s_symbolInfo.Name(m_symbol)) {   // Select the desired symbol
         s_symbolInfo.RefreshRates();     // Update information about current prices

         // Current price, at which the position can be closed
         double closePrice = (m_type == ORDER_TYPE_BUY) ? s_symbolInfo.Bid() : s_symbolInfo.Ask();
         double spread = s_symbolInfo.Spread();

         bool res = false;
         // Check that the price has reached SL or TP
         if(m_type == ORDER_TYPE_BUY) {
            m_isStopLoss = (m_stopLoss > 0 && closePrice <= m_stopLoss);
            m_isTakeProfit = (m_takeProfit > 0 && closePrice >= m_takeProfit);
         } else if(m_type == ORDER_TYPE_SELL) {
            m_isStopLoss = (m_stopLoss > 0 && closePrice >= m_stopLoss);
            m_isTakeProfit = (m_takeProfit > 0 && closePrice <= m_takeProfit);
         }

         // Has SL or TP been reached?
         res = (m_isStopLoss || m_isTakeProfit);

         if(res) {
            PrintFormat(__FUNCTION__ + "#%d | %s REACHED at %.5f: %.5f | %.5f, Profit=%.2f | %s",
                        m_id, (m_isStopLoss ? "SL" : "TP"), closePrice, m_stopLoss, m_takeProfit,
                        Profit(), m_comment);
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Handle a tick of a single virtual order (position)               |
//+------------------------------------------------------------------+
void CVirtualOrder::Tick() {
   if(IsMarketOrder()) {  // If this is a market virtual position
      if(CheckClose()) {  // Check if SL or TP levels have been reached
         Close();         // Close when reached
      }
   }
}
//+------------------------------------------------------------------+
