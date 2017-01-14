//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of MFI strategy based on the Money Flow Index indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iMFI
 * - https://www.mql5.com/en/docs/indicators/iMFI
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __MFI_Parameters__ = "-- Settings for the Money Flow Index indicator --"; // >>> MFI <<<
#ifdef __input__ input #endif int MFI_Period = 14; // Period
#ifdef __input__ input #endif double MFI_SignalLevel = 0.00000000; // Signal level
#ifdef __input__ input #endif int MFI_SignalMethod = 0; // Signal method for M1 (0-

class MFI: public Strategy {
protected:

  double mfi[H1][FINAL_ENUM_INDICATOR_INDEX];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

    public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Money Flow Index indicator.
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      mfi[index][i] = iMFI(symbol, tf, MFI_Period, i);
    }
    success = (bool)mfi[index][CURR];
  }

  /**
   * Check if MFI indicator is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_MFI, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_MFI, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_MFI, tf, 0.0);
    switch (cmd) {
      /*
        //18. Money Flow Index - MFI
        //Buy: Crossing 20 upwards
        //Sell: Crossing 20 downwards
        if(iMFI(NULL,pimfi,barsimfi,1)<20&&iMFI(NULL,pimfi,barsimfi,0)>=20)
        {f18=1;}
        if(iMFI(NULL,pimfi,barsimfi,1)>80&&iMFI(NULL,pimfi,barsimfi,0)<=80)
        {f18=-1;}]
      */
      case OP_BUY:
        break;
      case OP_SELL:
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    return result;
  }
};
