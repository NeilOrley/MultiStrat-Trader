//+------------------------------------------------------------------+
//|                                              VirtualReceiver.mqh |
//|                                 Copyright 2022-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

class CVirtualSymbolReceiver;

#include "Macros.mqh"
#include "Receiver.mqh"
#include "VirtualOrder.mqh"
#include "VirtualSymbolReceiver.mqh"

//+------------------------------------------------------------------+
//| Class for converting open volumes to market positions (receiver) |
//+------------------------------------------------------------------+
class CVirtualReceiver : public CReceiver {
protected:
// Static pointer to a single class instance
   static   CVirtualReceiver *s_instance;

   CVirtualOrder     *m_orders[];         // Array of virtual positions
   CVirtualSymbolReceiver
   *m_symbolReceivers[];                  // Array of recipients for individual symbols
   bool              m_isChanged;         // Are there any changes in open positions?

//--- Private methods
   CVirtualReceiver(ulong p_magic = 0);   // Private constructor
   bool              IsTradeAllowed();    // Is trading available?

public:
   ~CVirtualReceiver();  // Destructor

//--- Static methods
   static
   CVirtualReceiver  *Instance(ulong p_magic = 0);    // Singleton - creating and getting a single instance

   static void       Get(CVirtualStrategy *strategy,
                         CVirtualOrder *&orders[],
                         int n); // Allocate the necessary amount of virtual positions to the strategy

//--- Public methods
   void              OnOpen(CVirtualOrder *p_order);  // Handle virtual position opening
   void              OnClose(CVirtualOrder *p_order); // Handle virtual position closing
   void              Tick();     // Handle a tick for the array of virtual orders (positions)

   virtual bool      Correct() override;              // Adjustment of open volumes
};

// Initializing a static pointer to a single class instance
CVirtualReceiver *CVirtualReceiver::s_instance = NULL;

//+------------------------------------------------------------------+
//| Closed constructor                                               |
//+------------------------------------------------------------------+
CVirtualReceiver::CVirtualReceiver(ulong p_magic) :
   CReceiver(p_magic), m_isChanged(true) {}

//+------------------------------------------------------------------+
//| Is trading available?                                            |
//+------------------------------------------------------------------+
bool CVirtualReceiver::IsTradeAllowed() {
   return (true
           && MQLInfoInteger(MQL_TRADE_ALLOWED)
           && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)
           && AccountInfoInteger(ACCOUNT_TRADE_EXPERT)
           && AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)
           && TerminalInfoInteger(TERMINAL_CONNECTED)
          );
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CVirtualReceiver::~CVirtualReceiver() {
   FOREACH(m_orders, delete m_orders[i]); // Remove virtual positions
}

//+------------------------------------------------------------------+
//| Singleton - creating and getting a single instance               |
//+------------------------------------------------------------------+
CVirtualReceiver* CVirtualReceiver::Instance(ulong p_magic = 0) {
   if(!s_instance) {
      s_instance = new CVirtualReceiver(p_magic);
   }
   return s_instance;
}

//+------------------------------------------------------------------+
//| Allocate the necessary amount of virtual positions to strategy   |
//+------------------------------------------------------------------+
static void CVirtualReceiver::Get(CVirtualStrategy *strategy,   // Strategy
                                  CVirtualOrder *&orders[],     // Array of strategy positions
                                  int n                         // Required number
                                 ) {
   CVirtualReceiver *self = Instance();   // Receiver singleton
   ArrayResize(orders, n);                // Expand the array of virtual positions
   FOREACH(orders,
           orders[i] = new CVirtualOrder(self, strategy); // Fill the array with new objects
           APPEND(self.m_orders, orders[i])) // Register the created virtual position
   PrintFormat(__FUNCTION__ + " | OK, Strategy orders: %d from %d total",
               ArraySize(orders),
               ArraySize(self.m_orders));
}

//+------------------------------------------------------------------+
//| Handle opening a virtual position                                |
//+------------------------------------------------------------------+
void CVirtualReceiver::OnOpen(CVirtualOrder *p_order) {
   string symbol = p_order.Symbol();      // Define position symbol
   CVirtualSymbolReceiver *symbolReceiver;
   int i;
   FIND(m_symbolReceivers, symbol, i);    // Search for the symbol recipient

   if(i == -1) {
      // If not found, then create a new recipient for the symbol
      symbolReceiver = new CVirtualSymbolReceiver(m_magic, symbol);
      // and add it to the array of symbol recipients
      APPEND(m_symbolReceivers, symbolReceiver);
   } else {
      // If found, then take it
      symbolReceiver = m_symbolReceivers[i];
   }
   PrintFormat(__FUNCTION__"#%s | OPEN VirtualOrder #%d", p_order.Symbol(),  p_order.Id());
   symbolReceiver.Open(p_order); // Notify the symbol recipient about the new position
   m_isChanged = true;           // Remember that there are changes
}

//+------------------------------------------------------------------+
//| Handle closing a virtual position                                |
//+------------------------------------------------------------------+
void CVirtualReceiver::OnClose(CVirtualOrder *p_order) {
   string symbol = p_order.Symbol();   // Define position symbol
   int i;
   FIND(m_symbolReceivers, symbol, i); // Search for the symbol recipient

   if(i != -1) {
      PrintFormat(__FUNCTION__"#%s | CLOSE VirtualOrder #%d", p_order.Symbol(),  p_order.Id());
      m_symbolReceivers[i].Close(p_order);   // Notify the symbol recipient about closing a position
      m_isChanged = true;                    // Remember that there are changes
   }
}

//+------------------------------------------------------------------+
//| Handle a tick for the array of virtual orders (positions)        |
//+------------------------------------------------------------------+
void CVirtualReceiver::Tick() {
   FOREACH(m_orders, m_orders[i].Tick());
}

//+------------------------------------------------------------------+
//| Adjust open volumes                                              |
//+------------------------------------------------------------------+
bool CVirtualReceiver::Correct() {
   bool res = true;
   if(m_isChanged && IsTradeAllowed()) {
      // If there are changes, then we call the adjustment of the recipients of individual symbols
      FOREACH(m_symbolReceivers, res &= m_symbolReceivers[i].Correct());
      m_isChanged = !res;
   }
   return res;
}
//+------------------------------------------------------------------+
