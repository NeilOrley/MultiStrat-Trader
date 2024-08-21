//+------------------------------------------------------------------+
//|                                               VolumeReceiver.mqh |
//|                                 Copyright 2022-2024, Yuriy Bykov |
//|                            https://www.mql5.com/en/users/antekov |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022-2024, Yuriy Bykov"
#property link      "https://www.mql5.com/en/users/antekov"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>

#include "Receiver.mqh"

//+------------------------------------------------------------------+
//| Class for converting open volumes into market positions          |
//+------------------------------------------------------------------+
class CVolumeReceiver : public CReceiver {
protected:
   bool              m_isNetting;      // Is this a netting account?
   string            m_symbols[];      // Array of used symbols

   double            m_minMargin;      // Minimum margin for opening

   CPositionInfo     m_position;
   CSymbolInfo       m_symbolInfo;
   CTrade            m_trade;

   // Filling the array of open market volumes by symbols
   void              FillSymbolVolumes(double &oldVolumes[]);

   // Correction of open volumes using the array of volumes
   virtual bool      Correct(double &symbolVolumes[]);

   // Volume correction for this symbol
   bool              CorrectPosition(string symbol, double oldVolume, double diffVolume);

   // Auxiliary methods
   bool              ClearOpen(string symbol, double diffVolume);
   bool              AddBuy(string symbol, double volume);
   bool              AddSell(string symbol, double volume);

   bool              CloseBuyPartial(string symbol, double volume);
   bool              CloseSellPartial(string symbol, double volume);
   bool              CloseHedgingPartial(string symbol, double volume, ENUM_POSITION_TYPE type);
   bool              CloseFull(string symbol = "");

   bool              FreeMarginCheck(string symbol, double volume, ENUM_ORDER_TYPE type);

public:
   CVolumeReceiver(ulong p_magic, double p_minMargin = 100);   // Constructor
   virtual void      Add(CStrategy *strategy) override;        // Add strategy
   virtual bool      Correct() override;                       // Adjustment of open volumes
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVolumeReceiver::CVolumeReceiver(ulong p_magic, double p_minMargin = 100) : CReceiver(p_magic) {
   m_minMargin = p_minMargin;
   m_isNetting = false;

#ifdef __MQL5__
   m_isNetting = AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
#endif

   m_trade.SetExpertMagicNumber(m_magic);
}

//+------------------------------------------------------------------+
//| Add strategy                                                     |
//+------------------------------------------------------------------+
void CVolumeReceiver::Add(CStrategy *strategy) {
   CReceiver::Add(strategy);
   ADD(m_symbols, strategy.Symbol());
}

//+------------------------------------------------------------------+
//| Adjustment of open volumes                                       |
//+------------------------------------------------------------------+
bool CVolumeReceiver::Correct() {
   int symbolsTotal = ArraySize(m_symbols);
   double newVolumes[];

   ArrayResize(newVolumes, symbolsTotal);
   ArrayInitialize(newVolumes, 0);

   for(int j = 0; j < symbolsTotal; j++) {  // For each used symbol
      for(int i = 0; i < ArraySize(m_strategies); i++) { // Iterate through all strategies
         if(m_strategies[i].Symbol() == m_symbols[j]) {  // If the strategy uses this symbol
            newVolumes[j] += m_strategies[i].Volume();   // Add its open volume
         }
      }
   }
   // Call correction of open volumes using the array of volumes
   return Correct(newVolumes);
}

//+------------------------------------------------------------------+
//| Adjusting open volumes using the array of volumes                |
//+------------------------------------------------------------------+
bool CVolumeReceiver::Correct(double &newVolumes[]) {
   double oldVolumes[];
   // Fill in the array of open market volumes
   FillSymbolVolumes(oldVolumes);

   bool res = true;

   // For each symbol
   for(int j = 0; j < ArraySize(m_symbols); j++) {
      // Check that the symbol exists and trading on it is allowed
      if(!m_symbolInfo.Name(m_symbols[j])) {
         continue;
      }

      if(m_symbolInfo.TradeMode() != SYMBOL_TRADE_MODE_FULL) {
         continue;
      }

      // Get the limit values of permissible volumes
      double minLot = MathMax(0.01, m_symbolInfo.LotsMin());
      double maxLot = m_symbolInfo.LotsMax();
      double lotStep = MathMax(0.01, m_symbolInfo.LotsStep());

      // Define how much the volume of open positions for the symbol should be changed
      double oldVolume = oldVolumes[j];
      double newVolume = newVolumes[j];
      int ratio = 0;

      // Check that the new volume is within acceptable limits
      if(MathAbs(newVolume) > maxLot) {
         newVolume = maxLot * MathAbs(newVolume) / newVolume;
      }

      if(MathAbs(newVolume) < minLot && MathAbs(newVolume) > 0) {
         if(MathAbs(newVolume) < 0.5 * minLot) {
            newVolume = 0;
         } else {
            newVolume = minLot * MathAbs(newVolume) / newVolume;
         }
      }
      // How much should we change the open volume?
      double diffVolume = newVolume - oldVolume;
      int digits = 2;

      if (lotStep >= 0.1 && lotStep < 1.0) {
         digits = 1;
      } else if (lotStep >= 1.0) {
         digits = 0;
      }

      if(oldVolume == 0) {
         if (minLot >= 0.1 && lotStep < 1.0) {
            digits = 1;
         } else if (minLot >= 1.0) {
            digits = 0;
         }
      }

      diffVolume = NormalizeDouble(diffVolume, digits);

      ratio = (int) MathRound(MathAbs(diffVolume) / lotStep);
      if(MathAbs(ratio * lotStep - MathAbs(diffVolume)) > 0.0000001) {
         diffVolume = ratio * lotStep * MathAbs(diffVolume) / diffVolume;
      }

      // If there is a need to adjust the volume for a given symbol, then do that
      if(MathAbs(diffVolume) > 0.001) {
         res = res && CorrectPosition(m_symbols[j], oldVolume, diffVolume);
         if(res) {
            PrintFormat(__FUNCTION__ + " | CORRECTED %s: %.2f -> %.2f", m_symbols[j], oldVolume, newVolume);
         }
      }
   }

   return res;
}


//+------------------------------------------------------------------+
//| Filling the array of open market volumes by symbols              |
//+------------------------------------------------------------------+
void CVolumeReceiver::FillSymbolVolumes(double &oldVolumes[]) {
   ArrayResize(oldVolumes, ArraySize(m_symbols));
   ArrayInitialize(oldVolumes, 0);

   int index;
   double volume;
   string symbol;
   ulong magic;
   int type;

   CPositionInfo p;

   for(int i = 0; i < PositionsTotal(); i++) {
      if(p.SelectByIndex(i)) {
         symbol = p.Symbol();
         magic = p.Magic();
         type = (int) p.PositionType();

         if(magic == m_magic /* && type < 2 */) {
            FIND(m_symbols, symbol, index);
            if (index != -1) {
               volume = p.Volume() * (-(type) * 2 + 1);
               oldVolumes[index] += volume;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Adjust volume by the symbol                                      |
//+------------------------------------------------------------------+
bool CVolumeReceiver::CorrectPosition(string symbol, double oldVolume, double diffVolume) {
   bool res = false;

   // Check that trading is available
   if(false
         || !MQLInfoInteger(MQL_TRADE_ALLOWED)
         || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)
         || !AccountInfoInteger(ACCOUNT_TRADE_EXPERT)
         || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)
         || !TerminalInfoInteger(TERMINAL_CONNECTED)) {
      return res;
   }

   int index;
   FIND(m_symbols, symbol, index);

   if(index == -1) {
      return res;
   }

   double volume = MathAbs(diffVolume);

   if(oldVolume > 0) { // Have BUY position
      if(diffVolume > 0) { // New BUY position
         res = AddBuy(symbol, volume);
      } else if(diffVolume < 0) { // New SELL position
         if(volume < oldVolume) {
            res = CloseBuyPartial(symbol, volume);
         } else {
            res = CloseFull(symbol);

            if(res && volume > oldVolume) {
               res = AddSell(symbol, volume - oldVolume);
            }
         }
      }
   } else if(oldVolume < 0) { // Have SELL position
      if(diffVolume < 0) { // New SELL position
         res = AddSell(symbol, volume);
      } else if(diffVolume > 0) { // New BUY position
         if(volume < -oldVolume) {
            res = CloseSellPartial(symbol, volume);
         } else {
            res = CloseFull(symbol);

            if(res && volume > -oldVolume) {
               res = AddBuy(symbol, volume + oldVolume);
            }
         }
      }
   } else { // No old position
      res = ClearOpen(symbol, diffVolume);
   }

   return res;
}

//+------------------------------------------------------------------+
//| Open BUY or SELL market position                                 |
//+------------------------------------------------------------------+
bool CVolumeReceiver::ClearOpen(string symbol, double diffVolume) {
   double volume = MathAbs(diffVolume);

   if(!m_symbolInfo.Name(symbol)) {
      return true;
   }

   double minLot = MathAbs(m_symbolInfo.LotsMin());

   if(minLot < 1e-12 || volume < minLot) {
      return true;
   }

   bool res = true;

   if(PositionsTotal() >= AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)) {
      Print("Error Clear open: PositionsTotal() >= AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)");
      return true;
   }

   ENUM_ORDER_TYPE type = (diffVolume > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);

   if(FreeMarginCheck(symbol, volume, type)) {
#ifdef DEBUG
      Print("Clear open: ", symbol, " ", (diffVolume > 0 ? "BUY" : "SELL"), " ", DoubleToString(volume, 2));
#endif

      if(diffVolume > 0) {
         res &= m_trade.Buy(volume, symbol);
      } else {
         res &= m_trade.Sell(volume, symbol);
      }

      if(!res) {
         Print("Error Clear open: ", _LastError);
      }
   }

   return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVolumeReceiver::AddBuy(string symbol, double volume) {
   return ClearOpen(symbol, volume);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVolumeReceiver::AddSell(string symbol, double volume) {
   return ClearOpen(symbol, -volume);
}

//+------------------------------------------------------------------+
//| Partial closure of BUY volume by symbol                          |
//+------------------------------------------------------------------+
bool CVolumeReceiver::CloseBuyPartial(string symbol, double volume) {
   bool res = true;

#ifdef DEBUG
   Print("Close BUY ", symbol, " partial | volume=", DoubleToString(volume, 2));
#endif
   int index;
   FIND(m_symbols, symbol, index);

   if(index == -1) {
      return false;
   }

   if(volume > 0) {
      if(m_isNetting) {
         res &= m_trade.Sell(volume, symbol, 0, 0, 0);
      } else {
         res &= CloseHedgingPartial(symbol, volume, POSITION_TYPE_BUY);
      }
   }

   if(!res) {
      Print("Error Close partial BUY. Error code: ", _LastError, " Result code: ", m_trade.ResultRetcode());
      ResetLastError();
   }

   return res;
}

//+------------------------------------------------------------------+
//| Partial closure of SELL volume by symbol                         |
//+------------------------------------------------------------------+
bool CVolumeReceiver::CloseSellPartial(string symbol, double volume) {
   bool res = true;

#ifdef DEBUG
   Print("Close SELL ", symbol, " partial | volume=", DoubleToString(volume, 2));
#endif

   int index;
   FIND(m_symbols, symbol, index);

   if(index == -1) {
      return false;
   }

   if(volume > 0) {
      if(m_isNetting) {
         res &= m_trade.Buy(volume, symbol, 0, 0, 0);
      } else {
         res &= CloseHedgingPartial(symbol, volume, POSITION_TYPE_SELL);
      }
   }
   if(!res) {
      Print("Error Close partial SELL. Error code: ", _LastError, " Result code: ", m_trade.ResultRetcode());
      ResetLastError();
   }

   return res;
}

//+------------------------------------------------------------------+
//| Partial closure of BUY or SELL by symbol on the Hedge account    |
//+------------------------------------------------------------------+
bool CVolumeReceiver::CloseHedgingPartial(string symbol, double volume, ENUM_POSITION_TYPE type) {
   bool res = true;

   ulong ticket;
   double positionVolume;

   for(int i = 0; i < PositionsTotal(); i++) {
      if (m_position.SelectByIndex(i)) {
         ticket = m_position.Ticket();

         if(m_position.Magic() == m_magic && m_position.Symbol() == symbol && m_position.PositionType() == type) {
            positionVolume = m_position.Volume();

            if(volume > 0) {
               if(positionVolume <= volume) {
                  res &= m_trade.PositionClose(ticket);
                  volume -= positionVolume;
               } else {
                  res &= m_trade.PositionClosePartial(ticket, volume);
                  volume = 0;
                  break;
               }
            } else {
               break;
            }
         }
      }
   }

   if(volume > 0) {
      res = false;
   }
   return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVolumeReceiver::CloseFull(string symbol = "") {
   bool res = true;

   ulong ticket;
   bool found = true;

   while(found && !IsStopped()) {
      found = false;
      for(int i = 0; i < PositionsTotal(); i++) {
         if (m_position.SelectByIndex(i)) {
            if(m_position.Magic() == m_magic && (symbol == "" || m_position.Symbol() == symbol)) {
               found = true;
               ticket = m_position.Ticket();
               res &= m_trade.PositionClose(ticket);
               break;
            }
         }
      }
      if(!res) {
         found = false;
      }
   }

   return res;
}

//+------------------------------------------------------------------+
//| Check margin requirements                                        |
//+------------------------------------------------------------------+
bool CVolumeReceiver::FreeMarginCheck(string symbol, double volume, ENUM_ORDER_TYPE type) {
   double freeMarginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

   if (freeMarginLevel != 0 && freeMarginLevel < m_minMargin) {
      PrintFormat(__FUNCTION__" | Margin level (%.2f) is less than minimum required (%.2f)", freeMarginLevel, m_minMargin);
      return false;
   }

#ifdef __MQL4__
   double free_margin = AccountFreeMarginCheck(symbol, type, volume);
//-- if there is not enough money
   if(free_margin < 0) {
      string oper = (type == OP_BUY) ? "BUY" : "SELL";
      Print("Not enough money for ", oper, " ", volume, " ", symbol);
      return(false);
   }
//--- checking successful
   return(true);
#endif

#ifdef __MQL5__
//--- get the open price
   MqlTick mqltick;
   SymbolInfoTick(symbol, mqltick);
   double price = mqltick.ask;
   if(type == ORDER_TYPE_SELL) {
      price = mqltick.bid;
   }
//--- values of the required and free margin
   double margin, free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//--- call the verification function
   if(!OrderCalcMargin(type, symbol, volume, price, margin)) {
      //--- something is wrong, report and return 'false'
      Print("Error in ", __FUNCTION__, " code=", GetLastError());
      return(false);
   }
//--- if there are insufficient funds to perform the operation
   if(margin > free_margin) {
      //--- report the error and return 'false'
      string oper = (type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
      Print("Not enough money for ", oper, " ", volume, " ", symbol);
      return(false);
   }
//--- verification successful
   return(true);
#endif
}
//+------------------------------------------------------------------+
