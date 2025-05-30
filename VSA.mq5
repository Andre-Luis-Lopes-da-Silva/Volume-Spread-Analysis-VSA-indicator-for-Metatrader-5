//+------------------------------------------------------------------+
//|                           Volume Spread Analysis (VSA) indicator |
//|                                           Von Schelzen Investing |
//|                     https://github.com/Andre-Luis-Lopes-da-Silva |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   5

// Configuração para cada tipo de sinal
#property indicator_label1  "NoDemand"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  2

#property indicator_label2  "NoSupply"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrBlue
#property indicator_width2  2

#property indicator_label3  "ClimaxUp"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrGreen
#property indicator_width3  2

#property indicator_label4  "ClimaxDown"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrOrange
#property indicator_width4  2

#property indicator_label5  "StopVol"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrPurple
#property indicator_width5  2

input int MA_Period = 20;
input double ArrowOffset = 20;

// Buffers para cada sinal
double NoDemandBuffer[];
double NoSupplyBuffer[];
double ClimaxUpBuffer[];
double ClimaxDownBuffer[];
double StopVolBuffer[];
double VolumeMA[];

//+------------------------------------------------------------------+
//| Initialization                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   // Configuração dos buffers
   SetIndexBuffer(0, NoDemandBuffer);
   SetIndexBuffer(1, NoSupplyBuffer);
   SetIndexBuffer(2, ClimaxUpBuffer);
   SetIndexBuffer(3, ClimaxDownBuffer);
   SetIndexBuffer(4, StopVolBuffer);
   SetIndexBuffer(5, VolumeMA, INDICATOR_CALCULATIONS);
   
   // Configuração do desenho para cada sinal
   for(int i=0; i<5; i++)
   {
      PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_ARROW);
      PlotIndexSetInteger(i, PLOT_ARROW, 234);
      PlotIndexSetInteger(i, PLOT_ARROW_SHIFT, 0);
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   }
   
   // Inicialização
   ArrayInitialize(NoDemandBuffer, EMPTY_VALUE);
   ArrayInitialize(NoSupplyBuffer, EMPTY_VALUE);
   ArrayInitialize(ClimaxUpBuffer, EMPTY_VALUE);
   ArrayInitialize(ClimaxDownBuffer, EMPTY_VALUE);
   ArrayInitialize(StopVolBuffer, EMPTY_VALUE);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Main calculation function                                        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < MA_Period)
      return(0);
   
   // Cálculo do ponto de início (declaração de 'start' adicionada)
   int start = (prev_calculated > 1) ? prev_calculated - 1 : MA_Period;
   start = MathMax(start, 0);
   
   // Cálculo da média de volume
   for(int i = start; i < rates_total && !IsStopped(); i++)
   {
      double sum = 0;
      for(int j = 0; j < MA_Period && (i-j) >= 0; j++)
         sum += (double)tick_volume[i-j];
      VolumeMA[i] = sum / MA_Period;
   }

   // Detecção de padrões VSA
   for(int i = start; i < rates_total && !IsStopped(); i++)
   {
      // Reset todos os buffers
      NoDemandBuffer[i] = EMPTY_VALUE;
      NoSupplyBuffer[i] = EMPTY_VALUE;
      ClimaxUpBuffer[i] = EMPTY_VALUE;
      ClimaxDownBuffer[i] = EMPTY_VALUE;
      StopVolBuffer[i] = EMPTY_VALUE;
      
      // Declaração das variáveis que estavam faltando
      double range = high[i] - low[i];
      double prev_range = (i > 0) ? (high[i-1] - low[i-1]) : range;
      double close_rel = (range > 0) ? (close[i] - low[i]) / range : 0.5;
      double offset = ArrowOffset * _Point;
      
      // Lógica de sinais
      if(tick_volume[i] < VolumeMA[i]*0.5 && range < prev_range)
      {
         //NoDemandBuffer[i] = low[i] - offset;
         NoDemandBuffer[i] = low[i] - (offset*100);
      }
      else if(tick_volume[i] < VolumeMA[i]*0.5 && close_rel < 0.3)
      {
         //NoSupplyBuffer[i] = high[i] + offset;
         NoSupplyBuffer[i] = high[i] + (offset*100);
      }
      else if(tick_volume[i] > VolumeMA[i]*1.5 && close_rel > 0.7)
      {
         //ClimaxUpBuffer[i] = high[i] + offset;
         ClimaxUpBuffer[i] = high[i] + (offset*100);
      }
      else if(tick_volume[i] > VolumeMA[i]*1.5 && close_rel < 0.3)
      {
         //ClimaxDownBuffer[i] = low[i] - offset;
         ClimaxDownBuffer[i] = low[i] - (offset*100);
      }
      else if(tick_volume[i] > VolumeMA[i]*1.2 && range < prev_range*0.5)
      {
         StopVolBuffer[i] = (high[i] + low[i])/2;
      }
   }
   
   return(rates_total);
}