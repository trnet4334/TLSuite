# UI Shell Redesign — Phase 1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current single-column NavigationStack shell with the full NavigationSplitView app shell (sidebar + content), resize the window to 1280×800, redesign Login and MFA screens per spec, and add screen stubs for Backtesting, Strategy Lab, and Portfolio.

**Architecture:** `MainAppView` becomes the shell — `NavigationSplitView` with a fixed 256px `SidebarView` and a detail column that routes to the active screen. Auth flow stays fullscreen (no split view). Screen stubs (`PortfolioView`, `StrategyLabStubView`) are added so navigation compiles. Login and MFA are fully redrawn per the screen map.

**Tech Stack:** SwiftUI `NavigationSplitView`, `@Observable`, existing design tokens (`Color.fms*`), `SwiftData` (already wired), no new SPM dependencies.

---

## Reference: Design Tokens

```
fmsBackground  #111113   (app bg)
fmsSurface     #1C1C1E   (cards, sidebar)
fmsPrimary     #13ec80   (accent, CTA)
fmsLoss        #ff5f57   (negative)
fmsOnSurface   #EBEBF0   (primary text)
fmsMuted       #8E8E93   (secondary text)
```

---

### Task 1: Expand window to 1280×800

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSApp/FMSYSApp.swift`

No TDD — build verification only.

**Step 1: Update defaultSize and frame**

Replace in `body`:
```swift
.defaultSize(width: 1280, height: 800)
```
Replace `.frame(minWidth: 480, minHeight: 640)` with:
```swift
.frame(minWidth: 1000, minHeight: 640)
```

**Step 2: Build**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```
Expected: `Build complete!`

**Step 3: Commit**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSApp/FMSYSApp.swift && git commit -m "feat: expand window to 1280x800"
```

---

### Task 2: `AppScreen` navigation enum

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/App/AppScreen.swift`

No TDD — pure enum.

**Step 1: Create file**

```swift
// Sources/FMSYSCore/App/AppScreen.swift
import Foundation

public enum AppScreen: String, Hashable, CaseIterable {
    case dashboard   = "Dashboard"
    case journal     = "Journal"
    case backtesting = "Backtesting"
    case strategyLab = "Strategy Lab"
    case portfolio   = "Portfolio"
}
```

**Step 2: Build**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```

**Step 3: Commit**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/App/AppScreen.swift && git commit -m "feat: add AppScreen navigation enum"
```

---

### Task 3: `SidebarView`

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/App/SidebarView.swift`

No TDD — pure layout.

**Step 1: Create file**

```swift
// Sources/FMSYSCore/App/SidebarView.swift
import SwiftUI

public struct SidebarView: View {
    @Binding var selection: AppScreen
    @State private var journalExpanded = true

    public init(selection: Binding<AppScreen>) {
        self._selection = selection
    }

    public var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                navItem(.dashboard,   icon: "chart.bar.fill",          label: "Dashboard",     shortcut: "1")
                journalSection
                navItem(.backtesting, icon: "arrow.clockwise.circle",  label: "Backtesting",   shortcut: "3")
                navItem(.strategyLab, icon: "flask.fill",              label: "Strategy Lab",  shortcut: "4")
                navItem(.portfolio,   icon: "dollarsign.circle.fill",  label: "Portfolio",     shortcut: "5")
            }
            .listStyle(.sidebar)
            .frame(maxHeight: .infinity)

            equityCard
        }
        .frame(minWidth: 256, maxWidth: 256)
        .background(Color.fmsSurface)
    }

    // MARK: - Nav item

    private func navItem(_ screen: AppScreen, icon: String, label: String, shortcut: String) -> some View {
        Label(label, systemImage: icon)
            .tag(screen)
            .keyboardShortcut(KeyEquivalent(shortcut.first!), modifiers: .command)
    }

    // MARK: - Journal with sub-items

    private var journalSection: some View {
        DisclosureGroup(isExpanded: $journalExpanded) {
            ForEach(["Stocks", "ETFs", "Forex", "Crypto"], id: \.self) { cat in
                Text(cat)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                    .padding(.leading, 8)
                    .tag(AppScreen.journal)
            }
        } label: {
            Label("Journal", systemImage: "book.fill")
                .tag(AppScreen.journal)
                .keyboardShortcut("2", modifiers: .command)
        }
    }

    // MARK: - Bottom equity card

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

**Step 2: Build**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```

**Step 3: Commit**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/App/SidebarView.swift && git commit -m "feat: add SidebarView with 5 nav items and equity card"
```

---

### Task 4: Screen stubs (Backtesting, Strategy Lab, Portfolio)

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift`
- Create: `FMSYSApp/Sources/FMSYSCore/Features/StrategyLab/Views/StrategyLabView.swift`
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift`

No TDD — stubs only.

**Step 1: Create BacktestingView**

```swift
// Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift
import SwiftUI

public struct BacktestingView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.fmsBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.fmsMuted)
                Text("Backtesting")
                    .font(.title2.bold())
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**Step 2: Create StrategyLabView**

```swift
// Sources/FMSYSCore/Features/StrategyLab/Views/StrategyLabView.swift
import SwiftUI

public struct StrategyLabView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.fmsBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "flask.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.fmsMuted)
                Text("Strategy Lab")
                    .font(.title2.bold())
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**Step 3: Create PortfolioView**

```swift
// Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift
import SwiftUI

public struct PortfolioView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.fmsBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.fmsMuted)
                Text("Portfolio")
                    .font(.title2.bold())
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**Step 4: Build**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```

**Step 5: Commit**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift Sources/FMSYSCore/Features/StrategyLab/Views/StrategyLabView.swift Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift && git commit -m "feat: add screen stubs for Backtesting, StrategyLab, Portfolio"
```

---

### Task 5: `StatusBar`

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Shared/Components/StatusBar.swift`

```swift
// Sources/FMSYSCore/Shared/Components/StatusBar.swift
import SwiftUI

public struct StatusBar: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            statusDot(color: .fmsPrimary, label: "Engine: Ready")
            divider
            Text("Latency: 4ms")
                .foregroundStyle(Color.fmsMuted)
            Spacer()
            Text("Core Version: 2.1.0")
                .foregroundStyle(Color.fmsMuted)
            divider
            Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString.components(separatedBy: " ").first ?? "14")")
                .foregroundStyle(Color.fmsMuted)
        }
        .font(.system(size: 11, weight: .medium).monospacedDigit())
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(Color.fmsSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.fmsMuted.opacity(0.3))
        }
    }

    private var divider: some View {
        Rectangle()
            .frame(width: 0.5, height: 12)
            .foregroundStyle(Color.fmsMuted.opacity(0.4))
    }

    private func statusDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(Color.fmsOnSurface)
        }
    }
}
```

**Build + Commit:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
git add Sources/FMSYSCore/Shared/Components/StatusBar.swift && git commit -m "feat: add StatusBar component"
```

---

### Task 6: Rewrite `MainAppView` with `NavigationSplitView`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/App/MainAppView.swift`

Replace the entire file:

```swift
// Sources/FMSYSCore/App/MainAppView.swift
import SwiftUI
import SwiftData

public struct MainAppView: View {
    @State private var appState: AppState
    @State private var authViewModel: AuthViewModel
    @State private var selectedScreen: AppScreen = .dashboard

    private let authService: any AuthServiceProtocol
    private let modelContainer: ModelContainer

    public init(
        appState: AppState,
        authService: any AuthServiceProtocol,
        modelContainer: ModelContainer
    ) {
        self._appState = State(wrappedValue: appState)
        self._authViewModel = State(wrappedValue: AuthViewModel(authService: authService))
        self.authService = authService
        self.modelContainer = modelContainer
    }

    public var body: some View {
        if appState.isAuthenticated {
            appShell
        } else {
            authFlow
        }
    }

    // MARK: - Authenticated shell

    private var appShell: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                SidebarView(selection: $selectedScreen)
            } detail: {
                screenContent
            }
            StatusBar()
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch selectedScreen {
        case .dashboard:
            DashboardView(trades: loadTrades())
        case .journal:
            TradeListView(
                viewModel: TradeViewModel(
                    repository: TradeRepository(context: modelContainer.mainContext),
                    userId: "current-user"
                )
            )
        case .backtesting:
            BacktestingView()
        case .strategyLab:
            StrategyLabView()
        case .portfolio:
            PortfolioView()
        }
    }

    private func loadTrades() -> [Trade] {
        let repo = TradeRepository(context: modelContainer.mainContext)
        return (try? repo.findAll(userId: "current-user")) ?? []
    }

    // MARK: - Auth flow

    @ViewBuilder
    private var authFlow: some View {
        LoginView(
            viewModel: authViewModel,
            onAuthenticated: { appState.markAuthenticated() },
            onMFARequired: { _, _ in }
        )
        .navigationDestination(
            isPresented: Binding(
                get: {
                    if case .mfaRequired = authViewModel.state { return true }
                    return false
                },
                set: { if !$0 { authViewModel.state = .idle } }
            )
        ) {
            if case .mfaRequired(let token, let userId) = authViewModel.state {
                MFAVerificationView(
                    viewModel: MFAViewModel(
                        authService: authService,
                        sessionToken: token,
                        userId: userId
                    ),
                    onAuthenticated: { appState.markAuthenticated() }
                )
            }
        }
    }
}
```

**Build:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
```
Expected: `Build complete!` — fix any compile errors before committing.

**Run full tests:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test 2>&1 | tail -5
```
Expected: all pass (131).

**Commit:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/App/MainAppView.swift && git commit -m "feat: replace NavigationStack with NavigationSplitView shell"
```

---

### Task 7: Redesign `LoginView`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Auth/Views/LoginView.swift`

Replace the entire file per spec: gradient background, OAuth buttons, OR divider, email/password form with icons, Forgot link, Create account link, footer.

```swift
// Sources/FMSYSCore/Features/Auth/Views/LoginView.swift
import SwiftUI

public struct LoginView: View {
    @State private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    let onAuthenticated: () -> Void
    let onMFARequired: (String, String) -> Void

    public init(
        viewModel: AuthViewModel,
        onAuthenticated: @escaping () -> Void,
        onMFARequired: @escaping (String, String) -> Void
    ) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onAuthenticated = onAuthenticated
        self.onMFARequired = onMFARequired
    }

    public var body: some View {
        ZStack {
            // Gradient background
            Color.fmsBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            RadialGradient(
                colors: [Color.fmsPrimary.opacity(0.07), Color.clear],
                center: .init(x: 0.5, y: 0.05),
                startRadius: 0,
                endRadius: 500
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Card
            VStack(spacing: 0) {
                card
            }
            .frame(width: 400)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.4), radius: 40, y: 20)

            // Toast
            if let msg = viewModel.errorMessage {
                VStack {
                    Spacer()
                    ToastOverlay(message: msg, style: .error)
                        .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.errorMessage)
        .onChange(of: viewModel.state) { _, state in
            switch state {
            case .authenticated:        onAuthenticated()
            case .mfaRequired(let t, let u): onMFARequired(t, u)
            case .idle: break
            }
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 24) {
            cardHeader
            oauthButtons
            divider
            formSection
            footerLinks
        }
        .padding(32)
    }

    private var cardHeader: some View {
        VStack(spacing: 6) {
            Text("TRADING SUITE PRO")
                .font(.system(size: 10, weight: .bold))
                .kerning(2)
                .foregroundStyle(Color.fmsMuted)

            Text("FMSYS")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(Color.fmsOnSurface)

            Text("Secure Login for Trading Suite Pro")
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var oauthButtons: some View {
        VStack(spacing: 10) {
            // Google
            Button {
                // OAuth — coming soon
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                    Text("Continue with Google")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .foregroundStyle(Color.black)
            }
            .buttonStyle(.plain)

            // Apple Passkey
            Button {
                // Passkey — coming soon
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Continue with Apple Passkey")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "#1c1c1e"), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().frame(height: 0.5).foregroundStyle(Color.fmsMuted.opacity(0.4))
            Text("OR").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.fmsMuted)
            Rectangle().frame(height: 0.5).foregroundStyle(Color.fmsMuted.opacity(0.4))
        }
    }

    private var formSection: some View {
        VStack(spacing: 12) {
            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("USERNAME / EMAIL")
                    .font(.system(size: 11, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(Color.fmsMuted)
                HStack(spacing: 8) {
                    Image(systemName: "at")
                        .foregroundStyle(Color.fmsMuted)
                        .frame(width: 16)
                    TextField("name@company.com", text: $email)
                        .foregroundStyle(Color.fmsOnSurface)
                }
                .padding(12)
                .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fmsMuted.opacity(0.2), lineWidth: 1))
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("PASSWORD")
                        .font(.system(size: 11, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    Button("Forgot?") {}
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsPrimary)
                        .buttonStyle(.plain)
                }
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.fmsMuted)
                        .frame(width: 16)
                    SecureField("••••••••", text: $password)
                        .foregroundStyle(Color.fmsOnSurface)
                }
                .padding(12)
                .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fmsMuted.opacity(0.2), lineWidth: 1))
            }

            // Sign In button
            Button {
                Task { await viewModel.login(email: email, password: password) }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(Color.fmsBackground)
                    } else {
                        Text("SIGN IN")
                            .font(.system(size: 14, weight: .bold))
                            .kerning(1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Color.fmsBackground)
                .shadow(color: Color.fmsPrimary.opacity(0.3), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 4)
        }
    }

    private var footerLinks: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundStyle(Color.fmsMuted)
                Button("Create an account") {}
                    .foregroundStyle(Color.fmsPrimary)
                    .buttonStyle(.plain)
            }
            .font(.system(size: 13))

            HStack(spacing: 16) {
                Button("Privacy Policy") {}.buttonStyle(.plain)
                Button("Terms") {}.buttonStyle(.plain)
                Button("Contact Support") {}.buttonStyle(.plain)
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.fmsMuted)
        }
    }
}
```

**Build:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
```

**Commit:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Auth/Views/LoginView.swift && git commit -m "feat: redesign LoginView per screen map (gradient, OAuth, new form)"
```

---

### Task 8: Redesign `MFAVerificationView`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Auth/Views/MFAVerificationView.swift`

Replace entire file:

```swift
// Sources/FMSYSCore/Features/Auth/Views/MFAVerificationView.swift
import SwiftUI

public struct MFAVerificationView: View {
    @State private var viewModel: MFAViewModel
    @State private var code = ""

    let onAuthenticated: () -> Void

    public init(
        viewModel: MFAViewModel,
        onAuthenticated: @escaping () -> Void
    ) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onAuthenticated = onAuthenticated
    }

    public var body: some View {
        ZStack {
            Color.fmsBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                // Window chrome row
                HStack {
                    // Traffic light placeholders
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "#ff5f57")).frame(width: 12, height: 12)
                        Circle().fill(Color(hex: "#ffbd2e")).frame(width: 12, height: 12)
                        Circle().fill(Color(hex: "#28c840")).frame(width: 12, height: 12)
                    }
                    Spacer()
                    Text("FMSYS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    // Balance the traffic lights
                    HStack(spacing: 6) {
                        Circle().fill(Color.clear).frame(width: 12, height: 12)
                        Circle().fill(Color.clear).frame(width: 12, height: 12)
                        Circle().fill(Color.clear).frame(width: 12, height: 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.fmsSurface.opacity(0.6))
                .overlay(alignment: .bottom) {
                    Rectangle().frame(height: 0.5).foregroundStyle(Color.fmsMuted.opacity(0.2))
                }

                // Content
                VStack(spacing: 28) {
                    // Shield icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.fmsPrimary.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.fmsPrimary)
                    }
                    .padding(.top, 32)

                    // Title
                    VStack(spacing: 8) {
                        Text("Verify Identity")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color.fmsOnSurface)
                        Text("Enter the 6-digit code from\nyour authenticator app")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.fmsMuted)
                            .multilineTextAlignment(.center)
                    }

                    // OTP inputs
                    OTPFieldView(code: $code) { completed in
                        Task { await viewModel.verify(code: completed) }
                    }

                    // Locked state or Verify button
                    if viewModel.isLocked {
                        Label("Account locked. Too many attempts.", systemImage: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.fmsLoss)
                    } else {
                        VStack(spacing: 16) {
                            Button {
                                Task { await viewModel.verify(code: code) }
                            } label: {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView().tint(Color.fmsBackground)
                                    } else {
                                        Text("Verify Identity")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Color.fmsBackground)
                                .shadow(color: Color.fmsPrimary.opacity(0.3), radius: 12, y: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoading || code.count < 6)

                            Button("Resend code") {}
                                .font(.system(size: 13))
                                .foregroundStyle(Color.fmsPrimary)
                                .buttonStyle(.plain)
                        }
                    }

                    // Method pill
                    HStack(spacing: 8) {
                        Image(systemName: "iphone")
                            .font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Method").font(.system(size: 10)).foregroundStyle(Color.fmsMuted)
                            Text("Google Authenticator").font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Color.fmsOnSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.15), in: Capsule())
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 40)
            }

            // Error toast
            if let msg = viewModel.errorMessage, !viewModel.isLocked {
                VStack {
                    Spacer()
                    ToastOverlay(message: msg, style: .error)
                        .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.errorMessage)
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated { onAuthenticated() }
        }
    }
}
```

**Build + test:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -5
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift test 2>&1 | tail -5
```
Expected: build clean, 131 tests pass.

**Commit:**
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && git add Sources/FMSYSCore/Features/Auth/Views/MFAVerificationView.swift && git commit -m "feat: redesign MFAVerificationView per screen map"
```

---

## Done

Phase 1 complete when:
- [ ] Window opens at 1280×800
- [ ] Sidebar shows 5 nav items with ⌘1–⌘5 shortcuts
- [ ] Dashboard, Journal, Backtesting, Strategy Lab, Portfolio all navigable
- [ ] Status bar visible at bottom
- [ ] Login screen shows gradient, OAuth buttons, new form layout
- [ ] MFA screen shows traffic lights, shield icon, method pill
- [ ] All 131 tests still pass
