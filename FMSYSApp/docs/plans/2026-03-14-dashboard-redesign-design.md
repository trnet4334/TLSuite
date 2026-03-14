# Dashboard Redesign — Design Document

**Date:** 2026-03-14
**Scope:** Full replacement of DashboardView with 3-section layout, title bar expansion, editable daily checklist, psychological analytics

---

## Goal

Replace the existing stat-grid DashboardView with a new scrollable 3-section layout: Equity Curve, Market Overview + Daily Checklist, Psychological Analytics. Expand the title bar with search stub, icon popovers (stub), and an avatar popover (user info + sign out).

---

## Section 1: Data Layer

### `EmotionTag` enum (new file)

```swift
public enum EmotionTag: String, Codable, CaseIterable {
    case confident, fearful, greedy, neutral, revenge, fomo
}
```

Extracted to `Core/Models/EmotionTag.swift`.

### `Trade` model additions

- `emotionTagRaw: String?` — SwiftData-stored raw value
- `var emotionTag: EmotionTag?` — computed wrapper (get/set via `emotionTagRaw`)

### `DashboardRange` update

Replace existing `7D/30D/90D/All` cases with:

```swift
public enum DashboardRange: String, CaseIterable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case ytd = "YTD"
}
```

### `MarketQuote` struct (new, in DashboardViewModel)

```swift
public struct MarketQuote: Identifiable {
    public let id: String          // symbol, e.g. "BTC"
    public let name: String
    public let price: Double
    public let changePercent: Double
    public let sparkline: [Double] // 6 data points
}
```

Two hardcoded stubs: BTC (+2.4%) and ETH (-1.2%).

### `ChecklistItem` struct (new, Codable)

```swift
public struct ChecklistItem: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var isChecked: Bool
}
```

Stored as JSON array in `UserDefaults` key `"fmsys.dailyChecklist"`. Default items seeded on first launch:
1. Pre-market prep finished
2. Economic calendar checked
3. Identify key HTF levels

### `ChecklistViewModel` (new, `@Observable`)

Owns `[ChecklistItem]`. Operations:
- `add(title: String)`
- `toggle(id: UUID)`
- `delete(id: UUID)`
- `rename(id: UUID, title: String)`

Reads/writes `UserDefaults` on every mutation.

### `DashboardViewModel` additions

- `var marketQuotes: [MarketQuote]` — static stubs
- `func psychAnalytics` → `PsychAnalytics` struct:
  ```swift
  public struct PsychAnalytics {
      public let disciplineScore: Double   // % trades where emotionTag == .confident || .neutral
      public let patienceIndex: Double     // % trades where emotionTag != .fomo && != .revenge
      public let heatmapCells: [HeatmapCell]
  }
  public struct HeatmapCell: Identifiable {
      public let id: String               // "\(emotion)-\(plBucket)"
      public let emotion: String          // "Fear", "Greed", etc.
      public let plBucket: PLBucket       // .loss / .neutral / .profit
      public let count: Int
  }
  public enum PLBucket { case loss, neutral, profit }
  ```
- Computed from last 30 trades that have `emotionTag != nil`
- `EmotionTag` → display column mapping:
  - `.fearful` → "Fear", `.greedy` → "Greed", `.neutral` → "Bored" (note: neutral maps to Bored; Calm is `.confident`)
  - `.confident` → "Calm", `.fomo` → "Excited", `.revenge` → "Tired", no tag → "Focus" (trades with no emotion tag are excluded from heatmap)
  - Wait — use this mapping:
    - `.fearful` → "Fear"
    - `.greedy` → "Greed"
    - `.neutral` → "Bored"
    - `.confident` → "Calm"
    - `.fomo` → "Excited"
    - `.revenge` → "Tired"
    - "Focus" column: trades where `emotionTag == .confident` AND trade was profitable (special case — same as Calm but filtered to wins only)

  **Simplified mapping (final):**
  | EmotionTag | Heatmap Column |
  |---|---|
  | `.fearful` | Fear |
  | `.greedy` | Greed |
  | `.neutral` | Bored |
  | `.confident` | Calm |
  | `.fomo` | Excited |
  | `.revenge` | Tired |
  | `.confident` + profitable | Focus (duplicate confident → split by P/L) |

  Actually simplest: 6 emotion columns map 1:1 to EmotionTag cases, plus "Focus" = profitable + `.confident`. Implementation: compute count per (emotionTag, plBucket) pair; "Focus" is a synthetic column = `.confident` trades where P/L > 0.

---

## Section 2: Title Bar

**Height:** 48pt. Background: `Color.toolbarLight` / `Color(hex: "#2c2c2e")`.

**Layout (HStack):**
```
[Traffic lights 80pt]  [Spacer]  [Search bar 320pt]  [Spacer]  [Icons + Avatar]
```

**Search bar** (center):
- `HStack`: `magnifyingglass` SF Symbol (16pt, opacity 0.4) + placeholder text "Search trades, journals, analytics..." (11pt, opacity 0.4)
- Background: `Color.white.opacity(0.5)` / `Color.white.opacity(0.1)`, border `Color.black.opacity(0.05)`
- Non-interactive (no action) — Phase 4 stub

**Icon buttons** (32×32pt, `mac-toolbar-btn` style: hover bg `black/5` or `white/10`):
- `bell` → `.popover { Text("Notifications coming soon").padding() }`
- `square.and.arrow.up` → `.popover { Text("Export & Share coming soon").padding() }`
- `gearshape` → `.popover { Text("Settings coming soon").padding() }`

**Avatar button** (28×28pt circle, `slate-300/slate-700` bg, `person` SF Symbol):
`.popover` → `AvatarPopover`:
```
[Circle avatar 40pt]  DisplayName (semibold 14pt)
                      email (muted 11pt)
                      [Role badge] (fmsPrimary bg, dark text, 10pt)
─────────────────────────────────────────
[⚙] Account Settings  →  (navigates to Settings stub)
[→] Sign Out          →  authViewModel.signOut()
```

Data source: `AppState.userDisplayName`, `AppState.userEmail`, `AppState.userRole` (placeholder strings).

---

## Section 3: Main Content

**Shell:** `ScrollView(.vertical)` wrapping `VStack(spacing: 24)`, padding 24pt.
Background: `Color.backgroundLight` (light) / `Color.baseDark` (dark).

### Section 1 — Equity Curve Card

```
┌──────────────────────────────────────────────────────┐
│ Equity Curve               [1W] [1M] [3M] [YTD]      │
│ Compound performance vs. benchmark                    │
│                                                       │
│  [Swift Charts AreaMark + LineMark, height 180pt]     │
│  fmsPrimary stroke + gradient fill (opacity 0→0.2)   │
│                                                       │
│  May 01      May 10      May 20      Jun 01           │
└──────────────────────────────────────────────────────┘
```

- Range picker: segmented control (or button row with bg highlight) — sets `DashboardViewModel.selectedRange`
- Chart data: `DashboardViewModel.equityCurve(range: selectedRange)`
- X-axis: 4 evenly spaced date labels, 9pt uppercase muted

### Section 2 — 2-Column Grid

`HStack(spacing: 24)`, each card equal width (`maxWidth: .infinity`).

**Market Overview card (left):**
```
┌────────────────────────────────┐
│ 📈 Market Overview             │
│                                │
│ [BTC]  Bitcoin   sparkline +2.4%│
│        $64,231.50              │
│ [ETH]  Ethereum  sparkline -1.2%│
│        $3,420.12               │
└────────────────────────────────┘
```
- Asset icon: colored square (orange/BTC, blue/ETH), 32×32pt rounded
- Sparkline: Swift Charts `LineMark`, 64×24pt, stroke color green/red based on `changePercent` sign
- Change badge: `fmsPrimary` if positive, `fmsLoss` if negative

**Daily Checklist card (right):**
```
┌────────────────────────────────┐
│ ✅ Daily Checklist          [+] │
│                                │
│ [✓] Pre-market prep finished   │
│ [✓] Economic calendar checked  │
│ [ ] Identify key HTF levels    │
│                                │
└────────────────────────────────┘
```
- Checkbox: `fmsPrimary` bg + checkmark when checked; border-only when unchecked
- Tap label: inline `TextField` for rename
- `+` button: appends new item (empty title, auto-focuses)
- Swipe-to-delete (`.onDelete`)
- Empty state: "Add your first checklist item" (muted, centered)
- Data: `ChecklistViewModel`

### Section 3 — Psychological Analytics Card

```
┌──────────────────────────────────────────────────────┐
│ 🧠 PSYCHOLOGICAL ANALYTICS          LAST 30 SESSIONS │
│                                                       │
│  Discipline Score  88%  ████████░░                   │
│  Patience Index    72%  ███████░░░  (blue)            │
│                                                       │
│  Emotion vs. P/L Heatmap      Loss · Neutral · Profit│
│  [Fear][Greed][Bored][Calm][Excited][Tired][Focus]   │
│  [ cell ][ cell ]...  (3 rows × 7 cols)              │
└──────────────────────────────────────────────────────┘
```

- Left 1/3: two `VStack` progress bar cards
  - Discipline Score: `fmsPrimary` fill
  - Patience Index: `Color.info` (#58a6ff) fill
- Right 2/3: heatmap grid
  - `LazyVGrid(columns: Array(repeating: .flexible(), count: 7))`
  - Each cell: `RoundedRectangle(cornerRadius: 4)` colored at opacity proportional to count
    - Loss → `fmsLoss` opacity `0.1...0.8`
    - Profit → `fmsPrimary` opacity `0.1...0.9`
    - Neutral → `Color.fmsMuted` opacity `0.2`
  - Column headers: emotion label (8pt uppercase muted)
  - Legend: 3 swatches + labels (9pt), top-right of heatmap area

---

## Section 4: File Map

### Modified
| File | Change |
|---|---|
| `Core/Models/Trade.swift` | Add `emotionTagRaw: String?` + computed `emotionTag` |
| `Features/Dashboard/DashboardViewModel.swift` | Update `DashboardRange`, add `marketQuotes`, `psychAnalytics`, `MarketQuote`, `PsychAnalytics`, `HeatmapCell` |
| `App/MainAppView.swift` | Expand title bar |
| `App/AppState.swift` | Add `userDisplayName`, `userEmail`, `userRole` placeholder properties |
| `Tests/FMSYSAppTests/DashboardViewModelTests.swift` | Extend with range, psychAnalytics, heatmap tests |

### New
| File | Purpose |
|---|---|
| `Core/Models/EmotionTag.swift` | EmotionTag enum |
| `Features/Dashboard/Views/DashboardView.swift` | Full rewrite — 3-section scroll shell |
| `Features/Dashboard/Views/EquityCurveSection.swift` | Section 1 |
| `Features/Dashboard/Views/MarketOverviewCard.swift` | Section 2 left |
| `Features/Dashboard/Views/DailyChecklistCard.swift` | Section 2 right |
| `Features/Dashboard/Views/PsychAnalyticsSection.swift` | Section 3 |
| `Features/Dashboard/ChecklistViewModel.swift` | Editable checklist, UserDefaults |
| `Shared/Components/AvatarPopover.swift` | Avatar popover content |
| `Tests/FMSYSAppTests/ChecklistViewModelTests.swift` | Checklist CRUD + persistence tests |

---

## Out of Scope

- Real market data API (stubs only)
- Notifications, Share, Settings popovers (stubs only)
- User profile API (AppState placeholders only)
- ⌘K global search
- Emotion tag input UI in TradeDetailPanels (Phase 4)
