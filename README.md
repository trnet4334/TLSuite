# FMSYS Trading Suite Pro

A macOS-native trading journal, strategy management, and market intelligence app built with SwiftUI.

**Platform:** macOS 14+ (Sonoma) · **Language:** Swift 5.9+ · **UI:** SwiftUI · **Storage:** SwiftData

---

## Features

| Module | Status |
|---|---|
| Auth (Email/Password + MFA) | ✅ Complete |
| Trading Journal (4 categories) | ✅ Complete |
| CSV Import (multi-broker) | ✅ Complete |
| Backtesting | ✅ Complete |
| Strategy Lab | ✅ Complete |
| Portfolio | ✅ Complete |
| Dashboard | ✅ Complete |
| News Feed + Market Panel | ✅ Complete |
| Notification Center | ✅ Complete |
| Settings (Preferences, Security, Account, Subscription, Referral) | ✅ Complete |
| Localization (English / 繁體中文) | ✅ Complete |

### Journal Categories
- **Stocks/ETFs** — direction badge, shares, P&L, entry/exit price & time
- **Crypto** — leverage, funding rate, wallet address (copy button)
- **Forex** — pip value, lot size, exposure, session notes
- **Options** — strike price, expiration, cost basis, Greeks (Δ Γ Θ V)

### Market Panel (live data, no API key required)
- **Trending Tickers** — SPX, NVDA, BTC, EUR/USD via Yahoo Finance (intraday sparkline + % change)
- **Market Sentiment** — Fear & Greed Index via Alternative.me
- **Economic Calendar** — High/Medium impact events via ForexFactory

---

## Architecture

```
FMSYSApp (executable)  →  imports FMSYSCore
FMSYSCore (library)    →  all business logic, views, services
FMSYSAppTests          →  214 tests, Swift Testing framework
```

**Layer stack:** Views → ViewModels (`@Observable`) → Services / Repositories → SwiftData

**Offline-First:** writes go to SwiftData immediately, synced to REST API in the background via `AuthInterceptor`.

---

## Project Structure

```
FMSYSApp/
├── Sources/
│   ├── FMSYSApp/
│   │   └── FMSYSApp.swift                  # @main entry point
│   └── FMSYSCore/
│       ├── App/
│       │   ├── AppStore.swift              # @Observable app state
│       │   ├── AppScreen.swift             # navigation enum
│       │   ├── MainAppView.swift           # root shell + title bar
│       │   └── SidebarView.swift           # 256px sidebar rail
│       ├── Core/
│       │   ├── Models/                     # Trade, Strategy, BacktestResult, ...
│       │   ├── Networking/                 # APIClient, AuthInterceptor, DTOs
│       │   ├── Repositories/              # TradeRepository, StrategyRepository, ...
│       │   └── Services/
│       │       ├── AuthService.swift
│       │       ├── MarketNewsService.swift  # RSS feeds (Reuters, MarketWatch, ForexLive, CoinTelegraph)
│       │       └── MarketPanelService.swift # Yahoo Finance, Alternative.me, ForexFactory
│       ├── Features/
│       │   ├── Auth/
│       │   ├── Dashboard/
│       │   ├── Journal/
│       │   │   └── Views/CSV/              # ColumnMappingSheet, ImportPreviewSheet
│       │   ├── Backtesting/
│       │   ├── StrategyLab/
│       │   ├── Portfolio/
│       │   ├── NewsFeed/
│       │   └── Settings/
│       └── Shared/
│           ├── Components/
│           │   └── Notifications/          # NotificationCenterView, detail views
│           ├── Theme/                      # Colors, Typography, Spacing
│           └── Utilities/
│               ├── KeychainManager.swift
│               └── LanguageManager.swift   # runtime language switching
└── Tests/
    └── FMSYSAppTests/                      # 214 tests
```

---

## Getting Started

**Requirements:** macOS 14+, Xcode 15+, Swift 5.9+

```bash
git clone <repo-url>
cd TLSuite/FMSYSApp

swift build       # build
swift test        # run 214 tests
open Package.swift  # open in Xcode
```

---

## Localization

Supports **English** and **繁體中文** with runtime switching (no restart required).

- String files: `Sources/FMSYSCore/Resources/{en,zh-Hant}.lproj/Localizable.strings`
- Switch via: Settings → App Preferences → Language
- All views use `@Environment(LanguageManager.self)` + `lang.bundle`

---

## Design Tokens

| Token | Value | Usage |
|---|---|---|
| `fmsPrimary` | `#13ec80` | Brand green, CTA, gains |
| `fmsLoss` | `#ff5f57` | Losses, errors |
| `fmsWarning` | `#ffbd2e` | Warnings |
| `fmsSurface` | `#1C1C1E` | Cards, panels |
| `fmsBackground` | `#111113` | App background |
| `fmsOnSurface` | `#EBEBF0` | Primary text |
| `fmsMuted` | `#8E8E93` | Secondary text, labels |

Font: **Manrope** (weights 300–800)

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘1` | Dashboard |
| `⌘2` | Journal |
| `⌘3` | Backtesting |
| `⌘4` | Strategy Lab |
| `⌘5` | Portfolio |
| `⌘6` | News Feed |

---

## Auth Flow

```
LoginView → POST /auth/login
         → MFAVerificationView → POST /auth/mfa/verify
         → accessToken + refreshToken stored in Keychain
         → MainAppView
```

Token refresh is handled automatically by `AuthInterceptor` on every API request.
