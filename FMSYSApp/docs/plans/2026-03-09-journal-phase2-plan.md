# Journal Phase 2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 3-column journal shell with category-specific detail panels (Stocks/ETFs, Forex, Crypto, Options), update sidebar routing, and add per-category filtering and sort.

**Architecture:** `JournalCategory` enum drives all routing. `Trade` gains a stored `journalCategoryRaw` field plus optional category-specific fields. `JournalDetailView` owns the 3-column layout (sidebar 256px + `TradeListPanel` 320px + category detail panel flex), with `TradeViewModel` updated to filter by category and support inline saves.

**Tech Stack:** SwiftUI `NavigationSplitView` (existing), `@Observable` ViewModels, SwiftData `@Model`, Swift Testing (`@Test`, `@Suite(.serialized)`), design tokens (`Color.fms*`).

---

## Reference: Existing Patterns

- Tests use `@MainActor @Suite(.serialized)` + `makeRepository() -> (TradeRepository, ModelContext, ModelContainer)` — always return and bind the container to prevent SIGILL.
- SwiftData `#Predicate`: capture model properties in local `let` vars before the closure.
- Build: `cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5`
- Test: `cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test 2>&1 | tail -5`
- Current passing tests: 131 — must not regress.
- Working directory for all commands: `/Users/stevy/Documents/Git/TLSuite/FMSYSApp`

---

## Task 1: `JournalCategory` enum + Trade model extensions

**Files:**
- Create: `Sources/FMSYSCore/Core/Models/JournalCategory.swift`
- Modify: `Sources/FMSYSCore/Core/Models/Trade.swift`
- Modify: `Tests/FMSYSAppTests/TradeRepositoryTests.swift` (update `makeTrade` helper)

### Step 1: Write failing tests

Add to `Tests/FMSYSAppTests/TradeRepositoryTests.swift` inside `TradeRepositoryTests`:

```swift
@Test func tradeDefaultJournalCategoryIsStocksETFs() throws {
    let trade = makeTrade()
    #expect(trade.journalCategory == .stocksETFs)
}

@Test func tradeStoresCryptoJournalCategory() throws {
    let trade = makeTrade()
    trade.journalCategory = .crypto
    #expect(trade.journalCategory == .crypto)
}

@Test func tradeCategorySpecificFieldsDefaultToNil() throws {
    let trade = makeTrade()
    #expect(trade.leverage == nil)
    #expect(trade.fundingRate == nil)
    #expect(trade.walletAddress == nil)
    #expect(trade.pipValue == nil)
    #expect(trade.lotSize == nil)
    #expect(trade.exposure == nil)
    #expect(trade.sessionNotes == nil)
    #expect(trade.strikePrice == nil)
    #expect(trade.expirationDate == nil)
    #expect(trade.costBasis == nil)
    #expect(trade.greeksDelta == nil)
    #expect(trade.greeksGamma == nil)
    #expect(trade.greeksTheta == nil)
    #expect(trade.greeksVega == nil)
}

@Test func tradeCryptoFieldsCanBeSet() throws {
    let trade = makeTrade()
    trade.journalCategory = .crypto
    trade.leverage = 20.0
    trade.fundingRate = 0.01
    trade.walletAddress = "0x71C7b...3921"
    #expect(trade.leverage == 20.0)
    #expect(trade.fundingRate == 0.01)
    #expect(trade.walletAddress == "0x71C7b...3921")
}

@Test func tradeOptionsGreeksCanBeSet() throws {
    let trade = makeTrade()
    trade.journalCategory = .options
    trade.greeksDelta = 0.65
    trade.greeksGamma = 0.04
    trade.greeksTheta = -0.12
    trade.greeksVega = 0.28
    #expect(trade.greeksDelta == 0.65)
    #expect(trade.greeksGamma == 0.04)
    #expect(trade.greeksTheta == -0.12)
    #expect(trade.greeksVega == 0.28)
}
```

### Step 2: Run tests — expect FAIL

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test --filter TradeRepositoryTests 2>&1 | tail -10
```

Expected: compile error — `journalCategory` not found on `Trade`.

### Step 3: Create `JournalCategory.swift`

```swift
// Sources/FMSYSCore/Core/Models/JournalCategory.swift
import Foundation

public enum JournalCategory: String, Codable, CaseIterable, Hashable {
    case all        = "All"
    case stocksETFs = "Stocks/ETFs"
    case forex      = "Forex"
    case crypto     = "Crypto"
    case options    = "Options"
}
```

### Step 4: Add fields to `Trade.swift`

Add after `public var pendingSync: Bool`:

```swift
// Journal category
public var journalCategoryRaw: String

// Crypto
public var leverage: Double?
public var fundingRate: Double?
public var walletAddress: String?

// Forex
public var pipValue: Double?
public var lotSize: Double?
public var exposure: Double?
public var sessionNotes: String?

// Options
public var strikePrice: Double?
public var expirationDate: Date?
public var costBasis: Double?
public var greeksDelta: Double?
public var greeksGamma: Double?
public var greeksTheta: Double?
public var greeksVega: Double?
```

Add computed wrapper after the `emotionTag` wrapper:

```swift
public var journalCategory: JournalCategory {
    get { JournalCategory(rawValue: journalCategoryRaw) ?? .stocksETFs }
    set { journalCategoryRaw = newValue.rawValue }
}
```

Add `journalCategoryRaw: String = JournalCategory.stocksETFs.rawValue` to the `init` parameter list and body. Full updated init signature:

```swift
public init(
    id: UUID = UUID(),
    userId: String,
    asset: String,
    assetCategory: AssetCategory,
    direction: Direction,
    entryPrice: Double,
    stopLoss: Double,
    takeProfit: Double,
    positionSize: Double,
    entryAt: Date,
    exitPrice: Double? = nil,
    exitAt: Date? = nil,
    notes: String? = nil,
    emotionTag: EmotionTag? = nil,
    screenshotURL: String? = nil,
    pendingSync: Bool = true,
    journalCategory: JournalCategory = .stocksETFs,
    leverage: Double? = nil,
    fundingRate: Double? = nil,
    walletAddress: String? = nil,
    pipValue: Double? = nil,
    lotSize: Double? = nil,
    exposure: Double? = nil,
    sessionNotes: String? = nil,
    strikePrice: Double? = nil,
    expirationDate: Date? = nil,
    costBasis: Double? = nil,
    greeksDelta: Double? = nil,
    greeksGamma: Double? = nil,
    greeksTheta: Double? = nil,
    greeksVega: Double? = nil
) {
    self.id = id
    self.userId = userId
    self.asset = asset
    self.assetCategoryRaw = assetCategory.rawValue
    self.directionRaw = direction.rawValue
    self.entryPrice = entryPrice
    self.stopLoss = stopLoss
    self.takeProfit = takeProfit
    self.positionSize = positionSize
    self.entryAt = entryAt
    self.exitPrice = exitPrice
    self.exitAt = exitAt
    self.notes = notes
    self.emotionTagRaw = emotionTag?.rawValue
    self.screenshotURL = screenshotURL
    self.pendingSync = pendingSync
    self.journalCategoryRaw = journalCategory.rawValue
    self.leverage = leverage
    self.fundingRate = fundingRate
    self.walletAddress = walletAddress
    self.pipValue = pipValue
    self.lotSize = lotSize
    self.exposure = exposure
    self.sessionNotes = sessionNotes
    self.strikePrice = strikePrice
    self.expirationDate = expirationDate
    self.costBasis = costBasis
    self.greeksDelta = greeksDelta
    self.greeksGamma = greeksGamma
    self.greeksTheta = greeksTheta
    self.greeksVega = greeksVega
}
```

### Step 5: Build

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

### Step 6: Run tests — expect PASS

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test 2>&1 | tail -5
```

Expected: all 136 tests pass (131 existing + 5 new).

### Step 7: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Core/Models/JournalCategory.swift Sources/FMSYSCore/Core/Models/Trade.swift Tests/FMSYSAppTests/TradeRepositoryTests.swift && git commit -m "feat: add JournalCategory enum and category-specific fields to Trade model"
```

---

## Task 2: `TradeRepository` + `TradeViewModel` updates

**Files:**
- Modify: `Sources/FMSYSCore/Core/Repositories/TradeRepository.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/TradeViewModel.swift`
- Modify: `Tests/FMSYSAppTests/TradeRepositoryTests.swift`

### Step 1: Write failing tests

Add to `TradeRepositoryTests`:

```swift
@Test func findAllFiltersByCategoryWhenNotAll() throws {
    let (sut, _, _container) = try makeRepository()
    _ = _container
    let crypto = makeTrade(asset: "BTC/USDT", journalCategory: .crypto)
    let stocks = makeTrade(asset: "AAPL", journalCategory: .stocksETFs)
    try sut.create(crypto)
    try sut.create(stocks)

    let result = try sut.findAll(userId: "user-1", journalCategory: .crypto)
    #expect(result.count == 1)
    #expect(result.first?.asset == "BTC/USDT")
}

@Test func findAllReturnsAllTradesWhenCategoryIsAll() throws {
    let (sut, _, _container) = try makeRepository()
    _ = _container
    let crypto = makeTrade(asset: "BTC/USDT", journalCategory: .crypto)
    let stocks = makeTrade(asset: "AAPL", journalCategory: .stocksETFs)
    try sut.create(crypto)
    try sut.create(stocks)

    let result = try sut.findAll(userId: "user-1", journalCategory: .all)
    #expect(result.count == 2)
}

@Test func saveUpdatesJournalCategoryField() throws {
    let (sut, _, _container) = try makeRepository()
    _ = _container
    let trade = makeTrade()
    try sut.create(trade)

    trade.journalCategory = .forex
    try sut.save()

    let fetched = try sut.findAll(userId: "user-1", journalCategory: .forex)
    #expect(fetched.count == 1)
}
```

Update the `makeTrade` helper to accept `journalCategory`:

```swift
private func makeTrade(
    userId: String = "user-1",
    asset: String = "EUR/USD",
    direction: Direction = .long,
    entryAt: Date = Date(),
    pendingSync: Bool = false,
    journalCategory: JournalCategory = .stocksETFs
) -> Trade {
    Trade(
        userId: userId,
        asset: asset,
        assetCategory: .forex,
        direction: direction,
        entryPrice: 1.1000,
        stopLoss: 1.0950,
        takeProfit: 1.1100,
        positionSize: 1.0,
        entryAt: entryAt,
        pendingSync: pendingSync,
        journalCategory: journalCategory
    )
}
```

### Step 2: Run tests — expect FAIL

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test --filter TradeRepositoryTests 2>&1 | tail -10
```

Expected: compile error — `findAll(userId:journalCategory:)` not found.

### Step 3: Add `findAll(userId:journalCategory:)` to `TradeRepository`

Add after the existing `findAll(userId:)`:

```swift
public func findAll(userId: String, journalCategory: JournalCategory) throws -> [Trade] {
    if journalCategory == .all {
        return try findAll(userId: userId)
    }
    let uid = userId
    let catRaw = journalCategory.rawValue
    let descriptor = FetchDescriptor<Trade>(
        predicate: #Predicate { $0.userId == uid && $0.journalCategoryRaw == catRaw },
        sortBy: [SortDescriptor(\.entryAt, order: .reverse)]
    )
    return try context.fetch(descriptor)
}
```

### Step 4: Add `updateTrade(_:)` and `loadTrades(category:)` to `TradeViewModel`

Add to `TradeViewModel`:

```swift
public var journalCategory: JournalCategory = .all

@MainActor
public func loadTrades(category: JournalCategory = .all) {
    journalCategory = category
    do {
        trades = try repository.findAll(userId: userId, journalCategory: category)
    } catch {
        errorMessage = error.localizedDescription
    }
}

@MainActor
public func updateTrade(_ trade: Trade) {
    do {
        try repository.save()
        trades = try repository.findAll(userId: userId, journalCategory: journalCategory)
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### Step 5: Build + test

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5 && swift test 2>&1 | tail -5
```

Expected: `Build complete!`, all tests pass.

### Step 6: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Core/Repositories/TradeRepository.swift Sources/FMSYSCore/Features/Journal/TradeViewModel.swift Tests/FMSYSAppTests/TradeRepositoryTests.swift && git commit -m "feat: add category-filtered query and updateTrade to repository and view model"
```

---

## Task 3: Sidebar + `MainAppView` routing update

**Files:**
- Modify: `Sources/FMSYSCore/App/SidebarView.swift`
- Modify: `Sources/FMSYSCore/App/MainAppView.swift`

No TDD — pure layout. Build verification only.

### Step 1: Update `SidebarView`

Replace the entire file:

```swift
// Sources/FMSYSCore/App/SidebarView.swift
import SwiftUI

public struct SidebarView: View {
    @Binding var selection: AppScreen
    @Binding var journalCategory: JournalCategory
    @State private var journalExpanded = true

    public init(selection: Binding<AppScreen>, journalCategory: Binding<JournalCategory>) {
        self._selection = selection
        self._journalCategory = journalCategory
    }

    public var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                navItem(.dashboard,   icon: "chart.bar.fill",         label: "Dashboard",    shortcut: Character("1"))
                journalSection
                navItem(.backtesting, icon: "arrow.clockwise.circle", label: "Backtesting",  shortcut: Character("3"))
                navItem(.strategyLab, icon: "flask.fill",             label: "Strategy Lab", shortcut: Character("4"))
                navItem(.portfolio,   icon: "dollarsign.circle.fill", label: "Portfolio",    shortcut: Character("5"))
            }
            .listStyle(.sidebar)
            .frame(maxHeight: .infinity)

            equityCard
        }
        .frame(minWidth: 256, maxWidth: 256)
        .background(Color.fmsSurface)
    }

    private func navItem(_ screen: AppScreen, icon: String, label: String, shortcut: Character) -> some View {
        Label(label, systemImage: icon)
            .tag(screen)
            .keyboardShortcut(KeyEquivalent(shortcut), modifiers: .command)
    }

    private var journalSection: some View {
        DisclosureGroup(isExpanded: $journalExpanded) {
            ForEach(JournalCategory.allCases.filter { $0 != .all }, id: \.self) { cat in
                Button {
                    selection = .journal
                    journalCategory = cat
                } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(journalCategory == cat && selection == .journal
                            ? Color.fmsPrimary
                            : Color.fmsMuted)
                        .padding(.leading, 8)
                }
                .buttonStyle(.plain)
            }
        } label: {
            Label("Journal", systemImage: "book.fill")
                .tag(AppScreen.journal)
                .keyboardShortcut("2", modifiers: .command)
                .simultaneousGesture(TapGesture().onEnded {
                    journalCategory = .all
                })
        }
    }

    private var equityCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total Equity")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.fmsMuted)
            Text("$0.00")
                .font(.system(size: 18, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.fmsOnSurface)
            Text("MTD  —")
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsPrimary.opacity(0.3), lineWidth: 1)
        )
        .padding(12)
    }
}
```

### Step 2: Update `MainAppView`

Add `@State private var journalCategory: JournalCategory = .all` after `selectedScreen`.

Pass it to `SidebarView`:
```swift
SidebarView(selection: $selectedScreen, journalCategory: $journalCategory)
```

Update the `.journal` case in `screenContent`:
```swift
case .journal:
    JournalDetailView(
        category: journalCategory,
        modelContainer: modelContainer
    )
```

Remove the old `TradeListView` instantiation and the `loadTrades()` helper (Dashboard still calls it — keep `loadTrades()` for dashboard only).

### Step 3: Build

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
```

`JournalDetailView` doesn't exist yet — expect a compile error on that type only. That's fine — fix by adding a stub:

```swift
// Temporary stub — will be replaced in Task 4
public struct JournalDetailView: View {
    let category: JournalCategory
    let modelContainer: ModelContainer
    public var body: some View { Text("Journal — \(category.rawValue)") }
}
```

Place this stub at the bottom of `MainAppView.swift` temporarily, or in its own file.

Build again:

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

### Step 4: Test

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test 2>&1 | tail -5
```

Expected: all tests still pass.

### Step 5: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/App/SidebarView.swift Sources/FMSYSCore/App/MainAppView.swift && git commit -m "feat: update sidebar with JournalCategory routing and wire MainAppView"
```

---

## Task 4: `JournalDetailView` shell + `TradeListPanel`

**Files:**
- Create: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift`
- Create: `Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift`

No TDD — pure layout. Build verification only.

### Step 1: Create `JournalDetailView.swift`

```swift
// Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift
import SwiftUI
import SwiftData

public struct JournalDetailView: View {
    let category: JournalCategory
    let modelContainer: ModelContainer

    @State private var viewModel: TradeViewModel
    @State private var selectedTrade: Trade?
    @State private var sortByPnL = false

    public init(category: JournalCategory, modelContainer: ModelContainer) {
        self.category = category
        self.modelContainer = modelContainer
        self._viewModel = State(wrappedValue: TradeViewModel(
            repository: TradeRepository(context: modelContainer.mainContext),
            userId: "current-user"
        ))
    }

    public var body: some View {
        HSplitView {
            TradeListPanel(
                category: category,
                trades: sortedTrades,
                selectedTrade: $selectedTrade,
                sortByPnL: $sortByPnL
            )
            .frame(minWidth: 320, maxWidth: 320)

            detailPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { viewModel.loadTrades(category: category) }
        .onChange(of: category) { _, newCategory in
            selectedTrade = nil
            viewModel.loadTrades(category: newCategory)
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let trade = selectedTrade {
            switch trade.journalCategory {
            case .crypto:
                CryptoDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .stocksETFs:
                StocksDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .forex:
                ForexDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .options:
                OptionsDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .all:
                StocksDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            }
        } else {
            emptyDetailState
        }
    }

    private var emptyDetailState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundStyle(Color.fmsMuted.opacity(0.3))
            Text("Select a trade to view details")
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.fmsBackground)
    }

    private var sortedTrades: [Trade] {
        if sortByPnL {
            return viewModel.trades.sorted {
                let pnl0 = ($0.exitPrice.map { $0 - $0.0 } ?? 0)
                let pnl1 = ($1.exitPrice.map { $0 - $0.0 } ?? 0)
                return pnl0 > pnl1
            }
        }
        return viewModel.trades
    }
}
```

**Note:** `sortedTrades` P&L sort is a placeholder — actual P&L logic is `(exitPrice - entryPrice) * positionSize`. Update the sort closure:

```swift
private func pnl(_ trade: Trade) -> Double {
    guard let exit = trade.exitPrice else { return 0 }
    let multiplier = trade.direction == .long ? 1.0 : -1.0
    return (exit - trade.entryPrice) * trade.positionSize * multiplier
}

private var sortedTrades: [Trade] {
    sortByPnL ? viewModel.trades.sorted { pnl($0) > pnl($1) } : viewModel.trades
}
```

### Step 2: Create `TradeListPanel.swift`

```swift
// Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift
import SwiftUI

public struct TradeListPanel: View {
    let category: JournalCategory
    let trades: [Trade]
    @Binding var selectedTrade: Trade?
    @Binding var sortByPnL: Bool

    public init(
        category: JournalCategory,
        trades: [Trade],
        selectedTrade: Binding<Trade?>,
        sortByPnL: Binding<Bool>
    ) {
        self.category = category
        self.trades = trades
        self._selectedTrade = selectedTrade
        self._sortByPnL = sortByPnL
    }

    public var body: some View {
        VStack(spacing: 0) {
            listHeader
            Divider()
            if trades.isEmpty {
                emptyState
            } else {
                tradeList
            }
        }
        .background(Color.fmsSurface)
    }

    private var listHeader: some View {
        HStack {
            Text(category == .all ? "All Trades" : category.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
            Spacer()
            Button {
                sortByPnL.toggle()
            } label: {
                Label(sortByPnL ? "P&L" : "Newest", systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var tradeList: some View {
        List(trades, id: \.id, selection: $selectedTrade) { trade in
            tradeCard(trade)
                .tag(trade)
                .listRowBackground(
                    selectedTrade?.id == trade.id
                        ? Color.fmsPrimary.opacity(0.08)
                        : Color.clear
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func tradeCard(_ trade: Trade) -> some View {
        switch trade.journalCategory {
        case .crypto:  CryptoTradeCard(trade: trade)
        case .forex:   ForexTradeCard(trade: trade)
        case .options: OptionsTradeCard(trade: trade)
        default:       StocksTradeCard(trade: trade)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundStyle(Color.fmsMuted.opacity(0.3))
            Text("Start Your Trading Journal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            Text("Record your first trade to begin\ntracking performance.")
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
            Button("+ Log First Trade") {}
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.fmsBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
```

### Step 3: Remove stub from `MainAppView.swift`

Delete the temporary `JournalDetailView` stub added in Task 3.

### Step 4: Build

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
```

Expect compile errors for missing card/panel types — those come in Tasks 5-8. Add minimal stubs for each missing type at the bottom of `JournalDetailView.swift`:

```swift
// MARK: - Stubs (replaced in Tasks 5–8)
struct CryptoTradeCard: View { let trade: Trade; var body: some View { Text(trade.asset) } }
struct StocksTradeCard: View { let trade: Trade; var body: some View { Text(trade.asset) } }
struct ForexTradeCard: View { let trade: Trade; var body: some View { Text(trade.asset) } }
struct OptionsTradeCard: View { let trade: Trade; var body: some View { Text(trade.asset) } }
struct CryptoDetailPanel: View { let trade: Trade; let onSave: () -> Void; var body: some View { Text("Crypto") } }
struct StocksDetailPanel: View { let trade: Trade; let onSave: () -> Void; var body: some View { Text("Stocks") } }
struct ForexDetailPanel: View { let trade: Trade; let onSave: () -> Void; var body: some View { Text("Forex") } }
struct OptionsDetailPanel: View { let trade: Trade; let onSave: () -> Void; var body: some View { Text("Options") } }
```

Build again:

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

### Step 5: Test

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test 2>&1 | tail -5
```

### Step 6: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift Sources/FMSYSCore/App/MainAppView.swift && git commit -m "feat: add JournalDetailView shell and TradeListPanel with stub cards"
```

---

## Task 5: Stocks/ETFs — card + detail panel

**Files:**
- Create: `Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksTradeCard.swift`
- Create: `Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksDetailPanel.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift` (remove stub)

No TDD — pure layout. Build verification only.

### Step 1: Create `StocksTradeCard.swift`

```swift
// Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksTradeCard.swift
import SwiftUI

public struct StocksTradeCard: View {
    let trade: Trade

    public init(trade: Trade) { self.trade = trade }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trade.asset)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                directionBadge
            }
            HStack {
                Text("$\(trade.entryPrice, specifier: "%.2f") · \(trade.positionSize, specifier: "%.0f") shares")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                Spacer()
                pnlText
            }
            Text(trade.entryAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
        }
        .padding(.vertical, 4)
    }

    private var directionBadge: some View {
        Text(trade.direction == .long ? "BUY" : "SELL")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                trade.direction == .long ? Color.fmsPrimary.opacity(0.2) : Color.fmsLoss.opacity(0.2),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }
}
```

### Step 2: Create `StocksDetailPanel.swift`

```swift
// Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksDetailPanel.swift
import SwiftUI

public struct StocksDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                detailHeader
                metricsRow1
                metricsRow2
                notesSection
                screenshotSection
            }
            .padding(24)
        }
        .background(Color.fmsBackground)
    }

    private var detailHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.asset)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("ID: #\(trade.id.uuidString.prefix(8).uppercased())")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            Button("Save") { onSave() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.fmsBackground)
        }
    }

    // Row 1: Entry Price | Entry Time | Exit Price | Exit Time
    private var metricsRow1: some View {
        HStack(spacing: 12) {
            metricField(label: "ENTRY PRICE") {
                TextField("0.00", value: $trade.entryPrice, format: .number)
            }
            metricField(label: "ENTRY TIME") {
                DatePicker("", selection: Binding(
                    get: { trade.entryAt },
                    set: { trade.entryAt = $0 }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }
            metricField(label: "EXIT PRICE") {
                TextField("0.00", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { trade.exitPrice = $0 }
                ), format: .number)
            }
            metricField(label: "EXIT TIME") {
                DatePicker("", selection: Binding(
                    get: { trade.exitAt ?? Date() },
                    set: { trade.exitAt = $0 }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }
        }
    }

    // Row 2: Qty | Fees
    private var metricsRow2: some View {
        HStack(spacing: 12) {
            metricField(label: "QTY") {
                TextField("0", value: $trade.positionSize, format: .number)
            }
            metricField(label: "FEES") {
                TextField("0.00", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { _ in }
                ), format: .number)
            }
            Spacer()
            Spacer()
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRADE REFLECTION & ANALYSIS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
            TextEditor(text: Binding(
                get: { trade.notes ?? "" },
                set: { trade.notes = $0 }
            ))
            .font(.system(size: 13))
            .foregroundStyle(Color.fmsOnSurface)
            .frame(minHeight: 250)
            .padding(12)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
            .scrollContentBackground(.hidden)
        }
    }

    private var screenshotSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHART SCREENSHOTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
            HStack(spacing: 12) {
                uploadArea(label: "Entry Chart")
                uploadArea(label: "Exit Chart")
            }
        }
    }

    private func uploadArea(label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 24))
                .foregroundStyle(Color.fmsMuted)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(Color.fmsMuted.opacity(0.4))
        )
    }

    @ViewBuilder
    private func metricField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
            content()
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(10)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
    }
}
```

### Step 3: Remove the `StocksTradeCard` and `StocksDetailPanel` stubs from `JournalDetailView.swift`

### Step 4: Build + test

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5 && swift test 2>&1 | tail -5
```

### Step 5: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Journal/Views/Stocks/ Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift && git commit -m "feat: add StocksTradeCard and StocksDetailPanel"
```

---

## Task 6: Crypto — card + detail panel

**Files:**
- Create: `Sources/FMSYSCore/Features/Journal/Views/Crypto/CryptoTradeCard.swift`
- Create: `Sources/FMSYSCore/Features/Journal/Views/Crypto/CryptoDetailPanel.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift` (remove stub)

No TDD — pure layout.

### Step 1: Create `CryptoTradeCard.swift`

```swift
// Sources/FMSYSCore/Features/Journal/Views/Crypto/CryptoTradeCard.swift
import SwiftUI

public struct CryptoTradeCard: View {
    let trade: Trade

    public init(trade: Trade) { self.trade = trade }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trade.asset)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                directionBadge
            }
            HStack {
                if let leverage = trade.leverage {
                    Text("\(trade.direction == .long ? "LONG" : "SHORT") \(leverage, specifier: "%.0f")x")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                pnlText
            }
            HStack {
                Text(trade.entryAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
                if let wallet = trade.walletAddress {
                    Spacer()
                    Text(String(wallet.prefix(8)) + "...")
                        .font(.system(size: 10).monospaced())
                        .foregroundStyle(Color.fmsMuted)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var directionBadge: some View {
        Text(trade.direction == .long ? "LONG" : "SHORT")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                trade.direction == .long ? Color.fmsPrimary.opacity(0.2) : Color.fmsLoss.opacity(0.2),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }
}
```

### Step 2: Create `CryptoDetailPanel.swift`

Copy `StocksDetailPanel` structure. Replace Row 2 with:

```swift
// Row 2: Leverage | Funding Rate | Wallet Address (full width)
private var metricsRow2: some View {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            metricField(label: "LEVERAGE") {
                TextField("1x", value: Binding(
                    get: { trade.leverage ?? 1 },
                    set: { trade.leverage = $0 }
                ), format: .number)
            }
            metricField(label: "FUNDING RATE") {
                TextField("0.00%", value: Binding(
                    get: { trade.fundingRate ?? 0 },
                    set: { trade.fundingRate = $0 }
                ), format: .percent)
            }
        }
        walletAddressRow
    }
}

private var walletAddressRow: some View {
    VStack(alignment: .leading, spacing: 6) {
        Text("EXECUTING WALLET")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
        HStack {
            Text(trade.walletAddress ?? "—")
                .font(.system(size: 13).monospaced())
                .foregroundStyle(Color.fmsOnSurface)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button {
                if let addr = trade.walletAddress {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(addr, forType: .string)
                }
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
    }
}
```

### Step 3: Remove Crypto stubs from `JournalDetailView.swift`

### Step 4: Build + test

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5 && swift test 2>&1 | tail -5
```

### Step 5: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Journal/Views/Crypto/ Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift && git commit -m "feat: add CryptoTradeCard and CryptoDetailPanel"
```

---

## Task 7: Forex — card + detail panel

**Files:**
- Create: `Sources/FMSYSCore/Features/Journal/Views/Forex/ForexTradeCard.swift`
- Create: `Sources/FMSYSCore/Features/Journal/Views/Forex/ForexDetailPanel.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift` (remove stub)

No TDD — pure layout.

### Step 1: Create `ForexTradeCard.swift`

Same structure as `StocksTradeCard` but shows pair rate and daily change instead of shares. Key differences:

```swift
// Replace the middle HStack content:
HStack {
    Text("Rate: \(trade.entryPrice, specifier: "%.4f")")
        .font(.system(size: 12))
        .foregroundStyle(Color.fmsMuted)
    Spacer()
    pnlText
}
```

### Step 2: Create `ForexDetailPanel.swift`

Copy `StocksDetailPanel`. Replace Row 2 with:

```swift
// Row 2: Pip Value | Lot Size | Exposure
private var metricsRow2: some View {
    HStack(spacing: 12) {
        metricField(label: "PIP VALUE") {
            TextField("0.00", value: Binding(
                get: { trade.pipValue ?? 0 },
                set: { trade.pipValue = $0 }
            ), format: .number)
        }
        metricField(label: "LOT SIZE") {
            TextField("0.00", value: Binding(
                get: { trade.lotSize ?? 0 },
                set: { trade.lotSize = $0 }
            ), format: .number)
        }
        metricField(label: "EXPOSURE") {
            TextField("0.00", value: Binding(
                get: { trade.exposure ?? 0 },
                set: { trade.exposure = $0 }
            ), format: .number)
        }
        Spacer()
    }
}
```

Add Session Notes section between metricsRow2 and notesSection:

```swift
private var sessionNotesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("SESSION NOTES")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
        TextEditor(text: Binding(
            get: { trade.sessionNotes ?? "" },
            set: { trade.sessionNotes = $0 }
        ))
        .font(.system(size: 13))
        .foregroundStyle(Color.fmsOnSurface)
        .frame(minHeight: 80)
        .padding(12)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
        .scrollContentBackground(.hidden)
    }
}
```

### Step 3: Remove Forex stubs + build + test + commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5 && swift test 2>&1 | tail -5
git add Sources/FMSYSCore/Features/Journal/Views/Forex/ Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift
git commit -m "feat: add ForexTradeCard and ForexDetailPanel"
```

---

## Task 8: Options — card + detail panel

**Files:**
- Create: `Sources/FMSYSCore/Features/Journal/Views/Options/OptionsTradeCard.swift`
- Create: `Sources/FMSYSCore/Features/Journal/Views/Options/OptionsDetailPanel.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift` (remove last stub)

No TDD — pure layout.

### Step 1: Create `OptionsTradeCard.swift`

```swift
// Sources/FMSYSCore/Features/Journal/Views/Options/OptionsTradeCard.swift
import SwiftUI

public struct OptionsTradeCard: View {
    let trade: Trade

    public init(trade: Trade) { self.trade = trade }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // e.g. "AAPL $150 Call"
                Text(contractName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                pnlText
            }
            HStack {
                if let expiry = trade.expirationDate {
                    Text("Exp: \(expiry.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Text("Qty: \(trade.positionSize, specifier: "%.0f")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .padding(.vertical, 4)
    }

    private var contractName: String {
        let strike = trade.strikePrice.map { "$\(String(format: "%.0f", $0))" } ?? ""
        let type = trade.direction == .long ? "Call" : "Put"
        return "\(trade.asset) \(strike) \(type)"
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        return (exit - trade.entryPrice) * trade.positionSize
    }
}
```

### Step 2: Create `OptionsDetailPanel.swift`

Copy `StocksDetailPanel`. Replace Row 2 and add Greeks section:

```swift
// Row 2: Strike Price | Expiration | Qty | Cost Basis
private var metricsRow2: some View {
    HStack(spacing: 12) {
        metricField(label: "STRIKE PRICE") {
            TextField("0.00", value: Binding(
                get: { trade.strikePrice ?? 0 },
                set: { trade.strikePrice = $0 }
            ), format: .number)
        }
        metricField(label: "EXPIRATION") {
            DatePicker("", selection: Binding(
                get: { trade.expirationDate ?? Date() },
                set: { trade.expirationDate = $0 }
            ), displayedComponents: .date)
            .labelsHidden()
        }
        metricField(label: "QTY") {
            TextField("0", value: $trade.positionSize, format: .number)
        }
        metricField(label: "COST BASIS") {
            TextField("0.00", value: Binding(
                get: { trade.costBasis ?? 0 },
                set: { trade.costBasis = $0 }
            ), format: .number)
        }
    }
}

// Greeks row (read-only display)
private var greeksSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("GREEKS")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
        HStack(spacing: 12) {
            greekCell(label: "Delta", value: trade.greeksDelta)
            greekCell(label: "Gamma", value: trade.greeksGamma)
            greekCell(label: "Theta", value: trade.greeksTheta)
            greekCell(label: "Vega",  value: trade.greeksVega)
        }
        .padding(12)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
    }
}

private func greekCell(label: String, value: Double?) -> some View {
    VStack(spacing: 4) {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)
        Text(value.map { String(format: "%.2f", $0) } ?? "—")
            .font(.system(size: 14, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.fmsOnSurface)
    }
    .frame(maxWidth: .infinity)
}
```

Add `greeksSection` to the `body` VStack between `metricsRow2` and `notesSection`.

### Step 3: Remove Options stubs + build + test

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5 && swift test 2>&1 | tail -5
```

All stubs should now be removed — `JournalDetailView.swift` should have no stub types left.

### Step 4: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Journal/Views/Options/ Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift && git commit -m "feat: add OptionsTradeCard and OptionsDetailPanel with Greeks"
```

---

## Task 9: Per-category filter bar

**Files:**
- Modify: `Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift`
- Modify: `Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift`

No TDD — client-side filtering on existing data.

### Step 1: Add filter state to `TradeListPanel`

Add `@State private var activeFilter: String = "All"` to `TradeListPanel`.

Add `filterBar` computed property:

```swift
@ViewBuilder
private var filterBar: some View {
    switch category {
    case .all:
        EmptyView()
    case .stocksETFs:
        segmentedFilter(options: ["All", "Buy", "Sell"])
    case .crypto:
        segmentedFilter(options: ["All", "Spot", "Futures"])
    case .forex:
        EmptyView() // toggle handled differently
    case .options:
        segmentedFilter(options: ["All", "Call", "Put"])
    }
}

private func segmentedFilter(options: [String]) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { opt in
                Button(opt) { activeFilter = opt }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: activeFilter == opt ? .bold : .regular))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        activeFilter == opt ? Color.fmsPrimary.opacity(0.15) : Color.clear,
                        in: Capsule()
                    )
                    .foregroundStyle(activeFilter == opt ? Color.fmsPrimary : Color.fmsMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
```

Add `filterBar` + `Divider()` below `listHeader` + first `Divider()` in the body VStack.

### Step 2: Apply filter to the list

In `JournalDetailView`, update `sortedTrades` to apply `TradeListPanel`'s active filter. Since `activeFilter` is inside `TradeListPanel`, pass it up via `@Binding` or filter inside `TradeListPanel` directly.

Simplest: filter inside `TradeListPanel`. Change `let trades` to accept the raw unfiltered array and compute filtered internally:

```swift
private var filteredTrades: [Trade] {
    guard activeFilter != "All" else { return trades }
    switch category {
    case .stocksETFs:
        if activeFilter == "Buy"  { return trades.filter { $0.direction == .long } }
        if activeFilter == "Sell" { return trades.filter { $0.direction == .short } }
    case .crypto:
        // Spot = no leverage, Futures = has leverage
        if activeFilter == "Spot"    { return trades.filter { ($0.leverage ?? 1) <= 1 } }
        if activeFilter == "Futures" { return trades.filter { ($0.leverage ?? 1) > 1 } }
    case .options:
        if activeFilter == "Call" { return trades.filter { $0.direction == .long } }
        if activeFilter == "Put"  { return trades.filter { $0.direction == .short } }
    default: break
    }
    return trades
}
```

Use `filteredTrades` in `tradeList` instead of `trades`.

Reset `activeFilter = "All"` in `.onChange(of: category)` in `JournalDetailView`.

### Step 3: Build + test

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5 && swift test 2>&1 | tail -5
```

Expected: `Build complete!`, all tests pass.

### Step 4: Commit

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift && git commit -m "feat: add per-category filter bar to TradeListPanel"
```

---

## Done

Phase 2 complete when:
- [ ] Sidebar shows: Dashboard · Journal ▾ (Stocks/ETFs · Forex · Crypto · Options) · Backtesting · Strategy Lab · Portfolio
- [ ] Clicking "Journal" shows all trades; clicking a sub-item shows filtered trades
- [ ] Each category has its own trade card and detail panel
- [ ] Detail panel shows two metric rows: Row 1 (Entry Price · Entry Time · Exit Price · Exit Time) + Row 2 (category-specific)
- [ ] Options panel shows Greeks row
- [ ] Crypto panel shows wallet address with copy button
- [ ] Forex panel shows Session Notes field
- [ ] Notes editor (TextEditor) and screenshot upload areas present on all panels
- [ ] Sort toggle (Newest ↕ P&L) works in list header
- [ ] Per-category filter bar works (Buy/Sell for Stocks, All/Spot/Futures for Crypto, Call/Put for Options)
- [ ] All existing 131+ tests still pass
