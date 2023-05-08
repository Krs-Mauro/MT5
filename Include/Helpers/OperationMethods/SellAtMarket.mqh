#property copyright "MauroK"
#property link      ""
#property version   "1.00"

void SellAtMarket (MqlTick &tick, int numberOfLots = 100, int takeProfit = 60, int stopLoss = 30) {
  int arbitraryIdentifier = 123456;
  MqlTradeRequest request;
  MqlTradeResult response;

  ZeroMemory(request);
  ZeroMemory(response);

  request.action       = TRADE_ACTION_DEAL;
  request.magic        = arbitraryIdentifier;
  request.symbol       = _Symbol;
  request.volume       = numberOfLots;
  request.price        = NormalizeDouble(tick.bid, _Digits);
  request.sl           = NormalizeDouble(tick.bid + stopLoss * _Point, _Digits);
  request.tp           = NormalizeDouble(tick.bid - takeProfit * _Point, _Digits);
  request.deviation    = 0;
  request.type         = ORDER_TYPE_SELL;
  request.type_filling = ORDER_FILLING_FOK;

  bool result = OrderSend(request, response);

  if(!result){
    Print("Error sending order, Error: " , GetLastError());
    ResetLastError();
  }

  if( response.retcode == 10008 || response.retcode == 10009){
    Print("Order executed successfully");
  }
  
  else {
    Print("Error sending order to buy, Error: " , GetLastError());
    ResetLastError();
  }
}