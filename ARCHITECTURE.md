# FMSYS Trading Suite Pro — Software Architecture Plan

**Platform:** macOS 14+ (Sonoma) · **Language:** Swift 5.9+ · **Version:** 1.0

---

## 1. 整體架構概述

FMSYS 採用 **Clean Architecture + MVVM + Service Layer** 分層架構，搭配 **Offline-First** 資料策略。整個專案以 Swift Package Manager 管理，分為三個 target：

```
FMSYSApp (executable)  →  imports FMSYSCore
FMSYSCore (library)    →  全部業務邏輯與 UI
FMSYSAppTests (tests)  →  測試 FMSYSCore
```

### 分層職責

```
Views  ↔  ViewModels (@Observable)  ↔  Services  ↔  Repositories
                                                        ↓              ↓
                                                   SwiftData       REST API
                                                   (Local)         (Remote)
```

| 層級 | 職責 | 依賴方向 |
|------|------|----------|
| **View** | SwiftUI 宣告式 UI，零業務邏輯 | → ViewModel |
| **ViewModel** | UI 狀態管理、Service 呼叫、@Observable | → Service |
| **Service** | 業務邏輯、驗證規則、Repository 協調 | → Repository |
| **Repository** | 資料存取統一介面，決定 Local/Remote | → SwiftData / APIClient |
| **Core/Networking** | URLSession + async/await，Token 自動刷新 | → 外部 API |

---

## 2. 專案結構

```
FMSYSApp/
├── Sources/
│   ├── FMSYSApp/
│   │   └── FMSYSApp.swift              # @main, WindowGroup + Settings scene
│   └── FMSYSCore/
│       ├── App/
│       │   ├── AppState.swift           # @Observable 全域狀態，AppScreen enum
│       │   └── Router.swift             # RootView，screen 切換邏輯
│       ├── Features/
│       │   ├── Auth/
│       │   │   ├── Views/
│       │   │   │   ├── LoginView.swift
│       │   │   │   └── MFAVerificationView.swift
│       │   │   ├── AuthViewModel.swift
│       │   │   └── OAuthService.swift   # ASWebAuthenticationSession + PKCE
│       │   ├── Dashboard/
│       │   │   ├── Views/
│       │   │   │   ├── DashboardView.swift
│       │   │   │   ├── EquityCurveChart.swift  # Swift Charts
│       │   │   │   └── MarketOverviewCard.swift
│       │   │   └── DashboardViewModel.swift
│       │   ├── Journal/
│       │   │   ├── Views/
│       │   │   │   ├── JournalListView.swift
│       │   │   │   ├── JournalDetailView.swift
│       │   │   │   └── TradeRowView.swift
│       │   │   └── JournalViewModel.swift
│       │   ├── Backtesting/
│       │   │   ├── Views/
│       │   │   │   ├── BacktestView.swift
│       │   │   │   └── BacktestResultCard.swift
│       │   │   └── BacktestViewModel.swift
│       │   ├── StrategyLab/
│       │   │   ├── Views/
│       │   │   │   ├── StrategyListView.swift
│       │   │   │   ├── StrategyCardView.swift
│       │   │   │   ├── InspectorPanel.swift
│       │   │   │   └── CodeEditorView.swift
│       │   │   └── StrategyViewModel.swift
│       │   ├── Portfolio/
│       │   │   ├── Views/
│       │   │   │   ├── PortfolioView.swift
│       │   │   │   └── PositionTableView.swift
│       │   │   └── PortfolioViewModel.swift
│       │   └── Settings/
│       │       ├── Views/
│       │       │   ├── SettingsView.swift
│       │       │   ├── GeneralTab.swift
│       │       │   └── APIKeysTab.swift
│       │       └── SettingsViewModel.swift
│       ├── Core/
│       │   ├── Models/
│       │   │   ├── User.swift
│       │   │   ├── Trade.swift
│       │   │   ├── Strategy.swift
│       │   │   ├── BacktestResult.swift
│       │   │   ├── Portfolio.swift
│       │   │   └── Position.swift
│       │   ├── Services/
│       │   │   ├── AuthService.swift       # Login, MFA, OAuth, Token refresh
│       │   │   ├── TradeService.swift
│       │   │   ├── StrategyService.swift
│       │   │   ├── BacktestService.swift
│       │   │   ├── PortfolioService.swift
│       │   │   └── MarketDataService.swift # REST polling (15s interval)
│       │   ├── Repositories/
│       │   │   ├── TradeRepository.swift
│       │   │   ├── StrategyRepository.swift
│       │   │   └── PortfolioRepository.swift
│       │   └── Networking/
│       │       ├── APIClient.swift         # URLSession + async/await
│       │       ├── Endpoints.swift         # API endpoint definitions
│       │       ├── AuthInterceptor.swift   # 自動 token refresh
│       │       └── DTOs/
│       │           ├── AuthDTOs.swift
│       │           ├── TradeDTOs.swift
│       │           └── StrategyDTOs.swift
│       └── Shared/
│           ├── Components/
│           │   ├── OTPFieldView.swift      # 6-digit MFA input
│           │   ├── SidebarView.swift
│           │   ├── StatusBarView.swift
│           │   ├── KPICard.swift
│           │   ├── ToastOverlay.swift      # success/error/warning/info
│           │   ├── EmptyStateView.swift
│           │   └── SkeletonView.swift
│           ├── Theme/
│           │   ├── Colors.swift            # Design token 色彩系統
│           │   ├── Typography.swift        # Manrope font helper
│           │   └── Spacing.swift
│           └── Utilities/
│               ├── KeychainManager.swift   # JWT + API key 安全儲存
│               ├── DateFormatters.swift
│               └── Validators.swift
└── Tests/
    └── FMSYSAppTests/
        ├── AuthServiceTests.swift
        ├── TradeServiceTests.swift
        └── RepositoryTests.swift
```

---

## 3. 資料模型

所有 ID 使用 UUID，時間戳記統一 ISO 8601 UTC。

### 3.1 SwiftData 本機模型

```swift
// @Model 標記供 SwiftData 持久化
@Model class Trade {
    var id: UUID
    var userId: UUID
    var strategyId: UUID?
    var asset: String                    // e.g. "BTC/USDT"
    var assetCategory: AssetCategory
    var direction: Direction             // .long / .short
    var entryPrice: Decimal
    var exitPrice: Decimal?
    var entryAt: Date
    var exitAt: Date?
    var size: Decimal
    var pnlAmount: Decimal?
    var pnlPercent: Decimal?
    var emotionTag: EmotionTag?
    var notes: String?
    var screenshotURLs: [String]
    var pendingSync: Bool                // Offline-first flag
    var createdAt: Date
    var updatedAt: Date
}

@Model class Strategy {
    var id: UUID
    var userId: UUID
    var name: String
    var indicatorTag: String
    var status: StrategyStatus
    var logicCode: String
    var parameters: Data                 // JSON encoded
    var winRate: Decimal?
    var profitFactor: Decimal?
    var riskMgmtEnabled: Bool
    var trailingStopEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
}

@Model class BacktestResult {
    var id: UUID
    var strategyId: UUID
    var assetPair: String
    var timeframe: Timeframe
    var startDate: Date
    var endDate: Date
    var totalTrades: Int
    var winRate: Decimal
    var profitFactor: Decimal
    var maxDrawdown: Decimal
    var sharpeRatio: Decimal
    var equityCurveData: Data            // JSON [{ date, value }]
    var tradeLog: Data                   // JSON []
    var createdAt: Date
}
```

### 3.2 Enum 定義

```swift
enum UserRole: String, Codable { case owner, admin, trader, viewer }
enum AssetCategory: String, Codable { case crypto, stock, etf, forex, commodity }
enum Direction: String, Codable { case long, short }
enum EmotionTag: String, Codable { case confident, fearful, greedy, neutral, revenge, fomo }
enum StrategyStatus: String, Codable { case active, paused, drafting, archived }
enum Timeframe: String, Codable { case m1="1m", m5="5m", m15="15m", h1="1h", h4="4h", d1="1d", w1="1w" }
enum MfaMethod: String, Codable { case totp, sms, passkey }
enum OAuthProvider: String, Codable { case google, apple }
```

### 3.3 Entity Relationship

```
User ──1:N──► Trade ──N:1──► Strategy
User ──1:N──► Backtest ──N:1──► Strategy
User ──1:1──► Portfolio ──1:N──► Position
```

---

## 4. 認證架構

### 4.1 Auth Flow

```
[LoginView]
    │ email+password → POST /auth/login
    │ Google/Apple   → ASWebAuthenticationSession (PKCE)
    ▼
[AuthService] → 回傳 partialToken (MFA 待驗證)
    ▼
[MFAVerificationView]
    │ TOTP code → POST /auth/mfa/verify
    ▼
[AuthService] → 取得 accessToken + refreshToken
    │           → 存入 Keychain (kSecClassGenericPassword)
    ▼
[AppState.screen = .dashboard]
```

### 4.2 Token 策略

| Token | TTL | 儲存 |
|-------|-----|------|
| Access Token | 15 分鐘 | Keychain (記憶體也存一份) |
| Refresh Token | 7 天 (Remember Me: 30 天) | Keychain |

**AuthInterceptor** 負責：
- 每次 API request 自動附加 `Authorization: Bearer <token>`
- Access Token 過期時自動用 Refresh Token 換新，無縫重試原始 request
- Refresh Token 過期時清除 Keychain，導向 Login

### 4.3 MFA 規則

- 最多 5 次錯誤嘗試 → 鎖定 15 分鐘
- 3 次鎖定 → 需要 Email 驗證解鎖
- 觸發條件：新裝置、30 天未使用、敏感操作（API Key 管理、角色變更、刪帳）

---

## 5. Offline-First 策略

```
讀取：SwiftData(Local) → 立即顯示 → 背景觸發 remote sync
寫入：先寫 SwiftData(pendingSync=true) → UI 立即更新 → async 上傳 → 成功後 pendingSync=false
同步：以 updated_at 時間戳比對差異，增量同步
衝突：Last-Write-Wins，伺服器為權威來源
```

**Repository 模式：**

```swift
protocol TradeRepositoryProtocol {
    func fetchAll(filter: TradeFilter) async throws -> [Trade]
    func fetch(id: UUID) async throws -> Trade?
    func create(_ trade: Trade) async throws -> Trade
    func update(_ trade: Trade) async throws -> Trade
    func delete(id: UUID) async throws
}

// 實作：先寫本機 SwiftData，再 async 同步 Remote
actor TradeRepository: TradeRepositoryProtocol { ... }
```

---

## 6. NavigationSplitView 佈局

```swift
NavigationSplitView {
    // Column 1: Sidebar (256px)
    SidebarView()
        .navigationSplitViewColumnWidth(min: 200, ideal: 256, max: 300)
} content: {
    // Column 2: Main Content (flex)
    ContentRouter(selection: $appState.selectedModule)
} detail: {
    // Column 3: Inspector / Properties (320px, 可選)
    InspectorPanel(selection: $appState.selectedItem)
        .navigationSplitViewColumnWidth(ideal: 320)
}
```

**斷點行為：**

| 視窗寬度 | Sidebar | Inspector |
|----------|---------|-----------|
| ≥ 1280px | 展開 256px | 展開 320px |
| 960–1279px | 展開 256px | Overlay Drawer |
| 720–959px | Icon-only 56px | 隱藏 |
| ≥ 640px | 漢堡選單 | 隱藏 |

---

## 7. REST API 端點

**Base URL:** `https://api.fmsys.app/api/v1`
**Auth:** `Authorization: Bearer <JWT>`

### Authentication

| Method | Endpoint | 說明 | Auth |
|--------|----------|------|------|
| POST | `/auth/login` | Email + Password | — |
| POST | `/auth/oauth/callback` | OAuth PKCE 回調 | — |
| POST | `/auth/mfa/verify` | TOTP 驗證 | Partial Token |
| POST | `/auth/refresh` | Token 刷新 | Refresh Token |
| POST | `/auth/logout` | 登出，撤銷 Token | JWT |

### Trades / Journal

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/trades?page=&limit=&category=&direction=` | 分頁交易列表 |
| POST | `/trades` | 新增交易 |
| PUT | `/trades/:id` | 更新交易 |
| DELETE | `/trades/:id` | 刪除交易 |

### Strategies & Backtesting

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/strategies` | 策略列表 |
| POST | `/strategies` | 建立策略 |
| PUT | `/strategies/:id` | 更新策略 |
| POST | `/strategies/:id/backtest` | 觸發回測 |
| GET | `/strategies/:id/backtest/:btId` | 取得回測結果 |

### Portfolio

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/portfolio` | 投資組合摘要 |
| GET | `/portfolio/positions` | 持倉列表 |
| GET | `/portfolio/performance?range=1M\|3M\|YTD\|ALL` | 績效曲線 |

### Market Data & Settings

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/market/quotes?symbols=BTC,ETH` | 批量延遲行情（15s polling） |
| GET | `/users/me/settings` | 使用者設定 |
| PUT | `/users/me/settings` | 更新設定 |
| GET/POST/DELETE | `/users/me/api-keys` | API Key 管理（需 MFA） |

---

## 8. 權限系統 (RBAC)

| 功能 | Owner | Admin | Trader | Viewer |
|------|-------|-------|--------|--------|
| 新增/編輯/刪除交易 | ✓ | ✓ | ✓ | ✗ |
| 檢視他人交易 | ✓ | ✓ | ✗ | ✗ |
| 執行回測 | ✓ | ✓ | ✓ | ✗ |
| 建立/編輯策略 | ✓ | ✓ | ✓ | ✗ |
| 管理 API Keys | ✓ | ✓ | 僅自己 | ✗ |
| 管理使用者角色 | ✓ | 不可改 Owner | ✗ | ✗ |
| 匯出全部資料 | ✓ | ✓ | ✗ | ✗ |
| 刪除帳戶 | ✓ | ✗ | ✗ | ✗ |

---

## 9. 設計系統 (Design Tokens)

### 色彩

```swift
// Colors.swift
extension Color {
    static let primary    = Color(hex: "#13ec80")  // Brand green
    static let loss       = Color(hex: "#ff5f57")  // Loss / Error
    static let warning    = Color(hex: "#ffbd2e")  // Warning
    static let gain       = Color(hex: "#28c840")  // macOS green
    static let info       = Color(hex: "#58a6ff")  // Info / Link
    static let analytics  = Color(hex: "#bc8cff")  // Analytics purple
    static let strategy   = Color(hex: "#f0883e")  // Strategy orange

    // Light Mode Surfaces
    static let cardLight      = Color.white
    static let backgroundLight = Color(hex: "#f6f6f7")
    static let toolbarLight   = Color(hex: "#f1f1f2")

    // Dark Mode Surfaces
    static let baseDark     = Color(hex: "#1c1c1e")
    static let cardDark     = Color(hex: "#2c2c2e")
    static let bgDark       = Color(hex: "#102219")
}
```

### Typography

```swift
// Typography.swift
extension Font {
    // Page Title: 20-21px / .heavy
    // Section Title: 14-15px / .bold
    // Nav / Button: 13px / .semibold
    // Body: 12-13px / .medium
    // Caption: 10-11px / .bold + uppercase
    static func manrope(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Manrope", size: size).weight(weight)
    }
}
```

### Spacing & Radius

| Token | Value | 使用場景 |
|-------|-------|----------|
| radius-sm | 4px | Badge、小按鈕 |
| radius-md | 8px | 輸入框 |
| radius-lg | 12px | 卡片、面板 |
| radius-xl | 16px | macOS 主視窗 |
| padding-card | 20–24px | 卡片內距 |
| window-shadow | `0 30px 60px rgba(0,0,0,0.12)` | macOS 視窗 |
| sidebar-blur | `blur(40px)` | Sidebar 毛玻璃 |

---

## 10. 頁面清單與對應 ViewModel

| 畫面 | View | ViewModel | 主要 Service |
|------|------|-----------|-------------|
| 登入 | `LoginView` | `AuthViewModel` | `AuthService` |
| MFA 驗證 | `MFAVerificationView` | `AuthViewModel` | `AuthService` |
| Dashboard | `DashboardView` | `DashboardViewModel` | `TradeService`, `MarketDataService` |
| 交易列表 | `JournalListView` | `JournalViewModel` | `TradeService` |
| 交易詳情 | `JournalDetailView` | `JournalViewModel` | `TradeService` |
| 回測 | `BacktestView` | `BacktestViewModel` | `BacktestService` |
| 策略實驗室 | `StrategyListView` | `StrategyViewModel` | `StrategyService` |
| 投資組合 | `PortfolioView` | `PortfolioViewModel` | `PortfolioService` |
| 設定 | `SettingsView` | `SettingsViewModel` | `AuthService` |

---

## 11. 互動規格

### 動畫 Token

| Token | Duration | Easing | 使用場景 |
|-------|----------|--------|----------|
| fast | 100ms | ease-out | Button hover、Toggle |
| base | 200ms | ease-in-out | Nav highlight、Tab switch |
| smooth | 300ms | cubic-bezier(0.4,0,0.2,1) | Chart redraw、Page transition |
| slow | 500ms | ease-in-out | Modal open/close |

### 鍵盤快捷鍵

| 快捷鍵 | 動作 |
|--------|------|
| ⌘K | 全域搜尋 (Command Palette) |
| ⌘N | 新增交易 / 新增策略 |
| ⌘, | 開啟 Settings |
| ⌘1–5 | 切換 Dashboard / Journal / Backtesting / Strategy / Portfolio |
| ⌘S | 儲存（Journal Notes / Strategy Code） |
| ⌘⇧R | 執行回測 |
| ⌘\ | 收合/展開 Sidebar |
| Esc | 關閉 Modal |

---

## 12. UX 狀態設計

### Loading

- **初次載入：** Skeleton Screen（1.5s infinite pulse）
- **資料刷新：** 在現有內容上方覆蓋半透明遮罩 + 旋轉圖示（不清除舊資料）
- **回測執行中：** Progress Bar + 預估時間，CTA 按鈕顯示 "Running..."

### Empty States

- **Journal 無資料：** `edit_note` icon + "Start Your Trading Journal" + "Log First Trade" CTA
- **Strategy Lab 無策略：** `biotech` icon + "Create Your First Strategy" + "New Strategy" CTA

### Toast Notification

```swift
enum ToastStyle { case success, error, warning, info }
// 位置：右上角，距 Title Bar 8px
// 堆疊：最多 3 個，最新在上，間距 8px
// Success/Info: 3s auto-dismiss
// Warning: 5s auto-dismiss
// Error: 需手動關閉
```

### 錯誤處理

| 錯誤 | UI 回饋 |
|------|---------|
| Login Failed | 輸入框紅框 + shake 動畫 (300ms) + 錯誤訊息 |
| MFA Expired | 清空 OTP + Warning Toast + Resend 脈衝高亮 |
| MFA Invalid | Shake + "N attempts remaining" 遞減提示 |
| Network Error | 頂部持續性紅色 Banner + 自動重連 (exponential backoff) |
| Save Failed | 按鈕變紅 + Retry / Save as Draft 選項 |
| Backtest Error | Progress Bar 變紅 + Inspector 顯示錯誤日誌 |

---

## 13. 技術棧

### Client (macOS App)

| 項目 | 選型 |
|------|------|
| Framework | SwiftUI (macOS 14+) |
| 狀態管理 | `@Observable` (Swift 5.9 Observation) |
| 圖表 | Swift Charts framework |
| Navigation | NavigationSplitView (3-column) |
| 本機持久化 | SwiftData |
| 安全儲存 | macOS Keychain |
| OAuth | ASWebAuthenticationSession (PKCE) |
| 網路 | URLSession + async/await |

### Server (Backend)

| 項目 | 選型 |
|------|------|
| Framework | Vapor 4 (Swift) 或 Hummingbird |
| API Style | REST v1，可擴展 GraphQL |
| Auth | JWT + OAuth 2.0 PKCE |
| ORM | Fluent (Vapor) |
| Primary DB | PostgreSQL 16 |
| Cache / Session | Redis |
| 部署 | Docker → Railway / Fly.io |
| 行情 | REST polling (15s)，未來 WebSocket |
| 回測引擎 | Server-side Swift async task |

### macOS 原生整合

- **Menu Bar：** `CommandGroup` 實現 ⌘K / ⌘N 等快捷鍵
- **Settings Scene：** `Settings { }` 整合至 App 選單「偏好設定⋯」
- **Notifications：** `UNUserNotificationCenter`（回測完成、P&L 警示）
- **Spotlight：** Core Spotlight 索引交易紀錄
- **Touch ID：** App 開啟保護（可選）
- **App Sandbox：** 啟用，僅開放 Network outgoing
- **Hardened Runtime：** Notarization 必備
- **Data Protection：** SwiftData SQLite 使用 `completeFileProtection`

---

## 14. 未來擴展 Roadmap

| 階段 | 項目 | 技術方案 |
|------|------|----------|
| Phase 2 | 即時行情 | WebSocket 串流取代 REST polling |
| Phase 2 | iOS / iPadOS App | SwiftUI + 共用 FMSYSCore library |
| Phase 3 | AI 策略建議 | Claude API 整合，分析交易日誌模式 |
| Phase 3 | 多帳戶管理 | User Group + shared Portfolio 功能 |
| Phase 4 | 直接下單整合 | Exchange API write-access + Risk Guard |

---

## 15. 實作優先順序

### Phase 1 — 基礎 (MVP)

1. `Package.swift` + 專案結構
2. Design Tokens (Colors, Typography, Spacing)
3. Shared Components (OTPFieldView, ToastOverlay, KPICard, SkeletonView)
4. Auth Layer (LoginView → MFAView → AppState)
5. NavigationSplitView + SidebarView 框架
6. Dashboard (EquityCurveChart, MarketOverviewCard)
7. KeychainManager + APIClient + AuthInterceptor
8. SwiftData Models (Trade, Strategy, BacktestResult, Portfolio, Position)

### Phase 2 — 核心模組

9. Trading Journal (List + Detail + CRUD)
10. Backtesting (View + BacktestService + polling)
11. Strategy Lab (StrategyCardView + CodeEditorView + InspectorPanel)
12. Portfolio (PositionTable + Donut Chart)

### Phase 3 — 進階功能

13. Settings (GeneralTab + APIKeysTab)
14. Offline sync (pendingSync + background upload)
15. Keyboard shortcuts (⌘K Command Palette)
16. RBAC enforcement (middleware + UI 隱藏)
17. UX States (Empty, Error, Loading, Onboarding)
