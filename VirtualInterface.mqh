//+------------------------------------------------------------------+
//|                                             VirtualInterface.mqh |
//|                                 Copyright 2022-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

class CVirtualChartOrder;

#include "Interface.mqh"
#include "VirtualChartOrder.mqh"

//+------------------------------------------------------------------+
//| EA GUI class                                                     |
//+------------------------------------------------------------------+
class CVirtualInterface : public CInterface {
protected:
// Static pointer to a single class instance
   static   CVirtualInterface *s_instance;

   CVirtualChartOrder *m_chartOrders[];   // Array of graphical virtual positions

//--- Private methods
   CVirtualInterface();   // Closed constructor

public:
   ~CVirtualInterface();  // Destructor

//--- Static methods
   static
   CVirtualInterface  *Instance(ulong p_magic = 0);   // Singleton - creating and getting a single instance

//--- Public methods
   void              Changed(CVirtualOrder *p_order); // Handle virtual position changes
   void              Add(CVirtualOrder *p_order);     // Add a virtual position

   virtual void      Redraw() override;   // Draw changed objects on the chart
};

// Initializing a static pointer to a single class instance
CVirtualInterface *CVirtualInterface::s_instance = NULL;

//+------------------------------------------------------------------+
//| Closed constructor                                               |
//+------------------------------------------------------------------+
CVirtualInterface::CVirtualInterface() {}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CVirtualInterface::~CVirtualInterface() {
   // Delete all created objects of graphical virtual positions
   FOREACH(m_chartOrders, delete m_chartOrders[i]);
}

//+------------------------------------------------------------------+
//| Singleton - creating and getting a single instance               |
//+------------------------------------------------------------------+
CVirtualInterface* CVirtualInterface::Instance(ulong p_magic = 0) {
   if(!s_instance) {
      s_instance = new CVirtualInterface();
   }
   if(s_magic == 0 && p_magic != 0) {
      s_magic = p_magic;
   }
   return s_instance;
}

//+------------------------------------------------------------------+
//| Add a virtual position                                           |
//+------------------------------------------------------------------+
void CVirtualInterface::Add(CVirtualOrder *p_order) {
   // Add a new graphical virtual position 
   // created from a virtual position
   APPEND(m_chartOrders, new CVirtualChartOrder(p_order));
}

//+------------------------------------------------------------------+
//| Handle virtual position changes                                  |
//+------------------------------------------------------------------+
void CVirtualInterface::Changed(CVirtualOrder *p_order) {
   // Remember that this position has changes
   int i;
   FIND(m_chartOrders, p_order.Id(), i);
   if(i != -1) {
      m_chartOrders[i].Changed();
      m_isChanged = true;
   }
}

//+------------------------------------------------------------------+
//| Draw changed objects on a chart                                  |
//+------------------------------------------------------------------+
void CVirtualInterface::Redraw() {
   if(m_isActive && m_isChanged) {  // If the interface is active and there are changes
      // Start redrawing graphical virtual positions
      FOREACH(m_chartOrders, m_chartOrders[i].Redraw());
      m_isChanged = false;          // Reset the changes flag
   }
}
//+------------------------------------------------------------------+
