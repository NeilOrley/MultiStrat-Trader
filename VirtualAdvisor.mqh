//+------------------------------------------------------------------+
//|                                               VirtualAdvisor.mqh |
//|                                 Copyright 2019-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.01"

#include "Advisor.mqh"
#include "VirtualReceiver.mqh"

//+------------------------------------------------------------------+
//| Class of the EA handling virtual positions (orders)              |
//+------------------------------------------------------------------+
class CVirtualAdvisor : public CAdvisor {
protected:
   CVirtualReceiver  *m_receiver; // Receiver object that brings positions to the market

public:
                     CVirtualAdvisor(ulong p_magic = 1); // Constructor
                    ~CVirtualAdvisor();                  // Destructor
   virtual void      Tick() override;                    // OnTick event handler

};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVirtualAdvisor::CVirtualAdvisor(ulong p_magic = 1) :
// Initialize the receiver with a static receiver
   m_receiver(CVirtualReceiver::Instance(p_magic)) {};

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CVirtualAdvisor::~CVirtualAdvisor() {
   delete m_receiver;         // Delete the recipient
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
}
//+------------------------------------------------------------------+
