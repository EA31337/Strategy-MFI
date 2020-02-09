//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_MFI_EURUSD_H4_Params : Stg_MFI_Params {
  Stg_MFI_EURUSD_H4_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H4;
    MFI_Period = 2;
    MFI_Shift = 0;
    MFI_SignalOpenMethod = 0;
    MFI_SignalOpenLevel = 36;
    MFI_SignalCloseMethod = 1;
    MFI_SignalCloseLevel = 36;
    MFI_PriceLimitMethod = 0;
    MFI_PriceLimitLevel = 0;
    MFI_MaxSpread = 10;
  }
} stg_mfi_h4;
