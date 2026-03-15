# Trade Entry Overlay Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the basic `NavigationStack + Form` trade entry sheet with a glass-morphism overlay modal featuring a category switcher (Stocks/ETFs | Forex | Options | Crypto) and dynamic category-specific fields, pre-selecting the category based on the active journal tab.

**Architecture:** `TradeEntryView` becomes a self-contained ZStack overlay (glass backdrop + centered modal card). `JournalDetailView` adds `@State var showingEntry` and renders the overlay via a ZStack. `TradeListPanel` gains an `onNewTrade: () -> Void` callback wired to a "+" button in the header and the empty-state button. `TradeViewModel` gains a rich `createTrade` overload accepting all category-specific fields.

**Tech Stack:** SwiftUI, Swift 5.9+, macOS 14+, SwiftData (`@Observable` TradeViewModel), design tokens (`Color.fmsPrimary / fmsSurface / fmsBackground / fmsOnSurface / fmsMuted / fmsLoss`).

---

## Files Overview

| File | Action |
|------|--------|
| `Core/Models/JournalCategory.swift` | **Modify** — add `assetCategory: AssetCategory` computed property |
| `Features/Journal/TradeViewModel.swift` | **Modify** — add rich `createTrade` overload |
| `Features/Journal/Views/TradeEntryView.swift` | **Rewrite** — glass overlay modal |
| `Features/Journal/Views/TradeListPanel.swift` | **Modify** — add `onNewTrade` callback + "+" header button |
| `Features/Journal/Views/JournalDetailView.swift` | **Modify** — ZStack overlay + pass `onNewTrade` |

**No Trade model schema changes** — all category fields (leverage, fundingRate, walletAddress, pipValue, lotSize, exposure, strikePrice, expirationDate, costBasis) already exist on `Trade`. `stopLoss`/`takeProfit` default to `0` in the new entry form (fields are omitted by design in the HTML).

---

### Task 1: Add `assetCategory` to `JournalCategory` + rich `createTrade` to `TradeViewModel`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Core/Models/JournalCategory.swift`
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/TradeViewModel.swift`

**Step 1: Add `assetCategory` to `JournalCategory`**

Append the computed property to `JournalCategory.swift`:

```swift
import Foundation

public enum JournalCategory: String, Codable, CaseIterable, Hashable {
    case all        = "All"
    case stocksETFs = "Stocks/ETFs"
    case forex      = "Forex"
    case crypto     = "Crypto"
    case options    = "Options"

    public var assetCategory: AssetCategory {
        switch self {
        case .stocksETFs, .all: return .stocks
        case .forex:            return .forex
        case .crypto:           return .crypto
        case .options:          return .options
        }
    }
}
```

**Step 2: Add rich `createTrade` overload to `TradeViewModel`**

Append the new method inside `TradeViewModel` (after the existing `createTrade`):

```swift
@MainActor
public func createTrade(
    asset: String,
    journalCategory: JournalCategory,
    direction: Direction,
    entryPrice: Double,
    exitPrice: Double?,
    positionSize: Double,
    notes: String?,
    pipValue: Double?,
    lotSize: Double?,
    exposure: Double?,
    leverage: Double?,
    fundingRate: Double?,
    walletAddress: String?,
    strikePrice: Double?,
    expirationDate: Date?,
    costBasis: Double?
) {
    let trade = Trade(
        userId: userId,
        asset: asset,
        assetCategory: journalCategory.assetCategory,
        direction: direction,
        entryPrice: entryPrice,
        stopLoss: 0,
        takeProfit: 0,
        positionSize: positionSize,
        entryAt: Date(),
        exitPrice: exitPrice,
        notes: notes?.isEmpty == true ? nil : notes,
        journalCategory: journalCategory,
        leverage: leverage,
        fundingRate: fundingRate,
        walletAddress: walletAddress?.isEmpty == true ? nil : walletAddress,
        pipValue: pipValue,
        lotSize: lotSize,
        exposure: exposure,
        strikePrice: strikePrice,
        expirationDate: expirationDate,
        costBasis: costBasis
    )
    do {
        try repository.create(trade)
        trades = try repository.findAll(userId: userId, journalCategory: self.journalCategory)
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

**Step 3: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
```

Expected: `Build complete!`

**Step 4: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Core/Models/JournalCategory.swift \
        FMSYSApp/Sources/FMSYSCore/Features/Journal/TradeViewModel.swift
git commit -m "feat: add JournalCategory.assetCategory + rich createTrade overload"
```

---

### Task 2: Rewrite `TradeEntryView` as glass overlay modal

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/TradeEntryView.swift`

**Step 1: Rewrite the file**

```swift
// Sources/FMSYSCore/Features/Journal/Views/TradeEntryView.swift
import SwiftUI

public struct TradeEntryView: View {
    let initialCategory: JournalCategory
    let viewModel: TradeViewModel
    let onDismiss: () -> Void

    @State private var selectedCategory: JournalCategory
    @State private var asset = ""
    @State private var direction: Direction = .long

    // Common
    @State private var entryPriceText = ""
    @State private var exitPriceText = ""
    @State private var positionSizeText = ""
    @State private var notesText = ""

    // Stocks
    @State private var stopLossText = ""

    // Forex
    @State private var pipValueText = ""
    @State private var lotSizeText = ""
    @State private var exposureText = ""

    // Crypto
    @State private var leverageText = ""
    @State private var fundingRateText = ""
    @State private var walletText = ""

    // Options
    @State private var strikeText = ""
    @State private var expirationDate = Date()
    @State private var costBasisText = ""

    public init(
        initialCategory: JournalCategory,
        viewModel: TradeViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.initialCategory = initialCategory
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        let cat = initialCategory == .all ? JournalCategory.stocksETFs : initialCategory
        self._selectedCategory = State(wrappedValue: cat)
    }

    private var isValid: Bool {
        !asset.trimmingCharacters(in: .whitespaces).isEmpty && Double(entryPriceText) != nil
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Glass backdrop — tap outside to dismiss
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Modal card
            VStack(spacing: 0) {
                modalHeader
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        categorySwitcher
                        assetAndDirectionRow
                        executionDetailsSection
                        notesSection
                    }
                    .padding(24)
                }
                Divider()
                modalFooter
            }
            .frame(width: 560)
            .frame(maxHeight: 700)
            .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 40, x: 0, y: 20)
            // Prevent backdrop tap from propagating through card
            .contentShape(Rectangle())
            .onTapGesture {}
        }
    }

    // MARK: - Header

    private var modalHeader: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.fmsPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.fmsPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add New Trade")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("Log your execution details")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.fmsSurface, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Category Switcher

    private var categorySwitcher: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 2) {
                ForEach(
                    [JournalCategory.stocksETFs, .forex, .options, .crypto],
                    id: \.self
                ) { cat in
                    Button(cat.rawValue) {
                        selectedCategory = cat
                    }
                    .buttonStyle(.plain)
                    .font(.system(
                        size: 12,
                        weight: selectedCategory == cat ? .bold : .medium
                    ))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        selectedCategory == cat ? Color.fmsBackground : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .foregroundStyle(
                        selectedCategory == cat ? Color.fmsPrimary : Color.fmsMuted
                    )
                }
            }
            .padding(4)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Asset + Direction

    private var assetAndDirectionRow: some View {
        HStack(spacing: 16) {
            // Asset ticker
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Asset Ticker")
                HStack(spacing: 6) {
                    TextField(assetPlaceholder, text: $asset)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsOnSurface)
                        .autocorrectionDisabled()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
                .padding(10)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity)

            // Direction / Call-Put toggle
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Direction")
                HStack(spacing: 2) {
                    Button {
                        direction = .long
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                            Text(selectedCategory == .options ? "CALL" : "LONG")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            direction == .long ? Color.fmsPrimary : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                        .foregroundStyle(
                            direction == .long ? Color.fmsBackground : Color.fmsMuted
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        direction = .short
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text(selectedCategory == .options ? "PUT" : "SHORT")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            direction == .short ? Color.fmsLoss : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                        .foregroundStyle(
                            direction == .short ? Color.white : Color.fmsMuted
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var assetPlaceholder: String {
        switch selectedCategory {
        case .stocksETFs, .all: return "e.g. AAPL"
        case .forex:            return "e.g. EUR/USD"
        case .crypto:           return "e.g. BTC/USDT"
        case .options:          return "e.g. AAPL"
        }
    }

    // MARK: - Execution Details

    private var executionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsPrimary)
                Text("Execution Details")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .tracking(0.5)
            }
            Divider()
            switch selectedCategory {
            case .stocksETFs, .all: stocksFields
            case .forex:            forexFields
            case .crypto:           cryptoFields
            case .options:          optionsFields
            }
        }
    }

    private var stocksFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: "Entry Price", prefix: "$", text: $entryPriceText, placeholder: "0.00")
            entryField(label: "Exit Price (Optional)", prefix: "$", text: $exitPriceText, placeholder: "0.00")
            entryField(label: "Quantity (Shares)", text: $positionSizeText, placeholder: "0")
            entryField(label: "Stop Loss", prefix: "$", text: $stopLossText, placeholder: "0.00")
        }
    }

    private var forexFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: "Entry Price", prefix: "$", text: $entryPriceText, placeholder: "1.0850")
            entryField(label: "Exit Price", prefix: "$", text: $exitPriceText, placeholder: "1.0920")
            entryField(label: "Pip Value ($)", text: $pipValueText, placeholder: "10.00")
            entryField(label: "Lot Size", text: $lotSizeText, placeholder: "1.0")
            entryField(label: "Exposure", text: $exposureText, placeholder: "150000")
            entryField(label: "Position Size", text: $positionSizeText, placeholder: "1")
        }
    }

    private var cryptoFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: "Entry Price", prefix: "$", text: $entryPriceText, placeholder: "0.00")
            entryField(label: "Exit Price", prefix: "$", text: $exitPriceText, placeholder: "0.00")
            entryField(label: "Leverage", suffix: "x", text: $leverageText, placeholder: "1")
            entryField(label: "Funding Rate", suffix: "%", text: $fundingRateText, placeholder: "0.01")
            entryField(label: "Position Size", text: $positionSizeText, placeholder: "0")
            entryField(label: "Wallet Address (Optional)", text: $walletText, placeholder: "0x...")
        }
    }

    private var optionsFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: "Strike Price", prefix: "$", text: $strikeText, placeholder: "0.00")
            expirationField
            entryField(label: "Quantity (Contracts)", text: $positionSizeText, placeholder: "1")
            entryField(label: "Cost Basis", prefix: "$", text: $costBasisText, placeholder: "0.00")
            entryField(label: "Entry Price (Premium)", prefix: "$", text: $entryPriceText, placeholder: "0.00")
            entryField(label: "Exit Price (Optional)", prefix: "$", text: $exitPriceText, placeholder: "0.00")
        }
    }

    private var expirationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Expiration Date")
            DatePicker("", selection: $expirationDate, displayedComponents: .date)
                .labelsHidden()
                .padding(8)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes & Reflection")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            TextEditor(text: $notesText)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(minHeight: 80)
                .padding(10)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Footer

    private var modalFooter: some View {
        HStack {
            Spacer()
            Button("Cancel") { onDismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fmsMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            Button("Save Trade") { saveTrade() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    isValid ? Color.fmsPrimary : Color.fmsMuted.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .foregroundStyle(isValid ? Color.fmsBackground : Color.fmsMuted)
                .disabled(!isValid)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func entryField(
        label: String,
        prefix: String? = nil,
        suffix: String? = nil,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(label)
            HStack(spacing: 4) {
                if let prefix {
                    Text(prefix)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsMuted)
                }
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsOnSurface)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            .padding(8)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
            )
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.fmsMuted)
    }

    // MARK: - Save

    private func saveTrade() {
        guard let entryPrice = Double(entryPriceText) else { return }
        let exitPrice = Double(exitPriceText)
        let positionSize = Double(positionSizeText) ?? 1

        viewModel.createTrade(
            asset: asset.trimmingCharacters(in: .whitespaces).uppercased(),
            journalCategory: selectedCategory,
            direction: direction,
            entryPrice: entryPrice,
            exitPrice: exitPrice,
            positionSize: positionSize,
            notes: notesText.isEmpty ? nil : notesText,
            pipValue: Double(pipValueText),
            lotSize: Double(lotSizeText),
            exposure: Double(exposureText),
            leverage: Double(leverageText),
            fundingRate: Double(fundingRateText),
            walletAddress: walletText.isEmpty ? nil : walletText,
            strikePrice: Double(strikeText),
            expirationDate: selectedCategory == .options ? expirationDate : nil,
            costBasis: Double(costBasisText)
        )
        onDismiss()
    }
}
```

**Step 2: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
```

Expected: Build succeeds. (Existing callers of old `TradeEntryView(viewModel:)` signature will break — fixed in Task 4.)

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/TradeEntryView.swift
git commit -m "feat: rewrite TradeEntryView as glass overlay modal with category switcher"
```

---

### Task 3: Update `TradeListPanel` — add `onNewTrade` callback + "+" button

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift`

**Step 1: Add `onNewTrade` parameter to init**

Replace the `init` and stored property block:

```swift
public struct TradeListPanel: View {
    let category: JournalCategory
    let trades: [Trade]
    @Binding var selectedTrade: Trade?
    @Binding var sortByPnL: Bool
    let onNewTrade: () -> Void

    @State private var activeFilter: String = "All"

    public init(
        category: JournalCategory,
        trades: [Trade],
        selectedTrade: Binding<Trade?>,
        sortByPnL: Binding<Bool>,
        onNewTrade: @escaping () -> Void
    ) {
        self.category = category
        self.trades = trades
        self._selectedTrade = selectedTrade
        self._sortByPnL = sortByPnL
        self.onNewTrade = onNewTrade
    }
```

**Step 2: Add "+" button to `listHeader`**

Replace the `listHeader` computed property:

```swift
private var listHeader: some View {
    HStack {
        Text(category == .all ? "All Trades" : category.rawValue)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)
        Spacer()
        Button {
            onNewTrade()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fmsPrimary)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 6)
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
```

**Step 3: Wire empty state button**

Replace `Button("+ Log First Trade") {}` with:

```swift
Button("+ Log First Trade") { onNewTrade() }
```

**Step 4: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
```

Expected: Compile error in `JournalDetailView.swift` — missing `onNewTrade` argument. That's correct; fix in Task 4.

**Step 5: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift
git commit -m "feat: add onNewTrade callback and + button to TradeListPanel"
```

---

### Task 4: Update `JournalDetailView` — ZStack overlay + wire everything

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift`

**Step 1: Rewrite `JournalDetailView`**

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
    @State private var showingEntry = false

    public init(category: JournalCategory, modelContainer: ModelContainer) {
        self.category = category
        self.modelContainer = modelContainer
        self._viewModel = State(wrappedValue: TradeViewModel(
            repository: TradeRepository(context: modelContainer.mainContext),
            userId: "current-user"
        ))
    }

    public var body: some View {
        ZStack {
            HSplitView {
                TradeListPanel(
                    category: category,
                    trades: sortedTrades,
                    selectedTrade: $selectedTrade,
                    sortByPnL: $sortByPnL,
                    onNewTrade: { showingEntry = true }
                )
                .frame(minWidth: 320, maxWidth: 320)

                detailPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if showingEntry {
                TradeEntryView(
                    initialCategory: category,
                    viewModel: viewModel,
                    onDismiss: {
                        showingEntry = false
                        viewModel.loadTrades(category: category)
                    }
                )
            }
        }
        .onAppear { viewModel.loadTrades(category: category) }
        .onChange(of: category) { _, newCategory in
            selectedTrade = nil
            showingEntry = false
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

    private func pnl(_ trade: Trade) -> Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }

    private var sortedTrades: [Trade] {
        sortByPnL ? viewModel.trades.sorted { pnl($0) > pnl($1) } : viewModel.trades
    }
}
```

**Step 2: Build + run tests**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
swift test 2>&1 | tail -5
```

Expected: `Build complete!` and `193 tests passed`.

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift
git commit -m "feat: add trade entry overlay to JournalDetailView with ZStack + category pre-select"
```

---

### Task 5: Delete HTML reference files + final verification

**Files:**
- Delete: `crypto_layover.html`, `forex_layover.html`, `options_layover.html`, `stock:etf_layover.html`

**Step 1: Delete HTML files**

```bash
cd /Users/stevy/Documents/Git/TLSuite
rm crypto_layover.html forex_layover.html options_layover.html "stock:etf_layover.html"
```

**Step 2: Run full test suite**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test 2>&1 | tail -5
```

Expected: `193 tests passed` (all green).

**Step 3: Final commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add -A
git commit -m "chore: remove trade entry overlay HTML reference files"
```

---

## Quick Reference

### Design tokens
- `Color.fmsPrimary` — #13ec80
- `Color.fmsLoss` — #ff5f57
- `Color.fmsSurface` — card/field backgrounds
- `Color.fmsBackground` — window / modal background
- `Color.fmsOnSurface` — primary text
- `Color.fmsMuted` — labels, secondary text

### Category → AssetCategory mapping (added to `JournalCategory`)
| JournalCategory | AssetCategory |
|-----------------|---------------|
| `.stocksETFs` / `.all` | `.stocks` |
| `.forex` | `.forex` |
| `.crypto` | `.crypto` |
| `.options` | `.options` |

### Build + test
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp
swift build   # compile check
swift test    # all 193 tests must pass
```
