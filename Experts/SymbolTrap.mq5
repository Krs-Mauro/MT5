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

void OnDeinit(const int reason){}

void OnTick(){
  /* Comments appear on the upper left corner of the chart, prints appear
  on the experts console and alerts appear as popups in the middle
  of the screen */

  Comment("Close = " + DoubleToString(candle[0].close));
   
}