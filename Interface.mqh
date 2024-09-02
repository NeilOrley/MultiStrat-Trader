//+------------------------------------------------------------------+
//|                                                    Interface.mqh |
//|                                      Copyright 2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Basic class for visualizing various objects                      |
//+------------------------------------------------------------------+
class CInterface {
protected:
   static ulong      s_magic;       // EA magic number
   bool              m_isActive;    // Is the interface active?
   bool              m_isChanged;   // Does the object have any changes?
public:
   CInterface();                    // Constructor
   virtual void      Redraw() = 0;  // Draw changed objects on the chart
   virtual void      Changed() {    // Set the flag for changes
      m_isChanged = true;
   }
};

ulong CInterface::s_magic = 0;

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CInterface::CInterface() :
   m_isActive(!MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE)),
   m_isChanged(true) {}
//+------------------------------------------------------------------+
