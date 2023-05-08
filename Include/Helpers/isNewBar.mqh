#property copyright "MauroK"
#property link      ""
#property version   "1.00"



bool isNewBar () {
  static datetime lastTime = 0;
  datetime lastBarTime =
    (datetime) SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);

  if ( lastTime == 0 ){
    lastTime = lastBarTime;
    return(false);
  }

  if ( lastTime != lastBarTime) {
    lastTime = lastBarTime;
    return(true);
  }

  return(false);
}