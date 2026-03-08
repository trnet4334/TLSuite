# Dashboard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Dashboard sheet (triggered from the Journal toolbar) showing 6 stat cards and an equity curve chart.

**Architecture:** `DashboardViewModel` (@Observable) receives `[Trade]` and exposes computed stats. `DashboardView` renders a 6-card grid + Swift Charts line chart. Opened as a `.sheet` from `TradeListView`'s toolbar.

**Tech Stack:** Swift Testing (`@Test`, `#expect`, `@Suite(.serialized)`), SwiftData in-memory container for test fixtures, Swift Charts (`import Charts`), `@Observable`.

---

### Task 1: Supporting types — `DashboardRange` + `EquityPoint`

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift`
- Create: `FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/FMSYSAppTests/DashboardViewModelTests.swift
import Testing
import SwiftData
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    struct DashboardViewModelTests {

        // MARK: - Helpers

        private func makeContainer() throws -> (ModelContext, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Trade.self, configurations: config)
            return (container.mainContext, container)
        }

        private func makeTrade(
            context: ModelContext,
            entryPrice: Double,
            exitPrice: Double? = nil,
            direction: Direction = .long,
            stopLoss: Double? = nil,
            takeProfit: Double? = nil,
            positionSize: Double = 1.0,
            exitAt: Date? = nil
        ) -> Trade {
            let sl = stopLoss ?? (direction == .long ? entryPrice - 10 : entryPrice + 10)
            let tp = takeProfit ?? (direction == .long ? entryPrice + 20 : entryPrice - 20)
            let trade = Trade(
                userId: "u1",
                asset: "EUR/USD",
                assetCategory: .forex,
                direction: direction,
                entryPrice: entryPrice,
                stopLoss: sl,
                takeProfit: tp,
                positionSize: positionSize,
                entryAt: Date(),
                exitPrice: exitPrice,
                exitAt: exitAt ?? (exitPrice != nil ? Date() : nil)
            )
            context.insert(trade)
            return trade
        }

        // MARK: - Task 1 test

        @Test func dashboardRangeAllCasesExist() {
            let ranges = DashboardRange.allCases
            #expect(ranges.count == 4)
            #expect(DashboardRange.sevenDays.label == "7D")
            #expect(DashboardRange.thirtyDays.label == "30D")
            #expect(DashboardRange.ninetyDays.label == "90D")
            #expect(DashboardRange.allTime.label == "All")
        }
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter DashboardViewModelTests/dashboardRangeAllCasesExist 2>&1 | tail -10
```
Expected: compile error — `DashboardRange` not found.

**Step 3: Write minimal implementation**

```swift
// Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift
import Foundation

// MARK: - Supporting types

public enum DashboardRange: String, CaseIterable {
    case sevenDays, thirtyDays, ninetyDays, allTime

    public var label: String {
        switch self {
        case .sevenDays:   return "7D"
        case .thirtyDays:  return "30D"
        case .ninetyDays:  return "90D"
        case .allTime:     return "All"
        }
    }

    var days: Int? {
        switch self {
        case .sevenDays:   return 7
        case .thirtyDays:  return 30
        case .ninetyDays:  return 90
        case .allTime:     return nil
        }
    }
}

public struct EquityPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
}

// MARK: - ViewModel stub (will be filled in Task 2+)

import Observation

@Observable
public final class DashboardViewModel {
    public let trades: [Trade]
    public var selectedRange: DashboardRange = .thirtyDays

    public init(trades: [Trade]) {
        self.trades = trades
    }
}
```

**Step 4: Run test to verify it passes**

```bash
swift test --filter DashboardViewModelTests/dashboardRangeAllCasesExist 2>&1 | tail -5
```
Expected: `Test run with 1 test passed.`

**Step 5: Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift \
        FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift
git commit -m "feat: add DashboardRange + EquityPoint types"
```

---

### Task 2: `totalPnL` and `totalTrades`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift`
- Modify: `FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift`

**Step 1: Write the failing tests** (add inside `DashboardViewModelTests`)

```swift
@Test func totalPnLSumsClosedLongTrades() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, positionSize: 2.0) // +1.0
    let t2 = makeTrade(context: ctx, entryPrice: 2.0, exitPrice: 1.8, positionSize: 1.0) // -0.2
    let sut = DashboardViewModel(trades: [t1, t2])
    #expect(abs(sut.totalPnL - 0.8) < 0.0001)
}

@Test func totalPnLHandlesShortTrades() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let t = makeTrade(context: ctx, entryPrice: 2.0, exitPrice: 1.5, direction: .short, positionSize: 1.0) // +0.5
    let sut = DashboardViewModel(trades: [t])
    #expect(abs(sut.totalPnL - 0.5) < 0.0001)
}

@Test func totalPnLIgnoresOpenTrades() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let closed = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 2.0)
    let open   = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
    let sut = DashboardViewModel(trades: [closed, open])
    #expect(abs(sut.totalPnL - 1.0) < 0.0001)
}

@Test func totalTradesCountsAll() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let trades = [
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5),
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
    ]
    let sut = DashboardViewModel(trades: trades)
    #expect(sut.totalTrades == 2)
}
```

**Step 2: Run to verify they fail**

```bash
swift test --filter DashboardViewModelTests 2>&1 | grep -E "FAIL|error:" | head -10
```
Expected: compile errors — `totalPnL`, `totalTrades` not found.

**Step 3: Implement** (add to `DashboardViewModel`)

```swift
public var closedTrades: [Trade] {
    trades.filter { $0.exitPrice != nil }
}

public var totalTrades: Int { trades.count }

public var totalPnL: Double {
    closedTrades.reduce(0.0) { sum, trade in
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return sum + (trade.exitPrice! - trade.entryPrice) * multiplier * trade.positionSize
    }
}
```

**Step 4: Run to verify they pass**

```bash
swift test --filter DashboardViewModelTests 2>&1 | tail -5
```
Expected: all pass.

**Step 5: Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift \
        FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift
git commit -m "feat: add totalPnL and totalTrades to DashboardViewModel"
```

---

### Task 3: `winRate` and `avgRR`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift`
- Modify: `FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
@Test func winRateIs1WhenAllWins() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let trades = [
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5),
        makeTrade(context: ctx, entryPrice: 2.0, exitPrice: 2.5)
    ]
    let sut = DashboardViewModel(trades: trades)
    #expect(abs(sut.winRate - 1.0) < 0.0001)
}

@Test func winRateIs0WhenNoClosedTrades() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let open = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
    let sut = DashboardViewModel(trades: [open])
    #expect(sut.winRate == 0.0)
}

@Test func winRateCalculatesMixed() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let win  = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5)
    let loss = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5)
    let sut = DashboardViewModel(trades: [win, loss])
    #expect(abs(sut.winRate - 0.5) < 0.0001)
}

@Test func avgRRCalculatesRatio() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    // entry=1.0, sl=0.9 (risk=0.1), tp=1.3 (reward=0.3) → R:R = 3.0
    let t = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil,
                      stopLoss: 0.9, takeProfit: 1.3)
    let sut = DashboardViewModel(trades: [t])
    #expect(abs(sut.avgRR - 3.0) < 0.0001)
}

@Test func avgRRIs0WhenNoTrades() throws {
    let sut = DashboardViewModel(trades: [])
    #expect(sut.avgRR == 0.0)
}
```

**Step 2: Run to verify they fail**

```bash
swift test --filter DashboardViewModelTests 2>&1 | grep -E "FAIL|error:" | head -10
```

**Step 3: Implement**

```swift
public var winRate: Double {
    guard !closedTrades.isEmpty else { return 0 }
    let wins = closedTrades.filter { trade in
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (trade.exitPrice! - trade.entryPrice) * multiplier > 0
    }
    return Double(wins.count) / Double(closedTrades.count)
}

public var avgRR: Double {
    guard !trades.isEmpty else { return 0 }
    let rrs = trades.compactMap { trade -> Double? in
        let reward = abs(trade.takeProfit - trade.entryPrice)
        let risk   = abs(trade.entryPrice - trade.stopLoss)
        guard risk > 0 else { return nil }
        return reward / risk
    }
    guard !rrs.isEmpty else { return 0 }
    return rrs.reduce(0, +) / Double(rrs.count)
}
```

**Step 4: Run to verify they pass**

```bash
swift test --filter DashboardViewModelTests 2>&1 | tail -5
```

**Step 5: Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift \
        FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift
git commit -m "feat: add winRate and avgRR to DashboardViewModel"
```

---

### Task 4: `bestStreak` and `currentStreak`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift`
- Modify: `FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
@Test func bestStreakCountsLongestWinRun() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    // W W L W W W → best = 3
    let base = Date()
    func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
    let trades = [
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(0)),  // W
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(1)),  // W
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(2)),  // L
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(3)),  // W
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(4)),  // W
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(5)),  // W
    ]
    let sut = DashboardViewModel(trades: trades)
    #expect(sut.bestStreak == 3)
}

@Test func bestStreakIs0WithNoClosedTrades() throws {
    let sut = DashboardViewModel(trades: [])
    #expect(sut.bestStreak == 0)
}

@Test func currentStreakPositiveForWins() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let base = Date()
    func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
    let trades = [
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(0)),  // L
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(1)),  // W
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(2)),  // W
    ]
    let sut = DashboardViewModel(trades: trades)
    #expect(sut.currentStreak == 2)
}

@Test func currentStreakNegativeForLosses() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let base = Date()
    func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
    let trades = [
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(0)),  // W
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(1)),  // L
        makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(2)),  // L
    ]
    let sut = DashboardViewModel(trades: trades)
    #expect(sut.currentStreak == -2)
}
```

**Step 2: Run to verify they fail**

```bash
swift test --filter DashboardViewModelTests 2>&1 | grep -E "FAIL|error:" | head -10
```

**Step 3: Implement**

```swift
private func sortedClosed() -> [Trade] {
    closedTrades.sorted { ($0.exitAt ?? $0.entryAt) < ($1.exitAt ?? $1.entryAt) }
}

private func isWin(_ trade: Trade) -> Bool {
    let multiplier = trade.direction == .long ? 1.0 : -1.0
    return (trade.exitPrice! - trade.entryPrice) * multiplier > 0
}

public var bestStreak: Int {
    var best = 0, current = 0
    for trade in sortedClosed() {
        if isWin(trade) { current += 1; best = max(best, current) }
        else { current = 0 }
    }
    return best
}

public var currentStreak: Int {
    let sorted = sortedClosed()
    guard let last = sorted.last else { return 0 }
    let targetWin = isWin(last)
    var streak = 0
    for trade in sorted.reversed() {
        guard isWin(trade) == targetWin else { break }
        streak += targetWin ? 1 : -1
    }
    return streak
}
```

**Step 4: Run to verify they pass**

```bash
swift test --filter DashboardViewModelTests 2>&1 | tail -5
```

**Step 5: Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift \
        FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift
git commit -m "feat: add bestStreak and currentStreak to DashboardViewModel"
```

---

### Task 5: `equityCurve(range:)`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift`
- Modify: `FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
@Test func equityCurveAllTimeReturnsCumulativePnL() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let base = Date()
    func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
    let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, positionSize: 1.0, exitAt: date(-2)) // +0.5
    let t2 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.8, positionSize: 1.0, exitAt: date(-1)) // -0.2
    let sut = DashboardViewModel(trades: [t1, t2])
    let curve = sut.equityCurve(range: .allTime)
    #expect(curve.count == 2)
    #expect(abs(curve[0].value - 0.5) < 0.0001)
    #expect(abs(curve[1].value - 0.3) < 0.0001)
}

@Test func equityCurveFiltersBy7Days() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let base = Date()
    func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
    let old   = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-10)) // outside 7d
    let recent = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-2)) // inside 7d
    let sut = DashboardViewModel(trades: [old, recent])
    let curve = sut.equityCurve(range: .sevenDays)
    #expect(curve.count == 1)
}

@Test func equityCurveExcludesOpenTrades() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let closed = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: Date())
    let open   = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
    let sut = DashboardViewModel(trades: [closed, open])
    let curve = sut.equityCurve(range: .allTime)
    #expect(curve.count == 1)
}
```

**Step 2: Run to verify they fail**

```bash
swift test --filter DashboardViewModelTests 2>&1 | grep -E "FAIL|error:" | head -10
```

**Step 3: Implement**

```swift
public func equityCurve(range: DashboardRange) -> [EquityPoint] {
    let sorted = sortedClosed()
    let filtered: [Trade]
    if let days = range.days {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        filtered = sorted.filter { ($0.exitAt ?? $0.entryAt) >= cutoff }
    } else {
        filtered = sorted
    }
    var cumulative = 0.0
    return filtered.map { trade in
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        cumulative += (trade.exitPrice! - trade.entryPrice) * multiplier * trade.positionSize
        return EquityPoint(date: trade.exitAt ?? trade.entryAt, value: cumulative)
    }
}
```

**Step 4: Run all tests**

```bash
swift test 2>&1 | tail -5
```
Expected: all pass (114 existing + new dashboard tests).

**Step 5: Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift \
        FMSYSApp/Tests/FMSYSAppTests/DashboardViewModelTests.swift
git commit -m "feat: add equityCurve(range:) to DashboardViewModel"
```

---

### Task 6: `StatCardView`

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Dashboard/Views/StatCardView.swift`

No TDD for pure layout views. Build and verify visually.

```swift
// Sources/FMSYSCore/Features/Dashboard/Views/StatCardView.swift
import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    var valueColor: Color = Color.fmsOnSurface
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.fmsMuted)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(valueColor)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Dashboard/Views/StatCardView.swift
git commit -m "feat: add StatCardView"
```

---

### Task 7: `DashboardView`

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Dashboard/Views/DashboardView.swift`

```swift
// Sources/FMSYSCore/Features/Dashboard/Views/DashboardView.swift
import SwiftUI
import Charts

public struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    public init(trades: [Trade]) {
        self._viewModel = State(wrappedValue: DashboardViewModel(trades: trades))
    }

    public var body: some View {
        ZStack {
            Color.fmsBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Dashboard")
                        .font(.title2.bold())
                        .foregroundStyle(Color.fmsOnSurface)
                        .padding(.top, 8)

                    statsGrid

                    equitySection
                }
                .padding(24)
            }
        }
    }

    // MARK: - Stat Cards

    private var statsGrid: some View {
        let pnlFormatted = String(format: "%+.2f", viewModel.totalPnL)
        let pnlColor: Color = viewModel.totalPnL >= 0 ? Color.fmsPrimary : Color.fmsLoss
        let winPct = String(format: "%.1f%%", viewModel.winRate * 100)
        let rr = String(format: "%.2f", viewModel.avgRR)
        let streak = viewModel.currentStreak
        let streakLabel = streak >= 0 ? "+\(streak)W" : "\(abs(streak))L"
        let streakColor: Color = streak >= 0 ? Color.fmsPrimary : Color.fmsLoss

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(title: "Total P&L", value: pnlFormatted, valueColor: pnlColor)
            StatCardView(title: "Win Rate", value: winPct)
            StatCardView(title: "Avg R:R", value: rr)
            StatCardView(title: "Total Trades", value: "\(viewModel.totalTrades)")
            StatCardView(title: "Best Streak", value: "\(viewModel.bestStreak)W")
            StatCardView(title: "Current Streak", value: streakLabel, valueColor: streakColor)
        }
    }

    // MARK: - Equity Curve

    private var equitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Equity Curve")
                    .font(.headline)
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Picker("Range", selection: $viewModel.selectedRange) {
                    ForEach(DashboardRange.allCases, id: \.self) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            let curve = viewModel.equityCurve(range: viewModel.selectedRange)

            if curve.isEmpty {
                Text("No closed trades in this period.")
                    .font(.subheadline)
                    .foregroundStyle(Color.fmsMuted)
                    .frame(height: 160)
            } else {
                Chart(curve) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("P&L", point.value)
                    )
                    .foregroundStyle(point.value >= 0 ? Color.fmsPrimary : Color.fmsLoss)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("P&L", point.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.fmsPrimary.opacity(0.2), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.fmsMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.fmsMuted)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Build to verify:**

```bash
swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Dashboard/Views/DashboardView.swift
git commit -m "feat: add DashboardView with stat cards and equity curve"
```

---

### Task 8: Wire Dashboard into `TradeListView`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/TradeListView.swift`

**Step 1:** Add `@State private var showingDashboard = false` to `TradeListView`.

**Step 2:** Add toolbar button (alongside existing `+` button):

```swift
ToolbarItem(placement: .automatic) {
    Button {
        showingDashboard = true
    } label: {
        Image(systemName: "chart.line.uptrend.xyaxis")
            .foregroundStyle(Color.fmsPrimary)
    }
}
```

**Step 3:** Add sheet after the existing `.sheet(isPresented: $showingEntry)`:

```swift
.sheet(isPresented: $showingDashboard) {
    DashboardView(trades: viewModel.trades)
        .frame(minWidth: 480, minHeight: 560)
}
```

**Step 4: Build + run all tests**

```bash
swift build 2>&1 | tail -5
swift test 2>&1 | tail -5
```
Expected: build clean, all tests pass.

**Step 5: Commit**

```bash
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/TradeListView.swift
git commit -m "feat: add Dashboard sheet to Journal toolbar"
```

---

## Done

Dashboard is complete when:
- [ ] All `DashboardViewModelTests` pass
- [ ] `swift build` succeeds
- [ ] Full suite passes (`swift test`)
- [ ] App shows chart icon in Journal toolbar → sheet opens with stat cards + equity curve
