/**
 * @file
 * Implements MFI strategy based on the Money Flow Index indicator.
 */

// User input params.
INPUT_GROUP("MFI strategy: strategy params");
INPUT float MFI_LotSize = 0;                // Lot size
INPUT int MFI_SignalOpenMethod = 0;         // Signal open method (-127-127)
INPUT float MFI_SignalOpenLevel = 20;       // Signal open level (-49-49)
INPUT int MFI_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int MFI_SignalOpenFilterTime = 3;     // Signal open filter time
INPUT int MFI_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int MFI_SignalCloseMethod = 0;        // Signal close method (-127-127)
INPUT int MFI_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT float MFI_SignalCloseLevel = 20;      // Signal close level (-49-49)
INPUT int MFI_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float MFI_PriceStopLevel = 2;         // Price stop level
INPUT int MFI_TickFilterMethod = 32;        // Tick filter method
INPUT float MFI_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short MFI_Shift = 0;                  // Shift (relative to the current bar, 0 - default)
INPUT float MFI_OrderCloseLoss = 80;        // Order close loss
INPUT float MFI_OrderCloseProfit = 80;      // Order close profit
INPUT int MFI_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("MFI strategy: MFI indicator params");
INPUT int MFI_Indi_MFI_MA_Period = 22;                                           // MA Period
INPUT ENUM_APPLIED_VOLUME MFI_Indi_MFI_Applied_Volume = (ENUM_APPLIED_VOLUME)0;  // Applied volume.
INPUT int MFI_Indi_MFI_Shift = 0;                                                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_MFI_Params_Defaults : IndiMFIParams {
  Indi_MFI_Params_Defaults()
      : IndiMFIParams(::MFI_Indi_MFI_MA_Period, ::MFI_Indi_MFI_Applied_Volume, ::MFI_Indi_MFI_Shift) {}
};

// Defines struct with default user strategy values.
struct Stg_MFI_Params_Defaults : StgParams {
  Stg_MFI_Params_Defaults()
      : StgParams(::MFI_SignalOpenMethod, ::MFI_SignalOpenFilterMethod, ::MFI_SignalOpenLevel,
                  ::MFI_SignalOpenBoostMethod, ::MFI_SignalCloseMethod, ::MFI_SignalCloseFilter, ::MFI_SignalCloseLevel,
                  ::MFI_PriceStopMethod, ::MFI_PriceStopLevel, ::MFI_TickFilterMethod, ::MFI_MaxSpread, ::MFI_Shift) {
    Set(STRAT_PARAM_LS, MFI_LotSize);
    Set(STRAT_PARAM_OCL, MFI_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, MFI_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, MFI_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, MFI_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_MFI : public Strategy {
 public:
  Stg_MFI(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_MFI *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    Stg_MFI_Params_Defaults stg_mfi_defaults;
    StgParams _stg_params(stg_mfi_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_mfi_m1, stg_mfi_m5, stg_mfi_m15, stg_mfi_m30, stg_mfi_h1, stg_mfi_h4,
                             stg_mfi_h8);
#endif
    // Initialize indicator.
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_MFI(_stg_params, _tparams, _cparams, "MFI");
    return _strat;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() {
    Indi_MFI_Params_Defaults indi_mfi_defaults;
    IndiMFIParams _indi_params(indi_mfi_defaults, Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    SetIndicator(new Indi_MFI(_indi_params));
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_MFI *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift);
    double _level_pips = _level * Chart().GetPipSize();
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
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
    return _result;
  }
};
