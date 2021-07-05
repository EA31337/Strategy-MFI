/**
 * @file
 * Implements MFI strategy based on the Money Flow Index indicator.
 */

// User input params.
INPUT string __MFI_Parameters__ = "-- MFI strategy params --";  // >>> MFI <<<
INPUT float MFI_LotSize = 0;                                    // Lot size
INPUT int MFI_SignalOpenMethod = 2;                             // Signal open method (-127-127)
INPUT float MFI_SignalOpenLevel = 20;                           // Signal open level (-49-49)
INPUT int MFI_SignalOpenFilterMethod = 32;                      // Signal open filter method
INPUT int MFI_SignalOpenBoostMethod = 0;                        // Signal open boost method
INPUT int MFI_SignalCloseMethod = 2;                            // Signal close method (-127-127)
INPUT float MFI_SignalCloseLevel = 20;                          // Signal close level (-49-49)
INPUT int MFI_PriceStopMethod = 1;                              // Price stop method
INPUT float MFI_PriceStopLevel = 0;                             // Price stop level
INPUT int MFI_TickFilterMethod = 1;                             // Tick filter method
INPUT float MFI_MaxSpread = 4.0;                                // Max spread to trade (pips)
INPUT short MFI_Shift = 0;                                      // Shift (relative to the current bar, 0 - default)
INPUT int MFI_OrderCloseTime = -20;                             // Order close time in mins (>0) or bars (<0)
INPUT string __MFI_Indi_MFI_Parameters__ =
    "-- MFI strategy: MFI indicator params --";                                  // >>> MFI strategy: MFI indicator <<<
INPUT int MFI_Indi_MFI_MA_Period = 12;                                           // MA Period
INPUT ENUM_APPLIED_VOLUME MFI_Indi_MFI_Applied_Volume = (ENUM_APPLIED_VOLUME)0;  // Applied volume.
INPUT int MFI_Indi_MFI_Shift = 0;                                                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_MFI_Params_Defaults : MFIParams {
  Indi_MFI_Params_Defaults()
      : MFIParams(::MFI_Indi_MFI_MA_Period, ::MFI_Indi_MFI_Applied_Volume, ::MFI_Indi_MFI_Shift) {}
} indi_mfi_defaults;

// Defines struct with default user strategy values.
struct Stg_MFI_Params_Defaults : StgParams {
  Stg_MFI_Params_Defaults()
      : StgParams(::MFI_SignalOpenMethod, ::MFI_SignalOpenFilterMethod, ::MFI_SignalOpenLevel,
                  ::MFI_SignalOpenBoostMethod, ::MFI_SignalCloseMethod, ::MFI_SignalCloseLevel, ::MFI_PriceStopMethod,
                  ::MFI_PriceStopLevel, ::MFI_TickFilterMethod, ::MFI_MaxSpread, ::MFI_Shift, ::MFI_OrderCloseTime) {}
} stg_mfi_defaults;

// Struct to define strategy parameters to override.
struct Stg_MFI_Params : StgParams {
  MFIParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_MFI_Params(MFIParams &_iparams, StgParams &_sparams)
      : iparams(indi_mfi_defaults, _iparams.tf.GetTf()), sparams(stg_mfi_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_MFI : public Strategy {
 public:
  Stg_MFI(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_MFI *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    MFIParams _indi_params(indi_mfi_defaults, _tf);
    StgParams _stg_params(stg_mfi_defaults);
#ifdef __config__
    SetParamsByTf<MFIParams>(_indi_params, _tf, indi_mfi_m1, indi_mfi_m5, indi_mfi_m15, indi_mfi_m30, indi_mfi_h1,
                             indi_mfi_h4, indi_mfi_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_mfi_m1, stg_mfi_m5, stg_mfi_m15, stg_mfi_m30, stg_mfi_h1, stg_mfi_h4,
                             stg_mfi_h8);
#endif
    // Initialize indicator.
    MFIParams mfi_params(_indi_params);
    _stg_params.SetIndicator(new Indi_MFI(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_MFI(_stg_params, _tparams, _cparams, "MFI");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_MFI *_indi = GetIndicator();
    bool _is_valid = _indi[_shift].IsValid() && _indi[_shift + 1].IsValid() && _indi[_shift + 2].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      IndicatorSignal _signals = _indi.GetSignals(4, _shift);
      switch (_cmd) {
        // Buy: Crossing 20 upwards.
        case ORDER_TYPE_BUY:
          //_result &= _indi[_shift][0] < (50 - _level);
          _result &= _indi[_shift][0] > (50 - _level) && _indi[_shift + 2][0] < (50 - _level);
          _result &= _indi.IsIncreasing(2);
          _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
          // @todo: Add breakouts and positive/negative divergence signals.
          break;
        // Sell: Crossing 80 downwards.
        case ORDER_TYPE_SELL:
          //_result &= _indi[_shift][0] > (50 + _level);
          _result &= _indi[_shift][0] < (50 + _level) && _indi[_shift + 2][0] > (50 + _level);
          _result &= _indi.IsDecreasing(2);
          _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
          // @todo: Add breakouts and positive/negative divergence signals.
          break;
      }
    }
    return _result;
  }
};
