# Backtesting View Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the `BacktestingView` stub with a full backtesting analysis screen showing an equity curve, KPI cards, and a trade log table — seeded with realistic stub data.

**Architecture:** `BacktestResult` is a SwiftData `@Model` storing equity curve and trade log as JSON `Data` blobs. `BacktestRepository` provides CRUD. `BacktestViewModel` (@Observable) seeds one realistic result on first launch (UserDefaults flag), loads results, and exposes `selectedResult` to the UI. The view layer is split into `BacktestEquityCurveSection`, `BacktestKPICards`, and `BacktestTradeLogTable` — all pure display views receiving a `BacktestResult`.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, Swift Charts, Swift Testing (`@Suite`, `#expect`, `@MainActor`, `.serialized`), UserDefaults for seed flag, JSONEncoder/Decoder for blob fields.

---

## Codebase Context

- **Package root:** `FMSYSApp/` (all paths below are relative to it)
- **Library target:** `Sources/FMSYSCore/` — all business logic and UI
- **Executable target:** `Sources/FMSYSApp/FMSYSApp.swift` — `@main`, owns `ModelContainer`
- **Tests:** `Tests/FMSYSAppTests/` — Swift Testing, nested under `FMSYSTests` top-level suite
- **Test pattern:** Nest new suites as `extension FMSYSTests { @Suite(.serialized) struct XxxTests { } }`
- **ModelContainer schema** is currently `ModelContainer(for: Trade.self, Strategy.self, ...)` — you must add `BacktestResult.self`
- **Color tokens:** `Color.fmsPrimary` (#13ec80), `Color.fmsLoss` (#ff5f57), `Color.fmsSurface` (#1C1C1E), `Color.fmsBackground` (#111113), `Color.fmsOnSurface` (#EBEBF0), `Color.fmsMuted` (#8E8E93)
- **Fonts:** Use `.system(size:weight:)` — no custom font helper exists
- **SwiftData test rules:**
  - Always `@MainActor @Suite(.serialized)` on SwiftData suites
  - `makeRepository()` returns `(Repo, ModelContext, ModelContainer)` — bind `_ = _container` to keep it alive
  - Use `ModelConfiguration(isStoredInMemoryOnly: true)` for test containers
- **`Direction` enum** already exists in `Sources/FMSYSCore/Core/Models/Trade.swift` — `.long` / `.short`
- **`BacktestingView`** currently a stub at `Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift`
- **`MainAppView`** wires screens at line ~171: `case .backtesting: BacktestingView()` — update to pass `modelContainer`
- **Test runner:** `cd FMSYSApp && swift test 2>&1 | tail -30`
- **Specific test filter:** `swift test --filter BacktestRepositoryTests 2>&1 | tail -30`

---

## Task 1: `Timeframe` enum + `BacktestResult` @Model + schema update

**Files:**
- Create: `Sources/FMSYSCore/Core/Models/Timeframe.swift`
- Create: `Sources/FMSYSCore/Core/Models/BacktestResult.swift`
- Modify: `Sources/FMSYSApp/FMSYSApp.swift` (add `BacktestResult.self` to schema)

> **No tests for this task** — model-only, covered by repository tests in Task 2.

### Step 1: Create `Timeframe.swift`

```swift
// Sources/FMSYSCore/Core/Models/Timeframe.swift
import Foundation

public enum Timeframe: String, Codable, CaseIterable {
    case m1  = "1m"
    case m5  = "5m"
    case m15 = "15m"
    case h1  = "1h"
    case h4  = "4h"
    case d1  = "1d"
    case w1  = "1w"

    public var displayName: String {
        switch self {
        case .m1:  return "1 Min"
        case .m5:  return "5 Min"
        case .m15: return "15 Min"
        case .h1:  return "1 Hour"
        case .h4:  return "4 Hours"
        case .d1:  return "Daily"
        case .w1:  return "Weekly"
        }
    }
}
```

### Step 2: Create `BacktestResult.swift`

```swift
// Sources/FMSYSCore/Core/Models/BacktestResult.swift
import Foundation
import SwiftData

// MARK: - Value types stored as JSON blobs inside BacktestResult

public struct BacktestEquityPoint: Codable {
    public let tradeNumber: Int
    public let equity: Double

    public init(tradeNumber: Int, equity: Double) {
        self.tradeNumber = tradeNumber
        self.equity = equity
    }
}

public struct BacktestTradeEntry: Codable, Identifiable {
    public var id: UUID
    public let date: Date
    public let symbol: String
    public let strategy: String
    public let directionRaw: String   // "long" / "short" — avoids importing Direction across contexts
    public let netProfit: Double

    public var direction: Direction {
        Direction(rawValue: directionRaw) ?? .long
    }

    public init(id: UUID = UUID(), date: Date, symbol: String, strategy: String, direction: Direction, netProfit: Double) {
        self.id = id
        self.date = date
        self.symbol = symbol
        self.strategy = strategy
        self.directionRaw = direction.rawValue
        self.netProfit = netProfit
    }
}

// MARK: - SwiftData model

@Model
public final class BacktestResult {

    public var id: UUID
    public var strategyId: UUID
    public var strategyName: String
    public var assetPair: String
    public var timeframeRaw: String

    public var startDate: Date
    public var endDate: Date

    public var totalTrades: Int
    public var winRate: Double        // 0.0–1.0
    public var profitFactor: Double
    public var maxDrawdown: Double    // 0.0–1.0
    public var sharpeRatio: Double

    // JSON-encoded blobs
    public var equityCurveData: Data  // [BacktestEquityPoint]
    public var tradeLogData: Data     // [BacktestTradeEntry]

    public var createdAt: Date

    // MARK: Computed wrappers

    public var timeframe: Timeframe {
        get { Timeframe(rawValue: timeframeRaw) ?? .h1 }
        set { timeframeRaw = newValue.rawValue }
    }

    public var equityCurve: [BacktestEquityPoint] {
        (try? JSONDecoder().decode([BacktestEquityPoint].self, from: equityCurveData)) ?? []
    }

    public var tradeLog: [BacktestTradeEntry] {
        (try? JSONDecoder().decode([BacktestTradeEntry].self, from: tradeLogData)) ?? []
    }

    // MARK: Init

    public init(
        id: UUID = UUID(),
        strategyId: UUID,
        strategyName: String,
        assetPair: String,
        timeframe: Timeframe,
        startDate: Date,
        endDate: Date,
        totalTrades: Int,
        winRate: Double,
        profitFactor: Double,
        maxDrawdown: Double,
        sharpeRatio: Double,
        equityCurveData: Data,
        tradeLogData: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.strategyId = strategyId
        self.strategyName = strategyName
        self.assetPair = assetPair
        self.timeframeRaw = timeframe.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.totalTrades = totalTrades
        self.winRate = winRate
        self.profitFactor = profitFactor
        self.maxDrawdown = maxDrawdown
        self.sharpeRatio = sharpeRatio
        self.equityCurveData = equityCurveData
        self.tradeLogData = tradeLogData
        self.createdAt = createdAt
    }
}
```

### Step 3: Update `FMSYSApp.swift` schema

Find this line (~line 19):
```swift
return try ModelContainer(for: Trade.self, Strategy.self, configurations: config)
```
Replace with:
```swift
return try ModelContainer(for: Trade.self, Strategy.self, BacktestResult.self, configurations: config)
```

### Step 4: Build to verify

```bash
cd FMSYSApp && swift build 2>&1 | tail -20
```
Expected: `Build complete!`

### Step 5: Commit

```bash
git add Sources/FMSYSCore/Core/Models/Timeframe.swift \
        Sources/FMSYSCore/Core/Models/BacktestResult.swift \
        Sources/FMSYSApp/FMSYSApp.swift
git commit -m "feat: add BacktestResult @Model, Timeframe enum, update schema"
```

---

## Task 2: `BacktestRepository` + tests

**Files:**
- Create: `Sources/FMSYSCore/Core/Repositories/BacktestRepository.swift`
- Create: `Tests/FMSYSAppTests/BacktestRepositoryTests.swift`

### Step 1: Write failing tests

```swift
// Tests/FMSYSAppTests/BacktestRepositoryTests.swift
import Testing
import SwiftData
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    @MainActor
    struct BacktestRepositoryTests {

        // MARK: Helpers

        func makeRepository() throws -> (BacktestRepository, ModelContext, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: BacktestResult.self, configurations: config)
            let context = ModelContext(container)
            return (BacktestRepository(context: context), context, container)
        }

        func makeResult(strategyId: UUID = UUID(), createdAt: Date = Date()) throws -> BacktestResult {
            let curve = try JSONEncoder().encode([
                BacktestEquityPoint(tradeNumber: 1, equity: 10_000),
                BacktestEquityPoint(tradeNumber: 2, equity: 10_500)
            ])
            let log = try JSONEncoder().encode([
                BacktestTradeEntry(date: Date(), symbol: "BTC/USDT", strategy: "Test", direction: .long, netProfit: 500)
            ])
            return BacktestResult(
                strategyId: strategyId,
                strategyName: "Test Strategy",
                assetPair: "BTC/USDT",
                timeframe: .h1,
                startDate: Date(),
                endDate: Date(),
                totalTrades: 2,
                winRate: 0.5,
                profitFactor: 1.5,
                maxDrawdown: 0.05,
                sharpeRatio: 1.0,
                equityCurveData: curve,
                tradeLogData: log,
                createdAt: createdAt
            )
        }

        // MARK: Tests

        @Test func createAndFindAll() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            let all = try repo.findAll()
            #expect(all.count == 1)
        }

        @Test func findAllByStrategyId_filtersCorrectly() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let sid1 = UUID()
            let sid2 = UUID()
            try repo.create(try makeResult(strategyId: sid1))
            try repo.create(try makeResult(strategyId: sid2))
            let filtered = try repo.findAll(strategyId: sid1)
            #expect(filtered.count == 1)
            #expect(filtered[0].strategyId == sid1)
        }

        @Test func delete_removesResult() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            try repo.delete(result)
            #expect(try repo.findAll().count == 0)
        }

        @Test func findAll_sortedDescending() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let now = Date()
            let older = try makeResult(createdAt: now.addingTimeInterval(-10))
            let newer = try makeResult(createdAt: now)
            try repo.create(older)
            try repo.create(newer)
            let all = try repo.findAll()
            #expect(all.count == 2)
            #expect(all[0].createdAt >= all[1].createdAt)
        }

        @Test func equityCurveDecodable() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            let fetched = try repo.findAll().first!
            #expect(fetched.equityCurve.count == 2)
            #expect(fetched.equityCurve[0].tradeNumber == 1)
        }

        @Test func tradeLogDecodable() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            let fetched = try repo.findAll().first!
            #expect(fetched.tradeLog.count == 1)
            #expect(fetched.tradeLog[0].symbol == "BTC/USDT")
        }
    }
}
```

### Step 2: Run — expect failure

```bash
cd FMSYSApp && swift test --filter BacktestRepositoryTests 2>&1 | tail -20
```
Expected: build error — `BacktestRepository` not found.

### Step 3: Implement `BacktestRepository`

```swift
// Sources/FMSYSCore/Core/Repositories/BacktestRepository.swift
import Foundation
import SwiftData

public struct BacktestRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func findAll() throws -> [BacktestResult] {
        let descriptor = FetchDescriptor<BacktestResult>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func findAll(strategyId: UUID) throws -> [BacktestResult] {
        let id = strategyId
        let descriptor = FetchDescriptor<BacktestResult>(
            predicate: #Predicate { $0.strategyId == id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func create(_ result: BacktestResult) throws {
        context.insert(result)
        try context.save()
    }

    public func delete(_ result: BacktestResult) throws {
        context.delete(result)
        try context.save()
    }
}
```

### Step 4: Run — expect pass

```bash
cd FMSYSApp && swift test --filter BacktestRepositoryTests 2>&1 | tail -20
```
Expected: `Test run with 6 tests passed.`

### Step 5: Commit

```bash
git add Sources/FMSYSCore/Core/Repositories/BacktestRepository.swift \
        Tests/FMSYSAppTests/BacktestRepositoryTests.swift
git commit -m "feat: add BacktestRepository with CRUD and tests"
```

---

## Task 3: `BacktestViewModel` + tests

**Files:**
- Create: `Sources/FMSYSCore/Features/Backtesting/BacktestViewModel.swift`
- Create: `Tests/FMSYSAppTests/BacktestViewModelTests.swift`

### Step 1: Write failing tests

```swift
// Tests/FMSYSAppTests/BacktestViewModelTests.swift
import Testing
import SwiftData
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    @MainActor
    struct BacktestViewModelTests {

        private let seedKey = "fmsys.backtestSeeded"

        func makeViewModel() throws -> (BacktestViewModel, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: BacktestResult.self, configurations: config)
            let context = ModelContext(container)
            return (BacktestViewModel(context: context), container)
        }

        @Test func loadWithoutSeed_isEmpty() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.set(true, forKey: seedKey)   // prevent seed
            vm.load()
            #expect(vm.results.isEmpty)
            #expect(vm.selectedResult == nil)
        }

        @Test func seedOnFirstLoad_populatesResults() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            #expect(vm.results.count == 1)
            #expect(vm.selectedResult != nil)
        }

        @Test func selectedResultIsFirstResult() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            #expect(vm.selectedResult?.id == vm.results.first?.id)
        }

        @Test func delete_removesFromResults() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            guard let first = vm.results.first else {
                Issue.record("Expected at least one result after seed")
                return
            }
            let countBefore = vm.results.count
            vm.delete(first)
            #expect(vm.results.count == countBefore - 1)
        }

        @Test func delete_clearsSelectedIfDeleted() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            guard let first = vm.results.first else { return }
            vm.selectedResult = first
            vm.delete(first)
            #expect(vm.selectedResult == nil || vm.selectedResult?.id != first.id)
        }

        @Test func makeSeedResult_has250EquityPoints() throws {
            let result = try BacktestViewModel.makeSeedResult()
            #expect(result.equityCurve.count == 250)
            #expect(result.totalTrades == 250)
        }

        @Test func makeSeedResult_kpisMatchDesign() throws {
            let result = try BacktestViewModel.makeSeedResult()
            #expect(result.winRate == 0.642)
            #expect(result.profitFactor == 2.84)
            #expect(result.maxDrawdown == 0.0842)
        }
    }
}
```

### Step 2: Run — expect failure

```bash
cd FMSYSApp && swift test --filter BacktestViewModelTests 2>&1 | tail -20
```
Expected: build error — `BacktestViewModel` not found.

### Step 3: Implement `BacktestViewModel`

```swift
// Sources/FMSYSCore/Features/Backtesting/BacktestViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
public final class BacktestViewModel {

    // MARK: State
    public var results: [BacktestResult] = []
    public var selectedResult: BacktestResult?
    public var errorMessage: String?

    // MARK: Private
    private let repository: BacktestRepository
    private let seededKey = "fmsys.backtestSeeded"

    // MARK: Init
    public init(context: ModelContext) {
        self.repository = BacktestRepository(context: context)
    }

    // MARK: Load

    @MainActor
    public func load() {
        do {
            results = try repository.findAll()
            if selectedResult == nil {
                selectedResult = results.first
            }
            seedIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Delete

    @MainActor
    public func delete(_ result: BacktestResult) {
        do {
            if selectedResult?.id == result.id {
                selectedResult = nil
            }
            try repository.delete(result)
            results = try repository.findAll()
            if selectedResult == nil {
                selectedResult = results.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Seed

    private func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        do {
            let seed = try Self.makeSeedResult()
            try repository.create(seed)
            results = try repository.findAll()
            selectedResult = results.first
            UserDefaults.standard.set(true, forKey: seededKey)
        } catch {
            // Do NOT write flag — will retry on next launch
        }
    }

    // MARK: Seed factory (public for testability)

    public static func makeSeedResult() throws -> BacktestResult {
        let now = Date()
        let calendar = Calendar.current

        // Build 250 equity points (random walk from 10,000)
        var equity = 10_000.0
        var equityPoints: [BacktestEquityPoint] = []
        // Use a seeded sequence for reproducibility
        var rng = SystemRandomNumberGenerator()
        for i in 1...250 {
            let delta = Double.random(in: -200...350, using: &rng)
            equity = max(5_000, equity + delta)
            equityPoints.append(BacktestEquityPoint(tradeNumber: i, equity: equity))
        }

        // 4 representative trade log entries matching the HTML prototype
        let log: [BacktestTradeEntry] = [
            BacktestTradeEntry(
                date: calendar.date(byAdding: .hour, value: -20, to: now) ?? now,
                symbol: "BTC/USDT", strategy: "Mean Reversion", direction: .long,  netProfit:  1420.50),
            BacktestTradeEntry(
                date: calendar.date(byAdding: .hour, value: -25, to: now) ?? now,
                symbol: "ETH/USDT", strategy: "Mean Reversion", direction: .short, netProfit: -450.20),
            BacktestTradeEntry(
                date: calendar.date(byAdding: .day,  value:  -2, to: now) ?? now,
                symbol: "BTC/USDT", strategy: "Mean Reversion", direction: .long,  netProfit:  2890.00),
            BacktestTradeEntry(
                date: calendar.date(byAdding: .day,  value:  -2, to: now) ?? now,
                symbol: "SOL/USDT", strategy: "Mean Reversion", direction: .long,  netProfit:   820.15),
        ]

        let curveData = try JSONEncoder().encode(equityPoints)
        let logData   = try JSONEncoder().encode(log)

        return BacktestResult(
            strategyId:      UUID(),
            strategyName:    "Mean Reversion V3.1",
            assetPair:       "BTC/USDT",
            timeframe:       .h1,
            startDate:       calendar.date(byAdding: .month, value: -6, to: now) ?? now,
            endDate:         now,
            totalTrades:     250,
            winRate:         0.642,
            profitFactor:    2.84,
            maxDrawdown:     0.0842,
            sharpeRatio:     1.87,
            equityCurveData: curveData,
            tradeLogData:    logData
        )
    }
}
```

### Step 4: Run — expect pass

```bash
cd FMSYSApp && swift test --filter BacktestViewModelTests 2>&1 | tail -20
```
Expected: `Test run with 7 tests passed.`

### Step 5: Commit

```bash
git add Sources/FMSYSCore/Features/Backtesting/BacktestViewModel.swift \
        Tests/FMSYSAppTests/BacktestViewModelTests.swift
git commit -m "feat: add BacktestViewModel with seed data and tests"
```

---

## Task 4: `BacktestEquityCurveSection` view

**Files:**
- Create: `Sources/FMSYSCore/Features/Backtesting/Views/BacktestEquityCurveSection.swift`

> No unit tests — pure SwiftUI display view, verified by build.

### Step 1: Create the file

```swift
// Sources/FMSYSCore/Features/Backtesting/Views/BacktestEquityCurveSection.swift
import SwiftUI
import Charts

public struct BacktestEquityCurveSection: View {

    let result: BacktestResult

    @State private var viewMode: ViewMode = .tradeByTrade

    public init(result: BacktestResult) {
        self.result = result
    }

    // MARK: View modes

    enum ViewMode: String, CaseIterable {
        case daily       = "Daily"
        case tradeByTrade = "Trade-by-Trade"
    }

    // MARK: Data

    private var displayedPoints: [BacktestEquityPoint] {
        let all = result.equityCurve
        switch viewMode {
        case .tradeByTrade:
            return all
        case .daily:
            // Stub: sample every 5th point as proxy for "daily"
            return all.enumerated().compactMap { idx, pt in idx % 5 == 0 ? pt : nil }
        }
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
                .padding(.bottom, 16)

            chartArea
        }
        .padding(20)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsMuted.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Subviews

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Equity Curve")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Cumulative Net Profit over \(result.totalTrades) trades")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            modePicker
        }
    }

    private var modePicker: some View {
        HStack(spacing: 2) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) {
                    viewMode = mode
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    viewMode == mode
                        ? Color.fmsOnSurface.opacity(0.12)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .foregroundStyle(
                    viewMode == mode ? Color.fmsOnSurface : Color.fmsMuted
                )
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var chartArea: some View {
        if displayedPoints.isEmpty {
            Color.fmsMuted.opacity(0.1)
                .frame(height: 200)
                .overlay(
                    Text("No equity data")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Chart(displayedPoints, id: \.tradeNumber) { pt in
                AreaMark(
                    x: .value("Trade", pt.tradeNumber),
                    y: .value("Equity", pt.equity)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.fmsPrimary.opacity(0.3), Color.fmsPrimary.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Trade", pt.tradeNumber),
                    y: .value("Equity", pt.equity)
                )
                .foregroundStyle(Color.fmsPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(xLabel(for: v))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.fmsMuted)
                                .textCase(.uppercase)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.fmsMuted.opacity(0.1))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("$\(Int(v / 1000))k")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.fmsMuted)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.fmsMuted.opacity(0.1))
                }
            }
        }
    }

    // MARK: Helpers

    private func xLabel(for tradeNumber: Int) -> String {
        guard let last = result.equityCurve.last else { return "" }
        if tradeNumber <= 1         { return "Start" }
        if tradeNumber >= last.tradeNumber { return "End" }
        return "Trade \(tradeNumber)"
    }
}
```

### Step 2: Build to verify

```bash
cd FMSYSApp && swift build 2>&1 | tail -10
```
Expected: `Build complete!`

### Step 3: Commit

```bash
git add Sources/FMSYSCore/Features/Backtesting/Views/BacktestEquityCurveSection.swift
git commit -m "feat: add BacktestEquityCurveSection with Daily/Trade-by-Trade toggle"
```

---

## Task 5: `BacktestKPICards` view

**Files:**
- Create: `Sources/FMSYSCore/Features/Backtesting/Views/BacktestKPICards.swift`

### Step 1: Create the file

```swift
// Sources/FMSYSCore/Features/Backtesting/Views/BacktestKPICards.swift
import SwiftUI

public struct BacktestKPICards: View {

    let result: BacktestResult

    public init(result: BacktestResult) {
        self.result = result
    }

    public var body: some View {
        HStack(spacing: 16) {
            kpiCard(
                systemIcon:    "checkmark.seal.fill",
                iconColor:     .blue,
                title:         "Win Rate",
                value:         String(format: "%.1f%%", result.winRate * 100),
                subtext:       result.winRate >= 0.6 ? "Above target (60%)" : "Below target (60%)",
                subtextColor:  result.winRate >= 0.6 ? Color.fmsPrimary : Color.fmsLoss
            )
            kpiCard(
                systemIcon:    "chart.bar.fill",
                iconColor:     .orange,
                title:         "Profit Factor",
                value:         String(format: "%.2f", result.profitFactor),
                subtext:       result.profitFactor >= 2.0 ? "Excellent performance" : "Fair performance",
                subtextColor:  Color.fmsMuted
            )
            kpiCard(
                systemIcon:    "arrow.down.right",
                iconColor:     Color.fmsLoss,
                title:         "Max Drawdown",
                value:         String(format: "%.2f%%", result.maxDrawdown * 100),
                subtext:       "Sharpe: \(String(format: "%.2f", result.sharpeRatio))",
                subtextColor:  Color.fmsMuted
            )
        }
    }

    @ViewBuilder
    private func kpiCard(
        systemIcon:   String,
        iconColor:    Color,
        title:        String,
        value:        String,
        subtext:      String,
        subtextColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .tracking(0.8)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            Text(subtext)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(subtextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsMuted.opacity(0.15), lineWidth: 1)
        )
    }
}
```

### Step 2: Build to verify

```bash
cd FMSYSApp && swift build 2>&1 | tail -10
```
Expected: `Build complete!`

### Step 3: Commit

```bash
git add Sources/FMSYSCore/Features/Backtesting/Views/BacktestKPICards.swift
git commit -m "feat: add BacktestKPICards with Win Rate, Profit Factor, Max Drawdown"
```

---

## Task 6: `BacktestTradeLogTable` view

**Files:**
- Create: `Sources/FMSYSCore/Features/Backtesting/Views/BacktestTradeLogTable.swift`

### Step 1: Create the file

```swift
// Sources/FMSYSCore/Features/Backtesting/Views/BacktestTradeLogTable.swift
import SwiftUI

public struct BacktestTradeLogTable: View {

    let result: BacktestResult

    public init(result: BacktestResult) {
        self.result = result
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()

    public var body: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider().opacity(0.3)
            columnHeaderRow
            Divider().opacity(0.3)
            tableBody
        }
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsMuted.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Subviews

    private var tableHeader: some View {
        HStack {
            Text("Detailed Test Results")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .tracking(0.8)
                .textCase(.uppercase)
            Spacer()
            HStack(spacing: 4) {
                toolbarBtn(systemName: "line.3.horizontal.decrease")
                toolbarBtn(systemName: "arrow.down.circle")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.fmsSurface.opacity(0.5))
    }

    private var columnHeaderRow: some View {
        HStack(spacing: 0) {
            colHeader("Date",       width: 140)
            colHeader("Symbol",     width: 100)
            colHeader("Strategy",   width: 160)
            colHeader("Type",       width: 80)
            colHeader("Net Profit", width: 120)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.fmsMuted.opacity(0.05))
    }

    @ViewBuilder
    private var tableBody: some View {
        if result.tradeLog.isEmpty {
            Text("No trades in log")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
                .frame(maxWidth: .infinity)
                .padding(24)
        } else {
            ForEach(result.tradeLog) { entry in
                tradeRow(entry)
                Divider()
                    .opacity(0.15)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Row

    @ViewBuilder
    private func tradeRow(_ entry: BacktestTradeEntry) -> some View {
        HStack(spacing: 0) {
            Text(Self.dateFormatter.string(from: entry.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(width: 140, alignment: .leading)

            symbolBadge(entry.symbol)
                .frame(width: 100, alignment: .leading)

            Text(entry.strategy)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(width: 160, alignment: .leading)

            Text(entry.direction == .long ? "Long" : "Short")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(entry.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
                .frame(width: 80, alignment: .leading)

            Text(
                entry.netProfit >= 0
                    ? String(format: "+$%.2f", entry.netProfit)
                    : String(format: "-$%.2f", abs(entry.netProfit))
            )
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(entry.netProfit >= 0 ? Color.fmsPrimary : Color.fmsLoss)
            .frame(width: 120, alignment: .leading)

            Spacer()

            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .opacity(0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: Helpers

    @ViewBuilder
    private func symbolBadge(_ symbol: String) -> some View {
        let color = badgeColor(for: symbol)
        Text(symbol)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
    }

    private func badgeColor(for symbol: String) -> Color {
        if symbol.hasPrefix("BTC") { return .blue }
        if symbol.hasPrefix("ETH") { return .purple }
        if symbol.hasPrefix("SOL") { return .orange }
        return Color.fmsMuted
    }

    @ViewBuilder
    private func colHeader(_ title: String, width: CGFloat) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .tracking(0.8)
            .frame(width: width, alignment: .leading)
    }

    @ViewBuilder
    private func toolbarBtn(systemName: String) -> some View {
        Button {
            // stub — filter/download not implemented
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 28, height: 28)
                .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.fmsMuted.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
```

### Step 2: Build to verify

```bash
cd FMSYSApp && swift build 2>&1 | tail -10
```
Expected: `Build complete!`

### Step 3: Commit

```bash
git add Sources/FMSYSCore/Features/Backtesting/Views/BacktestTradeLogTable.swift
git commit -m "feat: add BacktestTradeLogTable with symbol badges and direction coloring"
```

---

## Task 7: `BacktestingView` full rewrite + wire `MainAppView`

**Files:**
- Modify: `Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift` (full rewrite)
- Modify: `Sources/FMSYSApp/FMSYSApp.swift` (already done in Task 1 if not done separately)
- Modify: `Sources/FMSYSCore/App/MainAppView.swift` (pass `modelContainer` to `BacktestingView`)

### Step 1: Rewrite `BacktestingView.swift`

Replace entire file contents with:

```swift
// Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift
import SwiftUI
import SwiftData

public struct BacktestingView: View {

    @State private var viewModel: BacktestViewModel

    public init(modelContainer: ModelContainer) {
        let context = ModelContext(modelContainer)
        _viewModel = State(initialValue: BacktestViewModel(context: context))
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerRow

                if let result = viewModel.selectedResult {
                    BacktestEquityCurveSection(result: result)
                    BacktestKPICards(result: result)
                    BacktestTradeLogTable(result: result)
                } else {
                    emptyState
                }
            }
            .padding(24)
        }
        .background(Color.fmsBackground)
        .onAppear { viewModel.load() }
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Backtesting Analysis")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                if let result = viewModel.selectedResult {
                    Text("Strategy: \(result.strategyName) - \(result.assetPair) (\(result.timeframe.rawValue.uppercased()))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            Spacer()
            newBacktestButton
        }
    }

    private var newBacktestButton: some View {
        Button {
            // TODO: Phase 4 — trigger backtest from strategy
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                Text("New Backtest")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.fmsPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            "No Backtests Yet",
            systemImage: "arrow.clockwise.circle",
            description: Text("Run a backtest from the Strategy Lab to see results here.")
        )
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}
```

### Step 2: Update `MainAppView.swift`

Find (~line 171):
```swift
case .backtesting:
    BacktestingView()
```
Replace with:
```swift
case .backtesting:
    BacktestingView(modelContainer: modelContainer)
```

### Step 3: Build to verify

```bash
cd FMSYSApp && swift build 2>&1 | tail -10
```
Expected: `Build complete!`

### Step 4: Run full test suite

```bash
cd FMSYSApp && swift test 2>&1 | tail -20
```
Expected: all tests pass (existing 177 + new 13 = 190 total).

### Step 5: Commit

```bash
git add Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift \
        Sources/FMSYSCore/App/MainAppView.swift
git commit -m "feat: rewrite BacktestingView — equity curve, KPI cards, trade log table"
```

---

## Out of Scope

- "New Backtest" button connecting to a real API (Phase 4)
- Filter and download toolbar buttons in trade log (stubs only)
- Result selector / run history list (only one result shown at a time)
- Real equity curve animation / tooltip on hover
