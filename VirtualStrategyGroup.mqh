//+------------------------------------------------------------------+
//|                                         VirtualStrategyGroup.mqh |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

#include "VirtualStrategy.mqh"

//+------------------------------------------------------------------+
//| Class of trading strategies group(s)                             |
//+------------------------------------------------------------------+
class CVirtualStrategyGroup {
protected:
   void              Scale(double p_scale); // Scale normalized balance
public:
   CVirtualStrategyGroup(CVirtualStrategy *&p_strategies[],
                         double p_scale = 1);   // Constructor for a group of strategies
   CVirtualStrategyGroup(CVirtualStrategyGroup *&p_groups[],
                         double p_scale = 1);   // Constructor for a group of strategy groups

   CVirtualStrategy      *m_strategies[];       // Array of strategies
   CVirtualStrategyGroup *m_groups[];           // Array of strategy groups
};

//+------------------------------------------------------------------+
//| Constructor for strategy groups                                  |
//+------------------------------------------------------------------+
CVirtualStrategyGroup::CVirtualStrategyGroup(
   CVirtualStrategy *&p_strategies[],
   double p_scale
) {
   ArrayCopy(m_strategies, p_strategies);
   PrintFormat(__FUNCTION__" | Scale = %.2f, total strategies = %d", p_scale, ArraySize(m_strategies));
   Scale(p_scale / ArraySize(m_strategies));
}

//+------------------------------------------------------------------+
//| Constructor for a group of strategy groups                       |
//+------------------------------------------------------------------+
CVirtualStrategyGroup::CVirtualStrategyGroup(
   CVirtualStrategyGroup *&p_groups[],
   double p_scale
) {
   ArrayCopy(m_groups, p_groups);
   PrintFormat(__FUNCTION__" | Scale = %.2f, total groups = %d", p_scale, ArraySize(m_groups));
   Scale(p_scale / ArraySize(m_groups));
}

//+------------------------------------------------------------------+
//| Scale normalized balance                                         |
//+------------------------------------------------------------------+
void CVirtualStrategyGroup::Scale(double p_scale) {
   int totalGroups = ArraySize(m_groups);
   int totalStrategies = ArraySize(m_strategies);
   int total = totalGroups + totalStrategies;
   PrintFormat(__FUNCTION__" | Scale = %.2f, total groups = %d, total strategies = %d, total = %d", p_scale, totalGroups, totalStrategies, total);
   FOREACH(m_groups,     m_groups[i].Scale(p_scale));
   FOREACH(m_strategies, m_strategies[i].Scale(p_scale));
}
//+------------------------------------------------------------------+
