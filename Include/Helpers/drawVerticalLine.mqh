#property copyright "MauroK"
#property link      ""
#property version   "1.00"

void drawVerticalLine (string name, datetime time, color lineColor = C'126,0,199'){
  ObjectDelete(0, name);
  ObjectCreate(0, name , OBJ_VLINE, 0, time, 0);
  ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
}