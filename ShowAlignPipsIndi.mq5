//+------------------------------------------------------------------+
//|                                                   Align_pips.mq4 |
//|                                       Copyright 2021, T.Shiroiwa |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//
//

#property copyright "Copyright 2021, T.Shiroiwa"
#property link      "https://www.mql5.com"
#property version   "1.1"                         // 2022/2/2
#property strict
#property indicator_chart_window

#define WM_MDIGETACTIVE 0x00000229
#import "user32.dll"
  int GetParent(int hWnd);
  int SendMessageW(int hWnd,int Msg,int wParam,int lParam);
#import

#include <MT4Orders.mqh>

//extern color Color_JST = clrCadetBlue;

input bool bPipsAlign=true;
input int Corner = CORNER_RIGHT_LOWER;
input int offset_x=60;
input int offset_y=40;
input int diff_x=57;
input int diff_y=27;
input int max_x=500;
input int max_y=360;
input string FontName = "Arial Black";
input int FontSize = 15;
input color PipsColorPlus=clrBlue;
input color PipsColorSpread=clrGold;
input color PipsColorMinus=clrRed;
input color PipsColorZero=clrBlack;
input color LineColorBuy=clrBlue;
input color LineColorSell=clrRed;
input int CornerPipsTotal = CORNER_RIGHT_UPPER;
input int PosXPipsTotal=20;
input int PosYPipsTotal=150;
input string FontNamePipsTotal = "Arial Bold";
input bool bUserLabelForIndivi=false;
input bool bUserLabelForTotal=false;

int chart_height;
int chart_width;

int gLocationX=offset_x;
int gLocationY=offset_y;
int gLocationX_abs;
int gLocationY_abs;

string str_order_symbol;
string  symbol_str;
//int tick_denomi=0;
int gk=0;

/*-- 変数の宣言 ----------------------------------------------------*/
int ClientHandle = 0; //クライアントウィンドウハンドル保持用
int ThisWinHandle = 0; //Thisウィンドウハンドル保持用
int ParentWinHandle = 0; //Parentウィンドウハンドル保持用

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int ObjectType(string name){
  int ret;
  ret = ObjectGetInteger(0, name, OBJPROP_TYPE, 0);
  return ret;
}
//+------------------------------------------------------------------+
int OnInit()
{
  //EventSetTimer(10);
  symbol_str = Symbol();

  chart_height=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
  chart_width=ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);

  ClientHandle = (int)ChartGetInteger(0,CHART_WINDOW_HANDLE);
  //          Print ("SyncMain OnTimer ClientHandle0: "+ClientHandle);
  if (ClientHandle != 0) ThisWinHandle = GetParent(ClientHandle);
  //          Print ("SyncMain OnTimer ClientHandle1: "+ClientHandle);
  if (ThisWinHandle != 0) ParentWinHandle = GetParent(ThisWinHandle);
  
  EventSetTimer(5);

  return  ( INIT_SUCCEEDED );
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  EventKillTimer();

  //int obj_total= ObjectsTotal(0,0, EMPTY); //ObjectsTotal(0,0,-1) ;
  int obj_total= ObjectsTotal(0,0, -1); //ObjectsTotal(0,0,-1) ;
  for (int k= obj_total; k>=0; k--){
    string obj_name= ObjectName(0,k);
    //Print ("name name:"+name);

    if(0<=StringFind(StringSubstr(obj_name,0,5),"PIPS ")
        || 0<=StringFind(StringSubstr(obj_name,0,9),"TotalPIPS" )){
      //Get_Arrow_Code = ObjectGetInteger(0,name,OBJPROP_ARROWCODE, 0);
      if(OBJ_TEXT == ObjectType(obj_name) || OBJ_LABEL == ObjectType(obj_name)){
        ObjectDelete(0,obj_name);
      }
    }
  }
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
void UpdatePipsTextMQL4()
{
  int LocationX=offset_x;
  int LocationY=offset_y;
  int LocationX_abs;
  int LocationY_abs;
  datetime dt;
  double price, price_diff, commision_total, profit_total;
  int window_num= 0;
  string obj_name;
  string obj_name_line;
  double dPips,dPips_total;
  bool bActive = false;
  
  int obj_total;

  int wHandle = SendMessageW(ParentWinHandle,WM_MDIGETACTIVE,0,0);
  //Print ("main ce cli wHandle "+wHandle);
  if(wHandle != ThisWinHandle){
    // if not activated
    bActive = false;
    //return  ( rates_total );
  }else{
    chart_height=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
    chart_width=ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);

    bActive = true;
  }

  dPips_total = 0; commision_total = 0; profit_total = 0;
  for(int i = OrdersTotal() - 1; i >= 0; i--){
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true){
      str_order_symbol = OrderSymbol();
      if(OrderType() == OP_BUY || OrderType() == OP_SELL){
        //commision_total += OrderCommission();
        //profit_total += OrderProfit();
        price_diff = 0;
        price = OrderOpenPrice();
        datetime time_open = OrderOpenTime();
        double price_latest;
        color LineColor;
        double Bid = SymbolInfoDouble(str_order_symbol,SYMBOL_BID); 
        double Ask = SymbolInfoDouble(str_order_symbol,SYMBOL_ASK); 

        if(OrderType() == OP_BUY){
          price_diff = Bid - price;
          price_latest = Bid;
          LineColor = LineColorBuy;
        }
        if(OrderType() == OP_SELL){
          price_diff = price - Ask;
          price_latest = Ask;
          LineColor = LineColorSell;
        }
        dPips = (price_diff/_Point)/10;

        if( str_order_symbol == symbol_str){
          int ticket = OrderTicket();
          obj_name = "PIPS "+IntegerToString(ticket);
          obj_name_line = "TradeLine"+IntegerToString(ticket);
          if(ObjectFind(0, obj_name) < 0){
            // not found
            if(!bUserLabelForIndivi){
              ObjectCreate(0,obj_name, OBJ_TEXT, 0, time_open, price);
            }else{
              ObjectCreate(0,obj_name, OBJ_LABEL, 0, time_open, price);
            }
            //--- set text font
            ObjectSetString(0,obj_name,OBJPROP_FONT,FontName);
            //--- set font size
            ObjectSetInteger(0, obj_name,OBJPROP_FONTSIZE,FontSize);
            ObjectSetInteger(0,obj_name,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
            //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態
            //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
            // オブジェクトバインディングのアンカーポイント設定
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);  
          }

          if(ObjectFind(0, obj_name_line) < 0){
            // not found
            ObjectCreate(0,obj_name_line, OBJ_TREND, 0, time_open, price, iTime(NULL, 0, 0), price_latest);
            ObjectSetInteger(0, obj_name_line,OBJPROP_STYLE,STYLE_DOT);
            ObjectSetInteger(0, obj_name_line,OBJPROP_WIDTH,1);
            ObjectSetInteger(0, obj_name_line,OBJPROP_COLOR,LineColor);
            ObjectSetInteger(0,obj_name_line,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
            ObjectSetInteger(0,obj_name_line,OBJPROP_SELECTED,false);       // オブジェクトの選択状態
            ObjectSetInteger(0,obj_name_line,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
            ObjectSetInteger(0,obj_name_line,OBJPROP_RAY_RIGHT,false);      // ラインの延長線(右)
            ObjectSetInteger(0,obj_name_line,OBJPROP_RAY,false);      // ラインの延長線(右)
          }else{
            ObjectMove(0,obj_name_line, 1, iTime(NULL, 0, 0), price_latest);
          }

          //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
          ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);  
          if(0 < OrderProfit()){
            if(OrderProfit() + OrderCommission() < 0){
              // color spread
              ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorSpread);    // 色設定
              // color profit
            }else{
              ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorPlus);    // 色設定
            }
          }else{
            // color minus
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorMinus);    // 色設定
          }

          if(NormalizeDouble(dPips,1) == 0){
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorZero);    // 色設定
          }
          
          //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態
          //ObjectSetString(0,obj_name,OBJPROP_TEXT,DoubleToString(Value0,3));

          //if(OrderType() == OP_BUY){
          //  price_diff = Bid - price;
          //}
          //if(OrderType() == OP_SELL){
          //  price_diff = price - Ask;
          //}
          //dPips = (price_diff/Point)/10;

          ObjectSetString(0,obj_name,OBJPROP_TEXT,DoubleToString(dPips,1));   // 表示するテキスト

          // ticket bango check, ticket bango ni soutou suru text wo sagasu areba skip
          // nakereba tsukuru
          // pips wo get
          // profit wo get
          // color set
        }
        commision_total += OrderCommission();
        profit_total += OrderProfit();
        dPips_total += dPips;
      } // if(OrderType() == OP_BUY || OrderType() == OP_SELL){
    }
  }

  // show total pips
  //commision_total
  obj_name = "TotalPIPS";
  if(ObjectFind(0, obj_name) < 0){
    // not found
    if(!bUserLabelForTotal){
      ObjectCreate(0,obj_name, OBJ_TEXT, 0, iTime(NULL, PERIOD_CURRENT,0), iClose(NULL, PERIOD_CURRENT, 0));
    }else{
      ObjectCreate(0,obj_name, OBJ_LABEL, 0, 100, 100);
    }
    ObjectSetInteger(0,obj_name,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
    //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態
    //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
    // オブジェクトバインディングのアンカーポイント設定
  }
  //--- set text font
  ObjectSetString(0,obj_name,OBJPROP_FONT,FontNamePipsTotal);
  //--- set font size
  ObjectSetInteger(0, obj_name,OBJPROP_FONTSIZE,FontSize);
  ObjectSetString(0,obj_name,OBJPROP_TEXT,"Total  "+DoubleToString(dPips_total,1));   // 表示するテキスト

  //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
  if(0 < profit_total){
    if(profit_total + commision_total < 0){
      // color spread
      ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorSpread);    // 色設定
      // color profit
    }else{
      ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorPlus);    // 色設定
    }
  }else{
    // color minus
    ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorMinus);    // 色設定
  }

  if(profit_total == 0){
    ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorZero);    // 色設定
  }

  //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態

  //ObjectSetString(0,obj_name,OBJPROP_TEXT,DoubleToString(Value0,3));
  LocationX_abs = PosXPipsTotal;
  LocationY_abs = PosYPipsTotal;
  ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);  

  if(bActive){
    if(!bUserLabelForTotal){
      if(CornerPipsTotal == CORNER_RIGHT_LOWER){
        LocationX_abs=chart_width - PosXPipsTotal;
        LocationY_abs=chart_height - PosYPipsTotal;
        ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);  
      }else if(CornerPipsTotal == CORNER_RIGHT_UPPER){
        LocationX_abs=chart_width - PosXPipsTotal;
        ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);  
      }else if(CornerPipsTotal == CORNER_LEFT_LOWER){
        LocationY_abs=chart_height - PosYPipsTotal;
        ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);  
      }
      ChartXYToTimePrice(0, LocationX_abs, LocationY_abs, window_num, dt, price);
      ObjectMove(0, obj_name, 0,dt, price);
    }else{
      ObjectSetInteger(0,obj_name,OBJPROP_CORNER,CornerPipsTotal);  
      ObjectMove(0, obj_name, 0,LocationX_abs, LocationY_abs);
    }
  }
  //        if(MAGIC_NUM_thisEA == OrderMagicNumber()){
  //        OrderClose(OrderTicket(),OrderLots(),0, 20, clrNONE);

  //obj_total= ObjectsTotal();
  //obj_total= ObjectsTotal(0,0, OBJ_TEXT);
  obj_total= ObjectsTotal(0,0, -1);

  //int Get_Arrow_Code;

  //Print ("Object_total = " + obj_total);


  if(bPipsAlign && bActive){
    for (int k= obj_total; k>=0; k--){
      string name= ObjectName(0,k);
      //Print ("Object_name 000 = " + name + " type" + ObjectType(name));
      //if(0<=StringFind(StringSubstr(name,0,4),"PIPS")){
      //   Print ("Object_name 001 = " + name);
      //}
      //Get_Arrow_Code = ObjectGetInteger(0,name,OBJPROP_ARROWCODE, 0);
      if(OBJ_TEXT == ObjectType(name) || OBJ_LABEL == ObjectType(name)){
        if(0<=StringFind(StringSubstr(name,0,4),"PIPS")){
          //Print ("Object_name 002 = " + name);
          //ObjectDelete(name);
          if(LocationX < max_x && LocationY < max_y){
            LocationX_abs = LocationX;
            LocationY_abs = LocationY;
            if(Corner == CORNER_RIGHT_LOWER){
              LocationX_abs=chart_width - LocationX;
              LocationY_abs=chart_height - LocationY;
            }else if(Corner == CORNER_RIGHT_UPPER){
              LocationX_abs=chart_width - LocationX;
            }else if(Corner == CORNER_LEFT_LOWER){
              LocationY_abs=chart_height - LocationY;
            }

            if(bActive){
              if(!bUserLabelForIndivi){
                ChartXYToTimePrice(0, LocationX_abs, LocationY_abs, window_num, dt, price);
                //ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
                ObjectMove(0, name, 0,dt, price);
              }else{
                ObjectMove(0, name, 0,LocationX_abs, LocationY_abs);
              }
            }
            //ObjectSet(name, OBJPROP_XDISTANCE, LocationX);
	         // ObjectSet(name, OBJPROP_YDISTANCE, LocationY);
	         //ObjectSet(name, OBJPROP_CORNER, Corner);
            LocationY = LocationY + diff_y;
            if(max_y < LocationY){
              LocationY = offset_y;
              LocationX = LocationX + diff_x;
            }
          }
        }
      }
    }
  }

}
//+------------------------------------------------------------------+
void UpdatePipsTextMQL5()
{
  int LocationX=offset_x;
  int LocationY=offset_y;
  int LocationX_abs;
  int LocationY_abs;
  datetime dt;
  double price, price_diff, commision_total, profit_total;
  int window_num= 0;
  string obj_name;
  double dPips,dPips_total, symbol_point;
  string pos_symbol;
  int iPosTotal = PositionsTotal();
  bool bActive=true;

  int wHandle = SendMessageW(ParentWinHandle,WM_MDIGETACTIVE,0,0);
  //Print ("main ce cli wHandle "+wHandle);
  if(wHandle != ThisWinHandle){
    // if not activated
    bActive=false;
    if(0==iPosTotal){
      return;
    }
  }else{
    bActive=true;
  }

  dPips_total = 0; commision_total = 0; profit_total = 0;
  //for(int i = OrdersTotal() - 1; i >= 0; i--){
  //Print ("PosTotal="+iPosTotal);
  for(int i = iPosTotal - 1; i >= 0; i--){
    //if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true){
    ulong ulTicket = PositionGetTicket(i);
    //if(PositionSelect(i,SELECT_BY_POS,MODE_TRADES) == true){ //bool  PositionSelectByTicket(ulong  ticket     // ポジションチケット   );
    if(PositionSelectByTicket(ulTicket) == true){ //bool  PositionSelectByTicket(ulong  ticket     // ポジションチケット   );
      // str_order_symbol = OrderSymbol();  //  OrderGetString() 
      str_order_symbol = PositionGetString(POSITION_SYMBOL);  //  OrderGetString() 
      //if(OrderType() == OP_BUY || OrderType() == OP_SELL){
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
        //commision_total += OrderCommission();
        //commision_total += OrderCommission();  //PositionGetDouble(POSITION_COMMISSION)
        commision_total += PositionGetDouble(POSITION_COMMISSION);  //PositionGetDouble(POSITION_COMMISSION)
        profit_total += PositionGetDouble(POSITION_PROFIT);
        price_diff = 0;
        //price = OrderOpenPrice();  //POSITION_PRICE_OPEN
        price = PositionGetDouble(POSITION_PRICE_OPEN);  //POSITION_PRICE_OPEN
        pos_symbol = PositionGetString(POSITION_SYMBOL);
        double PosBid = SymbolInfoDouble(pos_symbol,SYMBOL_BID); 
        double PosAsk = SymbolInfoDouble(pos_symbol,SYMBOL_ASK); 
        symbol_point = SymbolInfoDouble(pos_symbol,SYMBOL_POINT); 

        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
          price_diff = PosBid - price;
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
          price_diff = price - PosAsk;
        }
        dPips = (price_diff/symbol_point)/10;
        dPips_total += dPips;

        if( str_order_symbol == symbol_str){
          //int ticket = OrderGetInteger(ORDER_TICKET);  //ORDER_TICKET
          obj_name = "PIPS "+IntegerToString(ulTicket);
          //Print ("obj_name="+obj_name);

          if(ObjectFind(0, obj_name) < 0){
            // not found
            ObjectCreate(0,obj_name, OBJ_TEXT, 0, PositionGetInteger(POSITION_TIME), price);  // open time
          }
          if(bActive){
            //--- set text font
            ObjectSetString(0,obj_name,OBJPROP_FONT,FontName);
            //--- set font size
            ObjectSetInteger(0, obj_name,OBJPROP_FONTSIZE,FontSize);
            ObjectSetInteger(0,obj_name,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
            //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態
            //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
            // オブジェクトバインディングのアンカーポイント設定
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);  
            //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
            //ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);  
            //if(0 < OrderProfit()){
            //  if(OrderProfit() + OrderCommission() < 0){
            if(0 < PositionGetDouble(POSITION_PROFIT)){
              //if(PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_COMMISION) < 0){  //PositionGetDouble(POSITION_COMMISSION)
              if(PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_COMMISSION) < 0){  //PositionGetDouble(POSITION_COMMISSION)
                // color spread
                ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorSpread);    // 色設定
                // color profit
              }else{
                ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorPlus);    // 色設定
              }
            }else{
              // color minus
              ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorMinus);    // 色設定
            }
            
            
            //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態
            //ObjectSetString(0,obj_name,OBJPROP_TEXT,DoubleToString(Value0,3));
  
            double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); 
            double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); 
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
              price_diff = Bid - price;
            }
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
              price_diff = price - Ask;
            }
            dPips = (price_diff/Point())/10;
            if(NormalizeDouble(dPips,1) == 0){
              ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorZero);    // 色設定
            }
  
            ObjectSetString(0,obj_name,OBJPROP_TEXT,DoubleToString(dPips,1));   // 表示するテキスト
  
            // ticket bango check, ticket bango ni soutou suru text wo sagasu areba skip
            // nakereba tsukuru
            // pips wo get
            // profit wo get
            // color set
          } // bActive
        }
      }
    }
  }
  
  // show total pips
  //commision_total
  obj_name = "TotalPIPS";
  if(ObjectFind(0, obj_name) < 0){
    // not found
    ObjectCreate(0,obj_name, OBJ_TEXT, 0, iTime(NULL,0,0), iClose(NULL,0,0));  //iTime(NULL,0,i), 
    ObjectSetInteger(0,obj_name,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
    //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態
    //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
    // オブジェクトバインディングのアンカーポイント設定
  }
  //--- set text font
  ObjectSetString(0,obj_name,OBJPROP_FONT,FontNamePipsTotal);
  //--- set font size
  ObjectSetInteger(0, obj_name,OBJPROP_FONTSIZE,FontSize);
  ObjectSetString(0,obj_name,OBJPROP_TEXT,"Total  "+DoubleToString(dPips_total,1));   // 表示するテキスト

  //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
  if(0 < profit_total){
    if(profit_total + commision_total < 0){
      // color spread
      ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorSpread);    // 色設定
      // color profit
    }else{
      ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorPlus);    // 色設定
    }
  }else{
    // color minus
    ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorMinus);    // 色設定
  }

  if(profit_total == 0){
    ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorZero);    // 色設定
  }
          
  //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態

  //ObjectSetString(0,obj_name,OBJPROP_TEXT,DoubleToString(Value0,3));
  LocationX_abs = PosXPipsTotal;
  LocationY_abs = PosYPipsTotal;
  ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);  

  if(CornerPipsTotal == CORNER_RIGHT_LOWER){
    LocationX_abs=chart_width - PosXPipsTotal;
    LocationY_abs=chart_height - PosYPipsTotal;
    ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);  
  }else if(CornerPipsTotal == CORNER_RIGHT_UPPER){
    LocationX_abs=chart_width - PosXPipsTotal;
    ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);  
  }else if(CornerPipsTotal == CORNER_LEFT_LOWER){
    LocationY_abs=chart_height - PosYPipsTotal;
    ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);  
  }

  ChartXYToTimePrice(0, LocationX_abs, LocationY_abs, window_num, dt, price);
  ObjectMove(0, obj_name, 0,dt, price);

  //        if(MAGIC_NUM_thisEA == OrderMagicNumber()){
  //        OrderClose(OrderTicket(),OrderLots(),0, 20, clrNONE);

  int obj_total= ObjectsTotal(0,0,-1);
  //int Get_Arrow_Code;

  //Print ("Object_total = " + obj_total);

  if(bPipsAlign){
    for (int k= obj_total; k>=0; k--){
      string name= ObjectName(0,k, 0, -1);
      //Print ("Object_name 000 = " + name + " type" + ObjectType(name));
      //if(0<=StringFind(StringSubstr(name,0,4),"PIPS")){
      //   Print ("Object_name 001 = " + name);
      //}
      //Get_Arrow_Code = ObjectGetInteger(0,name,OBJPROP_ARROWCODE, 0);
      //if(OBJ_TEXT == ObjectType(name)){  //ObjectGetInteger (0, name, OBJPROP_TYPE)
      if(OBJ_TEXT == ObjectGetInteger (0, name, OBJPROP_TYPE)){  //ObjectGetInteger (0, name, OBJPROP_TYPE)
        if(0<=StringFind(StringSubstr(name,0,4),"PIPS")){
          //Print ("Object_name 002 = " + name);
          //ObjectDelete(name);
          if(LocationX < max_x && LocationY < max_y){
            LocationX_abs = LocationX;
            LocationY_abs = LocationY;
            if(Corner == CORNER_RIGHT_LOWER){
              LocationX_abs=chart_width - LocationX;
              LocationY_abs=chart_height - LocationY;
            }else if(Corner == CORNER_RIGHT_UPPER){
              LocationX_abs=chart_width - LocationX;
            }else if(Corner == CORNER_LEFT_LOWER){
              LocationY_abs=chart_height - LocationY;
            }

            ChartXYToTimePrice(0, LocationX_abs, LocationY_abs, window_num, dt, price);
            //ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
            ObjectMove(0, name, 0,dt, price);
            //ObjectSet(name, OBJPROP_XDISTANCE, LocationX);
	         // ObjectSet(name, OBJPROP_YDISTANCE, LocationY);
	         //ObjectSet(name, OBJPROP_CORNER, Corner);
            LocationY = LocationY + diff_y;
            if(max_y < LocationY){
              LocationY = offset_y;
              LocationX = LocationX + diff_x;
            }
          }
        }
      }
    }
  }

}
//+------------------------------------------------------------------+
int OnCalculate( const int       rates_total
                   , const int       prev_calculated
                   , const datetime &time       []
                   , const double   &open       []
                   , const double   &high       []
                   , const double   &low        []
                   , const double   &close      []
                   , const long     &tick_volume[]
                   , const long     &volume     []
                   , const int      &spread     []
                   )
{
//---
  UpdatePipsTextMQL4();
  return  ( rates_total );
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void    OnTimer()
{
  int LocationX=offset_x;
  int LocationY=offset_y;
  int LocationX_abs;
  int LocationY_abs;
  datetime dt;
  double price, price_diff, commision_total, profit_total;
  int window_num= 0;
  string obj_name;
  double dPips,dPips_total;
  //bool bActive = false;
  
  int obj_total;

  //obj_total= ObjectsTotal(0,0, OBJ_TEXT);
  obj_total= ObjectsTotal(0,0, -1);
  for (int k= obj_total; k>=0; k--){
    obj_name= ObjectName(0,k);
    int obj_type = ObjectType(obj_name);
    //Print ("name name:"+name);

    if( (obj_type == OBJ_LABEL || obj_type == OBJ_TEXT) &&  0<=StringFind(StringSubstr(obj_name,0,5),"PIPS ")){
      string ticket_str = StringSubstr(obj_name,5,-1);
      //Print ("ticket str:"+ticket_str);
      int ticket_number = StringToInteger(ticket_str);
      if(OrderSelect(StringToInteger(ticket_str), SELECT_BY_TICKET, MODE_HISTORY)){
      //if(PositionSelectByTicket(ticket_number)){
        //Print ("found order ticket str:"+ticket_str);
        //long position_id = PositionGetInteger(POSITION_IDENTIFIER);
        double open_price = OrderOpenPrice();
        double close_price = OrderClosePrice();
        //double open_price = PositionGetDouble( POSITION_PRICE_OPEN );
        //HistorySelectByPosition( position_id );
        //double close_price = OrderPositionGetDouble( POSITION_PRICE_CURRENT );
        if(0 == close_price){
          break;
        }
        int order_type = OrderType();
        //int order_type = PositionGetInteger( POSITION_TYPE );
        price_diff = open_price-close_price; 
        if(order_type == OP_BUY || order_type == OP_BUYLIMIT || order_type == OP_BUYSTOP){
        //if(order_type == POSITION_TYPE_BUY){
          price_diff = -price_diff;
        }
        dPips = (price_diff/_Point)/10;

        ObjectSetString(0,obj_name,OBJPROP_FONT,FontName);
        //--- set font size
        ObjectSetInteger(0, obj_name,OBJPROP_FONTSIZE,FontSize);
        ObjectSetInteger(0,obj_name,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
        //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態
        //ObjectSetInteger(0,obj_name,OBJPROP_ALIGN,ALIGN_LEFT);
        // オブジェクトバインディングのアンカーポイント設定
        ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);  

        if(0 < OrderProfit()){
        //if(0 < PositionGetDouble( POSITION_PROFIT )){
          if(OrderProfit() + OrderCommission() < 0){
          //if(PositionGetDouble( POSITION_PROFIT ) + PositionGetDouble( )OrderCommission() < 0){
            // color spread
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorSpread);    // 色設定
            // color profit
          }else{
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorPlus);    // 色設定
          }
        }else{
          // color minus
          ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorMinus);    // 色設定
        }

        if(NormalizeDouble(dPips,1) == 0){
          ObjectSetInteger(0,obj_name,OBJPROP_COLOR,PipsColorZero);    // 色設定
        }
        
        //ObjectSetInteger(0,obj_name,OBJPROP_SELECTED,true);      // オブジェクトの選択状態

        ObjectSetString(0,obj_name,OBJPROP_TEXT,DoubleToString(dPips,1));   // 表示するテキスト

      }
    }else if( (obj_type == OBJ_TREND) &&  0<=StringFind(StringSubstr(obj_name,0,9),"TradeLine")){
      string ticket_str = StringSubstr(obj_name,9,-1);
      //Print ("ticket str:"+ticket_str);
      if(OrderSelect(StringToInteger(ticket_str), SELECT_BY_TICKET, MODE_HISTORY)){
        //Print ("found order ticket str:"+ticket_str);

        double open_price = OrderOpenPrice();
        double close_price = OrderClosePrice();

        datetime open_time = OrderOpenTime();
        datetime close_time = OrderCloseTime();
        int order_type = OrderType();
        if(0 < close_price &&open_time < close_time ){
          ObjectMove(0, obj_name, 0, open_time, open_price);
          ObjectMove(0, obj_name, 1, close_time, close_price);
        }
      }
    }
  }  
  Align_Step_By_Step();


}
//+-------------------------------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
  if(id == CHARTEVENT_CHART_CHANGE){
    int wHandle = SendMessageW(ParentWinHandle,WM_MDIGETACTIVE,0,0);
    //Print ("main ce cli wHandle "+wHandle);
    if(wHandle != ThisWinHandle){
      // if not activated
      return;
    }else{
      chart_height=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
      chart_width=ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
      ChartRedraw(0);
    }
  }
}
//++//

//+-------------------------------------------------------------------------------------------+
//| reset to original                                                                         |
//+-------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+-------------------------------------------------------------------------------------------+
//| My own Program De-initialization                                                                 |
//+-------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void Align_Step_By_Step(){

  bool bActive=true;
  if(false == ChartGetInteger(0,CHART_BRING_TO_TOP)){
    // Do Something...
    // chart is not active
    bActive=false;
    return;
  }

  datetime dt;
  double price, price_diff, commision_total, profit_total;
  int window_num= 0;
  int obj_total= ObjectsTotal(0,0,-1) ;
  int k=obj_total-gk;
  if(0<=k){
    string name= ObjectName(0,k);
    //Print ("Object_name 000 = " + name + " type" + ObjectType(name));
    //if(0<=StringFind(StringSubstr(name,0,4),"PIPS")){
    //   Print ("Object_name 001 = " + name);
    //}
    //Get_Arrow_Code = ObjectGetInteger(0,name,OBJPROP_ARROWCODE, 0);
    if(OBJ_TEXT == ObjectType(name) || OBJ_LABEL == ObjectType(name)){
      if(0<=StringFind(StringSubstr(name,0,4),"PIPS")){
        //Print ("Object_name 002 = " + name);
        //ObjectDelete(name);
        if(gLocationX < max_x && gLocationY < max_y){
          gLocationX_abs = gLocationX;
          gLocationY_abs = gLocationY;
          if(Corner == CORNER_RIGHT_LOWER){
            gLocationX_abs=chart_width - gLocationX;
            gLocationY_abs=chart_height - gLocationY;
          }else if(Corner == CORNER_RIGHT_UPPER){
            gLocationX_abs=chart_width - gLocationX;
          }else if(Corner == CORNER_LEFT_LOWER){
            gLocationY_abs=chart_height - gLocationY;
          }
  
          if(bActive){
            if(!bUserLabelForIndivi){
              ChartXYToTimePrice(0, gLocationX_abs, gLocationY_abs, window_num, dt, price);
              //ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
              ObjectMove(0, name, 0,dt, price);
            }else{
              ObjectMove(0, name, 0,gLocationX_abs, gLocationY_abs);
            }
          }
          //ObjectSet(name, OBJPROP_XDISTANCE, LocationX);
         // ObjectSet(name, OBJPROP_YDISTANCE, LocationY);
         //ObjectSet(name, OBJPROP_CORNER, Corner);
          gLocationY = gLocationY + diff_y;
          if(max_y < gLocationY){
            gLocationY = offset_y;
            gLocationX = gLocationX + diff_x;
          }
        }
      }
    }
    gk++;
  }else{
    gk=0;
  }
}
