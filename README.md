# DayTraderPro

A MetaTrader 5 Expert Advisor (EA) implementing a **snap-back mean-reversion** strategy, using RSI and ADX to identify and trade short-term price reversals.

## Strategy

The EA looks for price extensions away from equilibrium (flagged by RSI) confirmed by trend-strength conditions from ADX, then trades the "snap-back" toward the mean. Built for symbols prone to sharp mean-reverting moves (e.g. XAUUSDm).

## Features

- Automated entry/exit based on RSI + ADX confluence
- Live GUI panel for monitoring and manual control (`DayTraderPro_v7_GUI.mqh`)
- Auto-trading module with directional logic (`DayTraderPro_v7_Auto.mqh`)
- Cross-chart auto-toggle support

## Version

Current: **v7**

Recent work:
- Fixed directional inversion bugs in the auto-trading module
- Resolved GUI panel layout and offset issues
- Fixed indicator handle reuse and invalid-stop errors on XAUUSDm
- Improved auto-toggle reliability across multiple charts

## Setup

1. Copy the `.mq5` and `.mqh` files into your MetaTrader 5 `MQL5/Experts` (and `Include`) folders
2. Restart MT5 or refresh the Navigator panel
3. Drag the EA onto a chart and configure inputs (see below)
4. Enable AutoTrading in MT5

## Inputs

> *(fill in your actual input parameters here - e.g. RSI period, ADX threshold, lot size, stop loss/take profit)*

## Roadmap

- Python ML bridge (pandas, scikit-learn, stable-baselines3, PyZMQ) for a self-learning/adaptive version of the strategy

## Disclaimer

This EA is provided for educational purposes. Trading carries risk of loss - test thoroughly on a demo account before live use.
