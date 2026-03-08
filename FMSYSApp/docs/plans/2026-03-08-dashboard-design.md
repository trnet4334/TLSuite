# Dashboard Design

**Date:** 2026-03-08

## Decision Summary

- Stat cards (6) + equity curve chart
- Dashboard slides in as a sheet from a toolbar icon on the Journal
- Equity curve defaults to 30d with a 7D / 30D / 90D / All picker

## Architecture

**MVVM (Approach B)** — `DashboardViewModel` (@Observable) receives `[Trade]` and exposes pre-computed properties. Matches existing pattern.

## DashboardViewModel

Takes `[Trade]`, exposes:

| Property | Type | Description |
|---|---|---|
| `totalPnL` | `Double` | Sum of `(exitPrice - entryPrice) × direction × positionSize` for closed trades |
| `winRate` | `Double` | wins / closed trades (0–1) |
| `avgRR` | `Double` | avg `(takeProfit − entry) / (entry − stopLoss)` across all trades |
| `totalTrades` | `Int` | Total trade count |
| `bestStreak` | `Int` | Longest consecutive winning run |
| `currentStreak` | `Int` | Current win/loss streak (positive = wins, negative = losses) |
| `equityCurve(range:)` | `[EquityPoint]` | Cumulative P&L per day, filtered by range |

`EquityPoint`: `{ date: Date, value: Double }`

`DashboardRange`: `enum { case sevenDays, thirtyDays, ninetyDays, allTime }`

## DashboardView

Scrollable `VStack`:
1. **6-card grid** (3×2) — Total P&L, Win Rate, Avg R:R, Total Trades, Best Streak, Current Streak
2. **Segmented picker** — 7D / 30D / 90D / All
3. **Swift Charts line chart** — cumulative P&L, green fill above zero / red below

Presented as `.sheet` from a chart icon (`chart.line.uptrend.xyaxis`) in the Journal toolbar.

## Design Tokens

- Positive P&L / wins: `Color.fmsPrimary` (#13ec80)
- Negative P&L / losses: `Color.fmsLoss` (#ff5f57)
- Card background: `Color.fmsSurface` (#1C1C1E)
- Background: `Color.fmsBackground` (#111113)

## File Plan

| File | Location |
|---|---|
| `DashboardViewModel.swift` | `Features/Dashboard/` |
| `DashboardView.swift` | `Features/Dashboard/Views/` |
| `StatCardView.swift` | `Features/Dashboard/Views/` |
| `DashboardViewModelTests.swift` | `Tests/FMSYSAppTests/` |

## Testing

All stat computations tested via TDD on `DashboardViewModel` using synthetic `[Trade]` arrays. No UI tests needed for this phase.
