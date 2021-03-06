/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_MFI_Params_M5 : MFIParams {
  Indi_MFI_Params_M5() : MFIParams(indi_mfi_defaults, PERIOD_M5) {
    ma_period = 22;
    shift = 0;
  }
} indi_mfi_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_MFI_Params_M5 : StgParams {
  // Struct constructor.
  Stg_MFI_Params_M5() : StgParams(stg_mfi_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)25;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)25;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_mfi_m5;
