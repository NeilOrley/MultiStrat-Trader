//+------------------------------------------------------------------+
//|                                               VirtualAdvisor.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.02"

#include "Advisor.mqh"
#include "VirtualInterface.mqh"
#include "VirtualReceiver.mqh"

//+------------------------------------------------------------------+
//| Class of the EA handling virtual positions (orders)              |
//+------------------------------------------------------------------+
class CVirtualAdvisor : public CAdvisor {
protected:
   CVirtualReceiver  *m_receiver;      // Receiver object that brings positions to the market
   CVirtualInterface *m_interface;     // Interface object to show the status to the user
   
   string            m_name;           // EA name
   datetime          m_lastSaveTime;   // Last save time

public:
   CVirtualAdvisor(ulong p_magic = 1, string p_name = ""); // Constructor
   ~CVirtualAdvisor();                 // Destructor
   virtual void      Tick() override;  // OnTick event handler

   virtual bool      Save();           // Save status
   virtual bool      Load();           // Load status
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVirtualAdvisor::CVirtualAdvisor(ulong p_magic = 1, string p_name = "") :
// Initialize the receiver with a static receiver
   m_receiver(CVirtualReceiver::Instance(p_magic)),
// Initialize the interface with the static interface
   m_interface(CVirtualInterface::Instance(p_magic)),
   m_lastSaveTime(0) {
   m_name = StringFormat("%s-%d%s.csv",
                         (p_name != "" ? p_name : "Expert"),
                         p_magic,
                         (MQLInfoInteger(MQL_TESTER) ? ".test" : "")
                        );
};

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CVirtualAdvisor::~CVirtualAdvisor() {
   delete m_receiver;         // Delete the recipient
   delete m_interface;        // Remove the interface
}

//+------------------------------------------------------------------+
//| OnTick event handler                                             |
//+------------------------------------------------------------------+
void CVirtualAdvisor::Tick(void) {
// Receiver handles virtual positions
   m_receiver.Tick();

// Start handling in strategies
   CAdvisor::Tick();

// Adjusting market volumes
   m_receiver.Correct();

// Save status
   Save();
   
// Render the interface
   m_interface.Redraw();
}


//+------------------------------------------------------------------+
//| Save status                                                      |
//+------------------------------------------------------------------+
bool CVirtualAdvisor::Save() {
   bool res = true;

   // Save status if:
   if(true
         // later changes appeared
         && m_lastSaveTime < CVirtualReceiver::s_lastChangeTime
         // currently, there is no optimization
         && !MQLInfoInteger(MQL_OPTIMIZATION)
         // and there is no testing at the moment or there is a visual test at the moment
         && (!MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE))
     ) {
      int f = FileOpen(m_name, FILE_CSV | FILE_WRITE, '\t');

      if(f != INVALID_HANDLE) {  // If file is open, save
         FileWrite(f, CVirtualReceiver::s_lastChangeTime);  // Time of last changes
         FileWrite(f, ArraySize(m_strategies));             // Number of strategies

         // All strategies
         FOREACH(m_strategies, ((CVirtualStrategy*) m_strategies[i]).Save(f));

         FileClose(f);

         // Update the last save time
         m_lastSaveTime = CVirtualReceiver::s_lastChangeTime;
         PrintFormat(__FUNCTION__" | OK at %s to %s",
                     TimeToString(m_lastSaveTime, TIME_DATE | TIME_MINUTES | TIME_SECONDS), m_name);
      } else {
         PrintFormat(__FUNCTION__" | ERROR: Operation FileOpen for %s failed, LastError=%d",
                     m_name, GetLastError());
         res = false;
      }
   }
   return res;
}

//+------------------------------------------------------------------+
//| Load status                                                      |
//+------------------------------------------------------------------+
bool CVirtualAdvisor::Load() {
   bool res = true;

   // Load status if:
   if(true
         // file exists
         && FileIsExist(m_name)
         // currently, there is no optimization
         && !MQLInfoInteger(MQL_OPTIMIZATION)
         // and there is no testing at the moment or there is a visual test at the moment
         && (!MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE))
     ) {
      int f = FileOpen(m_name, FILE_CSV | FILE_READ, '\t');

      if(f != INVALID_HANDLE) {  // If the file is open, then load
         m_lastSaveTime = FileReadDatetime(f);     // Last save time
         PrintFormat(__FUNCTION__" | LAST SAVE at %s", TimeToString(m_lastSaveTime, TIME_DATE | TIME_MINUTES | TIME_SECONDS));

         // Number of strategies
         long f_strategiesCount = StringToInteger(FileReadString(f));

         // Does the loaded number of strategies match the current one?
         res = (ArraySize(m_strategies) == f_strategiesCount);

         if(res) {
            // Load all strategies
            FOREACH(m_strategies, res &= ((CVirtualStrategy*) m_strategies[i]).Load(f));

            if(!res) {
               PrintFormat(__FUNCTION__" | ERROR loading strategies from file %s", m_name);
            }
         } else {
            PrintFormat(__FUNCTION__" | ERROR: Wrong strategies count (%d expected but %d found in file %s)",
                        ArraySize(m_strategies), f_strategiesCount, m_name);
         }
         FileClose(f);
      } else {
         PrintFormat(__FUNCTION__" | ERROR: Operation FileOpen for %s failed, LastError=%d", m_name, GetLastError());
         res = false;
      }
   }
   
   return res;
}
//+------------------------------------------------------------------+
