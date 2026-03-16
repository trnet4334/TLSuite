# Trading Data Import & Central Data Layer — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build `TradingDataService` as the single source of truth for all trade data across every page, add CSV import with broker auto-detection and column-mapping fallback UI, and add image attachment support with compression to journal notes.

**Architecture:** `TradingDataService` (`@MainActor @Observable`) wraps `TradeRepository` and holds a reactive `trades` array. All ViewModels observe it — mutations go through the service, derived data (KPIs, equity curve, positions) is computed in each ViewModel from the same array. `JournalAttachment` is a new SwiftData `@Model` that stores JPEG-compressed images alongside trades. `CSVImportService` detects broker format, maps rows to `Trade` objects, and falls back to a column-mapping sheet.

**Tech Stack:** SwiftUI, SwiftData, `@Observable`, `@MainActor`, AppKit (`NSImage`), Swift Testing, SPM

**Important context:**
- All source files live under `FMSYSApp/Sources/FMSYSCore/`
- Tests live in `FMSYSApp/Tests/FMSYSAppTests/`
- Run tests: `cd FMSYSApp && swift test`
- Run build: `cd FMSYSApp && swift build`
- Current userId placeholder: `"current-user"` (used everywhere)
- `EquityPoint` is defined in `Features/Dashboard/DashboardViewModel.swift` and is `public` — reuse it in Portfolio
- `@Suite(.serialized)` is **required** on every SwiftData test suite (parallel ModelContainer init crashes)
- SourceKit diagnostics are unreliable — always run `swift build` to confirm compilation

---

### Task 1: TradingDataService

**Files:**
- Create: `Sources/FMSYSCore/Core/Services/TradingDataService.swift`
- Test: `Tests/FMSYSAppTests/TradingDataServiceTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/FMSYSAppTests/TradingDataServiceTests.swift
import Testing
import SwiftData
@testable import FMSYSCore

@Suite(.serialized)
@MainActor
struct TradingDataServiceTests {

    private func makeService() throws -> (TradingDataService, ModelContainer) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Trade.self, configurations: config)
        let service = TradingDataService(modelContainer: container)
        return (service, container)
    }

    @Test func loadAllReturnsEmptyInitially() async throws {
        let (service, _) = try makeService()
        service.loadAll()
        #expect(service.trades.isEmpty)
    }

    @Test func createTrade() async throws {
        let (service, _) = try makeService()
        let trade = Trade(
            userId: "current-user", asset: "AAPL",
            assetCategory: .stocks, direction: .long,
            entryPrice: 150, stopLoss: 145, takeProfit: 160,
            positionSize: 10, entryAt: Date()
        )
        try service.create(trade)
        #expect(service.trades.count == 1)
        #expect(service.trades[0].asset == "AAPL")
    }

    @Test func deleteTrade() async throws {
        let (service, _) = try makeService()
        let trade = Trade(
            userId: "current-user", asset: "AAPL",
            assetCategory: .stocks, direction: .long,
            entryPrice: 150, stopLoss: 145, takeProfit: 160,
            positionSize: 10, entryAt: Date()
        )
        try service.create(trade)
        #expect(service.trades.count == 1)
        try service.delete(service.trades[0])
        #expect(service.trades.isEmpty)
    }

    @Test func tradesForCategory() async throws {
        let (service, _) = try makeService()
        let t1 = Trade(userId: "current-user", asset: "BTC", assetCategory: .crypto,
                       direction: .long, entryPrice: 60000, stopLoss: 55000,
                       takeProfit: 70000, positionSize: 0.5, entryAt: Date(),
                       journalCategory: .crypto)
        let t2 = Trade(userId: "current-user", asset: "AAPL", assetCategory: .stocks,
                       direction: .long, entryPrice: 150, stopLoss: 145,
                       takeProfit: 160, positionSize: 10, entryAt: Date(),
                       journalCategory: .stocksETFs)
        try service.create(t1)
        try service.create(t2)
        let cryptoTrades = service.trades(for: .crypto)
        #expect(cryptoTrades.count == 1)
        #expect(cryptoTrades[0].asset == "BTC")
    }

    @Test func importTradesBatch() async throws {
        let (service, _) = try makeService()
        let trades = (0..<5).map { i in
            Trade(userId: "current-user", asset: "T\(i)", assetCategory: .stocks,
                  direction: .long, entryPrice: Double(100 + i), stopLoss: 95,
                  takeProfit: 110, positionSize: 1, entryAt: Date())
        }
        try service.importTrades(trades)
        #expect(service.trades.count == 5)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd FMSYSApp && swift test --filter TradingDataServiceTests 2>&1 | tail -10
```
Expected: FAIL — `TradingDataService` not found.

**Step 3: Implement TradingDataService**

```swift
// Sources/FMSYSCore/Core/Services/TradingDataService.swift
import Foundation
import SwiftData
import Observation

@MainActor
@Observable
public final class TradingDataService {

    public private(set) var trades: [Trade] = []

    private let modelContainer: ModelContainer
    private let userId = "current-user"

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Read

    public func loadAll() {
        let repo = TradeRepository(context: modelContainer.mainContext)
        trades = (try? repo.findAll(userId: userId)) ?? []
    }

    public func trades(for category: JournalCategory) -> [Trade] {
        guard category != .all else { return trades }
        return trades.filter { $0.journalCategory == category }
    }

    // MARK: - Write

    public func create(_ trade: Trade) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        try repo.create(trade)
        loadAll()
    }

    public func update(_ trade: Trade) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        try repo.save()
        loadAll()
    }

    public func delete(_ trade: Trade) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        try repo.delete(trade)
        loadAll()
    }

    public func importTrades(_ newTrades: [Trade]) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        for trade in newTrades {
            try repo.create(trade)
        }
        loadAll()
    }
}
```

**Step 4: Run test to verify it passes**

```bash
cd FMSYSApp && swift test --filter TradingDataServiceTests 2>&1 | tail -10
```
Expected: All 5 tests PASS.

**Step 5: Build to confirm no regressions**

```bash
cd FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Step 6: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Core/Services/TradingDataService.swift Tests/FMSYSAppTests/TradingDataServiceTests.swift
git commit -m "feat: add TradingDataService as central trade data layer"
```

---

### Task 2: MarketDataServiceProtocol + MockMarketDataService

**Files:**
- Create: `Sources/FMSYSCore/Core/Services/MarketDataService.swift`
- Test: `Tests/FMSYSAppTests/MarketDataServiceTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/FMSYSAppTests/MarketDataServiceTests.swift
import Testing
@testable import FMSYSCore

struct MarketDataServiceTests {

    @Test func mockQuoteReturnsDataForKnownSymbol() async {
        let service = MockMarketDataService()
        let quote = await service.quote(for: "BTC")
        #expect(quote.symbol == "BTC")
        #expect(quote.price > 0)
    }

    @Test func mockQuoteReturnsPlaceholderForUnknownSymbol() async {
        let service = MockMarketDataService()
        let quote = await service.quote(for: "UNKNOWN")
        #expect(quote.symbol == "UNKNOWN")
        #expect(quote.price == 0)
    }

    @Test func mockHistoricalPricesReturnNonEmptyArray() async {
        let service = MockMarketDataService()
        let prices = await service.historicalPrices(symbol: "BTC", range: .oneMonth)
        #expect(!prices.isEmpty)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd FMSYSApp && swift test --filter MarketDataServiceTests 2>&1 | tail -10
```
Expected: FAIL — `MockMarketDataService` not found.

**Step 3: Implement**

```swift
// Sources/FMSYSCore/Core/Services/MarketDataService.swift
import Foundation

// MARK: - Types

public struct MarketQuoteResult {
    public let symbol: String
    public let name: String
    public let price: Double
    public let changePercent: Double
    public let sparkline: [Double]

    public init(symbol: String, name: String, price: Double, changePercent: Double, sparkline: [Double]) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.changePercent = changePercent
        self.sparkline = sparkline
    }
}

public struct PricePoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let price: Double

    public init(date: Date, price: Double) {
        self.date = date
        self.price = price
    }
}

// MARK: - Protocol

public protocol MarketDataServiceProtocol: Sendable {
    func quote(for symbol: String) async -> MarketQuoteResult
    func historicalPrices(symbol: String, range: DashboardRange) async -> [PricePoint]
}

// MARK: - Mock implementation

public struct MockMarketDataService: MarketDataServiceProtocol {

    private static let mockData: [String: (name: String, price: Double, change: Double, sparkline: [Double])] = [
        "BTC":  ("Bitcoin",        64_231.50,  2.4,  [60_000, 61_200, 59_800, 62_500, 63_100, 64_231]),
        "ETH":  ("Ethereum",        3_420.12, -1.2,  [3_500, 3_480, 3_510, 3_450, 3_430, 3_420]),
        "AAPL": ("Apple Inc.",        192.42,  0.8,  [188, 189, 191, 190, 192, 192.42]),
        "MSFT": ("Microsoft Corp.",   425.22,  1.1,  [415, 418, 420, 422, 424, 425.22]),
        "EUR/USD": ("Euro / USD",       1.085, -0.3, [1.09, 1.088, 1.087, 1.086, 1.085, 1.085]),
    ]

    public init() {}

    public func quote(for symbol: String) async -> MarketQuoteResult {
        if let d = Self.mockData[symbol] {
            return MarketQuoteResult(symbol: symbol, name: d.name, price: d.price,
                                    changePercent: d.change, sparkline: d.sparkline)
        }
        return MarketQuoteResult(symbol: symbol, name: symbol, price: 0,
                                 changePercent: 0, sparkline: [])
    }

    public func historicalPrices(symbol: String, range: DashboardRange) async -> [PricePoint] {
        let base = Self.mockData[symbol]?.price ?? 100
        let cal = Calendar.current
        let now = Date()
        let cutoff = range.cutoffDate
        let days = max(1, Int(now.timeIntervalSince(cutoff) / 86_400))
        return (0...days).map { i in
            let date = cal.date(byAdding: .day, value: -(days - i), to: now) ?? now
            let noise = Double.random(in: -0.02...0.02)
            return PricePoint(date: date, price: base * (1 + noise * Double(i) / Double(days)))
        }
    }
}
```

**Step 4: Run test to verify it passes**

```bash
cd FMSYSApp && swift test --filter MarketDataServiceTests 2>&1 | tail -10
```
Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Core/Services/MarketDataService.swift Tests/FMSYSAppTests/MarketDataServiceTests.swift
git commit -m "feat: add MarketDataServiceProtocol and MockMarketDataService"
```

---

### Task 3: Wire MainAppView to TradingDataService

**Files:**
- Modify: `Sources/FMSYSCore/App/MainAppView.swift`

No new tests needed — this is wiring only. Build is the verification.

**Step 1: Read the current file**

Read `Sources/FMSYSCore/App/MainAppView.swift` to get exact current content before editing.

**Step 2: Add TradingDataService state property**

Add after the `@AppStorage("isDarkMode")` line:

```swift
@State private var tradingService: TradingDataService
```

**Step 3: Initialize tradingService in init**

After `self.modelContainer = modelContainer`, add:

```swift
self._tradingService = State(wrappedValue: TradingDataService(modelContainer: modelContainer))
```

**Step 4: Load data on app shell appear**

In `appShell`, add `.task` modifier after `.preferredColorScheme`:

```swift
private var appShell: some View {
    VStack(spacing: 0) {
        titleBar
        HStack(spacing: 0) {
            SidebarView(selection: $selectedScreen, journalCategory: $journalCategory)
            Divider()
            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        StatusBar()
    }
    .task { tradingService.loadAll() }
}
```

**Step 5: Update screenContent to pass tradingService**

Replace the `screenContent` computed property:

```swift
@ViewBuilder
private var screenContent: some View {
    switch selectedScreen {
    case .dashboard:
        DashboardView(trades: tradingService.trades)
    case .journal:
        JournalDetailView(
            category: journalCategory,
            tradingService: tradingService
        )
    case .backtesting:
        BacktestingView(modelContainer: modelContainer)
    case .strategyLab:
        StrategyLabView(modelContainer: modelContainer)
    case .portfolio:
        PortfolioView(trades: tradingService.trades)
    }
}
```

**Step 6: Remove the old loadTrades() helper**

Delete the entire `private func loadTrades() -> [Trade]` method (it's no longer needed).

**Step 7: Build to verify**

```bash
cd FMSYSApp && swift build 2>&1 | tail -10
```

There will be compile errors about `JournalDetailView` and `PortfolioView` not accepting new params. **Do not fix those yet** — note them and proceed. They will be fixed in Tasks 4 and 5.

> **Note:** If `JournalDetailView` and `PortfolioView` errors block the build, temporarily revert those two `screenContent` cases to the old form and put a `// TODO:` comment. The important thing is the `tradingService` state property and init compile.

**Step 8: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/App/MainAppView.swift
git commit -m "feat: wire TradingDataService into MainAppView"
```

---

### Task 4: Update JournalDetailView + TradeViewModel to use TradingDataService

**Files:**
- Modify: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/TradeViewModel.swift`
- Modify: All callers of `TradeViewModel.init` within Journal views

**Context:** `JournalDetailView` currently takes `(category:modelContainer:)`. We change it to `(category:tradingService:)`. `TradeViewModel` currently takes `(repository:userId:)`. We add a convenience init that takes `TradingDataService`.

**Step 1: Read current JournalDetailView.swift**

Read `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift` to see exactly how TradeViewModel is initialized there.

**Step 2: Update TradeViewModel**

Add a new init that wraps TradingDataService, while keeping the existing init for backward compatibility with tests:

```swift
// Add to TradeViewModel.swift, after existing init:

private var service: TradingDataService?

public convenience init(service: TradingDataService, userId: String = "current-user") {
    // We still need a repository for the convenience init — create a dummy one
    // The service provides the real data source
    fatalError("Use init(repository:userId:) for test setup; this init is for production use")
}
```

> **Actually:** The simplest approach is to keep `TradeViewModel` as-is and have `JournalDetailView` create the `TradeViewModel` from `tradingService.modelContainer`. But `TradingDataService` doesn't expose `modelContainer` publicly.

**Revised approach — simplest change:**

1. Add `public let modelContainer: ModelContainer` as a public stored property in `TradingDataService`.
2. Change `JournalDetailView` init from `(category:modelContainer:)` to `(category:tradingService:)`.
3. Inside `JournalDetailView`, pass `tradingService.modelContainer` where it currently uses `modelContainer`.
4. After any TradeViewModel mutation, call `tradingService.loadAll()` via a callback or environment.

**Step 3: Add modelContainer public property to TradingDataService**

Edit `Sources/FMSYSCore/Core/Services/TradingDataService.swift`:

Change:
```swift
private let modelContainer: ModelContainer
```
To:
```swift
public let modelContainer: ModelContainer
```

**Step 4: Update JournalDetailView signature**

Read the file first, then change:
- `init(category:modelContainer:)` → `init(category:tradingService:)`
- Store `tradingService` instead of `modelContainer`
- Pass `tradingService.modelContainer` anywhere `modelContainer` was used
- After TradeViewModel mutations succeed, call `tradingService.loadAll()`

The call to `tradingService.loadAll()` after mutations ensures Dashboard/Portfolio stay fresh. Pass it via a closure parameter to TradeViewModel or call it directly in JournalDetailView via `.onChange`.

**Simplest pattern** — add `onTradesChanged: @escaping () -> Void` to `TradeViewModel` that is called after every mutation:

```swift
// In TradeViewModel, add:
public var onTradesChanged: (() -> Void)?

// At the end of createTrade, updateTrade, deleteTrade:
onTradesChanged?()
```

Then in JournalDetailView after creating TradeViewModel:
```swift
viewModel.onTradesChanged = { tradingService.loadAll() }
```

**Step 5: Build**

```bash
cd FMSYSApp && swift build 2>&1 | tail -10
```
Expected: `Build complete!`

**Step 6: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -20
```
Expected: All existing tests PASS. (TradeViewModel tests use the repository-based init which still works.)

**Step 7: Commit**

```bash
cd FMSYSApp && git add -p
git commit -m "feat: wire JournalDetailView to TradingDataService"
```

---

### Task 5: Update PortfolioViewModel with real trade data

**Files:**
- Modify: `Sources/FMSYSCore/Features/Portfolio/PortfolioViewModel.swift`
- Modify: `Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift`
- Modify: `Tests/FMSYSAppTests/PortfolioViewModelTests.swift`

**Step 1: Read current PortfolioViewModel.swift and PortfolioViewModelTests.swift**

Read both files to understand current stub data and existing tests.

**Step 2: Update PortfolioViewModel to accept [Trade]**

Replace the current all-stub `PortfolioViewModel` with one that derives real data:

```swift
// Sources/FMSYSCore/Features/Portfolio/PortfolioViewModel.swift
import Foundation
import Observation
import SwiftUI

@Observable
public final class PortfolioViewModel {

    public var trades: [Trade]
    public var selectedRange: PortfolioRange = .ytd

    public init(trades: [Trade] = []) {
        self.trades = trades
    }

    // MARK: - Open positions (no exitPrice)

    public var openTrades: [Trade] {
        trades.filter { $0.exitPrice == nil }
    }

    public var closedTrades: [Trade] {
        trades.filter { $0.exitPrice != nil }
    }

    // MARK: - KPIs

    public var totalPnL: Double {
        closedTrades.reduce(0.0) { sum, t in
            guard let exit = t.exitPrice else { return sum }
            let m = t.direction == .long ? 1.0 : -1.0
            return sum + (exit - t.entryPrice) * m * t.positionSize
        }
    }

    public var dailyPnL: Double {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return closedTrades
            .filter { ($0.exitAt ?? $0.entryAt) >= todayStart }
            .reduce(0.0) { sum, t in
                guard let exit = t.exitPrice else { return sum }
                let m = t.direction == .long ? 1.0 : -1.0
                return sum + (exit - t.entryPrice) * m * t.positionSize
            }
    }

    public var marginUtilization: Double {
        guard !trades.isEmpty else { return 0 }
        return Double(openTrades.count) / Double(max(trades.count, 1))
    }

    // MARK: - Equity curve

    public var performanceCurve: [EquityPoint] {
        let sorted = closedTrades.sorted { ($0.exitAt ?? $0.entryAt) < ($1.exitAt ?? $1.entryAt) }
        var cumulative = 0.0
        return sorted.map { t in
            let exit = t.exitPrice ?? t.entryPrice
            let m = t.direction == .long ? 1.0 : -1.0
            cumulative += (exit - t.entryPrice) * m * t.positionSize
            return EquityPoint(date: t.exitAt ?? t.entryAt, value: cumulative)
        }
    }

    // MARK: - Positions (group open trades by asset)

    public var positions: [PortfolioPosition] {
        var grouped: [String: [Trade]] = [:]
        for trade in openTrades {
            grouped[trade.asset, default: []].append(trade)
        }
        return grouped.map { symbol, group in
            let avgEntry = group.map(\.entryPrice).reduce(0, +) / Double(group.count)
            let totalSize = group.map(\.positionSize).reduce(0, +)
            // Market value = entry value (no live price in mock)
            let marketValue = avgEntry * totalSize
            return PortfolioPosition(
                id: symbol, name: symbol,
                qty: totalSize,
                lastPrice: avgEntry,
                marketValue: marketValue,
                unrealizedPnL: 0   // 0 until MarketDataService provides live price
            )
        }.sorted { $0.marketValue > $1.marketValue }
    }

    // MARK: - Asset allocation (by journalCategory of open trades)

    public var allocation: [AllocationSlice] {
        let colors: [JournalCategory: Color] = [
            .stocksETFs: Color(red: 0.231, green: 0.510, blue: 0.965),
            .crypto:     Color(red: 1.0,   green: 0.584, blue: 0.0),
            .forex:      Color(red: 0.663, green: 0.329, blue: 1.0),
            .options:    Color.fmsPrimary,
        ]
        let total = Double(max(openTrades.count, 1))
        return JournalCategory.allCases
            .filter { $0 != .all }
            .compactMap { cat -> AllocationSlice? in
                let count = openTrades.filter { $0.journalCategory == cat }.count
                guard count > 0 else { return nil }
                return AllocationSlice(
                    id: cat.rawValue, name: cat.rawValue,
                    percent: Double(count) / total,
                    color: colors[cat] ?? .gray
                )
            }
    }
}
```

**Step 3: Update PortfolioView init**

Read `Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift`, then change its init to accept `trades: [Trade]` and create `PortfolioViewModel(trades: trades)` internally.

```swift
// In PortfolioView:
@State private var viewModel: PortfolioViewModel

public init(trades: [Trade]) {
    self._viewModel = State(wrappedValue: PortfolioViewModel(trades: trades))
}
```

Add `.onChange(of: trades)` to refresh the viewModel when trades change:

```swift
.onChange(of: trades) { _, newTrades in
    viewModel.trades = newTrades
}
```

**Step 4: Update PortfolioViewModelTests**

Read `Tests/FMSYSAppTests/PortfolioViewModelTests.swift`, then update tests to create `PortfolioViewModel(trades: [...])` instead of `PortfolioViewModel()`. Fix or replace stub-based assertions with real-data assertions.

**Step 5: Run tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -20
```
Expected: All tests PASS.

**Step 6: Build**

```bash
cd FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Step 7: Commit**

```bash
cd FMSYSApp && git add -p
git commit -m "feat: PortfolioViewModel derives from real trade data"
```

---

### Task 6: JournalAttachment SwiftData model

**Files:**
- Create: `Sources/FMSYSCore/Core/Models/JournalAttachment.swift`
- Modify: `Sources/FMSYSApp/FMSYSApp.swift` (add to schema)
- Test: `Tests/FMSYSAppTests/JournalAttachmentTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/FMSYSAppTests/JournalAttachmentTests.swift
import Testing
import SwiftData
@testable import FMSYSCore

@Suite(.serialized)
struct JournalAttachmentTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: JournalAttachment.self, configurations: config)
    }

    @Test func insertAndFetchAttachment() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tradeId = UUID()
        let attachment = JournalAttachment(
            tradeId: tradeId,
            imageData: Data([0xFF, 0xD8, 0xFF]),   // JPEG header bytes
            thumbnailData: Data([0x89, 0x50, 0x4E]),
            originalFileName: "screenshot.jpg"
        )
        ctx.insert(attachment)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<JournalAttachment>())
        #expect(fetched.count == 1)
        #expect(fetched[0].tradeId == tradeId)
        #expect(fetched[0].originalFileName == "screenshot.jpg")
    }

    @Test func fetchByTradeId() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let id1 = UUID()
        let id2 = UUID()
        ctx.insert(JournalAttachment(tradeId: id1, imageData: Data(), thumbnailData: Data(), originalFileName: "a.jpg"))
        ctx.insert(JournalAttachment(tradeId: id2, imageData: Data(), thumbnailData: Data(), originalFileName: "b.jpg"))
        try ctx.save()

        let targetId = id1
        let results = try ctx.fetch(FetchDescriptor<JournalAttachment>(
            predicate: #Predicate { $0.tradeId == targetId }
        ))
        #expect(results.count == 1)
        #expect(results[0].originalFileName == "a.jpg")
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd FMSYSApp && swift test --filter JournalAttachmentTests 2>&1 | tail -10
```
Expected: FAIL — `JournalAttachment` not found.

**Step 3: Create JournalAttachment model**

```swift
// Sources/FMSYSCore/Core/Models/JournalAttachment.swift
import Foundation
import SwiftData

@Model
public final class JournalAttachment {
    public var id: UUID
    public var tradeId: UUID
    public var imageData: Data
    public var thumbnailData: Data
    public var originalFileName: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        tradeId: UUID,
        imageData: Data,
        thumbnailData: Data,
        originalFileName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tradeId = tradeId
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.originalFileName = originalFileName
        self.createdAt = createdAt
    }
}
```

**Step 4: Add JournalAttachment to schema in FMSYSApp.swift**

Read `Sources/FMSYSApp/FMSYSApp.swift` to find the `ModelContainer` creation, then add `JournalAttachment.self` to the schema. It will look something like:

```swift
// Find the line that creates ModelContainer, e.g.:
let container = try ModelContainer(for: Trade.self, Strategy.self, BacktestResult.self, ...)
// Add JournalAttachment.self to that list
let container = try ModelContainer(for: Trade.self, Strategy.self, BacktestResult.self, JournalAttachment.self, ...)
```

**Step 5: Run test to verify it passes**

```bash
cd FMSYSApp && swift test --filter JournalAttachmentTests 2>&1 | tail -10
```
Expected: All 2 tests PASS.

**Step 6: Build**

```bash
cd FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Step 7: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Core/Models/JournalAttachment.swift Sources/FMSYSApp/FMSYSApp.swift Tests/FMSYSAppTests/JournalAttachmentTests.swift
git commit -m "feat: add JournalAttachment SwiftData model"
```

---

### Task 7: ImageCompressionService

**Files:**
- Create: `Sources/FMSYSCore/Core/Services/ImageCompressionService.swift`
- Test: `Tests/FMSYSAppTests/ImageCompressionServiceTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/FMSYSAppTests/ImageCompressionServiceTests.swift
import Testing
import AppKit
@testable import FMSYSCore

struct ImageCompressionServiceTests {

    private func makeTestImage(width: Int, height: Int) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }

    @Test func compressProducesNonEmptyData() throws {
        let service = ImageCompressionService()
        let image = makeTestImage(width: 800, height: 600)
        let result = try service.compress(image)
        #expect(!result.imageData.isEmpty)
        #expect(!result.thumbnailData.isEmpty)
    }

    @Test func largeImageIsResizedBelow1920() throws {
        let service = ImageCompressionService()
        let image = makeTestImage(width: 3000, height: 2000)
        let result = try service.compress(image)
        // Decompress and check dimensions
        guard let compressed = NSImage(data: result.imageData) else {
            Issue.record("Could not decode compressed image")
            return
        }
        let maxEdge = max(compressed.size.width, compressed.size.height)
        #expect(maxEdge <= ImageCompressionService.maxDimension)
    }

    @Test func thumbnailIsSmallerThanMain() throws {
        let service = ImageCompressionService()
        let image = makeTestImage(width: 800, height: 600)
        let result = try service.compress(image)
        #expect(result.thumbnailData.count < result.imageData.count)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd FMSYSApp && swift test --filter ImageCompressionServiceTests 2>&1 | tail -10
```
Expected: FAIL — `ImageCompressionService` not found.

**Step 3: Implement ImageCompressionService**

```swift
// Sources/FMSYSCore/Core/Services/ImageCompressionService.swift
import AppKit
import Foundation

public struct CompressionResult {
    public let imageData: Data
    public let thumbnailData: Data
}

public struct ImageCompressionService {

    public static let maxDimension: CGFloat = 1920
    public static let jpegQuality: CGFloat  = 0.75
    public static let thumbnailSize: CGFloat = 120

    public init() {}

    public func compress(_ image: NSImage) throws -> CompressionResult {
        let resized = resize(image, maxEdge: Self.maxDimension)
        let thumbnail = resize(image, maxEdge: Self.thumbnailSize)

        guard
            let imageData     = jpegData(from: resized,   quality: Self.jpegQuality),
            let thumbnailData = jpegData(from: thumbnail, quality: 0.6)
        else {
            throw CompressionError.encodingFailed
        }
        return CompressionResult(imageData: imageData, thumbnailData: thumbnailData)
    }

    // MARK: - Private helpers

    private func resize(_ image: NSImage, maxEdge: CGFloat) -> NSImage {
        let original = image.size
        let scale = min(maxEdge / original.width, maxEdge / original.height, 1.0)
        guard scale < 1.0 else { return image }    // already fits
        let newSize = NSSize(width: original.width * scale, height: original.height * scale)
        let result = NSImage(size: newSize)
        result.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: original),
                   operation: .copy, fraction: 1.0)
        result.unlockFocus()
        return result
    }

    private func jpegData(from image: NSImage, quality: CGFloat) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }
}

public enum CompressionError: Error {
    case encodingFailed
}
```

**Step 4: Run test to verify it passes**

```bash
cd FMSYSApp && swift test --filter ImageCompressionServiceTests 2>&1 | tail -10
```
Expected: All 3 tests PASS.

**Step 5: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Core/Services/ImageCompressionService.swift Tests/FMSYSAppTests/ImageCompressionServiceTests.swift
git commit -m "feat: add ImageCompressionService (resize + JPEG encode + thumbnail)"
```

---

### Task 8: Journal image attachment UI

**Files:**
- Create: `Sources/FMSYSCore/Features/Journal/Views/AttachmentsSection.swift`
- Modify: Each detail panel that shows notes (Stocks, Crypto, Forex, Options)
- Modify: `Sources/FMSYSCore/Features/Journal/TradeViewModel.swift`

**Step 1: Read StocksDetailPanel.swift**

Read `Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksDetailPanel.swift` to understand the detail panel pattern, then apply the same changes to all four category panels.

**Step 2: Add attachment methods to TradeViewModel**

Add to `TradeViewModel.swift`:

```swift
// Add stored property
public var attachments: [JournalAttachment] = []

// Add methods
public func loadAttachments(for tradeId: UUID, context: ModelContext) {
    let id = tradeId
    let descriptor = FetchDescriptor<JournalAttachment>(
        predicate: #Predicate { $0.tradeId == id },
        sortBy: [SortDescriptor(\.createdAt)]
    )
    attachments = (try? context.fetch(descriptor)) ?? []
}

public func addAttachment(image: NSImage, tradeId: UUID, context: ModelContext) throws {
    let service = ImageCompressionService()
    let result = try service.compress(image)
    let attachment = JournalAttachment(
        tradeId: tradeId,
        imageData: result.imageData,
        thumbnailData: result.thumbnailData,
        originalFileName: "attachment-\(Date().timeIntervalSince1970).jpg"
    )
    context.insert(attachment)
    try context.save()
    loadAttachments(for: tradeId, context: context)
    onTradesChanged?()
}

public func deleteAttachment(_ attachment: JournalAttachment, context: ModelContext) throws {
    context.delete(attachment)
    try context.save()
    attachments.removeAll { $0.id == attachment.id }
}
```

**Step 3: Create AttachmentsSection view**

```swift
// Sources/FMSYSCore/Features/Journal/Views/AttachmentsSection.swift
import SwiftUI
import AppKit

public struct AttachmentsSection: View {
    let attachments: [JournalAttachment]
    let onAdd: () -> Void
    let onDelete: (JournalAttachment) -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Attachments")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.fmsMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsPrimary)
                }
                .buttonStyle(.plain)
            }

            if attachments.isEmpty {
                Text("No attachments")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(attachments) { attachment in
                            attachmentThumbnail(attachment)
                        }
                    }
                }
            }
        }
        .onDrop(of: [.image], isTargeted: nil) { providers in
            providers.first?.loadDataRepresentation(for: .image) { data, _ in
                guard let data,
                      let image = NSImage(data: data) else { return }
                DispatchQueue.main.async { onAdd() }
                // Note: full drop-to-NSImage flow handled by caller
                _ = image
            }
            return true
        }
    }

    private func attachmentThumbnail(_ attachment: JournalAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            if let img = NSImage(data: attachment.thumbnailData) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.fmsCardBackground)
                    .frame(width: 80, height: 80)
            }
            Button {
                onDelete(attachment)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsLoss)
                    .background(Color.fmsBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
    }
}
```

**Step 4: Wire AttachmentsSection into detail panels**

For each detail panel (Stocks, Crypto, Forex, Options), add a file picker trigger:

```swift
// Add to the detail panel's @State:
@State private var showingFilePicker = false

// Add in the view body (after notes field):
AttachmentsSection(
    attachments: viewModel.attachments,
    onAdd: { showingFilePicker = true },
    onDelete: { attachment in
        try? viewModel.deleteAttachment(attachment, context: modelContext)
    }
)
.fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.image]) { result in
    guard let url = try? result.get(),
          url.startAccessingSecurityScopedResource(),
          let image = NSImage(contentsOf: url) else { return }
    url.stopAccessingSecurityScopedResource()
    try? viewModel.addAttachment(image: image, tradeId: trade.id, context: modelContext)
}
```

You will need `@Environment(\.modelContext) private var modelContext` in each detail panel view. Read each file before editing to understand how it's structured.

**Step 5: Build**

```bash
cd FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Step 6: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -10
```
Expected: All tests PASS.

**Step 7: Commit**

```bash
cd FMSYSApp && git add -p
git commit -m "feat: journal image attachments with compression"
```

---

### Task 9: CSVImportService — parser, detector, mappers

**Files:**
- Create: `Sources/FMSYSCore/Core/Services/CSV/CSVParser.swift`
- Create: `Sources/FMSYSCore/Core/Services/CSV/BrokerFormatDetector.swift`
- Create: `Sources/FMSYSCore/Core/Services/CSV/TradeMappers.swift`
- Create: `Sources/FMSYSCore/Core/Services/CSV/CSVImportService.swift`
- Test: `Tests/FMSYSAppTests/CSVImportServiceTests.swift`

**Step 1: Write the failing tests**

```swift
// Tests/FMSYSAppTests/CSVImportServiceTests.swift
import Testing
@testable import FMSYSCore

struct CSVParserTests {
    @Test func parsesHeaderAndRows() {
        let csv = "symbol,price,date\nAAPL,150.0,2024-01-15\nMSFT,425.0,2024-01-16"
        let rows = CSVParser.parse(csv)
        #expect(rows.count == 2)
        #expect(rows[0]["symbol"] == "AAPL")
        #expect(rows[0]["price"] == "150.0")
        #expect(rows[1]["symbol"] == "MSFT")
    }

    @Test func handlesQuotedFields() {
        let csv = "name,notes\n\"Apple, Inc.\",\"buy low, sell high\""
        let rows = CSVParser.parse(csv)
        #expect(rows.count == 1)
        #expect(rows[0]["name"] == "Apple, Inc.")
        #expect(rows[0]["notes"] == "buy low, sell high")
    }
}

struct BrokerFormatDetectorTests {
    @Test func detectsIBKR() {
        let headers = ["Symbol", "Quantity", "T. Price", "C. Price", "Proceeds", "Comm/Fee", "Date/Time"]
        #expect(BrokerFormatDetector.detect(headers: headers) == .ibkr)
    }

    @Test func detectsBinance() {
        let headers = ["Date(UTC)", "Pair", "Side", "Price", "Executed", "Amount", "Fee"]
        #expect(BrokerFormatDetector.detect(headers: headers) == .binance)
    }

    @Test func returnsUnknownForUnrecognized() {
        let headers = ["foo", "bar", "baz"]
        #expect(BrokerFormatDetector.detect(headers: headers) == .unknown)
    }
}

struct TradeMapperTests {
    @Test func genericMapperMapsRequiredFields() throws {
        let row: [String: String] = [
            "symbol": "AAPL",
            "direction": "long",
            "entryPrice": "150.0",
            "entryTime": "2024-01-15T09:30:00Z",
            "positionSize": "10",
            "stopLoss": "145",
            "takeProfit": "160"
        ]
        let trade = try GenericTradeMapper.map(row: row, userId: "test-user")
        #expect(trade.asset == "AAPL")
        #expect(trade.direction == .long)
        #expect(trade.entryPrice == 150.0)
        #expect(trade.positionSize == 10)
    }

    @Test func mapperThrowsOnMissingRequiredField() {
        let row: [String: String] = ["symbol": "AAPL"]   // missing price, time, etc.
        #expect(throws: CSVMappingError.self) {
            _ = try GenericTradeMapper.map(row: row, userId: "test-user")
        }
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd FMSYSApp && swift test --filter CSVParserTests 2>&1 | tail -10
```
Expected: FAIL — types not found.

**Step 3: Implement CSVParser**

```swift
// Sources/FMSYSCore/Core/Services/CSV/CSVParser.swift
import Foundation

public struct CSVParser {

    /// Parses CSV text into an array of [header: value] dictionaries.
    public static func parse(_ text: String) -> [[String: String]] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let headerLine = lines.first else { return [] }
        let headers = parseRow(headerLine)
        return lines.dropFirst().compactMap { line -> [String: String]? in
            let values = parseRow(line)
            guard values.count == headers.count else { return nil }
            return Dictionary(uniqueKeysWithValues: zip(headers, values))
        }
    }

    public static func headers(from text: String) -> [String] {
        guard let firstLine = text.components(separatedBy: .newlines).first else { return [] }
        return parseRow(firstLine)
    }

    public static func preview(text: String, maxRows: Int = 3) -> [[String]] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return Array(lines.dropFirst().prefix(maxRows)).map { parseRow($0) }
    }

    // MARK: - Row parser (handles quoted fields with commas)

    static func parseRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}
```

**Step 4: Implement BrokerFormatDetector**

```swift
// Sources/FMSYSCore/Core/Services/CSV/BrokerFormatDetector.swift
import Foundation

public enum BrokerFormat: Equatable {
    case ibkr
    case tdAmeritrade
    case binance
    case generic
    case unknown
}

public struct BrokerFormatDetector {

    private static let ibkrSignature    = Set(["Symbol", "T. Price", "Proceeds", "Comm/Fee"])
    private static let tdSignature      = Set(["Symbol", "Qty", "Price", "Gross Amount", "Reg Fee"])
    private static let binanceSignature = Set(["Date(UTC)", "Pair", "Side", "Executed", "Fee"])
    private static let genericRequired  = Set(["symbol", "entryPrice", "entryTime"])

    public static func detect(headers: [String]) -> BrokerFormat {
        let headerSet = Set(headers)
        if ibkrSignature.isSubset(of: headerSet)    { return .ibkr }
        if tdSignature.isSubset(of: headerSet)      { return .tdAmeritrade }
        if binanceSignature.isSubset(of: headerSet) { return .binance }
        if genericRequired.isSubset(of: headerSet)  { return .generic }
        return .unknown
    }
}
```

**Step 5: Implement TradeMappers**

```swift
// Sources/FMSYSCore/Core/Services/CSV/TradeMappers.swift
import Foundation

public enum CSVMappingError: Error, LocalizedError {
    case missingRequiredField(String)
    case invalidNumber(String)
    case invalidDate(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredField(let f): return "Missing required field: \(f)"
        case .invalidNumber(let v):        return "Invalid number: \(v)"
        case .invalidDate(let v):          return "Invalid date: \(v)"
        }
    }
}

// MARK: - Shared helpers

private let dateFormatters: [DateFormatter] = {
    ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy"].map {
        let f = DateFormatter()
        f.dateFormat = $0
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }
}()

func parseDate(_ str: String) throws -> Date {
    for f in dateFormatters {
        if let d = f.date(from: str) { return d }
    }
    throw CSVMappingError.invalidDate(str)
}

func parseDouble(_ str: String) throws -> Double {
    let cleaned = str.replacingOccurrences(of: "[,$]", with: "", options: .regularExpression)
    guard let d = Double(cleaned) else { throw CSVMappingError.invalidNumber(str) }
    return d
}

func required(_ row: [String: String], _ key: String) throws -> String {
    guard let v = row[key], !v.isEmpty else { throw CSVMappingError.missingRequiredField(key) }
    return v
}

// MARK: - Generic mapper (our own format)

public struct GenericTradeMapper {
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let symbol    = try required(row, "symbol")
        let price     = try parseDouble(try required(row, "entryPrice"))
        let date      = try parseDate(try required(row, "entryTime"))
        let dirStr    = row["direction"] ?? "long"
        let direction = Direction(rawValue: dirStr.lowercased()) ?? .long
        let size      = try parseDouble(try required(row, "positionSize"))
        let sl        = (try? parseDouble(row["stopLoss"] ?? "")) ?? 0
        let tp        = (try? parseDouble(row["takeProfit"] ?? "")) ?? 0
        let exitPrice = row["exitPrice"].flatMap { try? parseDouble($0) }
        let catStr    = row["category"] ?? "Stocks/ETFs"
        let category  = JournalCategory(rawValue: catStr) ?? .stocksETFs

        return Trade(
            userId: userId, asset: symbol,
            assetCategory: category.assetCategory,
            direction: direction,
            entryPrice: price, stopLoss: sl, takeProfit: tp,
            positionSize: size, entryAt: date,
            exitPrice: exitPrice,
            notes: row["notes"],
            journalCategory: category
        )
    }
}

// MARK: - IBKR mapper

public struct IBKRTradeMapper {
    // IBKR columns: Symbol, Quantity, T. Price, C. Price, Proceeds, Comm/Fee, Date/Time
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let symbol    = try required(row, "Symbol")
        let price     = try parseDouble(try required(row, "T. Price"))
        let date      = try parseDate(try required(row, "Date/Time"))
        let qty       = try parseDouble(try required(row, "Quantity"))
        let direction: Direction = qty >= 0 ? .long : .short

        return Trade(
            userId: userId, asset: symbol,
            assetCategory: .stocks,
            direction: direction,
            entryPrice: price, stopLoss: 0, takeProfit: 0,
            positionSize: abs(qty), entryAt: date,
            journalCategory: .stocksETFs
        )
    }
}

// MARK: - Binance mapper

public struct BinanceTradeMapper {
    // Binance columns: Date(UTC), Pair, Side, Price, Executed, Amount, Fee
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let pair      = try required(row, "Pair")
        let price     = try parseDouble(try required(row, "Price"))
        let date      = try parseDate(try required(row, "Date(UTC)"))
        let sideStr   = try required(row, "Side")
        let direction: Direction = sideStr.uppercased() == "BUY" ? .long : .short
        let qty       = try parseDouble(try required(row, "Executed"))

        return Trade(
            userId: userId, asset: pair,
            assetCategory: .crypto,
            direction: direction,
            entryPrice: price, stopLoss: 0, takeProfit: 0,
            positionSize: qty, entryAt: date,
            journalCategory: .crypto
        )
    }
}

// MARK: - TD Ameritrade mapper

public struct TDTradeMapper {
    // TD columns: Symbol, Qty, Price, Gross Amount, Reg Fee, Net Amount, Date
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let symbol    = try required(row, "Symbol")
        let price     = try parseDouble(try required(row, "Price"))
        let date      = try parseDate(try required(row, "Date"))
        let qty       = try parseDouble(try required(row, "Qty"))
        let direction: Direction = qty >= 0 ? .long : .short

        return Trade(
            userId: userId, asset: symbol,
            assetCategory: .stocks,
            direction: direction,
            entryPrice: price, stopLoss: 0, takeProfit: 0,
            positionSize: abs(qty), entryAt: date,
            journalCategory: .stocksETFs
        )
    }
}
```

**Step 6: Implement CSVImportService**

```swift
// Sources/FMSYSCore/Core/Services/CSV/CSVImportService.swift
import Foundation

public struct CSVImportResult {
    public let trades: [Trade]
    public let failedRows: [(rowIndex: Int, error: Error)]
    public let detectedFormat: BrokerFormat
    public let requiresMapping: Bool   // true if format == .unknown
}

public struct CSVImportService {

    private let userId: String

    public init(userId: String = "current-user") {
        self.userId = userId
    }

    /// Phase 1: Detect format and parse rows.
    /// Returns `requiresMapping = true` if the format is .unknown — caller shows ColumnMappingSheet.
    public func analyze(csvText: String) -> (format: BrokerFormat, headers: [String], preview: [[String]]) {
        let headers = CSVParser.headers(from: csvText)
        let format  = BrokerFormatDetector.detect(headers: headers)
        let preview = CSVParser.preview(text: csvText, maxRows: 3)
        return (format, headers, preview)
    }

    /// Phase 2: Map rows to Trade objects using the detected (or user-supplied) format.
    public func map(csvText: String, format: BrokerFormat, columnMapping: [String: String] = [:]) -> CSVImportResult {
        let rows = CSVParser.parse(csvText)
        var trades: [Trade] = []
        var failed: [(Int, Error)] = []

        for (idx, var row) in rows.enumerated() {
            // Apply user-provided column mapping (renames CSV keys to expected keys)
            if !columnMapping.isEmpty {
                var remapped: [String: String] = [:]
                for (csvKey, tradeKey) in columnMapping {
                    if let val = row[csvKey] { remapped[tradeKey] = val }
                }
                row = remapped
            }

            do {
                let trade: Trade
                switch format {
                case .ibkr:          trade = try IBKRTradeMapper.map(row: row, userId: userId)
                case .tdAmeritrade:  trade = try TDTradeMapper.map(row: row, userId: userId)
                case .binance:       trade = try BinanceTradeMapper.map(row: row, userId: userId)
                case .generic, .unknown:
                    trade = try GenericTradeMapper.map(row: row, userId: userId)
                }
                trades.append(trade)
            } catch {
                failed.append((idx + 2, error))   // +2: 1-indexed, skip header
            }
        }

        return CSVImportResult(
            trades: trades,
            failedRows: failed,
            detectedFormat: format,
            requiresMapping: format == .unknown
        )
    }
}
```

**Step 7: Run tests to verify they pass**

```bash
cd FMSYSApp && swift test --filter CSVParserTests 2>&1 | tail -10
cd FMSYSApp && swift test --filter BrokerFormatDetectorTests 2>&1 | tail -10
cd FMSYSApp && swift test --filter TradeMapperTests 2>&1 | tail -10
```
Expected: All tests PASS.

**Step 8: Build**

```bash
cd FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Step 9: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Core/Services/CSV/ Tests/FMSYSAppTests/CSVImportServiceTests.swift
git commit -m "feat: CSVImportService — parser, broker detection, trade mappers"
```

---

### Task 10: ColumnMappingSheet + ImportPreviewSheet UI

**Files:**
- Create: `Sources/FMSYSCore/Features/Journal/Views/CSV/ColumnMappingSheet.swift`
- Create: `Sources/FMSYSCore/Features/Journal/Views/CSV/ImportPreviewSheet.swift`

No SwiftData tests for pure SwiftUI views. Build is the verification.

**Step 1: Implement ColumnMappingSheet**

```swift
// Sources/FMSYSCore/Features/Journal/Views/CSV/ColumnMappingSheet.swift
import SwiftUI

/// Shown when broker format cannot be auto-detected.
/// User maps CSV column names to Trade field names.
public struct ColumnMappingSheet: View {

    let csvHeaders: [String]
    let preview: [[String]]   // first 3 rows of raw values, parallel to csvHeaders
    let onConfirm: ([String: String]) -> Void   // [csvHeader: tradeField]
    let onCancel: () -> Void

    // Required Trade fields the user must map
    private static let requiredFields = ["symbol", "entryPrice", "entryTime", "direction", "positionSize"]
    private static let optionalFields = ["exitPrice", "stopLoss", "takeProfit", "notes", "category"]
    private static let allTargetFields = requiredFields + optionalFields

    @State private var mapping: [String: String] = [:]  // csvHeader → tradeField

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Map CSV Columns")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)

            Divider().overlay(Color.fmsBorder)

            // Mapping table
            ScrollView {
                VStack(spacing: 0) {
                    // Column header row
                    HStack {
                        Text("CSV Column")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Sample Values")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Maps To")
                            .frame(width: 180, alignment: .leading)
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    Divider().overlay(Color.fmsBorder)

                    ForEach(csvHeaders, id: \.self) { header in
                        MappingRow(
                            csvHeader: header,
                            sampleValues: sampleValues(for: header),
                            targetFields: Self.allTargetFields,
                            requiredFields: Self.requiredFields,
                            selectedTarget: Binding(
                                get: { mapping[header] ?? "" },
                                set: { mapping[header] = $0.isEmpty ? nil : $0 }
                            )
                        )
                        Divider().overlay(Color.fmsBorder)
                    }
                }
            }

            Divider().overlay(Color.fmsBorder)

            // Footer
            HStack {
                missingRequiredLabel
                Spacer()
                Button("Import") { onConfirm(mapping) }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(canImport ? Color.fmsPrimary : Color.fmsMuted.opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(canImport ? Color.black : Color.fmsMuted)
                    .disabled(!canImport)
            }
            .padding(16)
        }
        .frame(width: 620, height: 480)
        .background(Color.fmsBackground)
    }

    private func sampleValues(for header: String) -> String {
        guard let idx = csvHeaders.firstIndex(of: header) else { return "—" }
        let vals = preview.compactMap { row in row.indices.contains(idx) ? row[idx] : nil }
        return vals.prefix(2).joined(separator: ", ")
    }

    private var canImport: Bool {
        let mappedTargets = Set(mapping.values)
        return Self.requiredFields.allSatisfy { mappedTargets.contains($0) }
    }

    @ViewBuilder
    private var missingRequiredLabel: some View {
        let missing = Self.requiredFields.filter { !Set(mapping.values).contains($0) }
        if missing.isEmpty {
            Text("All required fields mapped")
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsPrimary)
        } else {
            Text("Missing: \(missing.joined(separator: ", "))")
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsLoss)
        }
    }
}

private struct MappingRow: View {
    let csvHeader: String
    let sampleValues: String
    let targetFields: [String]
    let requiredFields: [String]
    @Binding var selectedTarget: String

    var body: some View {
        HStack {
            Text(csvHeader)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(sampleValues)
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $selectedTarget) {
                Text("— skip —").tag("")
                ForEach(targetFields, id: \.self) { field in
                    HStack {
                        Text(field)
                        if requiredFields.contains(field) {
                            Text("*").foregroundStyle(Color.fmsLoss)
                        }
                    }.tag(field)
                }
            }
            .frame(width: 180)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
```

**Step 2: Implement ImportPreviewSheet**

```swift
// Sources/FMSYSCore/Features/Journal/Views/CSV/ImportPreviewSheet.swift
import SwiftUI

public struct ImportPreviewSheet: View {

    let result: CSVImportResult
    let onConfirm: () -> Void
    let onCancel: () -> Void

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import Preview")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("Format: \(formatLabel) · \(result.trades.count) trades · \(result.failedRows.count) errors")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)

            Divider().overlay(Color.fmsBorder)

            // Preview table (first 5 trades)
            VStack(spacing: 0) {
                HStack {
                    Text("Symbol").frame(width: 80, alignment: .leading)
                    Text("Direction").frame(width: 80, alignment: .leading)
                    Text("Entry").frame(width: 100, alignment: .trailing)
                    Text("Size").frame(width: 80, alignment: .trailing)
                    Text("Date").frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().overlay(Color.fmsBorder)

                ForEach(Array(result.trades.prefix(5).enumerated()), id: \.offset) { _, trade in
                    HStack {
                        Text(trade.asset).frame(width: 80, alignment: .leading)
                            .font(.system(size: 12, weight: .semibold))
                        Text(trade.directionRaw.capitalized).frame(width: 80, alignment: .leading)
                            .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
                            .font(.system(size: 12))
                        Text(String(format: "$%.2f", trade.entryPrice)).frame(width: 100, alignment: .trailing)
                            .font(.system(size: 12).monospacedDigit())
                        Text(String(format: "%.2f", trade.positionSize)).frame(width: 80, alignment: .trailing)
                            .font(.system(size: 12).monospacedDigit())
                        Text(trade.entryAt, style: .date).frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.fmsMuted)
                    }
                    .foregroundStyle(Color.fmsOnSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    Divider().overlay(Color.fmsBorder)
                }

                if result.trades.count > 5 {
                    Text("… and \(result.trades.count - 5) more")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                        .padding(12)
                }
            }

            // Errors (if any)
            if !result.failedRows.isEmpty {
                Divider().overlay(Color.fmsBorder)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rows with errors (\(result.failedRows.count)):")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.fmsLoss)
                        ForEach(result.failedRows.prefix(10), id: \.rowIndex) { row, error in
                            Text("Row \(row): \(error.localizedDescription)")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.fmsLoss.opacity(0.8))
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 100)
            }

            Spacer()
            Divider().overlay(Color.fmsBorder)

            // Footer
            HStack {
                Spacer()
                Button("Import \(result.trades.count) Trades") { onConfirm() }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(Color.black)
                    .disabled(result.trades.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 580, height: 420)
        .background(Color.fmsBackground)
    }

    private var formatLabel: String {
        switch result.detectedFormat {
        case .ibkr:         return "IBKR"
        case .tdAmeritrade: return "TD Ameritrade"
        case .binance:      return "Binance"
        case .generic:      return "Generic"
        case .unknown:      return "Custom"
        }
    }
}
```

**Step 3: Build**

```bash
cd FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Step 4: Commit**

```bash
cd FMSYSApp && git add Sources/FMSYSCore/Features/Journal/Views/CSV/
git commit -m "feat: ColumnMappingSheet and ImportPreviewSheet for CSV import"
```

---

### Task 11: Import button in Journal toolbar + wire full import flow

**Files:**
- Modify: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift`

**Step 1: Read JournalDetailView.swift and TradeListPanel.swift**

Read both files to understand where the toolbar lives and how to add a button.

**Step 2: Add import state to JournalDetailView (or TradeListPanel)**

Add these state variables to `TradeListPanel` (or wherever the toolbar lives):

```swift
@State private var showingCSVPicker    = false
@State private var showingMapping      = false
@State private var showingPreview      = false
@State private var csvText             = ""
@State private var csvHeaders: [String] = []
@State private var csvPreviewRows: [[String]] = []
@State private var importResult: CSVImportResult?
@State private var columnMapping: [String: String] = [:]
@State private var importFormat: BrokerFormat = .unknown
```

**Step 3: Add import button to toolbar**

In the toolbar `HStack`, add:

```swift
Button {
    showingCSVPicker = true
} label: {
    Image(systemName: "square.and.arrow.down")
        .font(.system(size: 13))
        .foregroundStyle(Color.fmsMuted)
}
.buttonStyle(.plain)
.help("Import trades from CSV")
.fileImporter(
    isPresented: $showingCSVPicker,
    allowedContentTypes: [.commaSeparatedText, .plainText]
) { result in
    guard let url = try? result.get(),
          url.startAccessingSecurityScopedResource() else { return }
    defer { url.stopAccessingSecurityScopedResource() }
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
    csvText = text
    let service = CSVImportService()
    let analysis = service.analyze(csvText: text)
    csvHeaders = analysis.headers
    csvPreviewRows = analysis.preview
    importFormat = analysis.format
    if analysis.format == .unknown {
        showingMapping = true
    } else {
        let res = service.map(csvText: text, format: analysis.format)
        importResult = res
        showingPreview = true
    }
}
```

**Step 4: Add sheet modifiers**

After the main view content, add:

```swift
.sheet(isPresented: $showingMapping) {
    ColumnMappingSheet(
        csvHeaders: csvHeaders,
        preview: csvPreviewRows,
        onConfirm: { mapping in
            columnMapping = mapping
            let service = CSVImportService()
            let res = service.map(csvText: csvText, format: .unknown, columnMapping: mapping)
            importResult = res
            showingMapping = false
            showingPreview = true
        },
        onCancel: { showingMapping = false }
    )
}
.sheet(isPresented: $showingPreview) {
    if let result = importResult {
        ImportPreviewSheet(
            result: result,
            onConfirm: {
                try? tradingService.importTrades(result.trades)
                showingPreview = false
            },
            onCancel: { showingPreview = false }
        )
    }
}
```

> `tradingService` must be passed into `TradeListPanel` (or accessed from the environment). Read the existing file to confirm how to thread it in.

**Step 5: Build**

```bash
cd FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!`

**Step 6: Run all tests**

```bash
cd FMSYSApp && swift test 2>&1 | tail -20
```
Expected: All tests PASS.

**Step 7: Commit**

```bash
cd FMSYSApp && git add -p
git commit -m "feat: CSV import button in Journal toolbar — full import flow"
```

---

## Summary

| Task | Feature |
|------|---------|
| 1 | TradingDataService actor (central data source) |
| 2 | MarketDataServiceProtocol + MockMarketDataService |
| 3 | Wire MainAppView |
| 4 | JournalDetailView + TradeViewModel → TradingDataService |
| 5 | PortfolioViewModel derives real data |
| 6 | JournalAttachment SwiftData model |
| 7 | ImageCompressionService |
| 8 | Journal image attachment UI |
| 9 | CSVImportService — parser, detector, mappers |
| 10 | ColumnMappingSheet + ImportPreviewSheet |
| 11 | Import button in Journal toolbar |
