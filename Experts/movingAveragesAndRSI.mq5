#property copyright "MauroK"
#property link      ""
#property version   "1.00"

#include <Helpers/isNewBar.mqh>
#include <Helpers/drawVerticalLine.mqh>
#include <Helpers/OperationMethods/BuyAtMarket.mqh>
#include <Helpers/OperationMethods/CloseBuy.mqh>
#include <Helpers/OperationMethods/CloseSell.mqh>
#include <Helpers/OperationMethods/SellAtMarket.mqh>

// PRICE VARIABLES

MqlRates candle[];
MqlTick localTick;
bool sell = false; 
bool buy = false;

// FAST MOVING AVERAGE VARIABLES

input ENUM_MA_METHOD Fast_MA_type              = MODE_SMA;
input ENUM_APPLIED_PRICE Fast_MA_applied_price = PRICE_CLOSE;
input int Fast_MA_Period                       = 12;
input int Fast_MA_shift                        = 0;
int fastMovingAverageHandle;
double fastMovingAverageBuffer[];

// slow MOVING AVERAGE VARIABLES

input ENUM_MA_METHOD Slow_MA_type              = MODE_SMA;
input ENUM_APPLIED_PRICE Slow_MA_applied_price = PRICE_CLOSE;
input int Slow_MA_Period                       = 12;
input int Slow_MA_shift                        = 0;
int slowMovingAverageHandle;
double slowMovingAverageBuffer[];

// RELATIVE STRENGTH INDEX VARIABLES

input ENUM_APPLIED_PRICE RSI_applied_price = PRICE_CLOSE;
input int RSI_period                       = 5;
int RSIHandle;
double RSIBuffer [];

int OnInit(){

  fastMovingAverageHandle = iMA(
    _Symbol, 
    _Period, 
    Fast_MA_Period, 
    Fast_MA_shift, 
    Fast_MA_type, 
    Fast_MA_applied_price 
  );

  slowMovingAverageHandle = iMA(
    _Symbol, 
    _Period, 
    Slow_MA_Period, 
    Slow_MA_shift, 
    Slow_MA_type, 
    Slow_MA_applied_price
  );

  RSIHandle = iRSI(
    _Symbol,
    _Period,
    RSI_period,
    RSI_applied_price
  );

  if(fastMovingAverageHandle < 0 || slowMovingAverageHandle < 0 ||RSIHandle < 0){
    Alert("Error trying to create handles for indicator:", GetLastError());
    return(-1);
  }

  ChartIndicatorAdd(0, 0, fastMovingAverageHandle);
  ChartIndicatorAdd(0, 0, slowMovingAverageHandle);
  ChartIndicatorAdd(0, 1, RSIHandle);

  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
  IndicatorRelease(fastMovingAverageHandle);
  IndicatorRelease(slowMovingAverageHandle);
  IndicatorRelease(RSIHandle);
}

void OnTick(){
  bool checkIfNewBar = isNewBar();

  CopyBuffer(fastMovingAverageHandle, 0, 0, 3, fastMovingAverageBuffer);
  CopyBuffer(slowMovingAverageHandle, 0, 0, 3, slowMovingAverageBuffer);
  CopyBuffer(RSIHandle, 0, 0, 3, RSIBuffer);

  CopyRates(_Symbol, _Period, 0, 4, candle);
  ArraySetAsSeries(candle, true);

  ArraySetAsSeries(fastMovingAverageBuffer, true);
  ArraySetAsSeries(slowMovingAverageBuffer, true);
  ArraySetAsSeries(RSIBuffer, true);

  SymbolInfoTick(_Symbol,localTick);

  bool movingAverageBuy  = fastMovingAverageBuffer[0] > slowMovingAverageBuffer[0]
                        && fastMovingAverageBuffer[2] < slowMovingAverageBuffer[2];

  bool RSIBuy = RSIBuffer[0] < 30; // over sold threshold

  bool movingAverageSell  = fastMovingAverageBuffer[0] < slowMovingAverageBuffer[0]
                        && fastMovingAverageBuffer[2] > slowMovingAverageBuffer[2];

  bool RSISell = RSIBuffer[0] < 70; // over bought threshold

  double rounded_0 = NormalizeDouble(fastMovingAverageBuffer[0], 7);
  double rounded_1 = NormalizeDouble(fastMovingAverageBuffer[1], 7);
  double rounded_2 = NormalizeDouble(fastMovingAverageBuffer[2], 7);


  sell = movingAverageSell && RSISell;
  buy = movingAverageBuy && RSIBuy;


  if( checkIfNewBar ){

    if(buy && PositionSelect(_Symbol)==false){
      drawVerticalLine("Buy", candle[1].time, clrBlue);
      BuyAtMarket(localTick);
    }

    if(sell && PositionSelect(_Symbol)==false){
      drawVerticalLine("Sell", candle[1].time, clrRed);
      SellAtMarket(localTick);
    }
  }
}
