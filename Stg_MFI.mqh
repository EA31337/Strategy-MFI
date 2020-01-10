//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements MFI strategy based on the Money Flow Index indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_MFI.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __MFI_Parameters__ = "-- MFI strategy params --";  // >>> MFI <<<
INPUT int MFI_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT ENUM_TRAIL_TYPE MFI_TrailingStopMethod = 7;     // Trail stop method
INPUT ENUM_TRAIL_TYPE MFI_TrailingProfitMethod = 22;  // Trail profit method
INPUT int MFI_Period = 2;                             // Period
INPUT double MFI_SignalOpenLevel = 0.9;               // Signal open level
INPUT int MFI_Shift = 0;                              // Shift (relative to the current bar, 0 - default)
INPUT int MFI1_SignalBaseMethod = 0;                  // Signal base method (0-1)
INPUT int MFI1_OpenCondition1 = 874;                  // Open condition 1 (0-1023)
INPUT int MFI1_OpenCondition2 = 0;                    // Open condition 2 (0-)
INPUT ENUM_MARKET_EVENT MFI1_CloseCondition = 14;     // Close condition for M1
INPUT double MFI_MaxSpread = 6.0;                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_MFI_Params : Stg_Params {
  unsigned int MFI_Period;
  ENUM_APPLIED_PRICE MFI_Applied_Price;
  int MFI_Shift;
  ENUM_TRAIL_TYPE MFI_TrailingStopMethod;
  ENUM_TRAIL_TYPE MFI_TrailingProfitMethod;
  double MFI_SignalOpenLevel;
  long MFI_SignalBaseMethod;
  long MFI_SignalOpenMethod1;
  long MFI_SignalOpenMethod2;
  double MFI_SignalCloseLevel;
  ENUM_MARKET_EVENT MFI_SignalCloseMethod1;
  ENUM_MARKET_EVENT MFI_SignalCloseMethod2;
  double MFI_MaxSpread;

  // Constructor: Set default param values.
  Stg_MFI_Params()
      : MFI_Period(::MFI_Period),
        MFI_Applied_Price(::MFI_Applied_Price),
        MFI_Shift(::MFI_Shift),
        MFI_TrailingStopMethod(::MFI_TrailingStopMethod),
        MFI_TrailingProfitMethod(::MFI_TrailingProfitMethod),
        MFI_SignalOpenLevel(::MFI_SignalOpenLevel),
        MFI_SignalBaseMethod(::MFI_SignalBaseMethod),
        MFI_SignalOpenMethod1(::MFI_SignalOpenMethod1),
        MFI_SignalOpenMethod2(::MFI_SignalOpenMethod2),
        MFI_SignalCloseLevel(::MFI_SignalCloseLevel),
        MFI_SignalCloseMethod1(::MFI_SignalCloseMethod1),
        MFI_SignalCloseMethod2(::MFI_SignalCloseMethod2),
        MFI_MaxSpread(::MFI_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_MFI : public Strategy {
 public:
  Stg_MFI(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_MFI *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_MFI_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_MFI_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_MFI_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_MFI_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_MFI_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_MFI_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_MFI_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    MFI_Params adx_params(_params.MFI_Period, _params.MFI_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_MFI);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_MFI(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.MFI_SignalBaseMethod, _params.MFI_SignalOpenMethod1, _params.MFI_SignalOpenMethod2,
                       _params.MFI_SignalCloseMethod1, _params.MFI_SignalCloseMethod2, _params.MFI_SignalOpenLevel,
                       _params.MFI_SignalCloseLevel);
    sparams.SetStops(_params.MFI_TrailingProfitMethod, _params.MFI_TrailingStopMethod);
    sparams.SetMaxSpread(_params.MFI_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_MFI(sparams, "MFI");
    return _strat;
  }

  /**
   * Check if MFI indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double mfi_0 = ((Indi_MFI *)this.Data()).GetValue(0);
    double mfi_1 = ((Indi_MFI *)this.Data()).GetValue(1);
    double mfi_2 = ((Indi_MFI *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      // Buy: Crossing 20 upwards.
      case ORDER_TYPE_BUY:
        _result = mfi_1 > 0 && mfi_1 < (50 - _signal_level1);
        if (METHOD(_signal_method, 0)) _result &= mfi_0 >= (50 - _signal_level1);
        break;
      // Sell: Crossing 80 downwards.
      case ORDER_TYPE_SELL:
        _result = mfi_1 > 0 && mfi_1 > (50 + _signal_level1);
        if (METHOD(_signal_method, 0)) _result &= mfi_0 <= (50 - _signal_level1);
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
