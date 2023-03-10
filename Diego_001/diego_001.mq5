//+------------------------------------------------------------------+
//|                                                    diego_001.mq5 |
//|                                 Copyright 2022, Fabio O.S. Netto |
//|                                   https://fabioosnetto.github.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, FABIO"
#property link      "https://fabioosnetto.github.io"
#property version   "1.00"

#include <WINSTON - Library.mqh>
#include <negotiation.mqh>
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

//--- Struct For Negotiation
struct negotiation
  {
   ENUM_TYPE_ORDER type;
   int             deviation;//to set above/below candle (on trade)
   double          price;
   double          sl;
   double          tp;
   bool            allowed;
  };
  
//--- Boolean values for Strategy Logic Conditions 
bool b_outsideBar = false;//true = exists
bool b_movingA    = false;//true = price > mme200
bool b_ifr        = false;//true = ifr14 > 50


//--- Basic Variables
MqlRates rates[];
double High[], Low[], Close[];
double Ask, Bid;
double movingA[], ifr[];//indicator
int    h_movingA, h_ifr;//handlers


//--- INPUTS
input ulong                   EAMagicNumber    =               314159;//EA Magic Number
input ENUM_ORDER_TYPE_FILLING OrderTypeFilling = ORDER_FILLING_RETURN;//Order Type Filling
input ulong                   OrderDeviation   =                   10;//Order Deviation - Points
input int                     devi_pts         =                    5;//Deviation above/below candle (on trade)
input int                     ma_period        =                  200;//MA Period
input ENUM_MA_METHOD          ma_method        =             MODE_EMA;//MA Method
input ENUM_APPLIED_PRICE      ma_appliedPrice  =          PRICE_CLOSE;//MA Applied Price
input int                     ifr_period       =                   14;//IFR Period
input ENUM_APPLIED_PRICE      ifr_appliedPrice =          PRICE_CLOSE;//IFR Applied Price
 
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
   if(ArrayIsNotSeries(rates,   "rates")   ||
      ArrayIsNotSeries(High,    "High")    ||
      ArrayIsNotSeries(Low,     "Low")     ||
      ArrayIsNotSeries(Close,   "Close")   ||
      ArrayIsNotSeries(movingA, "movingA") ||
      ArrayIsNotSeries(ifr,     "ifr")       )
     {
      return(INIT_FAILED);
     }
   
   
   //--- Set Trade Configurations  
   trade.SetExpertMagicNumber(EAMagicNumber);
   trade.SetTypeFilling(OrderTypeFilling);
   trade.SetDeviationInPoints(OrderDeviation);
    
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
   //--- Initialize Basic Variables
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 4, rates);
   CopyHigh(_Symbol,  PERIOD_CURRENT, 0, 4, High);
   CopyLow(_Symbol,   PERIOD_CURRENT, 0, 4, Low);
   CopyClose(_Symbol, PERIOD_CURRENT, 0, 4, Close);
   
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   CopyBuffer(h_movingA, 0, 0, 4, movingA);
   CopyBuffer(h_ifr,     0, 0, 4, ifr);
   
   //--- Initialize Negotiation Struct
   negotiation trading;
   trading.type      = NONE;
   trading.deviation = devi_pts;
   trading.price     = 0.0;
   trading.allowed   = false;
  
   //--- Manipulating 'diego_001' Class
   diego_001 logic;
   
   logic.copyArrays(High, Low, Close, movingA, ifr);

   b_outsideBar = logic.CheckOutsideBar();
   b_movingA    = logic.CheckMovingA();
   b_ifr        = logic.CheckIfr();
  
   trading.allowed = b_outsideBar;
   b_movingA && b_ifr? trading.type = BUY : (!b_movingA && !b_ifr? trading.type = SELL : NONE); 
   
   switch(trading.type)
     {
      case NONE: 
         trading.price = 0.0; 
         trading.sl    = 0.0;
         trading.tp    = 0.0;
         break;
      
      case BUY:  
         trading.price = High[1] + trading.deviation; 
         trading.sl    = Low[1];
         trading.tp    = trading.price + 2*(trading.price - Low[1]);
         break;
      
      case SELL: 
         trading.price = Low[1] - trading.deviation; 
         trading.sl    = High[1];
         trading.tp    = trading.price - 2*(High[1] - trading.price);
         break;
      
      default:
         Print("ERROR - 'tarding.type' says unexpected value.");
         ExpertRemove();
         break;
     }
   
   
   if(isNewCandle(rates)){CancelOrders(EAMagicNumber);}
   if(trading.allowed && Orders(_Symbol) == 0 && isNewCandle(rates))
     {
      SendOrder(trading.type, 1.0, trading.price, _Symbol, trading.sl, trading.tp, 10.0, "Order Sent", false); 
     }
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
      /*diego_001(void);
      ~diego_001(void);*/
      
      void copyArrays(double &_High[], double &_Low[], double &_Close[], double &_movingA[], double &_ifr[]);
      
      bool CheckOutsideBar(void);
      bool CheckMovingA(void);
      bool CheckIfr(void);  
  };
  


//+------------------------------------------------------------------+
//| Fucntions Definition                                             |
//+------------------------------------------------------------------+


//--- Initialize Private Arrays
void diego_001::copyArrays(double &_High[],double &_Low[],double &_Close[],double &_movingA[],double &_ifr[]){
   ArrayCopy(High, _High);
   ArrayCopy(Low, _Low);
   ArrayCopy(Close, _Close);
   ArrayCopy(movingA, _movingA);
   ArrayCopy(ifr, _ifr);
   if(ArrayIsNotSeries(rates,   "rates")   ||
      ArrayIsNotSeries(High,    "High")    ||
      ArrayIsNotSeries(Low,     "Low")     ||
      ArrayIsNotSeries(Close,   "Close")   ||
      ArrayIsNotSeries(movingA, "movingA") ||
      ArrayIsNotSeries(ifr,     "ifr")       )
     {
      ExpertRemove();
     }
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