# DayTraderPro

**An MT5 Expert Advisor that hunts for the snap.**

Markets overextend, then they snap back. DayTraderPro watches for that overextension using RSI and ADX, then trades the reversal — with a live control panel so you're never flying blind.

![Version](https://img.shields.io/badge/version-v7-blue)
![Platform](https://img.shields.io/badge/platform-MetaTrader%205-orange)
![Language](https://img.shields.io/badge/language-MQL5-red)

---

## The Idea

Most trend-followers lose money in choppy, range-bound conditions — they buy the top and sell the bottom of every fakeout. DayTraderPro does the opposite: it treats extreme RSI readings as *exhaustion*, checks ADX to confirm the market isn't actually trending hard, and trades the reversion back to equilibrium.

It's built and tuned for symbols that whip — XAUUSDm has been the primary testing ground.

## What's in v7

v7 is the most stable release to date. It fixed a nasty set of bugs that plagued earlier versions:

| Problem | Status |
|---|---|
| Auto-trading module firing in the wrong direction | Fixed |
| GUI panel layout breaking at different resolutions/offsets | Fixed |
| Indicator handles leaking / getting reused incorrectly | Fixed |
| Invalid stop errors on XAUUSDm | Fixed |
| Auto-toggle unreliable across multiple charts | Fixed |

## Architecture
DayTraderPro_v7.mq5 -> main EA entry point
DayTraderPro_v7_Auto.mqh -> automated trading logic (entries, exits, direction)
DayTraderPro_v7_GUI.mqh -> on-chart control panel


The GUI panel isn't cosmetic — it's a live control surface. You can monitor state and toggle auto-trading per chart without touching the Expert Advisor settings.

## Getting Started

1. Drop the `.mq5` and `.mqh` files into `MQL5/Experts` and `MQL5/Include` in your MT5 data folder
2. Refresh the Navigator panel (or restart MT5)
3. Attach the EA to a chart
4. Enable **AutoTrading** in the toolbar
5. Configure inputs (below) to match your risk profile

## Inputs

> *(fill in: RSI period, ADX threshold, lot sizing, stop loss / take profit rules)*

## What's Next

The roadmap points toward making this self-learning rather than rule-based:

- Python bridge via PyZMQ for live communication with the EA
- `pandas` / `scikit-learn` for feature engineering on historical snap-back events
- `stable-baselines3` to explore reinforcement learning for adaptive entries/exits

The goal: an EA that doesn't just execute a fixed rule set, but learns which snap-backs are worth taking.

## Disclaimer

This is a personal trading research project, not financial advice. Backtest and demo-test extensively before considering live capital. Past performance of any strategy is not indicative of future results.
