# Dashboard Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the stat-grid DashboardView with a 3-section scrollable layout (Equity Curve, Market Overview + Daily Checklist, Psychological Analytics) and expand the title bar with search stub, icon popovers, and an avatar popover.

**Architecture:** `DashboardViewModel` owns equity curve + psych analytics (computed from Trade.emotionTag). New `ChecklistViewModel` owns editable checklist items via UserDefaults JSON. New sub-views compose into a rewritten `DashboardView`. Title bar lives in `MainAppView.appShell`.

**Tech Stack:** Swift 5.9+, SwiftUI, Swift Charts, SwiftData, `@Observable`, Swift Testing, UserDefaults

**Design reference:** `docs/plans/2026-03-14-dashboard-redesign-design.md`

---

## Context for implementer

**Key paths (all under `FMSYSApp/Sources/FMSYSCore/`):**
- `Core/Models/Trade.swift` — `EmotionTag` enum is already defined here (cases: `.confident, .fearful, .greedy, .calm, .frustrated, .neutral`). `emotionTagRaw: String?` + computed `emotionTag: EmotionTag?` already exist on `Trade`.
- `Features/Dashboard/DashboardViewModel.swift` — existing `DashboardRange` (sevenDays/thirtyDays/ninetyDays/allTime), `DashboardViewModel`, `EquityPoint`
- `Features/Dashboard/Views/DashboardView.swift` — existing stat-grid view (full rewrite in Task 11)
- `Features/Dashboard/Views/StatCardView.swift` — deleted in Task 11
- `App/MainAppView.swift` — `appShell` computed var wraps `NavigationSplitView` + `StatusBar()`
- `App/AppState.swift` — `@Observable`, only has `isAuthenticated`, `markAuthenticated()`, `markLoggedOut()`

**Test file:** `Tests/FMSYSAppTests/DashboardViewModelTests.swift` — 17 tests, currently references `.sevenDays`/`.allTime` etc. (updated in Task 2).

**Test runner:** `cd FMSYSApp && swift test --filter FMSYSTests.DashboardViewModelTests`
All tests: `cd FMSYSApp && swift test`

**Design tokens (already in `Shared/Theme/Colors.swift`):**
- `Color.fmsPrimary` (#13ec80), `Color.fmsLoss` (#ff5f57), `Color.fmsSurface` (#1C1C1E)
- `Color.fmsBackground` (#111113), `Color.fmsOnSurface`, `Color.fmsMuted`

**Note:** SourceKit may show false "cannot find type" errors for cross-module types. `swift build` is the source of truth — if it compiles, ignore SourceKit warnings.

---

### Task 1: Extract EmotionTag to own file + update cases

**Goal:** Move `EmotionTag` out of `Trade.swift` into its own file and update its cases to match the 6 heatmap columns used in Psychological Analytics.

**Files:**
- Create: `Sources/FMSYSCore/Core/Models/EmotionTag.swift`
- Modify: `Sources/FMSYSCore/Core/Models/Trade.swift` (remove EmotionTag definition)

**Step 1: Create the new EmotionTag file**

```swift
// Sources/FMSYSCore/Core/Models/EmotionTag.swift
import Foundation

public enum EmotionTag: String, Codable, CaseIterable {
    case fearful    = "fearful"
    case greedy     = "greedy"
    case frustrated = "frustrated"
    case calm       = "calm"
    case confident  = "confident"
    case neutral    = "neutral"

    /// Human-readable label used in heatmap column headers
    public var displayName: String {
        switch self {
        case .fearful:    return "Fear"
        case .greedy:     return "Greed"
        case .frustrated: return "Bored"
        case .calm:       return "Calm"
        case .confident:  return "Focus"
        case .neutral:    return "Tired"
        }
    }
}
```

**Step 2: Remove EmotionTag from Trade.swift**

In `Sources/FMSYSCore/Core/Models/Trade.swift`, delete the entire `EmotionTag` enum block (lines 14–16):
```swift
// DELETE this:
public enum EmotionTag: String, Codable {
    case confident, fearful, greedy, calm, frustrated, neutral
}
```

**Step 3: Build to verify no duplicate definition**

```bash
cd FMSYSApp && swift build 2>&1 | grep -E "error:|warning:" | head -20
```
Expected: no errors about EmotionTag.

**Step 4: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -5
```
Expected: 141 tests pass.

**Step 5: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Core/Models/EmotionTag.swift Sources/FMSYSCore/Core/Models/Trade.swift
git commit -m "refactor: extract EmotionTag to own file with displayName"
```

---

### Task 2: Update DashboardRange + add psychAnalytics to DashboardViewModel

**Goal:** Rename `DashboardRange` cases to 1W/1M/3M/YTD, add `MarketQuote` stub data, add `PsychAnalytics`/`HeatmapCell` types and computed `psychAnalytics` property, update all affected tests.

**Files:**
- Modify: `Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift`
- Modify: `Tests/FMSYSAppTests/DashboardViewModelTests.swift`

**Step 1: Write the failing tests first**

In `DashboardViewModelTests.swift`, add a new test suite section at the bottom of `DashboardViewModelTests` (inside the struct, before the closing `}`):

```swift
// MARK: - DashboardRange 1W/1M/3M/YTD tests

@Test func dashboardRangeNewLabels() {
    #expect(DashboardRange.oneWeek.label == "1W")
    #expect(DashboardRange.oneMonth.label == "1M")
    #expect(DashboardRange.threeMonths.label == "3M")
    #expect(DashboardRange.ytd.label == "YTD")
    #expect(DashboardRange.allCases.count == 4)
}

@Test func equityCurveFiltersBy1Week() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let base = Date()
    func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
    let old    = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-10))
    let recent = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-2))
    let sut = DashboardViewModel(trades: [old, recent])
    let curve = sut.equityCurve(range: .oneWeek)
    #expect(curve.count == 1)
}

@Test func equityCurveFiltersBy1Month() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let base = Date()
    func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
    let old    = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-40))
    let recent = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-10))
    let sut = DashboardViewModel(trades: [old, recent])
    let curve = sut.equityCurve(range: .oneMonth)
    #expect(curve.count == 1)
}

// MARK: - psychAnalytics tests

@Test func disciplineScoreIs1WhenAllCalm() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .calm)
    let t2 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .confident)
    let sut = DashboardViewModel(trades: [t1, t2])
    #expect(abs(sut.psychAnalytics.disciplineScore - 1.0) < 0.001)
}

@Test func disciplineScoreIs0WhenAllFearful() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let t = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, emotionTag: .fearful)
    let sut = DashboardViewModel(trades: [t])
    #expect(sut.psychAnalytics.disciplineScore == 0.0)
}

@Test func patienceIndexExcludesFrustratedTrades() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let patient   = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .calm)
    let impatient = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, emotionTag: .frustrated)
    let sut = DashboardViewModel(trades: [patient, impatient])
    #expect(abs(sut.psychAnalytics.patienceIndex - 0.5) < 0.001)
}

@Test func heatmapCellsCountByEmotionAndPL() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    // 2 fearful trades: 1 loss, 1 profit
    let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, emotionTag: .fearful)  // loss
    let t2 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .fearful)  // profit
    let sut = DashboardViewModel(trades: [t1, t2])
    let cells = sut.psychAnalytics.heatmapCells
    let fearLoss   = cells.first { $0.emotion == "Fear" && $0.plBucket == .loss }
    let fearProfit = cells.first { $0.emotion == "Fear" && $0.plBucket == .profit }
    #expect(fearLoss?.count == 1)
    #expect(fearProfit?.count == 1)
}

@Test func heatmapExcludesTradesWithNoEmotionTag() throws {
    let (ctx, _container) = try makeContainer(); _ = _container
    let noTag  = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5)
    let tagged = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .calm)
    let sut = DashboardViewModel(trades: [noTag, tagged])
    let cells = sut.psychAnalytics.heatmapCells
    let total = cells.reduce(0) { $0 + $1.count }
    #expect(total == 1)
}
```

Also update the `makeTrade` helper to accept an optional `emotionTag` parameter (add at the end of the parameter list):

```swift
private func makeTrade(
    context: ModelContext,
    entryPrice: Double,
    exitPrice: Double? = nil,
    direction: Direction = .long,
    stopLoss: Double? = nil,
    takeProfit: Double? = nil,
    positionSize: Double = 1.0,
    exitAt: Date? = nil,
    emotionTag: EmotionTag? = nil    // ADD THIS
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
        exitAt: exitAt ?? (exitPrice != nil ? Date() : nil),
        emotionTag: emotionTag         // ADD THIS
    )
    context.insert(trade)
    return trade
}
```

Also update the old range tests that use `.sevenDays`/`.allTime` etc.:
- `dashboardRangeAllCasesExist` → replace with `dashboardRangeNewLabels` (already written above; delete the old one)
- `equityCurveFiltersBy7Days` → rename to `equityCurveFiltersBy1WeekLegacy` and change `.sevenDays` to `.oneWeek`
- `equityCurveAllTimeReturnsCumulativePnL` → update `.allTime` to `.oneMonth`, and use dates within the last month (e.g., `date(-2)` and `date(-1)`)
- `equityCurveExcludesOpenTrades` → update `.allTime` to `.oneMonth`

**Step 2: Run tests — expect failures**

```bash
cd FMSYSApp && swift test --filter FMSYSTests.DashboardViewModelTests 2>&1 | tail -20
```
Expected: compile errors about missing `.oneWeek`, `.psychAnalytics`, etc.

**Step 3: Update DashboardViewModel**

Replace the entire contents of `Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift`:

```swift
import Foundation
import Observation
import SwiftData

// MARK: - DashboardRange

public enum DashboardRange: String, CaseIterable {
    case oneWeek     = "1W"
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case ytd         = "YTD"

    public var label: String { rawValue }

    /// The earliest date included when filtering the equity curve.
    public var cutoffDate: Date {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .oneWeek:
            return cal.date(byAdding: .day, value: -7, to: now)!
        case .oneMonth:
            return cal.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths:
            return cal.date(byAdding: .month, value: -3, to: now)!
        case .ytd:
            return cal.date(from: cal.dateComponents([.year], from: now))!
        }
    }
}

// MARK: - EquityPoint

public struct EquityPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
}

// MARK: - MarketQuote

public struct MarketQuote: Identifiable {
    public let id: String          // symbol, e.g. "BTC"
    public let name: String
    public let price: Double
    public let changePercent: Double
    public let sparkline: [Double] // 6 values, relative prices for chart
}

// MARK: - PsychAnalytics

public enum PLBucket: String { case loss, neutral, profit }

public struct HeatmapCell: Identifiable {
    public let id: String               // "\(emotion)-\(plBucket.rawValue)"
    public let emotion: String
    public let plBucket: PLBucket
    public let count: Int
}

public struct PsychAnalytics {
    /// Fraction of tagged trades where emotionTag is .calm or .confident
    public let disciplineScore: Double
    /// Fraction of tagged trades where emotionTag is NOT .frustrated or .neutral
    public let patienceIndex: Double
    /// All (emotion, plBucket) combinations with at least one trade
    public let heatmapCells: [HeatmapCell]
}

// MARK: - ViewModel

@Observable
public final class DashboardViewModel {
    public let trades: [Trade]
    public var selectedRange: DashboardRange = .oneMonth

    public init(trades: [Trade]) {
        self.trades = trades
    }

    public var closedTrades: [Trade] {
        trades.filter { $0.exitPrice != nil }
    }

    public var totalTrades: Int { trades.count }

    public var totalPnL: Double {
        closedTrades.reduce(0.0) { sum, trade in
            guard let exitPrice = trade.exitPrice else { return sum }
            let multiplier = trade.direction == .long ? 1.0 : -1.0
            return sum + (exitPrice - trade.entryPrice) * multiplier * trade.positionSize
        }
    }

    public var winRate: Double {
        guard !closedTrades.isEmpty else { return 0 }
        let wins = closedTrades.filter { trade in
            guard let exitPrice = trade.exitPrice else { return false }
            let multiplier = trade.direction == .long ? 1.0 : -1.0
            return (exitPrice - trade.entryPrice) * multiplier > 0
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

    // MARK: - Streak metrics

    private func sortedClosed() -> [Trade] {
        closedTrades.sorted { ($0.exitAt ?? $0.entryAt) < ($1.exitAt ?? $1.entryAt) }
    }

    private func isWin(_ trade: Trade) -> Bool {
        guard let exitPrice = trade.exitPrice else { return false }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exitPrice - trade.entryPrice) * multiplier > 0
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

    // MARK: - Equity curve

    public func equityCurve(range: DashboardRange) -> [EquityPoint] {
        let cutoff = range.cutoffDate
        let filtered = sortedClosed().filter { ($0.exitAt ?? $0.entryAt) >= cutoff }
        var cumulative = 0.0
        return filtered.map { trade in
            let exitPrice = trade.exitPrice ?? trade.entryPrice
            let multiplier = trade.direction == .long ? 1.0 : -1.0
            cumulative += (exitPrice - trade.entryPrice) * multiplier * trade.positionSize
            return EquityPoint(date: trade.exitAt ?? trade.entryAt, value: cumulative)
        }
    }

    // MARK: - Market quotes (static stubs)

    public var marketQuotes: [MarketQuote] {
        [
            MarketQuote(
                id: "BTC",
                name: "Bitcoin",
                price: 64231.50,
                changePercent: 2.4,
                sparkline: [60000, 61200, 59800, 62500, 63100, 64231]
            ),
            MarketQuote(
                id: "ETH",
                name: "Ethereum",
                price: 3420.12,
                changePercent: -1.2,
                sparkline: [3500, 3480, 3510, 3450, 3430, 3420]
            )
        ]
    }

    // MARK: - Psychological analytics

    public var psychAnalytics: PsychAnalytics {
        // Use last 30 trades that have an emotionTag set
        let tagged = trades
            .filter { $0.emotionTag != nil }
            .suffix(30)

        guard !tagged.isEmpty else {
            return PsychAnalytics(disciplineScore: 0, patienceIndex: 0, heatmapCells: [])
        }

        let total = Double(tagged.count)

        // Discipline: calm or confident
        let disciplined = tagged.filter { $0.emotionTag == .calm || $0.emotionTag == .confident }
        let disciplineScore = Double(disciplined.count) / total

        // Patience: NOT frustrated or neutral
        let patient = tagged.filter { $0.emotionTag != .frustrated && $0.emotionTag != .neutral }
        let patienceIndex = Double(patient.count) / total

        // Heatmap: count per (emotionTag.displayName, PLBucket)
        var counts: [String: [PLBucket: Int]] = [:]
        for trade in tagged {
            guard let tag = trade.emotionTag else { continue }
            let col = tag.displayName
            let bucket = plBucket(for: trade)
            counts[col, default: [:]][bucket, default: 0] += 1
        }

        var cells: [HeatmapCell] = []
        for (emotion, buckets) in counts {
            for (bucket, count) in buckets {
                cells.append(HeatmapCell(
                    id: "\(emotion)-\(bucket.rawValue)",
                    emotion: emotion,
                    plBucket: bucket,
                    count: count
                ))
            }
        }

        return PsychAnalytics(
            disciplineScore: disciplineScore,
            patienceIndex: patienceIndex,
            heatmapCells: cells
        )
    }

    private func plBucket(for trade: Trade) -> PLBucket {
        guard let exitPrice = trade.exitPrice else { return .neutral }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        let pnl = (exitPrice - trade.entryPrice) * multiplier
        if pnl > 0 { return .profit }
        if pnl < 0 { return .loss }
        return .neutral
    }
}
```

**Step 4: Run tests**

```bash
cd FMSYSApp && swift test --filter FMSYSTests.DashboardViewModelTests 2>&1 | tail -10
```
Expected: all dashboard tests pass (the old range-label test was replaced by `dashboardRangeNewLabels`).

**Step 5: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -5
```
Expected: all tests pass.

**Step 6: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Dashboard/DashboardViewModel.swift Tests/FMSYSAppTests/DashboardViewModelTests.swift
git commit -m "feat: update DashboardRange to 1W/1M/3M/YTD, add psychAnalytics and marketQuotes"
```

---

### Task 3: ChecklistItem + ChecklistViewModel + tests

**Goal:** Build the `ChecklistViewModel` that persists an editable list of daily checklist items in `UserDefaults`.

**Files:**
- Create: `Sources/FMSYSCore/Features/Dashboard/ChecklistViewModel.swift`
- Create: `Tests/FMSYSAppTests/ChecklistViewModelTests.swift`

**Step 1: Write failing tests**

Create `Tests/FMSYSAppTests/ChecklistViewModelTests.swift`:

```swift
import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite
    struct ChecklistViewModelTests {

        private let defaults = UserDefaults(suiteName: "test.checklist.\(UUID().uuidString)")!

        @Test func defaultItemsSeededOnFirstLaunch() {
            let sut = ChecklistViewModel(defaults: defaults)
            #expect(sut.items.count == 3)
            #expect(sut.items[0].title == "Pre-market prep finished")
            #expect(sut.items[1].title == "Economic calendar checked")
            #expect(sut.items[2].title == "Identify key HTF levels")
            #expect(sut.items.allSatisfy { !$0.isChecked })
        }

        @Test func addItemAppendsToList() {
            let sut = ChecklistViewModel(defaults: defaults)
            sut.add(title: "Review trade plan")
            #expect(sut.items.count == 4)
            #expect(sut.items.last?.title == "Review trade plan")
        }

        @Test func toggleFlipsIsChecked() {
            let sut = ChecklistViewModel(defaults: defaults)
            let id = sut.items[0].id
            sut.toggle(id: id)
            #expect(sut.items[0].isChecked == true)
            sut.toggle(id: id)
            #expect(sut.items[0].isChecked == false)
        }

        @Test func deleteRemovesItem() {
            let sut = ChecklistViewModel(defaults: defaults)
            let id = sut.items[1].id
            sut.delete(id: id)
            #expect(sut.items.count == 2)
            #expect(sut.items.allSatisfy { $0.id != id })
        }

        @Test func renameUpdatesTitle() {
            let sut = ChecklistViewModel(defaults: defaults)
            let id = sut.items[0].id
            sut.rename(id: id, title: "Updated title")
            #expect(sut.items[0].title == "Updated title")
        }

        @Test func persistsAcrossInstances() {
            let sut1 = ChecklistViewModel(defaults: defaults)
            sut1.add(title: "Persisted item")
            sut1.toggle(id: sut1.items[0].id)

            let sut2 = ChecklistViewModel(defaults: defaults)
            #expect(sut2.items.count == 4)
            #expect(sut2.items.last?.title == "Persisted item")
            #expect(sut2.items[0].isChecked == true)
        }

        @Test func addEmptyTitleIsIgnored() {
            let sut = ChecklistViewModel(defaults: defaults)
            sut.add(title: "")
            #expect(sut.items.count == 3)
        }
    }
}
```

**Step 2: Run tests — expect failure**

```bash
cd FMSYSApp && swift test --filter FMSYSTests.ChecklistViewModelTests 2>&1 | tail -10
```
Expected: compile error — `ChecklistViewModel` not found.

**Step 3: Implement ChecklistViewModel**

Create `Sources/FMSYSCore/Features/Dashboard/ChecklistViewModel.swift`:

```swift
import Foundation
import Observation

// MARK: - ChecklistItem

public struct ChecklistItem: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var isChecked: Bool

    public init(id: UUID = UUID(), title: String, isChecked: Bool = false) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
    }
}

// MARK: - ChecklistViewModel

@Observable
public final class ChecklistViewModel {

    public private(set) var items: [ChecklistItem]

    private let defaults: UserDefaults
    private let storageKey = "fmsys.dailyChecklist"

    private static let defaultItems: [ChecklistItem] = [
        ChecklistItem(title: "Pre-market prep finished"),
        ChecklistItem(title: "Economic calendar checked"),
        ChecklistItem(title: "Identify key HTF levels")
    ]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "fmsys.dailyChecklist"),
           let decoded = try? JSONDecoder().decode([ChecklistItem].self, from: data),
           !decoded.isEmpty {
            self.items = decoded
        } else {
            self.items = Self.defaultItems
        }
    }

    public func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(ChecklistItem(title: trimmed))
        persist()
    }

    public func toggle(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isChecked.toggle()
        persist()
    }

    public func delete(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    public func rename(id: UUID, title: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].title = title
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
```

**Step 4: Run tests**

```bash
cd FMSYSApp && swift test --filter FMSYSTests.ChecklistViewModelTests 2>&1 | tail -10
```
Expected: all 7 checklist tests pass.

**Step 5: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -5
```
Expected: all tests pass.

**Step 6: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Dashboard/ChecklistViewModel.swift Tests/FMSYSAppTests/ChecklistViewModelTests.swift
git commit -m "feat: add ChecklistItem and ChecklistViewModel with UserDefaults persistence"
```

---

### Task 4: AppState user profile placeholders

**Goal:** Add `userDisplayName`, `userEmail`, and `userRole` properties to `AppState` for the avatar popover.

**Files:**
- Modify: `Sources/FMSYSCore/App/AppState.swift`
- Modify: `Tests/FMSYSAppTests/AppStateTests.swift`

**Step 1: Write failing tests**

Add inside `AppStateTests` struct in `Tests/FMSYSAppTests/AppStateTests.swift`:

```swift
// MARK: - User profile

@Test func userDisplayNameDefaultsToTradingDesk() {
    let sut = AppState(keychain: KeychainManager())
    #expect(sut.userDisplayName == "Trading Desk")
}

@Test func userEmailDefaultsToPlaceholder() {
    let sut = AppState(keychain: KeychainManager())
    #expect(sut.userEmail == "trader@fmsys.app")
}

@Test func userRoleDefaultsToTrader() {
    let sut = AppState(keychain: KeychainManager())
    #expect(sut.userRole == "Trader")
}
```

**Step 2: Run tests — expect failure**

```bash
cd FMSYSApp && swift test --filter FMSYSTests.AppStateTests 2>&1 | tail -10
```
Expected: compile error — `userDisplayName` not found.

**Step 3: Update AppState**

In `Sources/FMSYSCore/App/AppState.swift`, add after `public var isAuthenticated: Bool`:

```swift
// User profile (populated after auth — placeholders until profile API is wired)
public var userDisplayName: String = "Trading Desk"
public var userEmail: String = "trader@fmsys.app"
public var userRole: String = "Trader"
```

**Step 4: Run tests**

```bash
cd FMSYSApp && swift test --filter FMSYSTests.AppStateTests 2>&1 | tail -10
```
Expected: all AppState tests pass (including new 3).

**Step 5: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/App/AppState.swift Tests/FMSYSAppTests/AppStateTests.swift
git commit -m "feat: add userDisplayName/userEmail/userRole placeholders to AppState"
```

---

### Task 5: AvatarPopover component

**Goal:** Build the popover content view shown when the user clicks the avatar button in the title bar.

**Files:**
- Create: `Sources/FMSYSCore/Shared/Components/AvatarPopover.swift`

No unit tests needed for this pure layout view.

**Step 1: Create AvatarPopover**

```swift
// Sources/FMSYSCore/Shared/Components/AvatarPopover.swift
import SwiftUI

public struct AvatarPopover: View {
    public let displayName: String
    public let email: String
    public let role: String
    public let onSignOut: () -> Void

    public init(
        displayName: String,
        email: String,
        role: String,
        onSignOut: @escaping () -> Void
    ) {
        self.displayName = displayName
        self.email = email
        self.role = role
        self.onSignOut = onSignOut
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User info
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.fmsMuted.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.fmsMuted)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text(email)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                    Text(role)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.fmsBackground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.fmsPrimary, in: Capsule())
                }
            }
            .padding(16)

            Divider()
                .overlay(Color.fmsMuted.opacity(0.3))

            // Actions
            VStack(spacing: 0) {
                Button {
                    // TODO: navigate to Settings
                } label: {
                    Label("Account Settings", systemImage: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsOnSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(Color.clear)
                .contentShape(Rectangle())
                .hoverEffect()

                Button(role: .destructive) {
                    onSignOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsLoss)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.vertical, 4)
        }
        .frame(width: 260)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

Note: `.hoverEffect()` is iOS-only — on macOS use `.onHover` if needed, or omit. If the build errors on `.hoverEffect()`, remove those two lines.

**Step 2: Build**

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" | head -10
```
If `.hoverEffect()` causes an error, remove it from both Button labels.

**Step 3: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Shared/Components/AvatarPopover.swift
git commit -m "feat: add AvatarPopover component"
```

---

### Task 6: Expand MainAppView title bar

**Goal:** Add the centered search stub, notification/share/settings icon buttons with stub popovers, and the avatar button with `AvatarPopover` to the app shell title bar.

**Files:**
- Modify: `Sources/FMSYSCore/App/MainAppView.swift`

**Step 1: Update MainAppView**

The `appShell` computed var currently is:
```swift
private var appShell: some View {
    VStack(spacing: 0) {
        NavigationSplitView { ... } detail: { ... }
            .navigationSplitViewStyle(.prominentDetail)
        StatusBar()
    }
}
```

Replace it with:

```swift
private var appShell: some View {
    VStack(spacing: 0) {
        titleBar
        NavigationSplitView {
            SidebarView(selection: $selectedScreen, journalCategory: $journalCategory)
        } detail: {
            screenContent
        }
        .navigationSplitViewStyle(.prominentDetail)
        StatusBar()
    }
}

// MARK: - Title bar

@State private var showNotificationsPopover = false
@State private var showSharePopover = false
@State private var showSettingsPopover = false
@State private var showAvatarPopover = false

private var titleBar: some View {
    HStack(spacing: 0) {
        // Traffic light placeholder (macOS draws real ones in the window chrome,
        // but our custom VStack layout needs spacing to avoid overlap)
        Spacer().frame(width: 80)

        Spacer()

        // Centered search stub
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted.opacity(0.6))
            Text("Search trades, journals, analytics...")
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .frame(width: 320)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1)
        )

        Spacer()

        // Right-side controls
        HStack(spacing: 4) {
            toolbarIconButton(systemName: "bell", isPresented: $showNotificationsPopover) {
                Text("Notifications coming soon")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsOnSurface)
                    .padding(16)
            }

            toolbarIconButton(systemName: "square.and.arrow.up", isPresented: $showSharePopover) {
                Text("Export & Share coming soon")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsOnSurface)
                    .padding(16)
            }

            toolbarIconButton(systemName: "gearshape", isPresented: $showSettingsPopover) {
                Text("Settings coming soon")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsOnSurface)
                    .padding(16)
            }

            // Avatar button
            Button {
                showAvatarPopover.toggle()
            } label: {
                Circle()
                    .fill(Color.fmsMuted.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.fmsMuted)
                    }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showAvatarPopover, arrowEdge: .top) {
                AvatarPopover(
                    displayName: appState.userDisplayName,
                    email: appState.userEmail,
                    role: appState.userRole,
                    onSignOut: {
                        showAvatarPopover = false
                        appState.markLoggedOut()
                    }
                )
            }
            .padding(.leading, 4)
        }
        .padding(.trailing, 12)
    }
    .frame(height: 48)
    .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    .overlay(alignment: .bottom) {
        Divider()
            .overlay(Color.fmsMuted.opacity(0.15))
    }
}

@ViewBuilder
private func toolbarIconButton<Content: View>(
    systemName: String,
    isPresented: Binding<Bool>,
    @ViewBuilder popoverContent: () -> Content
) -> some View {
    Button {
        isPresented.wrappedValue.toggle()
    } label: {
        Image(systemName: systemName)
            .font(.system(size: 15))
            .foregroundStyle(Color.fmsMuted)
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .popover(isPresented: isPresented, arrowEdge: .top) {
        popoverContent()
    }
}
```

**Step 2: Build**

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" | head -20
```
Fix any issues. Common issue: `@State` variables declared inside a `View` body — move them to the struct level.

**Step 3: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -5
```
Expected: all tests pass.

**Step 4: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/App/MainAppView.swift
git commit -m "feat: expand title bar with search stub, icon popovers, and avatar popover"
```

---

### Task 7: EquityCurveSection view

**Goal:** Build the Equity Curve card (Section 1 of the dashboard).

**Files:**
- Create: `Sources/FMSYSCore/Features/Dashboard/Views/EquityCurveSection.swift`

**Step 1: Create the view**

```swift
// Sources/FMSYSCore/Features/Dashboard/Views/EquityCurveSection.swift
import SwiftUI
import Charts

public struct EquityCurveSection: View {
    @Binding var selectedRange: DashboardRange
    let curve: [EquityPoint]

    public init(selectedRange: Binding<DashboardRange>, curve: [EquityPoint]) {
        self._selectedRange = selectedRange
        self.curve = curve
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equity Curve")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("Compound performance vs. benchmark")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                rangePicker
            }

            // Chart
            if curve.isEmpty {
                emptyChart
            } else {
                chart
            }
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var rangePicker: some View {
        HStack(spacing: 2) {
            ForEach(DashboardRange.allCases, id: \.self) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(selectedRange == range ? Color.fmsBackground : Color.fmsOnSurface)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            selectedRange == range
                                ? Color.fmsOnSurface
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var chart: some View {
        Chart(curve) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("P&L", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.fmsPrimary.opacity(0.2), Color.fmsPrimary.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Date", point.date),
                y: .value("P&L", point.value)
            )
            .foregroundStyle(Color.fmsPrimary)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
        .frame(height: 180)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(Color.fmsMuted)
            }
        }
    }

    private var emptyChart: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.fmsBackground.opacity(0.5))
                .frame(height: 180)
            Text("No closed trades in this period.")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
        }
    }
}
```

**Step 2: Build**

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" | head -10
```
Expected: no errors.

**Step 3: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Dashboard/Views/EquityCurveSection.swift
git commit -m "feat: add EquityCurveSection view"
```

---

### Task 8: MarketOverviewCard view

**Goal:** Build the Market Overview card (left half of Section 2).

**Files:**
- Create: `Sources/FMSYSCore/Features/Dashboard/Views/MarketOverviewCard.swift`

**Step 1: Create the view**

```swift
// Sources/FMSYSCore/Features/Dashboard/Views/MarketOverviewCard.swift
import SwiftUI
import Charts

public struct MarketOverviewCard: View {
    let quotes: [MarketQuote]

    public init(quotes: [MarketQuote]) {
        self.quotes = quotes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsPrimary)
                Text("Market Overview")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }

            // Quote rows
            VStack(spacing: 8) {
                ForEach(quotes) { quote in
                    QuoteRow(quote: quote)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuoteRow: View {
    let quote: MarketQuote

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(quote.id)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))

            // Name + price
            VStack(alignment: .leading, spacing: 1) {
                Text(quote.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(priceFormatted)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted)
            }

            Spacer()

            // Sparkline
            Chart {
                ForEach(Array(quote.sparkline.enumerated()), id: \.offset) { idx, val in
                    LineMark(
                        x: .value("i", idx),
                        y: .value("p", val)
                    )
                    .foregroundStyle(changeColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(width: 64, height: 24)

            // Change badge
            Text(changeFormatted)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(changeColor)
                .frame(width: 46, alignment: .trailing)
        }
        .padding(10)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconColor: Color {
        quote.id == "BTC" ? Color.orange : Color.blue
    }

    private var changeColor: Color {
        quote.changePercent >= 0 ? Color.fmsPrimary : Color.fmsLoss
    }

    private var priceFormatted: String {
        "$\(String(format: "%.2f", quote.price))"
    }

    private var changeFormatted: String {
        let sign = quote.changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", quote.changePercent))%"
    }
}
```

**Step 2: Build**

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" | head -10
```

**Step 3: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Dashboard/Views/MarketOverviewCard.swift
git commit -m "feat: add MarketOverviewCard view with sparklines"
```

---

### Task 9: DailyChecklistCard view

**Goal:** Build the Daily Checklist card (right half of Section 2) with add/toggle/delete/rename.

**Files:**
- Create: `Sources/FMSYSCore/Features/Dashboard/Views/DailyChecklistCard.swift`

**Step 1: Create the view**

```swift
// Sources/FMSYSCore/Features/Dashboard/Views/DailyChecklistCard.swift
import SwiftUI

public struct DailyChecklistCard: View {
    @Bindable var viewModel: ChecklistViewModel
    @State private var editingId: UUID? = nil

    public init(viewModel: ChecklistViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsPrimary)
                Text("Daily Checklist")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button {
                    viewModel.add(title: "New item")
                    // Start editing the new item
                    editingId = viewModel.items.last?.id
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fmsPrimary)
                        .frame(width: 24, height: 24)
                        .background(Color.fmsPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // List or empty state
            if viewModel.items.isEmpty {
                Text("Add your first checklist item")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        ChecklistRow(
                            item: item,
                            isEditing: editingId == item.id,
                            onToggle: { viewModel.toggle(id: item.id) },
                            onRename: { newTitle in
                                viewModel.rename(id: item.id, title: newTitle)
                                editingId = nil
                            },
                            onTapLabel: { editingId = item.id },
                            onDelete: { viewModel.delete(id: item.id) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem
    let isEditing: Bool
    let onToggle: () -> Void
    let onRename: (String) -> Void
    let onTapLabel: () -> Void
    let onDelete: () -> Void

    @State private var editText: String = ""

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Button { onToggle() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.isChecked ? Color.fmsPrimary : Color.clear)
                        .frame(width: 16, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(item.isChecked ? Color.fmsPrimary : Color.fmsMuted.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.fmsBackground)
                    }
                }
            }
            .buttonStyle(.plain)

            // Label or inline editor
            if isEditing {
                TextField("Item title", text: $editText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface)
                    .textFieldStyle(.plain)
                    .onAppear { editText = item.title }
                    .onSubmit { onRename(editText) }
            } else {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(item.isChecked ? Color.fmsMuted : Color.fmsOnSurface.opacity(0.85))
                    .strikethrough(item.isChecked, color: Color.fmsMuted)
                    .onTapGesture { onTapLabel() }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Delete button
            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.fmsMuted.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
}
```

Note: `@Bindable` requires the class to be `@Observable`, which `ChecklistViewModel` is. If you get a compile error about `@Bindable` on a non-class, check that `ChecklistViewModel` is declared `public final class`, not a struct.

**Step 2: Build**

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" | head -10
```

**Step 3: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Dashboard/Views/DailyChecklistCard.swift
git commit -m "feat: add DailyChecklistCard with inline edit and delete"
```

---

### Task 10: PsychAnalyticsSection view

**Goal:** Build the Psychological Analytics card (Section 3) with progress bars and emotion heatmap.

**Files:**
- Create: `Sources/FMSYSCore/Features/Dashboard/Views/PsychAnalyticsSection.swift`

**Step 1: Create the view**

```swift
// Sources/FMSYSCore/Features/Dashboard/Views/PsychAnalyticsSection.swift
import SwiftUI

public struct PsychAnalyticsSection: View {
    let analytics: PsychAnalytics

    private let emotionColumns: [String] = ["Fear", "Greed", "Bored", "Calm", "Focus", "Tired"]

    public init(analytics: PsychAnalytics) {
        self.analytics = analytics
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#58a6ff"))
                Text("PSYCHOLOGICAL ANALYTICS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                    .kerning(0.5)
                Spacer()
                Text("LAST 30 SESSIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .kerning(0.5)
            }

            HStack(alignment: .top, spacing: 24) {
                // Left: score bars (1/3 width)
                VStack(spacing: 12) {
                    ScoreBar(
                        label: "Discipline Score",
                        value: analytics.disciplineScore,
                        color: Color.fmsPrimary
                    )
                    ScoreBar(
                        label: "Patience Index",
                        value: analytics.patienceIndex,
                        color: Color(hex: "#58a6ff")
                    )
                }
                .frame(maxWidth: .infinity)

                // Right: heatmap (2/3 width)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Emotion vs. P/L Heatmap")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.fmsMuted)
                        Spacer()
                        legend
                    }
                    heatmapGrid
                }
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            }
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var legend: some View {
        HStack(spacing: 8) {
            legendSwatch(color: Color.fmsLoss, label: "Loss")
            legendSwatch(color: Color.fmsMuted.opacity(0.5), label: "Neutral")
            legendSwatch(color: Color.fmsPrimary, label: "Profit")
        }
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color.fmsMuted)
        }
    }

    private var heatmapGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: emotionColumns.count),
            spacing: 4
        ) {
            // Column headers
            ForEach(emotionColumns, id: \.self) { col in
                Text(col)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.fmsMuted.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
            // Rows: profit, neutral, loss
            ForEach([PLBucket.profit, .neutral, .loss], id: \.rawValue) { bucket in
                ForEach(emotionColumns, id: \.self) { col in
                    let count = analytics.heatmapCells
                        .first { $0.emotion == col && $0.plBucket == bucket }?.count ?? 0
                    HeatmapCell(bucket: bucket, count: count)
                }
            }
        }
    }
}

private struct ScoreBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(color)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.fmsBackground)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geo.size.width * value, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(16)
        }
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct HeatmapCell: View {
    let bucket: PLBucket
    let count: Int

    private var opacity: Double {
        guard count > 0 else { return 0.04 }
        return min(0.2 + Double(count) * 0.15, 0.9)
    }

    private var color: Color {
        switch bucket {
        case .profit:  return Color.fmsPrimary
        case .loss:    return Color.fmsLoss
        case .neutral: return Color.fmsMuted
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color.opacity(opacity))
            .aspectRatio(1, contentMode: .fit)
    }
}
```

Note: `Color(hex:)` is used for `#58a6ff` (the `info` blue). This helper is already defined in `Shared/Theme/Colors.swift`. If the build errors saying `Color(hex:)` is unavailable, replace with `Color(red: 0.345, green: 0.651, blue: 1.0)`.

**Step 2: Build**

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" | head -10
```

**Step 3: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Dashboard/Views/PsychAnalyticsSection.swift
git commit -m "feat: add PsychAnalyticsSection with score bars and emotion heatmap"
```

---

### Task 11: DashboardView rewrite + delete StatCardView

**Goal:** Replace the existing `DashboardView` stat-grid with the new 3-section scrollable layout composing the 4 sub-views built in Tasks 7–10. Delete the now-unused `StatCardView`.

**Files:**
- Modify: `Sources/FMSYSCore/Features/Dashboard/Views/DashboardView.swift` (full rewrite)
- Delete: `Sources/FMSYSCore/Features/Dashboard/Views/StatCardView.swift`

**Step 1: Delete StatCardView**

```bash
rm FMSYSApp/Sources/FMSYSCore/Features/Dashboard/Views/StatCardView.swift
```

**Step 2: Rewrite DashboardView**

Replace the entire contents of `Sources/FMSYSCore/Features/Dashboard/Views/DashboardView.swift`:

```swift
// Sources/FMSYSCore/Features/Dashboard/Views/DashboardView.swift
import SwiftUI
import Charts

public struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var checklistViewModel: ChecklistViewModel

    public init(trades: [Trade]) {
        self._viewModel = State(wrappedValue: DashboardViewModel(trades: trades))
        self._checklistViewModel = State(wrappedValue: ChecklistViewModel())
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Section 1: Equity Curve
                EquityCurveSection(
                    selectedRange: $viewModel.selectedRange,
                    curve: viewModel.equityCurve(range: viewModel.selectedRange)
                )

                // Section 2: Market Overview + Daily Checklist
                HStack(alignment: .top, spacing: 24) {
                    MarketOverviewCard(quotes: viewModel.marketQuotes)
                    DailyChecklistCard(viewModel: checklistViewModel)
                }

                // Section 3: Psychological Analytics
                PsychAnalyticsSection(analytics: viewModel.psychAnalytics)
            }
            .padding(24)
        }
        .background(Color.fmsBackground)
    }
}
```

**Step 3: Build**

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" | head -20
```
Expected: no errors. If there are references to `StatCardView` anywhere, they should only be the deleted file (already gone).

**Step 4: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -10
```
Expected: all tests pass (should be 141 + new checklist + new dashboard tests = ~155+ tests).

**Step 5: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Dashboard/Views/DashboardView.swift
git add -u Sources/FMSYSCore/Features/Dashboard/Views/StatCardView.swift   # stages the deletion
git commit -m "feat: rewrite DashboardView with 3-section layout, delete StatCardView"
```

---

## Final verification

After all 11 tasks:

```bash
cd FMSYSApp && swift build 2>&1 | grep "error:" && swift test 2>&1 | tail -5
```

Expected:
- No build errors
- All tests pass
- New test count: ~155+ (141 original + 7 checklist + ~7 new dashboard range/psych tests)
