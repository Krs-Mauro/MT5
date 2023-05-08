#property copyright "MauroK"
#property link      ""
#property version   "1.00"

// MOVING AVERAGE VARIABLES

int movingAvgPeriod             = 7;
int movingAvgShift              = 0;
ENUM_MA_METHOD Slow_MA_type  = MODE_SMA;
ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE;

int movingAverageHandle;
double movingAverageBuffer[];

// RELATIVE STRENGTH INDEX VARIABLES

int RSI_period                         = 14;
ENUM_APPLIED_PRICE RSIappliedPrice = PRICE_CLOSE;

int RSIHandle;
double RSIBuffer [];

int OnInit(){
  /* Keep in mind that indicators have outputs, you need to assign
  a variable  of the right type to capture each one of those outputs */

  movingAverageHandle = iMA(
    _Symbol, 
    _Period, 
    movingAvgPeriod, 
    movingAvgShift, 
    Slow_MA_type, 
    appliedPrice 
  );

  RSIHandle = iRSI(
    _Symbol,
    _Period,
    RSI_period,
    RSIappliedPrice
  );

  if(movingAverageHandle < 0 || RSIHandle < 0){
    Alert("Error trying to create handles for indicator:", GetLastError());
    return(-1);
  }

  ChartIndicatorAdd(0, 0, movingAverageHandle);
  ChartIndicatorAdd(0, 1, RSIHandle);

  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
  IndicatorRelease(movingAverageHandle);
  IndicatorRelease(RSIHandle);
}

void OnTick(){

  CopyBuffer(movingAverageHandle, 0, 0, 3, movingAverageBuffer);
  CopyBuffer(RSIHandle, 0, 0, 3, RSIBuffer);
  ArraySetAsSeries(movingAverageBuffer, true);
  ArraySetAsSeries(RSIBuffer, true);

  Comment("Moving Average = " + DoubleToString(movingAverageBuffer[0]) + "\n" +
          "Relative Strength Index = " +  DoubleToString(RSIBuffer[0])
  );
}