//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_MFI_EURUSD_M15_Params : Stg_MFI_Params {
  Stg_MFI_EURUSD_M15_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M15;
    MFI_Period = 2;
    MFI_Applied_Price = 3;
    MFI_Shift = 0;
    MFI_TrailingStopMethod = 6;
    MFI_TrailingProfitMethod = 11;
    MFI_SignalOpenLevel = 36;
    MFI_SignalBaseMethod = -63;
    MFI_SignalOpenMethod1 = 389;
    MFI_SignalOpenMethod2 = 0;
    MFI_SignalCloseLevel = 36;
    MFI_SignalCloseMethod1 = 1;
    MFI_SignalCloseMethod2 = 0;
    MFI_MaxSpread = 4;
  }
};
