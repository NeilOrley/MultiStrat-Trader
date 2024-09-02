//+------------------------------------------------------------------+
//|                                                        Money.mqh |
//|                                 Copyright 2022-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

#include "VirtualOrder.mqh"
//+------------------------------------------------------------------+
//| Basic money management class                                     |
//+------------------------------------------------------------------+
class CMoney {
   static double     s_depoPart;       // Used part of the total balance
   static double     s_fixedBalance;   // Total balance used
public:
   CMoney() = delete;                  // Disable the constructor
   static double     Volume(CVirtualOrder *p_order); // Determine the real size of the virtual position

   static void       DepoPart(double p_depoPart) {
      s_depoPart = p_depoPart;
   }
   static void       FixedBalance(double p_fixedBalance) {
      s_fixedBalance = p_fixedBalance;
   }
};

double CMoney::s_depoPart = 1.0;
double CMoney::s_fixedBalance = 0;

//+------------------------------------------------------------------+
//| Determine the real size of the virtual position                  |
//+------------------------------------------------------------------+
double CMoney::Volume(CVirtualOrder *p_order) {
   // Request the normalized strategy balance for the virtual position 
   double fittedBalance = p_order.FittedBalance();
   
   // If it is 0, then the real volume is equal to the virtual one
   if(fittedBalance == 0.0) {
      return p_order.Volume();
   }
   
   // Otherwise, find the value of the total balance for trading
   double totalBalance = s_fixedBalance > 0 ? s_fixedBalance : AccountInfoDouble(ACCOUNT_BALANCE);
   
   // Return the calculated real volume based on the virtual one
   return p_order.Volume() * totalBalance * s_depoPart / fittedBalance ;
}
//+------------------------------------------------------------------+
