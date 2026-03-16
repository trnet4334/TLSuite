# Trading Data Import & Central Data Layer — Design

**Date:** 2026-03-16

## Goal

Build manual trade input (exists), CSV import with broker auto-detection, a central `TradingDataService` actor so all pages derive real data, and image compression for journal notes.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   SwiftData Layer                    │
│  Trade (existing)  ·  JournalAttachment (new)        │
└────────────────────┬────────────────────────────────┘
                     │
         ┌───────────▼───────────┐
         │  TradingDataService   │  ← actor，單一真相來源
         │  AsyncStream<[Trade]> │    所有 Trade CRUD 走這裡
         └──┬────┬────┬────┬────┘
            │    │    │    │
   Dashboard  Journal Portfolio Backtesting
   ViewModel  ViewModel ViewModel ViewModel

┌─────────────────────────────────┐
│  MarketDataServiceProtocol      │  mock now → real API later
│  MockMarketDataService          │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  CSVImportService               │  broker detection + mapping
│  ImageCompressionService        │  JPEG compress + thumbnail
└─────────────────────────────────┘
```

## Section 1: TradingDataService

**Actor interface:**
```swift
actor TradingDataService {
    var tradesStream: AsyncStream<[Trade]>

    func allTrades() async -> [Trade]
    func trades(for category: JournalCategory) async -> [Trade]
    func create(_ trade: Trade) async throws
    func update(_ trade: Trade) async throws
    func delete(_ trade: Trade) async throws
    func importTrades(_ trades: [Trade]) async throws  // CSV batch
}
```

**Page-level derived data:**

| Page | Derived from trades |
|------|-------------------|
| Dashboard | Total P&L, win rate, equity curve (cumulative), emotion distribution |
| Journal | Filtered trade list by category (existing, re-routed through service) |
| Portfolio | Position summary, asset allocation %, MTD/YTD return |
| Backtesting | Keep seeded data; future: compare against real trades |

## Section 2: MarketDataService

```swift
protocol MarketDataServiceProtocol {
    func quote(for symbol: String) async -> MarketQuote
    func historicalPrices(symbol: String, range: DashboardRange) async -> [PricePoint]
}

struct MockMarketDataService: MarketDataServiceProtocol {
    // Returns realistic static data
}
```

Injected via `MainAppView` init — swap to real implementation later without touching ViewModels.

## Section 3: CSV Import

**Three-stage pipeline:**

```
CSV file
  │
  ▼
1. BrokerFormatDetector
   ├── IBKR Activity Statement  → IBKRTradeMapper
   ├── TD Ameritrade / Schwab   → TDTradeMapper
   ├── Binance Trade History    → BinanceTradeMapper
   └── Unknown                 → ColumnMappingSheet (UI)
  │
  ▼
2. TradeMapper
   Raw CSV row → Trade model
   - Date format normalisation
   - Number cleaning (commas, currency symbols)
   - Missing columns → nil (most Trade fields are optional)
  │
  ▼
3. ImportPreviewSheet
   "Importing N trades — preview of first 5"
   User confirms → TradingDataService.importTrades()
   Failed rows   → error list shown to user
```

**ColumnMappingSheet (unknown format fallback):**
- Left column: CSV header name + first 3 row values as preview
- Right column: dropdown mapping to Trade field
- Required fields (symbol, direction, entryPrice, entryTime) marked red
- Proceeds to ImportPreviewSheet on confirm

**Supported broker formats:**
- IBKR Activity Statement
- TD Ameritrade / Schwab
- Binance Trade History
- Generic (any CSV with symbol + price + date columns)

## Section 4: Journal Image Attachments

**New SwiftData model:**
```swift
@Model class JournalAttachment {
    var id: UUID
    var tradeId: UUID
    var imageData: Data        // compressed JPEG
    var thumbnailData: Data    // 120px thumbnail for list preview
    var originalFileName: String
    var createdAt: Date
}
```

**ImageCompressionService:**
```swift
struct ImageCompressionService {
    static let maxDimension: CGFloat = 1920   // max edge length
    static let jpegQuality: CGFloat   = 0.75
    static let thumbnailSize: CGFloat = 120

    func compress(_ image: NSImage) throws -> (imageData: Data, thumbnailData: Data)
}
```

**Flow:**
1. User drags or selects image in DetailPanel
2. `ImageCompressionService.compress()` → resize → JPEG encode → thumbnail
3. `JournalAttachment` saved to SwiftData
4. DetailPanel shows thumbnail grid → tap for full image

**Expected compression:** Phone screenshot ~3–5 MB → ~200–500 KB after compression.

## Constraints

- Market data stays mock until broker API integration is scoped separately
- `TradingDataService` wraps existing `TradeRepository` — no SwiftData schema changes except adding `JournalAttachment`
- CSV import is additive — no deduplication in v1 (user is responsible for not importing twice)
- Image storage is local SwiftData only — no iCloud sync for binary blobs in v1
