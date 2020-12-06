/**
 * @file
 * Implements MFI strategy based on the Money Flow Index indicator.
 */

// User input params.
INPUT float MFI_LotSize = 0;               // Lot size
INPUT int MFI_SignalOpenMethod = 0;        // Signal open method (0-1)
INPUT float MFI_SignalOpenLevel = 0.9f;    // Signal open level
INPUT int MFI_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int MFI_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int MFI_SignalCloseMethod = 0;       // Signal close method (0-1)
INPUT float MFI_SignalCloseLevel = 0.9f;   // Signal close level
INPUT int MFI_PriceStopMethod = 0;         // Price stop method
INPUT float MFI_PriceStopLevel = 0;        // Price stop level
INPUT int MFI_TickFilterMethod = 0;        // Tick filter method
INPUT float MFI_MaxSpread = 6.0;           // Max spread to trade (pips)
INPUT int MFI_Shift = 0;                   // Shift (relative to the current bar, 0 - default)
INPUT string __MFI_Indi_MFI_Parameters__ =
    "-- MFI strategy: MFI indicator params --";  // >>> MFI strategy: MFI indicator <<<
INPUT int Indi_MFI_Period = 2;                   // Period

// Structs.

// Defines struct with default user indicator values.
struct Indi_MFI_Params_Defaults : MFIParams {
  Indi_MFI_Params_Defaults() : MFIParams(::Indi_MFI_Period) {}
} indi_mfi_defaults;

// Defines struct to store indicator parameter values.
struct Indi_MFI_Params : public MFIParams {
  // Struct constructors.
  void Indi_MFI_Params(MFIParams &_params, ENUM_TIMEFRAMES _tf) : MFIParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_MFI_Params_Defaults : StgParams {
  Stg_MFI_Params_Defaults()
      : StgParams(::MFI_SignalOpenMethod, ::MFI_SignalOpenFilterMethod, ::MFI_SignalOpenLevel,
                  ::MFI_SignalOpenBoostMethod, ::MFI_SignalCloseMethod, ::MFI_SignalCloseLevel, ::MFI_PriceStopMethod,
                  ::MFI_PriceStopLevel, ::MFI_TickFilterMethod, ::MFI_MaxSpread, ::MFI_Shift) {}
} stg_mfi_defaults;

// Struct to define strategy parameters to override.
struct Stg_MFI_Params : StgParams {
  Indi_MFI_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_MFI_Params(Indi_MFI_Params &_iparams, StgParams &_sparams)
      : iparams(indi_mfi_defaults, _iparams.tf), sparams(stg_mfi_defaults) {
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
  Stg_MFI(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_MFI *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_MFI_Params _indi_params(indi_mfi_defaults, _tf);
    StgParams _stg_params(stg_mfi_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_MFI_Params>(_indi_params, _tf, indi_mfi_m1, indi_mfi_m5, indi_mfi_m15, indi_mfi_m30,
                                     indi_mfi_h1, indi_mfi_h4, indi_mfi_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_mfi_m1, stg_mfi_m5, stg_mfi_m15, stg_mfi_m30, stg_mfi_h1,
                               stg_mfi_h4, stg_mfi_h8);
    }
    // Initialize indicator.
    MFIParams mfi_params(_indi_params);
    _stg_params.SetIndicator(new Indi_MFI(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_MFI(_stg_params, "MFI");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_MFI *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        // Buy: Crossing 20 upwards.
        case ORDER_TYPE_BUY:
          _result = _indi[PREV][0] < (50 - _level) || _indi[PPREV][0] < (50 - _level);
          if (METHOD(_method, 0)) _result &= _indi[CURR][0] >= (50 - _level);
          if (METHOD(_method, 1)) _result &= _indi[PPREV][0] >= (50 - _level);
          // @todo: Add breakouts and positive/negative divergence signals.
          break;
        // Sell: Crossing 80 downwards.
        case ORDER_TYPE_SELL:
          _result = _indi[PREV][0] > (50 + _level) || _indi[PPREV][0] > (50 + _level);
          if (METHOD(_method, 0)) _result &= _indi[CURR][0] <= (50 - _level);
          if (METHOD(_method, 1)) _result &= _indi[PPREV][0] <= (50 - _level);
          // @todo: Add breakouts and positive/negative divergence signals.
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_MFI *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 1: {
          int _bar_count0 = (int)_level * (int)_indi.GetPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count0))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count0));
          break;
        }
        case 2: {
          int _bar_count1 = (int)_level * (int)_indi.GetPeriod() * 2;
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count1))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count1));
          break;
        }
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
