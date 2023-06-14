#property copyright "MauroK"
#property link      ""
#property version   "1.00"

#include <Trade/Trade.mqh>

static input long inp_magic_number    = 123456;
static input double inp_lot_size      = 0.01;
input int  inp_RSI_period             = 21;
input int  inp_RSI_level              = 70;
input int  inp_stop_loss              = 200;
input int  inp_take_profit            = 100;
input bool inp_close_signal           = false;

int handle;
double buffer[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy  = 0;
datetime openTimeSell = 0;

int OnInit(){

  if(inp_magic_number <= 0){
    Alert("Magic number is less or equal to zero");
    return INIT_PARAMETERS_INCORRECT;
  }

  if(inp_lot_size <= 0 || inp_lot_size > 10){
    Alert("Lot size is negative or more than 10");
    return INIT_PARAMETERS_INCORRECT;
  }

  if(inp_RSI_level < 1){
    Alert("RSI level is too small");
    return INIT_PARAMETERS_INCORRECT;
  }

  if(inp_RSI_level > 100 || inp_RSI_level <= 50){
    Alert("RSI level must be between 51 and 100");
    return INIT_PARAMETERS_INCORRECT;
  }

  if(inp_stop_loss < 0){
    Alert("Stop loss is too small");
    return INIT_PARAMETERS_INCORRECT;
  }

  if(inp_take_profit < 0){
    Alert("Take profit is too small");
    return INIT_PARAMETERS_INCORRECT;
  }

  trade.SetExpertMagicNumber(inp_magic_number);

  handle = iRSI(_Symbol, _Period, inp_RSI_period, PRICE_CLOSE);

  if(handle == INVALID_HANDLE){
    Alert("Failed to create RSI handle");
    return INIT_FAILED;
  }

  ArraySetAsSeries(buffer,true);

  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){
  if(!SymbolInfoTick(_Symbol,currentTick)){
    Alert("Failed to get current tick");
    return;
  }

  int values = CopyBuffer(handle, 0, 0, 2, buffer);

  if(values!=2){
    Alert("Failed to get RSI values");
    return;
  }

  Comment("RSI last: ", buffer[0],
       "\n RSI first; ", buffer[1]);


  int countBuy, countSell;
  if(!CountOpenPositions(countBuy, countSell)){
    Print("Was not able to count open positions");
    return;
  }
// check for buy position:

  if(
    countBuy == 0 && 
    buffer[1] >= (100 - inp_RSI_level) && 
    buffer[0] < (100 - inp_RSI_level) &&
    openTimeBuy != iTime(_Symbol, _Period, 0)    
    ){
      openTimeBuy = iTime(_Symbol, _Period, 0);

      if(inp_close_signal){

        if(!ClosePositions(2)){
          Print("There are no positions to close");
          return;
        }

        double stop_loss = inp_stop_loss == 0 ? 0 : currentTick.bid - inp_stop_loss * _Point;
        double take_profit = inp_take_profit == 0 ? 0 : currentTick.bid + inp_take_profit * _Point;

        if(!NormalizePrice(stop_loss)){return;}
        if(!NormalizePrice(take_profit)){return;}

        trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, inp_lot_size, currentTick.ask, stop_loss, take_profit);
      }
    }

// Check for sell position: 

  if(
    countSell == 0 && 
    buffer[1] <= (100 - inp_RSI_level) && 
    buffer[0] > (100 - inp_RSI_level) &&
    openTimeBuy != iTime(_Symbol, _Period, 0)    
    ){
      openTimeSell = iTime(_Symbol, _Period, 0);

      if(inp_close_signal){

        if(!ClosePositions(1)){
          Print("There are no positions to close");
          return;
        }

        double stop_loss = inp_stop_loss == 0 ? 0 : currentTick.bid + inp_stop_loss * _Point;
        double take_profit = inp_take_profit == 0 ? 0 : currentTick.bid - inp_take_profit * _Point;

        if(!NormalizePrice(stop_loss)){return;}
        if(!NormalizePrice(take_profit)){return;}

        trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, inp_lot_size, currentTick.ask, stop_loss, take_profit);
      }
    }


}

bool CountOpenPositions( int &count_buy, int &count_sell){
  count_buy  = 0; 
  count_sell = 0;
  int total = PositionsTotal();
  for(int i = total - 1; i>=0; i--){
    ulong ticket = PositionGetTicket(i);
    long magic;

    if(ticket <= 0 || !PositionSelectByTicket(ticket)){
      Print("Failed to get position ticket");
      return false;
    }

    if( !PositionSelectByTicket(ticket)){
      Print("Failed to select ticket's position");
      return false;
    }

    if(!PositionGetInteger(POSITION_MAGIC, magic)){
      Print("Failed to select position's magic number");
      return false;
    }

    if(magic==inp_magic_number){
      long type;

      if(!PositionGetInteger(POSITION_TYPE, type)){
        Print("Failed to select position's type");
      return false;
      }

      if(type==POSITION_TYPE_BUY){count_buy++;}
      if(type==POSITION_TYPE_SELL){count_sell++;}

    }
  }
  return true;
}

bool NormalizePrice(double &price){

  double tickSize = 0;

  if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)){
    Print("Failed to get tick size");
    return false; 
  }

  price = NormalizeDouble(MathRound(price/tickSize), _Digits);

  return true;
}

bool ClosePositions ( int all_buy_sell){
  int total = PositionsTotal();
  for(int i = total - 1; i>=0; i--){

    ulong ticket = PositionGetTicket(i);
    long magic;

    if(ticket <= 0 || !PositionSelectByTicket(ticket)){
      Print("Failed to get position ticket");
      return false;
    }

    if( !PositionSelectByTicket(ticket)){
      Print("Failed to select ticket's position");
      return false;
    }

    if(!PositionGetInteger(POSITION_MAGIC, magic)){
      Print("Failed to select position's magic number");
      return false;
    }

    if(magic==inp_magic_number){
      long type;

      if(!PositionGetInteger(POSITION_TYPE, type)){
        Print("Failed to select position's type");
      return false;
      }

      if(all_buy_sell==1 && type==POSITION_TYPE_BUY){continue;}
      if(all_buy_sell==2 && type==POSITION_TYPE_SELL){continue;}

      trade.PositionClose((ticket));

      if(trade.ResultRetcode() != TRADE_RETCODE_DONE){
        Print("Failed to close position: ", 
          (string)ticket,
          (string)trade.ResultRetcode(), " : ",
          trade.CheckResultRetcodeDescription()
        );
      }
    }
  }
  return true;
}