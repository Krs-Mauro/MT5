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

input ENUM_MA_METHOD Fast_MA_type              = MODE_EMA;
input ENUM_APPLIED_PRICE Fast_MA_applied_price = PRICE_CLOSE;
input int Fast_MA_Period                       = 26;
input int Fast_MA_shift                        = 0;
int fastMovingAverageHandle;
double fastMovingAverageBuffer[];

// slow MOVING AVERAGE VARIABLES

input ENUM_MA_METHOD Slow_MA_type              = MODE_SMA;
input ENUM_APPLIED_PRICE Slow_MA_applied_price = PRICE_CLOSE;
input int Slow_MA_Period                       = 60;
input int Slow_MA_shift                        = 0;
int slowMovingAverageHandle;
double slowMovingAverageBuffer[];

// RELATIVE STRENGTH INDEX VARIABLES

input ENUM_APPLIED_PRICE RSI_applied_price = PRICE_CLOSE;
input int RSI_period                       = 4;
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
  ulong ticket_number = 0;
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

  bool trend_slope = slowMovingAverageBuffer[0] > slowMovingAverageBuffer[2];

  bool MA_buy_crossing  = fastMovingAverageBuffer[0] > slowMovingAverageBuffer[0]
                        && fastMovingAverageBuffer[2] < slowMovingAverageBuffer[2];

  bool RSIBuy = RSIBuffer[0] < 20; // over sold threshold

  bool MA_sell_crossing  = fastMovingAverageBuffer[0] < slowMovingAverageBuffer[0]
                        && fastMovingAverageBuffer[2] > slowMovingAverageBuffer[2];

  bool RSISell = RSIBuffer[0] < 80; // over bought threshold

  sell = MA_sell_crossing && RSISell && trend_slope == false;
  buy = MA_buy_crossing && RSIBuy && trend_slope;


  if( checkIfNewBar ){

    if(buy && PositionSelect(_Symbol)==false){
      drawVerticalLine("Buy", candle[1].time, clrBlue);
      ulong buy_ticket = BuyAtMarket(localTick);

      if(buy_ticket>0){ticket_number=buy_ticket;}
    }

    if(sell && PositionSelect(_Symbol)==false){
      drawVerticalLine("Sell", candle[1].time, clrRed);
      ulong sell_ticket= SellAtMarket(localTick);
      if(sell_ticket>0){ticket_number=sell_ticket;}
    }
  }
  
  if(PositionSelectByTicket(ticket_number)){

  MqlTradeRequest modifyRequest;
  ZeroMemory(modifyRequest);
  
  modifyRequest.action = TRADE_ACTION_SLTP;
  modifyRequest.position = ticket_number;
  modifyRequest.sl = slowMovingAverageBuffer[0];
  modifyRequest.tp = PositionGetDouble(POSITION_TP);

  MqlTradeResult modifyResponse;
  ZeroMemory(modifyResponse);

  if(!OrderSend(modifyRequest, modifyResponse)){
    Print("Error modifying order, Error: " , GetLastError());
    ResetLastError();
  }
  
}
}
