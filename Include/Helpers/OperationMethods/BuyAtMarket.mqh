#property copyright "MauroK"
#property link      ""
#property version   "1.00"

ulong BuyAtMarket (MqlTick &tick, int numberOfLots = 100,int takeProfit = 60,int stopLoss = 30) {
  int arbitraryIdentifier = 123456;
  MqlTradeRequest request;
  MqlTradeResult response;

  ZeroMemory(request);
  ZeroMemory(response);

  request.action       = TRADE_ACTION_DEAL;
  request.magic        = arbitraryIdentifier;
  request.symbol       = _Symbol;
  request.volume       = numberOfLots;
  request.price        = NormalizeDouble(tick.ask, _Digits);
  request.sl           = NormalizeDouble(tick.ask - stopLoss * _Point, _Digits);
  request.tp           = NormalizeDouble(tick.ask + takeProfit * _Point, _Digits);
  request.deviation    = 0;
  request.type         = ORDER_TYPE_BUY;
  request.type_filling = ORDER_FILLING_FOK;

  bool result = OrderSend(request, response);

  if(!result){
    Print("Error sending order, Error: " , GetLastError());
    ResetLastError();
    return -1;
  }

  if( response.retcode == 10008 || response.retcode == 10009){
    Print("Order executed successfully");
    return response.order;
  }
  
  else {
    Print("Error sending order to buy, Error: " , GetLastError());
    ResetLastError();
    return -1;
  }
}