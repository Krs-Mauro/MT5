#property copyright "MauroK"
#property link      ""
#property version   "1.00"

MqlRates candle[];
MqlTick tick;

int OnInit(){
  CopyRates(_Symbol, _Period, 0, 10, candle);
  ArraySetAsSeries(candle, true);
  SymbolInfoTick(_Symbol,tick);
  
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
// use this to unmount functions after EA closure
   
}

void OnTick(){
  Print("Close = ", candle[0].close);
  Print("#############################");
   
}