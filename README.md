# FMSYS Trading Suite Pro

A macOS-native trading journal and strategy management app built with SwiftUI.

**Platform:** macOS 14+ (Sonoma) · **Language:** Swift 5.9+ · **UI:** SwiftUI · **Storage:** SwiftData

---

## Features

| Module | Status |
|---|---|
| Auth (Email/Password + MFA + OAuth) | ✅ Complete |
| Trading Journal (4 categories) | ✅ Complete |
| Backtesting | ✅ Complete |
| Strategy Lab | 🔲 Stub |
| Portfolio | 🔲 Stub |
| Dashboard | 🔲 Stub |

### Journal Categories
- **Stocks/ETFs** — direction badge, shares, P&L, entry/exit price & time
- **Crypto** — leverage, funding rate, wallet address (copy button)
- **Forex** — pip value, lot size, exposure, session notes
- **Options** — strike price, expiration, cost basis, Greeks (Δ Γ Θ V)

---

## Architecture

```
FMSYSApp (executable)  →  imports FMSYSCore
FMSYSCore (library)    →  all business logic, views, services
FMSYSAppTests          →  tests against FMSYSCore
```

**Layer stack:** Views → ViewModels (`@Observable`) → Repositories → SwiftData

**Offline-First:** writes go to SwiftData immediately (`pendingSync = true`), synced to REST API in the background.

---

## Project Structure

```
FMSYSApp/
├── Sources/
│   ├── FMSYSApp/
│   │   └── FMSYSApp.swift              # @main entry point
│   └── FMSYSCore/
│       ├── App/
│       │   ├── AppState.swift
│       │   ├── AppScreen.swift
│       │   ├── MainAppView.swift
│       │   ├── SidebarView.swift
│       │   └── Router.swift
│       ├── Core/
│       │   ├── Models/
│       │   │   ├── Trade.swift
│       │   │   ├── JournalCategory.swift
│       │   │   └── ...
│       │   ├── Networking/
│       │   │   ├── APIClient.swift
│       │   │   ├── AuthInterceptor.swift
│       │   │   └── DTOs/
│       │   ├── Repositories/
│       │   │   ├── TradeRepository.swift
│       │   │   └── AuthRepository.swift
│       │   └── Services/
│       │       └── AuthService.swift
│       ├── Features/
│       │   ├── Auth/Views/
│       │   │   ├── LoginView.swift
│       │   │   └── MFAVerificationView.swift
│       │   ├── Journal/Views/
│       │   │   ├── JournalDetailView.swift
│       │   │   ├── TradeListPanel.swift
│       │   │   ├── Stocks/
│       │   │   ├── Crypto/
│       │   │   ├── Forex/
│       │   │   └── Options/
│       │   └── Backtesting/Views/
│       └── Shared/
│           ├── Components/
│           ├── Theme/          # Colors, Typography, Spacing
│           └── Utilities/      # KeychainManager, Validators
└── Tests/
    └── FMSYSAppTests/          # 141 tests, Swift Testing framework
```

---

## Getting Started

**Requirements:** macOS 14+, Xcode 15+, Swift 5.9+

```bash
# Clone
git clone <repo-url>
cd TLSuite/FMSYSApp

# Build
swift build

# Run tests
swift test

# Open in Xcode
open Package.swift
```

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

---

## Auth Flow

```
LoginView → POST /auth/login
         → MFAVerificationView → POST /auth/mfa/verify
         → accessToken + refreshToken stored in Keychain
         → MainAppView
```

Token refresh is handled automatically by `AuthInterceptor` on every API request.
