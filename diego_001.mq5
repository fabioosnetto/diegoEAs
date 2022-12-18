//+------------------------------------------------------------------+
//|                                                    diego_001.mq5 |
//|                                            Copyright 2022, FABIO |
//|                                   https://fabioosnetto.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, FABIO"
#property link      "https://fabioosnetto.github.io"
#property version   "1.00"

#include <WINSTON - Library.mqh>

/*
STRATEGY LOGIC:
   --> OUTSIDEBAR.
   --> ACIMA ou ABAIXO da MME 200.
   --> NÍVEL do IFR14.
      - ACIMA da MME 200, COMPRAS; ABAIXO, VENDAS.
      - IFR14 ACIMA de 50, COMPRA; ABAIXO de 50, VENDA.


NEGOCIATION:
   --> Convergência entre MME e IFR, COMPRA ACIMA DA MÁXIMA ou VENDA ABAIXO DA MÍNIMA.
   --> STOP na máxima ou mínima do mesmo candle.
   --> Alvo de 2x1
*/
  
//--- Boolean values for Strategy Logic Conditions 
bool b_outsideBar = false;//true = exists
bool b_movingA    = false;//true = price > mme200
bool b_ifr        = false;//true = ifr14 > 50


//--- Basic Variables
double High[], Low[], Close[];
double Ask, Bid;
double movingA[], ifr[];//indicator
int    h_movingA, h_ifr;//handlers


input int                ma_period        = 200;
input ENUM_MA_METHOD     ma_method        = MODE_EMA;
input ENUM_APPLIED_PRICE ma_appliedPrice  = PRICE_CLOSE;
input int                ifr_period       = 14;
input ENUM_APPLIED_PRICE ifr_appliedPrice = PRICE_CLOSE;
 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- create timer
   EventSetTimer(60);
   
   h_movingA = iMA(_Symbol,  PERIOD_CURRENT, ma_period, 0, ma_method, ma_appliedPrice);
   h_ifr     = iRSI(_Symbol, PERIOD_CURRENT, ifr_period, ifr_appliedPrice);
   
   //--- Check Handlers
   if(InvalidHandle(h_movingA, "h_movingA") ||
      InvalidHandle(h_ifr,     "h_ifr")       )
     {
      return(INIT_FAILED);
     }
   
   //--- Make Arrays As Series
   if(ArrayIsNotSeries(High, "High")     ||
      ArrayIsNotSeries(Low, "Low")       ||
      ArrayIsNotSeries(Close, "Close")   ||
      ArrayIsNotSeries(movingA, "movingA") ||
      ArrayIsNotSeries(ifr, "ifr")     )
     {
      return(INIT_FAILED);
     }
     
     
   Print("EA Initialized with Success!");
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- destroy timer
   EventKillTimer();
   
   //--- release indicators
   IndicatorRelease(h_movingA);
   IndicatorRelease(h_ifr);
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   //---
   
  }


//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   //---
   
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Class for Strategy Logic                                         |
//+------------------------------------------------------------------+
class diego_001
  {
   private:
      //--- Basic Variables
      double High[], Low[], Close[];
      double movingA[], ifr[];
      
      //--- Struct for OutsideBar
      struct str_outsideBar
        {
         bool highest;
         bool lowest;
         bool exists;
        };
      str_outsideBar outsideBar;
      
   public:
      diego_001(void);
      ~diego_001(void);
      
      void copyArrays(double &_High[], double &_Low[], double &_Close[], double &_movingA[], double &_ifr[]);
      
      bool CheckOutsideBar(void);
      bool CheckMovingA(void);
      bool CheckIfr(void);  
  };
  


//+------------------------------------------------------------------+
//| Fucntions Definition                                             |
//+------------------------------------------------------------------+
void diego_001::diego_001(){
   
  }

//--- Initialize Private Arrays
void diego_001::copyArrays(double &_High[],double &_Low[],double &_Close[],double &_movingA[],double &_ifr[]){
   ArrayCopy(High, _High);
   ArrayCopy(Low, _Low);
   ArrayCopy(Close, _Close);
   ArrayCopy(movingA, _movingA);
   ArrayCopy(ifr, _ifr);
  }

//--- Check Outsidebar
bool diego_001::CheckOutsideBar(void){

   outsideBar.highest = High[1] > High[2];//verify if high is greater than previous
   outsideBar.lowest  = Low[1]  < Low[2];//verify if low is less than previous
   outsideBar.exists  = outsideBar.highest & outsideBar.lowest;//if both conditions == true, candle is outsidebar
   
   return outsideBar.exists;//return to be processed
  }
  
  
//--- Check Moving Average
bool diego_001::CheckMovingA(void){
   
   bool checker = Close[1] > movingA[1];//check cl > ma = true; otherwise, false
   
   return checker;
  }
  
  
//--- Check RSI (IFR)
bool diego_001::CheckIfr(void){

   bool checker = ifr[1] > 50;//check ifr > 50 = true; otherwise, false
   
   return checker;
  }