//+------------------------------------------------------------------+
//|                                            VirtualChartOrder.mqh |
//|                                 Copyright 2022-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

#include <Charts\Chart.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

#include "VirtualOrder.mqh"

//+------------------------------------------------------------------+
//| Graphic virtual position class                                   |
//+------------------------------------------------------------------+
class CVirtualChartOrder : public CInterface {
   CVirtualOrder*    m_order;          // Associated virtual position (order)
   CChart            m_chart;          // Chart object to be displayed

   // Objects on the chart to display the virtual position
   CChartObjectHLine m_openLine;       // Open price line

   long              FindChart();      // Search/open the desired chart
public:
   CVirtualChartOrder(CVirtualOrder* p_order);     // Constructor
   ~CVirtualChartOrder();                          // Destructor

   bool              operator==(const ulong id) {  // ID comparison operator
      return m_order.Id() == id;
   }

   void              Show();    // Show a virtual position (order)
   void              Hide();    // Hide a virtual position (order)

   virtual void      Redraw() override;   // Redraw a virtual position (order)
};


//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVirtualChartOrder::CVirtualChartOrder(CVirtualOrder* p_order) :
   m_order(p_order) {}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CVirtualChartOrder::~CVirtualChartOrder() {
   Hide();
}

//+------------------------------------------------------------------+
//| Finding a chart to display                                       |
//+------------------------------------------------------------------+
long CVirtualChartOrder::FindChart() {
   if(m_chart.ChartId() == -1 || m_chart.Symbol() != m_order.Symbol()) {
      long currChart, prevChart = ChartFirst();
      int i = 0, limit = 1000;

      currChart = prevChart;

      while(i < limit) { // we probably have no more than 1000 open charts
         if(ChartSymbol(currChart) == m_order.Symbol()) {
            return currChart;
         }
         currChart = ChartNext(prevChart); // get new chart on the basis of the previous one
         if(currChart < 0)
            break;        // end of chart list is reached
         prevChart = currChart; // memorize identifier of the current chart for ChartNext()
         i++;
      }

      // If a suitable chart is not found, then open a new one
      if(currChart == -1) {
         m_chart.Open(m_order.Symbol(), PERIOD_CURRENT);
      }
   }
   return m_chart.ChartId();
}

//+------------------------------------------------------------------+
//| Show a virtual position (order)                                  |
//+------------------------------------------------------------------+
void CVirtualChartOrder::Show() {
   string name = StringFormat("%d #%d: %s %s %.2f",
                              s_magic,
                              m_order.Id(),
                              m_order.TypeName(),
                              m_order.Symbol(), m_order.Volume());

   long chartId = FindChart();
   if(!m_openLine.Create(chartId, name, 0, m_order.OpenPrice())) {
      PrintFormat(__FUNCTION__" | ERROR Creating line");
      return;
   }

   if(m_order.IsPendingOrder()) {
      if(m_order.IsStopOrder()) {
         m_openLine.Style(STYLE_DASH);
      }
      if(m_order.IsLimitOrder()) {
         m_openLine.Style(STYLE_DOT);
      }
      if(m_order.IsBuyOrder()) {
         m_openLine.Color(clrLightSkyBlue);
      }
      if(m_order.IsSellOrder()) {
         m_openLine.Color(clrLightSalmon);
      }
   } else {
      m_openLine.Style(STYLE_SOLID);

      if(m_order.IsBuyOrder()) {
         m_openLine.Color(clrBlue);
      }
      if(m_order.IsSellOrder()) {
         m_openLine.Color(clrRed);
      }
   }
}

//+------------------------------------------------------------------+
//| Hide a virtual position (order)                                  |
//+------------------------------------------------------------------+
void CVirtualChartOrder::Hide() {
   m_openLine.Delete();
}

//+------------------------------------------------------------------+
//| Redraw a virtual position (order)                                |
//+------------------------------------------------------------------+
void CVirtualChartOrder::Redraw() {
   if(m_isChanged) {
      if(m_order.IsOpen()) {
         Show();
      } else {
         Hide();
      }
      m_isChanged = false;
   }
}
//+------------------------------------------------------------------+
