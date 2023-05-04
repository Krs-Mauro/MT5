#property copyright "MauroK"
#property link      ""
#property version   "1.00"

int movingAverageHandle;
double movingAverageBuffer[];

int OnInit(){
  /* Keep in mind that indicators have outputs, you need to assign
  a variable  of the right type to capture each one of those outputs */

  movingAverageHandle = iMA(_Symbol, _Period, 7, 0, MODE_EMA, PRICE_CLOSE);

  if(movingAverageHandle < 0){
    Alert("Error trying to create handles for indicator:", GetLastError());
    return(-1);
  }

  ChartIndicatorAdd(0, 0, movingAverageHandle);

  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){}

void OnTick(){

   
}