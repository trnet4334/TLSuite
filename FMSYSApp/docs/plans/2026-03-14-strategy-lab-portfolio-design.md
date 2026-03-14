# Strategy Lab & Portfolio — Design Document

**Date:** 2026-03-14
**Scope:** Full replacement of StrategyLabView and PortfolioView stubs; new Strategy SwiftData model; context-aware sidebar bottom card.

---

## Goal

Build Strategy Lab (strategy card grid + Inspector panel with code editor + parameters) and Portfolio (KPI cards + performance chart + positions table + allocation donut + risk bars). Both follow the HTML prototypes in `strategy_lab.html` and `portfolio.html` and the ARCHITECTURE.md 3-column NavigationSplitView pattern.

---

## Section 1: Strategy Lab

### `Strategy` @Model (new file: `Core/Models/Strategy.swift`)

```swift
public enum StrategyStatus: String, Codable, CaseIterable {
    case active, paused, drafting, archived
}

@Model public final class Strategy {
    public var id: UUID
    public var userId: String
    public var name: String
    public var indicatorTag: String        // e.g. "EMA Cross + RSI"
    public var statusRaw: String           // StrategyStatus raw value
    public var logicCode: String           // plain-text pseudo-code
    public var emaFastPeriod: Int          // default 9
    public var emaSlowPeriod: Int          // default 21
    public var riskMgmtEnabled: Bool
    public var trailingStopEnabled: Bool
    public var winRate: Double?            // nil until backtested
    public var profitFactor: Double?
    public var createdAt: Date
    public var updatedAt: Date

    public var status: StrategyStatus { get/set via statusRaw }
}
```

Seeded with 3 sample strategies on first launch (UserDefaults flag `"fmsys.strategySeeded"`):
1. "Trend Follower Pro" — "EMA Cross + RSI" — `.active` — winRate 0.642, profitFactor 2.14
2. "Mean Reversion V2" — "Bollinger Band Scalp" — `.paused` — winRate 0.588, profitFactor 1.45
3. "Volatility Breakout" — "ATR Expansion" — `.drafting` — winRate nil, profitFactor nil

### `StrategyRepository` (new: `Core/Repositories/StrategyRepository.swift`)

SwiftData CRUD:
- `fetchAll(userId:) async throws -> [Strategy]`
- `fetch(id:) async throws -> Strategy?`
- `insert(_:) async throws`
- `update(_:) async throws`
- `delete(id:) async throws`

### `StrategyViewModel` (`@Observable`, new: `Features/StrategyLab/StrategyViewModel.swift`)

- `strategies: [Strategy]`
- `selectedStrategy: Strategy?`
- `func load() async`
- `func add()` — inserts new `.drafting` strategy, selects it
- `func update(_ strategy: Strategy) async`
- `func delete(id: UUID) async`
- `func runBacktest(strategy: Strategy)` — stub, posts `.info` toast "Backtest queued"

### Views

#### `StrategyLabView` (full rewrite)

```
┌─────────────────────────────────────────┬──────────────────┐
│ Strategy Lab                 [New Strat] │   Inspector       │
│ Develop, test, optimize...               │                   │
│                                          │ Strategy Logic    │
│  ┌──────────────┐  ┌──────────────┐     │ [dark code block] │
│  │ Trend Follow │  │ Mean Revert  │     │                   │
│  │ EMA Cross    │  │ Bollinger    │     │ Parameters        │
│  │ [Active]     │  │ [Paused]     │     │ EMA Fast  [9]─── │
│  │ sparkline    │  │ sparkline    │     │ EMA Slow [21]─── │
│  │ WR 64% PF2.1 │  │ WR 58% PF1.4│     │ Risk Mgmt [ON]   │
│  └──────────────┘  └──────────────┘     │ Trailing  [OFF]  │
│  ┌──────────────┐                        │                   │
│  │ Volatility   │  (empty slot)          │ [Run Backtest]   │
│  │ ATR Expan.   │                        │                   │
│  │ [Drafting]   │                        └──────────────────┘
│  └──────────────┘
└────────────────────────────────────────────────────────────┘
```

- `HSplitView`: left flex content + right `StrategyInspectorPanel` (320pt)
- Left: `ScrollView` → `VStack` with header + `LazyVGrid(columns: 2)`
- Empty state: `biotech` SF Symbol (48pt muted) + "Create Your First Strategy" + "New Strategy" CTA

#### `StrategyCard`

- Name (13pt bold), indicator tag (10pt uppercase muted)
- Status badge: `.active` → fmsPrimary/10 text fmsPrimary; `.paused` → slate; `.drafting` → fmsWarning/10 text fmsWarning; `.archived` → muted
- Sparkline: Swift Charts `LineMark`, 200×48pt, color = fmsPrimary (active) / fmsMuted (paused) / fmsWarning dashed (drafting)
- Metrics below divider: Win Rate + Profit Factor (or "Exp. Win Rate" + "RR Ratio" for drafting)
- Selected: `.overlay(RoundedRectangle.stroke(Color.fmsPrimary.opacity(0.4), lineWidth: 1.5))`

#### `StrategyInspectorPanel`

- Header: "Inspector" (13pt bold) + `info.circle` icon
- **Strategy Logic section:** `TextEditor` with monospace font, `Color(hex: "#1e1e1e")` background, 12pt, rounded corners
- **Parameters section:**
  - EMA Fast Period: `Slider(value:in:)` 1–50, integer, label + value display
  - EMA Slow Period: `Slider(value:in:)` 1–100
  - Risk Management: `Toggle`
  - Trailing Stop: `Toggle`
- **Run Backtest button:** blue (`Color.info` / `#58a6ff`), full width, calls `viewModel.runBacktest`
- No selection state: "Select a strategy to inspect" (muted, centered)

### Sidebar Bottom Card (Strategy Lab)

```
┌────────────────────────────────┐
│ ACTIVE LABS            (green) │
│ 4 Running                      │
│ 💾 82% CPU Usage               │
└────────────────────────────────┘
```

`fmsPrimary/10` gradient bg, `fmsPrimary` border. Count computed from `.active` strategies.
CPU is a hardcoded stub.

---

## Section 2: Portfolio

### Data Layer — all stubs, no SwiftData

#### `PortfolioRange` enum

```swift
public enum PortfolioRange: String, CaseIterable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case ytd = "YTD"
    case all = "ALL"
}
```

#### `PortfolioPosition` struct

```swift
public struct PortfolioPosition: Identifiable {
    public let id: String           // symbol
    public let name: String
    public let qty: Double
    public let lastPrice: Double
    public let marketValue: Double
    public let unrealizedPnL: Double
}
```

#### `AllocationSlice` struct

```swift
public struct AllocationSlice: Identifiable {
    public let id: String           // name
    public let name: String
    public let percent: Double
    public let color: Color
}
```

#### `PortfolioViewModel` (`@Observable`)

- `totalNetLiquidity: Double` — 142_500.42
- `dailyPnL: Double` — 1_842.20
- `buyingPower: Double` — 58_210.15
- `selectedRange: PortfolioRange` — default `.ytd`
- `performanceCurve: [EquityPoint]` — 5 stub points spanning YTD
- `positions: [PortfolioPosition]` — AAPL, MSFT, BTC
- `allocation: [AllocationSlice]` — Stocks/ETFs/Crypto/Forex with design token colors
- `betaWeighting: Double` — 1.12
- `marginUtilization: Double` — 0.32

### Views

#### `PortfolioView` (full rewrite)

```
┌──────────────────────────────────────┬──────────────────┐
│ [Net Liq]  [Daily P/L]  [Buy Power]  │ Asset Allocation │
│                                      │   [Donut Chart]  │
│ Portfolio Performance   [1M][3M][YTD]│                  │
│ [AreaMark + LineMark chart, 220pt]   │ Stocks  45.2%    │
│ Jan  Feb  Mar  Apr  May              │ ETFs    24.8%    │
│                                      │ Crypto  19.5%    │
│ Current Positions      [View All →]  │ Forex   10.5%    │
│ ┌──────┬─────┬──────┬──────┬──────┐ │                  │
│ │Symbol│ Qty │Price │MktVal│ P/L  │ │ Risk Exposure    │
│ │AAPL  │ 150 │$192  │$28k  │+$1.4k│ │ Beta   1.12 ▓▓▓ │
│ │MSFT  │  45 │$425  │$19k  │+$682 │ │ Margin  32% ▓▓  │
│ │BTC   │0.82 │$64k  │$52k  │-$412 │ │                  │
│ └──────┴─────┴──────┴──────┴──────┘ └──────────────────┘
└──────────────────────────────────────────────────────────┘
```

- `HSplitView`: left `ScrollView` (flex) + right `PortfolioInspectorPanel` (320pt)
- KPI cards: 3-column `HStack`, each card shows label (10pt uppercase) + value (22pt extrabold)
  - Daily P/L positive → fmsPrimary, negative → fmsLoss
- Performance chart: Swift Charts `AreaMark` (gradient fill fmsPrimary 0→0.15) + `LineMark` (2pt stroke), height 220pt
- Range picker: button row with bg highlight (same pattern as DashboardView)
- Positions: `List` rows — symbol badge (7pt ticker, colored bg square 28pt), name, right-aligned numeric columns; unrealizedPnL colored by sign

#### `PortfolioInspectorPanel`

- **Asset Allocation:** `AllocationDonutView` (custom `Path`/`Canvas`, 160pt diameter) with center label "$142k / Total Assets", legend below
- `AllocationDonutView`: draws 4 arcs using `Path`, each arc proportional to `percent`, gap of 2° between segments, `strokeStyle(lineWidth: 8)`
- **Risk Exposure:** two labeled progress bars (GeometryReader pattern from PsychAnalyticsSection)
  - Beta Weighting: `Color.info` fill, value label "1.12"
  - Margin Utilization: `fmsPrimary` fill, value label "32%"

### Sidebar Bottom Card (Portfolio)

```
┌────────────────────────────────┐
│ TOTAL EQUITY          (emerald)│
│ $142,500.42                    │
│ ↑ +12.5% MTD                  │
└────────────────────────────────┘
```

`Color.fmsPrimary/10` gradient bg, `fmsPrimary` border. Values from `PortfolioViewModel`.

---

## Section 3: Sidebar Context Card

`SidebarView` already receives `selectedScreen` via binding. Add a `@ViewBuilder` helper:

```swift
@ViewBuilder
private func bottomCard(for screen: AppScreen) -> some View {
    switch screen {
    case .strategyLab: StrategyLabSidebarCard(viewModel: strategyViewModel)
    case .portfolio:   PortfolioSidebarCard(viewModel: portfolioViewModel)
    default:           EquitySidebarCard()   // existing
    }
}
```

`SidebarView` will need `StrategyViewModel` and `PortfolioViewModel` injected (or created as `@State` inside).

---

## Section 4: File Map

### New
| File | Purpose |
|---|---|
| `Core/Models/Strategy.swift` | `Strategy` @Model + `StrategyStatus` enum |
| `Core/Repositories/StrategyRepository.swift` | SwiftData CRUD for Strategy |
| `Features/StrategyLab/StrategyViewModel.swift` | Strategy list + CRUD + selection |
| `Features/StrategyLab/Views/StrategyLabView.swift` | Full rewrite |
| `Features/StrategyLab/Views/StrategyCard.swift` | Card with sparkline + metrics |
| `Features/StrategyLab/Views/StrategyInspectorPanel.swift` | Logic + parameters + Run Backtest |
| `Features/Portfolio/PortfolioViewModel.swift` | Stub data + range switching |
| `Features/Portfolio/Views/PortfolioView.swift` | Full rewrite |
| `Features/Portfolio/Views/PortfolioInspectorPanel.swift` | Donut + risk bars |
| `Tests/FMSYSAppTests/StrategyRepositoryTests.swift` | SwiftData CRUD tests |
| `Tests/FMSYSAppTests/StrategyViewModelTests.swift` | Add/update/delete/selection |
| `Tests/FMSYSAppTests/PortfolioViewModelTests.swift` | KPI accessors + allocation |

### Modified
| File | Change |
|---|---|
| `App/SidebarView.swift` | Context-aware bottom card switch |
| `App/MainAppView.swift` | Pass `modelContainer` to StrategyLabView; inject ViewModels |
| `Package.swift` | No change — Strategy uses same schema |

---

## Out of Scope

- Real backtest execution (stub toast only)
- Live market data for positions (stubs only)
- Position creation/editing UI
- Strategy sharing or export
- Archived strategy management
- `StrategyDTOs` / remote sync for strategies
