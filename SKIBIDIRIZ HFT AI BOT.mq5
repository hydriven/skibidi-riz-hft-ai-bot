// Wayne HFT AI BOT (Dark Mode + Dynamic Panel + Skibidiriz Background + Flashing Trading Status)
#include <Trade/Trade.mqh>
CTrade trade;

//--- Inputs
input double LotSize = 0.01;
input int FastMA = 5;
input int SlowMA = 20;
input ENUM_TIMEFRAMES Timeframe = PERIOD_M1;
input double MaxSpread = 30;

//--- Globals
bool tradingEnabled = false;
bool hyperMode = false;
string panelName = "HFTPanel";
string backgroundName = "HFTBackground";
string buttonName = "TradeButton";
string modeButtonName = "ModeButton";
string profitLabel = "ProfitLabel";
string spreadLabel = "SpreadLabel";
string lotLabel = "LotLabel";
string statusLabel = "StatusLabel";
int fastMAHandle;
int slowMAHandle;
double todayProfit = 0.0;
bool blinkState = false;

//--- OnInit
int OnInit()
{
    CreateBackground();
    CreateLabels();
    CreateButtons();

    fastMAHandle = iMA(_Symbol, Timeframe, FastMA, 0, MODE_SMA, PRICE_CLOSE);
    slowMAHandle = iMA(_Symbol, Timeframe, SlowMA, 0, MODE_SMA, PRICE_CLOSE);

    if (fastMAHandle == INVALID_HANDLE || slowMAHandle == INVALID_HANDLE)
    {
        Print("Failed to create MA handles!");
        return INIT_FAILED;
    }

    EventSetTimer(1); // Update every second
    return INIT_SUCCEEDED;
}

//--- Create background bitmap panel
void CreateBackground()
{
    ObjectCreate(0, backgroundName, OBJ_BITMAP_LABEL, 0, 0, 0);
    ObjectSetInteger(0, backgroundName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, backgroundName, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, backgroundName, OBJPROP_YDISTANCE, 10);

    long width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
    ObjectSetInteger(0, backgroundName, OBJPROP_XSIZE, 220);
    ObjectSetInteger(0, backgroundName, OBJPROP_YSIZE, 250);

    ObjectSetString(0, backgroundName, OBJPROP_BMPFILE, "skibidiriz_panel.bmp"); // Your image file!
}

//--- Create info labels
void CreateLabels()
{
    CreateLabel(statusLabel, 30, 30, "Trading OFF", clrRed);
    CreateLabel(profitLabel, 30, 150, "Profit: 0.0", clrLimeGreen);
    CreateLabel(spreadLabel, 30, 170, "Spread: 0", clrLimeGreen);
    CreateLabel(lotLabel, 30, 190, "Lot: 0.01", clrLimeGreen);
}

//--- Helper to create a label
void CreateLabel(string name, int x, int y, string text, color fontColor)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, name, OBJPROP_COLOR, fontColor);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//--- Create buttons
void CreateButtons()
{
    CreateButton(buttonName, 30, 90, "Start Trading", clrGreen);
    CreateButton(modeButtonName, 30, 120, "Mode: NORMAL", clrDodgerBlue);
}

//--- Helper to create a button
void CreateButton(string name, int x, int y, string text, color bgcolor)
{
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, 140);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, 25);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgcolor);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//--- Chart event (for buttons)
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == buttonName)
        {
            tradingEnabled = !tradingEnabled;
            if (tradingEnabled)
            {
                ObjectSetString(0, buttonName, OBJPROP_TEXT, "Stop Trading");
                ObjectSetInteger(0, buttonName, OBJPROP_BGCOLOR, clrRed);
            }
            else
            {
                ObjectSetString(0, buttonName, OBJPROP_TEXT, "Start Trading");
                ObjectSetInteger(0, buttonName, OBJPROP_BGCOLOR, clrGreen);
            }
        }
        else if (sparam == modeButtonName)
        {
            hyperMode = !hyperMode;
            if (hyperMode)
            {
                ObjectSetString(0, modeButtonName, OBJPROP_TEXT, "Mode: HYPER");
                ObjectSetInteger(0, modeButtonName, OBJPROP_BGCOLOR, clrOrangeRed);
            }
            else
            {
                ObjectSetString(0, modeButtonName, OBJPROP_TEXT, "Mode: NORMAL");
                ObjectSetInteger(0, modeButtonName, OBJPROP_BGCOLOR, clrDodgerBlue);
            }
        }
    }
}

//--- Timer function: blinking + updating live stats
void OnTimer()
{
    double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;

    // Update values
    ObjectSetString(0, profitLabel, OBJPROP_TEXT, "Profit: " + DoubleToString(todayProfit, 2));
    ObjectSetString(0, spreadLabel, OBJPROP_TEXT, "Spread: " + DoubleToString(spread, 1));
    ObjectSetString(0, lotLabel, OBJPROP_TEXT, "Lot: " + DoubleToString(LotSize, 2));

    // Blinking trading status
    blinkState = !blinkState;
    if (tradingEnabled)
    {
        ObjectSetString(0, statusLabel, OBJPROP_TEXT, blinkState ? "TRADING ON" : "");
        ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrLimeGreen);
    }
    else
    {
        ObjectSetString(0, statusLabel, OBJPROP_TEXT, blinkState ? "TRADING OFF" : "");
        ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrRed);
    }
}

//--- Check Spread
bool CheckSpread()
{
    double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
    return spread <= MaxSpread;
}

//--- Main trading logic
void OnTick()
{
    if (!tradingEnabled)
        return;

    if (!CheckSpread())
        return;

    static datetime lastTradeTime = 0;
    if (!hyperMode && TimeCurrent() == lastTradeTime)
        return;

    double fast[2], slow[2];
    if (CopyBuffer(fastMAHandle, 0, 0, 2, fast) <= 0) return;
    if (CopyBuffer(slowMAHandle, 0, 0, 2, slow) <= 0) return;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    if (fast[0] > slow[0] && fast[1] <= slow[1])
    {
        if (trade.Buy(LotSize, _Symbol, ask, 0, 0))
        {
            todayProfit += PositionGetDouble(POSITION_PROFIT);
            lastTradeTime = TimeCurrent();
            Print("BUY at ", ask);
        }
    }
    else if (fast[0] < slow[0] && fast[1] >= slow[1])
    {
        if (trade.Sell(LotSize, _Symbol, bid, 0, 0))
        {
            todayProfit += PositionGetDouble(POSITION_PROFIT);
            lastTradeTime = TimeCurrent();
            Print("SELL at ", bid);
        }
    }
}
