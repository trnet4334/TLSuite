# Journal Sub-View Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign all 4 trade list cards and 4 detail panels in the journal feature to match the HTML reference designs (stocks:etf.html, crypto.html, forex.html, options.html).

**Architecture:** Create a shared `TradeDetailLayout` SwiftUI view that renders the common hero header (asset name + subtitle + large P&L), notes section, chart screenshots, and footer (Discard/Save) via a `@ViewBuilder metricsContent` slot. Each category detail panel provides only its specific 4-column metric cards. Trade cards gain an `isSelected: Bool` parameter so `TradeListPanel` can show the active left-border state.

**Tech Stack:** SwiftUI, Swift 5.9+, macOS 14+, SwiftData (@Bindable for detail panels), Manrope font (system font fallback), design tokens via `Color.fmsPrimary / fmsSurface / fmsBackground / fmsOnSurface / fmsMuted / fmsLoss`.

---

## Files Overview

| File | Action |
|------|--------|
| `Features/Journal/Views/Shared/TradeDetailLayout.swift` | **Create** — shared layout shell |
| `Features/Journal/Views/TradeListPanel.swift` | **Modify** — pass `isSelected` to each card |
| `Features/Journal/Views/Stocks/StocksTradeCard.swift` | **Rewrite** — richer card + selection border |
| `Features/Journal/Views/Stocks/StocksDetailPanel.swift` | **Rewrite** — use TradeDetailLayout |
| `Features/Journal/Views/Crypto/CryptoTradeCard.swift` | **Rewrite** — leverage badge + ROE% + wallet fragment |
| `Features/Journal/Views/Crypto/CryptoDetailPanel.swift` | **Rewrite** — use TradeDetailLayout + wallet row |
| `Features/Journal/Views/Forex/ForexTradeCard.swift` | **Rewrite** — rate display + last trade note |
| `Features/Journal/Views/Forex/ForexDetailPanel.swift` | **Rewrite** — use TradeDetailLayout |
| `Features/Journal/Views/Options/OptionsTradeCard.swift` | **Rewrite** — contract name + expiry+qty |
| `Features/Journal/Views/Options/OptionsDetailPanel.swift` | **Rewrite** — use TradeDetailLayout + Greeks |

**No Trade model changes needed** — all required fields already exist (leverage, fundingRate, walletAddress, pipValue, lotSize, exposure, strikePrice, expirationDate, costBasis, greeksDelta/Gamma/Theta/Vega).

**No new tests needed for pure SwiftUI view files** (no business logic is added). The existing 193 tests must continue to pass.

---

### Task 1: Create `TradeDetailLayout` — shared panel shell

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Shared/TradeDetailLayout.swift`

This view renders:
1. **Hero header** — large asset name (left) + subtitle text (left) + colored P&L amount (right)
2. **Metrics slot** — caller-provided `@ViewBuilder metricsContent`
3. **Notes & Reflection** — section label + `TextEditor` in a card
4. **Chart Analysis** — section label + 2 side-by-side dashed upload areas (16:9 aspect ratio)
5. **Footer** — Discard + Save Entry buttons

**Step 1: Create the file**

```swift
// FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Shared/TradeDetailLayout.swift
import SwiftUI

/// Shared layout shell for all category detail panels.
/// Callers supply the 4-column metrics content via `metricsContent`.
public struct TradeDetailLayout<Metrics: View>: View {
    @Bindable var trade: Trade
    let subtitle: String
    let onDiscard: () -> Void
    let onSave: () -> Void
    @ViewBuilder let metricsContent: () -> Metrics

    public init(
        trade: Trade,
        subtitle: String,
        onDiscard: @escaping () -> Void,
        onSave: @escaping () -> Void,
        @ViewBuilder metricsContent: @escaping () -> Metrics
    ) {
        self.trade = trade
        self.subtitle = subtitle
        self.onDiscard = onDiscard
        self.onSave = onSave
        self.metricsContent = metricsContent
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroHeader
                metricsContent()
                notesSection
                chartSection
                footerActions
            }
            .padding(32)
        }
        .background(Color.fmsBackground)
    }

    // MARK: Hero Header

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.asset)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(pnlFormatted)
                    .font(.system(size: 32, weight: .heavy).monospacedDigit())
                    .foregroundStyle(pnlColor)
                if let roi = roiPercent {
                    Text(roi)
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                        .foregroundStyle(pnlColor.opacity(0.7))
                }
            }
        }
    }

    // MARK: Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Notes & Reflection", systemImage: "note.text")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            TextEditor(text: Binding(
                get: { trade.notes ?? "" },
                set: { trade.notes = $0 }
            ))
            .font(.system(size: 13))
            .foregroundStyle(Color.fmsOnSurface)
            .frame(minHeight: 200)
            .padding(14)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: Chart Analysis

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Chart Analysis", systemImage: "photo")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 14) {
                uploadArea(label: "Entry Chart")
                uploadArea(label: "Exit Chart")
            }
        }
    }

    private func uploadArea(label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.viewfinder")
                .font(.system(size: 28))
                .foregroundStyle(Color.fmsMuted)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [6])
                )
                .foregroundStyle(Color.fmsMuted.opacity(0.35))
        )
    }

    // MARK: Footer

    private var footerActions: some View {
        HStack {
            Spacer()
            Button("Discard") { onDiscard() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(Color.fmsMuted)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            Button("Save Entry") { onSave() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.fmsBackground)
        }
        .padding(.top, 8)
    }

    // MARK: P&L helpers

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }

    private var pnlFormatted: String {
        let v = computedPnL
        return v >= 0 ? "+$\(String(format: "%.2f", v))" : "-$\(String(format: "%.2f", abs(v)))"
    }

    private var pnlColor: Color {
        let v = computedPnL
        if v > 0 { return Color.fmsPrimary }
        if v < 0 { return Color.fmsLoss }
        return Color.fmsMuted
    }

    private var roiPercent: String? {
        guard let exit = trade.exitPrice, trade.entryPrice > 0 else { return nil }
        let pct = ((exit - trade.entryPrice) / trade.entryPrice) * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% ROI"
    }
}

/// Reusable editable metric card used in all category panels.
public struct MetricCard<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    public init(label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.fmsOnSurface)
                .textFieldStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.fmsMuted.opacity(0.12), lineWidth: 1)
        )
    }
}
```

**Step 2: Verify it compiles**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp
swift build 2>&1 | tail -20
```

Expected: Build succeeds (new types used by no one yet, so no breaks).

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Shared/
git commit -m "feat: add TradeDetailLayout + MetricCard shared journal components"
```

---

### Task 2: Rewrite `StocksDetailPanel` using `TradeDetailLayout`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksDetailPanel.swift`

**Step 1: Rewrite the file**

```swift
import SwiftUI

public struct StocksDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: "Stocks & ETFs",
            onDiscard: {},
            onSave: onSave
        ) {
            metricsGrid
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: "Entry Price") {
                TextField("0.00", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: "Exit Price") {
                TextField("0.00", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { trade.exitPrice = $0 }
                ), format: .number)
            }
            MetricCard(label: "Quantity") {
                TextField("0", value: $trade.positionSize, format: .number)
            }
            MetricCard(label: "Direction") {
                Text(trade.direction == .long ? "Long" : "Short")
                    .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
            }
        }
    }
}
```

**Step 2: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
```

Expected: Build succeeds.

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksDetailPanel.swift
git commit -m "feat: rewrite StocksDetailPanel with TradeDetailLayout hero header"
```

---

### Task 3: Rewrite `CryptoDetailPanel` using `TradeDetailLayout`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Crypto/CryptoDetailPanel.swift`

**Step 1: Rewrite the file**

```swift
import SwiftUI

public struct CryptoDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: subtitle,
            onDiscard: {},
            onSave: onSave
        ) {
            VStack(spacing: 16) {
                metricsGrid
                if trade.walletAddress != nil {
                    walletRow
                }
            }
        }
    }

    private var subtitle: String {
        if let lev = trade.leverage, lev > 1 {
            return "Futures · \(String(format: "%.0f", lev))x Leverage"
        }
        return "Spot"
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: "Entry Price") {
                TextField("0.00", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: "Exit Price") {
                TextField("0.00", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { trade.exitPrice = $0 }
                ), format: .number)
            }
            MetricCard(label: "Leverage") {
                TextField("1x", value: Binding(
                    get: { trade.leverage ?? 1 },
                    set: { trade.leverage = $0 }
                ), format: .number)
            }
            MetricCard(label: "Funding Rate") {
                TextField("0.0000%", value: Binding(
                    get: { trade.fundingRate ?? 0 },
                    set: { trade.fundingRate = $0 }
                ), format: .number)
            }
        }
    }

    private var walletRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 16))
                .foregroundStyle(Color.fmsPrimary)
                .frame(width: 36, height: 36)
                .background(Color.fmsPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("EXECUTING WALLET")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .tracking(0.5)
                Text(trade.walletAddress ?? "—")
                    .font(.system(size: 12).monospaced())
                    .foregroundStyle(Color.fmsOnSurface)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button {
                if let addr = trade.walletAddress {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(addr, forType: .string)
                }
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.fmsPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.fmsPrimary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.fmsPrimary.opacity(0.2), lineWidth: 1)
        )
    }
}
```

**Step 2: Build + commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Crypto/CryptoDetailPanel.swift
git commit -m "feat: rewrite CryptoDetailPanel — leverage metrics + wallet address row"
```

---

### Task 4: Rewrite `ForexDetailPanel` using `TradeDetailLayout`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Forex/ForexDetailPanel.swift`

**Step 1: Rewrite the file**

```swift
import SwiftUI

public struct ForexDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: "Active Trade Analysis · \(sessionLabel)",
            onDiscard: {},
            onSave: onSave
        ) {
            metricsGrid
        }
    }

    private var sessionLabel: String {
        // Derive session from entry time (UTC hour ranges)
        let hour = Calendar.current.component(.hour, from: trade.entryAt)
        switch hour {
        case 8..<12:  return "London Session"
        case 12..<17: return "NY Session"
        case 0..<8:   return "Asia Session"
        default:      return "Off-Hours"
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: "Pip Value") {
                TextField("0.00", value: Binding(
                    get: { trade.pipValue ?? 0 },
                    set: { trade.pipValue = $0 }
                ), format: .number)
            }
            MetricCard(label: "Lot Size") {
                TextField("0.00", value: Binding(
                    get: { trade.lotSize ?? 0 },
                    set: { trade.lotSize = $0 }
                ), format: .number)
            }
            MetricCard(label: "Entry Rate") {
                TextField("0.0000", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: "Exposure") {
                TextField("0", value: Binding(
                    get: { trade.exposure ?? 0 },
                    set: { trade.exposure = $0 }
                ), format: .number)
            }
        }
    }
}
```

**Step 2: Build + commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Forex/ForexDetailPanel.swift
git commit -m "feat: rewrite ForexDetailPanel — pip/lot/rate/exposure metrics + session label"
```

---

### Task 5: Rewrite `OptionsDetailPanel` using `TradeDetailLayout`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Options/OptionsDetailPanel.swift`

**Step 1: Rewrite the file**

```swift
import SwiftUI

public struct OptionsDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    private var contractSubtitle: String {
        let type = trade.direction == .long ? "Call · Bullish Long" : "Put · Bearish Short"
        if let exp = trade.expirationDate {
            return "\(type) · Exp \(exp.formatted(.dateTime.month().day().year()))"
        }
        return type
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: contractSubtitle,
            onDiscard: {},
            onSave: onSave
        ) {
            VStack(spacing: 16) {
                metricsGrid
                greeksPanel
            }
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: "Strike Price") {
                TextField("0.00", value: Binding(
                    get: { trade.strikePrice ?? 0 },
                    set: { trade.strikePrice = $0 }
                ), format: .number)
            }
            MetricCard(label: "Expiration") {
                DatePicker("", selection: Binding(
                    get: { trade.expirationDate ?? Date() },
                    set: { trade.expirationDate = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .font(.system(size: 13))
            }
            MetricCard(label: "Quantity") {
                TextField("0", value: $trade.positionSize, format: .number)
            }
            MetricCard(label: "Cost Basis") {
                TextField("0.00", value: Binding(
                    get: { trade.costBasis ?? 0 },
                    set: { trade.costBasis = $0 }
                ), format: .number)
            }
        }
    }

    private var greeksPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Option Greeks", systemImage: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 12) {
                greekCell(label: "Delta", value: trade.greeksDelta)
                greekCell(label: "Gamma", value: trade.greeksGamma)
                greekCell(label: "Theta", value: trade.greeksTheta)
                greekCell(label: "Vega",  value: trade.greeksVega)
            }
            .padding(16)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.fmsMuted.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private func greekCell(label: String, value: Double?) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .tracking(0.5)
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.fmsOnSurface)
        }
        .frame(maxWidth: .infinity)
    }
}
```

**Step 2: Build + commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Options/OptionsDetailPanel.swift
git commit -m "feat: rewrite OptionsDetailPanel — strike/exp/qty/cost metrics + Greeks panel"
```

---

### Task 6: Update `TradeListPanel` to pass `isSelected` to trade cards

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift`

**Step 1: Update `tradeCard` helper to pass selection state**

In `TradeListPanel`, find the `tradeCard(_ trade: Trade)` method (line 130) and update it:

```swift
@ViewBuilder
private func tradeCard(_ trade: Trade) -> some View {
    let selected = selectedTrade?.id == trade.id
    switch trade.journalCategory {
    case .crypto:  CryptoTradeCard(trade: trade, isSelected: selected)
    case .forex:   ForexTradeCard(trade: trade, isSelected: selected)
    case .options: OptionsTradeCard(trade: trade, isSelected: selected)
    default:       StocksTradeCard(trade: trade, isSelected: selected)
    }
}
```

Also update `listRowBackground` to use `Color.clear` (the selected border is now handled within the card):

```swift
private var tradeList: some View {
    List(filteredTrades, id: \.id, selection: $selectedTrade) { trade in
        tradeCard(trade)
            .tag(trade)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
}
```

**Step 2: Verify build (will fail until cards are updated)**

Expected: Build errors about missing `isSelected` parameter — this is correct.

---

### Task 7: Rewrite `StocksTradeCard` with selection border

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Stocks/StocksTradeCard.swift`

**Step 1: Rewrite**

```swift
import SwiftUI

public struct StocksTradeCard: View {
    let trade: Trade
    let isSelected: Bool

    public init(trade: Trade, isSelected: Bool = false) {
        self.trade = trade
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Left selection indicator
            Rectangle()
                .fill(isSelected ? Color.fmsPrimary : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 5) {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var directionBadge: some View {
        Text(trade.direction == .long ? "BUY" : "SELL")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                trade.direction == .long ? Color.fmsPrimary.opacity(0.18) : Color.fmsLoss.opacity(0.18),
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

**Step 2: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
```

Expected: Still fails for crypto/forex/options cards (not yet updated).

---

### Task 8: Rewrite `CryptoTradeCard` with leverage badge + ROE% + selection border

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Crypto/CryptoTradeCard.swift`

**Step 1: Rewrite**

```swift
import SwiftUI

public struct CryptoTradeCard: View {
    let trade: Trade
    let isSelected: Bool

    public init(trade: Trade, isSelected: Bool = false) {
        self.trade = trade
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.fmsPrimary : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(trade.asset)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    leverageBadge
                }
                HStack {
                    Text(trade.entryAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        pnlText
                        if let roe = roePercent {
                            Text(roe)
                                .font(.system(size: 10).monospacedDigit())
                                .foregroundStyle(Color.fmsMuted)
                        }
                    }
                }
                if let wallet = trade.walletAddress {
                    Text(wallet.prefix(8) + "..." + wallet.suffix(4))
                        .font(.system(size: 10).monospaced())
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var leverageBadge: some View {
        let lev = trade.leverage ?? 1
        let isLong = trade.direction == .long
        let label = lev > 1
            ? "\(isLong ? "LONG" : "SHORT") \(String(format: "%.0f", lev))x"
            : (isLong ? "SPOT" : "SHORT")
        let color: Color = lev > 1 ? (isLong ? Color.fmsPrimary : Color.fmsLoss) : Color.fmsMuted
        return Text(label)
            .font(.system(size: 10, weight: .bold).monospaced())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var roePercent: String? {
        guard let exit = trade.exitPrice, trade.entryPrice > 0 else { return nil }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        let pct = ((exit - trade.entryPrice) / trade.entryPrice) * (trade.leverage ?? 1) * multiplier * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% ROE"
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }
}
```

**Step 2: Build**

Expected: Still fails for forex/options.

---

### Task 9: Rewrite `ForexTradeCard` with rate + session note + selection border

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Forex/ForexTradeCard.swift`

**Step 1: Rewrite**

```swift
import SwiftUI

public struct ForexTradeCard: View {
    let trade: Trade
    let isSelected: Bool

    public init(trade: Trade, isSelected: Bool = false) {
        self.trade = trade
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.fmsPrimary : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(trade.asset)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    pnlChangePill
                }
                HStack(alignment: .bottom) {
                    Text(trade.entryPrice, format: .number.precision(.fractionLength(4)))
                        .font(.system(size: 18, weight: .medium).monospacedDigit())
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    pnlText
                }
                Text(lastTradeNote)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var pnlChangePill: some View {
        let pnl = computedPnL
        let pct = trade.entryPrice > 0 && trade.exitPrice != nil
            ? ((trade.exitPrice! - trade.entryPrice) / trade.entryPrice) * 100
            : 0.0
        let color: Color = pct > 0 ? Color.fmsPrimary : (pct < 0 ? Color.fmsLoss : Color.fmsMuted)
        let sign = pct >= 0 ? "+" : ""
        return Text("\(sign)\(String(format: "%.2f", pct))%")
            .font(.system(size: 10, weight: .semibold).monospacedDigit())
            .foregroundStyle(color)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var lastTradeNote: String {
        let pnl = computedPnL
        if trade.exitPrice == nil { return "No active trades" }
        if pnl >= 0 { return "Last trade: Profit $\(String(format: "%.2f", pnl))" }
        return "Last trade: Loss -$\(String(format: "%.2f", abs(pnl)))"
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }
}
```

**Step 2: Build**

Expected: Still fails for options.

---

### Task 10: Rewrite `OptionsTradeCard` with contract name + expiry + selection border

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/Options/OptionsTradeCard.swift`

**Step 1: Rewrite**

```swift
import SwiftUI

public struct OptionsTradeCard: View {
    let trade: Trade
    let isSelected: Bool

    public init(trade: Trade, isSelected: Bool = false) {
        self.trade = trade
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.fmsPrimary : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(contractName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                        .lineLimit(1)
                    Spacer()
                    pnlText
                }
                HStack {
                    if let exp = trade.expirationDate {
                        Text("Exp: \(exp.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fmsMuted)
                    }
                    Spacer()
                    Text("Qty: \(trade.positionSize, specifier: "%.0f")")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var contractName: String {
        let strike = trade.strikePrice.map { "$\(String(format: "%.0f", $0))" } ?? ""
        let type = trade.direction == .long ? "Call" : "Put"
        return "\(trade.asset) \(strike) \(type)".trimmingCharacters(in: .whitespaces)
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

**Step 2: Build and run all tests**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -10
swift test 2>&1 | tail -20
```

Expected: Build succeeds. All 193 tests pass.

**Step 3: Commit all card rewrites**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Features/Journal/Views/
git commit -m "feat: rewrite all 4 trade cards — selection border, richer metadata per category"
```

---

### Task 11: Delete HTML reference files + final verification

**Files:**
- Delete: `crypto.html`, `forex.html`, `options.html`, `stocks:etf.html` (root of repo)

**Step 1: Delete HTML files**

```bash
cd /Users/stevy/Documents/Git/TLSuite
rm crypto.html forex.html options.html "stocks:etf.html"
```

**Step 2: Run full test suite**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp
swift test 2>&1 | tail -5
```

Expected: All 193 tests pass.

**Step 3: Final commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add -A
git commit -m "chore: remove journal HTML reference files after implementation"
```

---

## Quick Reference

### Design tokens
- `Color.fmsPrimary` — #13ec80 (profit green)
- `Color.fmsLoss` — #ff5f57 (loss red)
- `Color.fmsSurface` — #1C1C1E (card backgrounds)
- `Color.fmsBackground` — main window background
- `Color.fmsOnSurface` — primary text
- `Color.fmsMuted` — secondary / label text

### Build command
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build
```

### Test command
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test
```

### Key paths
- Shared layout: `Sources/FMSYSCore/Features/Journal/Views/Shared/TradeDetailLayout.swift`
- Trade model: `Sources/FMSYSCore/Core/Models/Trade.swift`
- List panel: `Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift`
