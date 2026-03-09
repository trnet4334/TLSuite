# Journal Phase 2 — Design Document

**Date:** 2026-03-09
**Scope:** Trade detail views (all 4 categories), journal category routing, sidebar update, journal enhancements

---

## Goal

Replace the current single-column `TradeListView` with a full 3-column journal shell: trade list panel (320px) + category-specific detail panel (flex). Add 4 category sub-views (Stocks/ETFs, Forex, Crypto, Options), each with category-specific fields. Update sidebar sub-items and wire category routing end-to-end.

---

## Section 1: Data Layer

### `JournalCategory` enum (new)

```swift
public enum JournalCategory: String, Codable, CaseIterable {
    case all        = "All"
    case stocksETFs = "Stocks/ETFs"
    case forex      = "Forex"
    case crypto     = "Crypto"
    case options    = "Options"
}
```

### `Trade` model additions

All new fields are optional and nil when not applicable to the category.

| Field | Type | Category |
|---|---|---|
| `category` | `JournalCategory` (non-optional, default `.stocksETFs`) | All |
| `entryTime` | `Date?` | All (time component of entry) |
| `exitTime` | `Date?` | All (time component of exit) |
| `leverage` | `Double?` | Crypto |
| `fundingRate` | `Double?` | Crypto |
| `walletAddress` | `String?` | Crypto |
| `pipValue` | `Double?` | Forex |
| `lotSize` | `Double?` | Forex |
| `exposure` | `Double?` | Forex |
| `sessionNotes` | `String?` | Forex |
| `strikePrice` | `Double?` | Options |
| `expirationDate` | `Date?` | Options |
| `costBasis` | `Double?` | Options |
| `greeksDelta` | `Double?` | Options |
| `greeksGamma` | `Double?` | Options |
| `greeksTheta` | `Double?` | Options |
| `greeksVega` | `Double?` | Options |

Common fields already on `Trade` (entryPrice, exitPrice, quantity, fees, notes, userId, direction, symbol, entryDate, exitDate) remain unchanged. `entryTime` and `exitTime` display the time component of the existing date fields.

---

## Section 2: Navigation & Routing

### Sidebar update

| Before | After |
|---|---|
| Stocks | Stocks/ETFs |
| ETFs | Options |
| Forex | Forex |
| Crypto | Crypto |

`AppScreen.journal` stays as the single case for the journal screen.

### `JournalCategory` routing

- `SidebarView` gains `@Binding var journalCategory: JournalCategory`
- Journal parent label tap → `journalCategory = .all`
- Each sub-item tap → sets its specific category + `selectedScreen = .journal`
- `MainAppView` adds `@State private var journalCategory: JournalCategory = .all`
- Passes `$journalCategory` to `SidebarView` and to the `.journal` case of `screenContent`

### Flow

```
User taps "Crypto" in sidebar
  → selectedScreen = .journal
  → journalCategory = .crypto
  → screenContent routes to JournalDetailView(category: .crypto, ...)
    → TradeListPanel shows trades filtered to category == .crypto
    → Detail panel shows CryptoDetailPanel for selectedTrade
```

When `journalCategory == .all`:
- `TradeListPanel` shows all trades (no filter), with a category badge on each card
- Detail panel routes to the correct category-specific panel based on `selectedTrade.category`

---

## Section 3: Shared 3-column Layout Shell

### `JournalDetailView` (new — thin router)

```
JournalDetailView(category: JournalCategory, modelContainer: ModelContainer)
  ├── TradeListPanel (320px fixed)
  │     ├── header: category title + sort toggle + filter bar
  │     ├── List(selection: $selectedTrade) of category-specific cards
  │     └── empty state when no trades
  └── TradeDetailPanel (flex) — routes by category/selectedTrade.category
        ├── CryptoDetailPanel
        ├── StocksDetailPanel
        ├── ForexDetailPanel
        └── OptionsDetailPanel
```

**State owned by `JournalDetailView`:**
- `@State var selectedTrade: Trade?`
- `@State var viewModel: TradeViewModel` (filtered by category)

### `TradeListPanel` (shared)

- Header: category name (12px uppercase bold) + sort toggle (Newest ↕ P&L) + filter bar
- `List(selection: $selectedTrade)` of trade cards
- Keyboard ↑↓ navigation
- Fixed width: 320px
- Empty state: edit_note icon (48px muted) + "Start Your Trading Journal" + "+ Log First Trade" CTA (fmsPrimary bg)

---

## Section 4: Category-specific Detail Panels

### Shared outer chrome (all categories)

```
[Asset / contract name]  [Status badge]  [Trade ID]  [💾 Save]
─────────────────────────────────────────────────────────────────
Row 1 (common): Entry Price | Entry Time | Exit Price | Exit Time
Row 2 (category-specific): see table below
[category extras if any]
─────────────────────────────────────────────────────────────────
Trade Reflection & Notes  (TextEditor, min-height 250px)
─────────────────────────────────────────────────────────────────
Chart Screenshots  (2-column grid, dashed upload areas)
```

### Row 2 metrics per category

| Category | Col 1 | Col 2 | Col 3 | Col 4 |
|---|---|---|---|---|
| Stocks/ETFs | Qty | Fees | — | — |
| Crypto | Leverage | Funding Rate | Wallet Address (colspan 2) | |
| Forex | Pip Value | Lot Size | Exposure | — |
| Options | Strike Price | Expiration | Qty | Cost Basis |

### Category extras

- **Options**: Greeks row below row 2 — Delta · Gamma · Theta · Vega (4-col grid, read-only display)
- **Crypto**: Wallet address shown monospaced, truncated, with copy button
- **Forex**: "Session Notes" text field (separate from Trade Reflection)

### Save behavior

All panels editable inline. Save button in header calls `TradeViewModel.update(trade:)`.

### New files

```
Features/Journal/Views/JournalDetailView.swift
Features/Journal/Views/TradeListPanel.swift
Features/Journal/Views/Crypto/CryptoTradeCard.swift
Features/Journal/Views/Crypto/CryptoDetailPanel.swift
Features/Journal/Views/Stocks/StocksTradeCard.swift
Features/Journal/Views/Stocks/StocksDetailPanel.swift
Features/Journal/Views/Forex/ForexTradeCard.swift
Features/Journal/Views/Forex/ForexDetailPanel.swift
Features/Journal/Views/Options/OptionsTradeCard.swift
Features/Journal/Views/Options/OptionsDetailPanel.swift
```

---

## Section 5: Journal Enhancements

### Filters (client-side, per category)

| Category | Filter options |
|---|---|
| All | Date range picker |
| Stocks/ETFs | [Buy] [Sell] · Date range |
| Crypto | [All] [Spot] [Futures] · Date range |
| Forex | Active pairs only toggle · Date range |
| Options | [Call] [Put] · Date range |

Filters are `@State` local to `TradeListPanel`, applied in-memory on `viewModel.trades`.

### Sort

Single toggle in list header: **Newest ↕ P&L** — switches between `entryDate` descending and `pnl` descending.

### Search

Deferred to Phase 3 (global ⌘K search is a separate large feature).

### Empty state (per spec)

Icon: edit_note (48px, muted/30)
Title: "Start Your Trading Journal"
Description: "Record your first trade to begin tracking performance and building insights."
CTA: "+ Log First Trade" (fmsPrimary background button)

---

## Out of Scope (Phase 2)

- Global ⌘K search
- Toolbar popovers (Notifications, Quick Settings, Share)
- Settings screen
- Portfolio, Strategy Lab, Backtesting (stubs remain)
- Rich text editor for notes (plain `TextEditor` for now)
- Screenshot upload (UI placeholder only, no actual file storage)
- Real-time market data in sidebar equity card
