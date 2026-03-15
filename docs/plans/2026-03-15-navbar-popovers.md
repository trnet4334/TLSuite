# Navbar Popovers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the four stub popovers in the title bar (bell, share, settings, avatar) with fully designed SwiftUI views matching the HTML reference designs, with all popovers opening below their icons.

**Architecture:** Each popover is a standalone `public struct` in `FMSYSApp/Sources/FMSYSCore/Shared/Components/`. `SettingsPopover` uses `@AppStorage("isDarkMode")` for its toggle; `MainAppView` reads the same key to apply `.preferredColorScheme`. The three `toolbarIconButton` stubs are replaced with the new views. `AvatarPopover` is rewritten in-place. All `.popover` calls use `arrowEdge: .top` (arrow points up → popover drops below icon).

**Tech Stack:** SwiftUI, macOS 14+, `@AppStorage`, `NSPasteboard` (for Copy Link), design tokens (`Color.fmsPrimary / fmsSurface / fmsBackground / fmsOnSurface / fmsMuted / fmsLoss`).

---

## Files Overview

| File | Action |
|------|--------|
| `Shared/Components/NotificationsPopover.swift` | **Create** |
| `Shared/Components/SettingsPopover.swift` | **Create** |
| `Shared/Components/SharePopover.swift` | **Create** |
| `Shared/Components/AvatarPopover.swift` | **Rewrite** |
| `App/MainAppView.swift` | **Modify** — wire popovers + `preferredColorScheme` |

All paths are relative to `FMSYSApp/Sources/FMSYSCore/`.

---

### Task 1: NotificationsPopover

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Shared/Components/NotificationsPopover.swift`

**Step 1: Create the file**

```swift
// Sources/FMSYSCore/Shared/Components/NotificationsPopover.swift
import SwiftUI

private struct NotificationItem: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let timestamp: String
    let subtitle: String
}

public struct NotificationsPopover: View {
    private let items: [NotificationItem] = [
        .init(systemImage: "chart.line.uptrend.xyaxis",
              title: "BTC target reached",
              timestamp: "2m ago",
              subtitle: "Bitcoin hit your $60k alert level."),
        .init(systemImage: "book",
              title: "New journal entry saved",
              timestamp: "15m ago",
              subtitle: "Your daily reflection has been stored."),
        .init(systemImage: "arrow.clockwise",
              title: "Subscription renewed",
              timestamp: "1h ago",
              subtitle: "Your pro plan was successfully extended."),
        .init(systemImage: "lock.shield",
              title: "Security alert",
              timestamp: "3h ago",
              subtitle: "A new login was detected from macOS."),
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Handle pill
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.fmsPrimary.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header
            HStack {
                Text("Notifications")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button("Mark all read") {}
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.fmsPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Notification rows
            VStack(spacing: 0) {
                ForEach(items) { item in
                    notificationRow(item)
                }
            }

            // Bottom accent strip
            Color.fmsPrimary.opacity(0.05)
                .frame(height: 10)
        }
        .frame(width: 380)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func notificationRow(_ item: NotificationItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(Color.fmsPrimary)
                .frame(width: 48, height: 48)
                .background(Color.fmsPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                        .lineLimit(1)
                    Spacer()
                    Text(item.timestamp)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
```

**Step 2: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```

Expected: `Build complete!`

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Shared/Components/NotificationsPopover.swift
git commit -m "feat: add NotificationsPopover with seed notification items"
```

---

### Task 2: SettingsPopover

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Shared/Components/SettingsPopover.swift`

**Step 1: Create the file**

```swift
// Sources/FMSYSCore/Shared/Components/SettingsPopover.swift
import SwiftUI

public struct SettingsPopover: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("priceAlertsEnabled") private var priceAlertsEnabled = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Handle pill
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.fmsMuted.opacity(0.3))
                .frame(width: 32, height: 4)
                .padding(.top, 10)

            Text("Quick Settings")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(.top, 8)
                .padding(.bottom, 8)

            VStack(spacing: 2) {
                toggleRow(systemImage: "moon.fill", label: "Dark Mode", binding: $isDarkMode)
                toggleRow(systemImage: "bell.fill", label: "Price Alerts", binding: $priceAlertsEnabled)

                Divider()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)

                navigateRow(systemImage: "gearshape.fill", label: "App Preferences")
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 300)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func toggleRow(
        systemImage: String,
        label: String,
        binding: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 34, height: 34)
                .background(Color.fmsMuted.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Color.fmsPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func navigateRow(systemImage: String, label: String) -> some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 34, height: 34)
                    .background(Color.fmsMuted.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
```

**Step 2: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```

Expected: `Build complete!`

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Shared/Components/SettingsPopover.swift
git commit -m "feat: add SettingsPopover with dark mode and price alerts toggles"
```

---

### Task 3: SharePopover

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Shared/Components/SharePopover.swift`

**Step 1: Create the file**

```swift
// Sources/FMSYSCore/Shared/Components/SharePopover.swift
import SwiftUI
import AppKit

public struct SharePopover: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Handle pill
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.fmsMuted.opacity(0.2))
                .frame(width: 32, height: 4)
                .padding(.top, 10)

            Text("Share Options")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(.top, 6)
                .padding(.bottom, 8)

            VStack(spacing: 2) {
                shareRow(systemImage: "link", label: "Copy Link") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("https://fmsys.pro/journal", forType: .string)
                }
                shareRow(systemImage: "envelope", label: "Email Journal") {}
                shareRow(systemImage: "doc.richtext", label: "Export as PDF") {}

                Divider()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)

                shareRow(systemImage: "square.and.arrow.up", label: "Share to Twitter/X") {}
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
        .frame(width: 280)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func shareRow(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.fmsPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
```

**Step 2: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```

Expected: `Build complete!`

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Shared/Components/SharePopover.swift
git commit -m "feat: add SharePopover with copy link and share action rows"
```

---

### Task 4: Rewrite AvatarPopover

**Files:**
- Rewrite: `FMSYSApp/Sources/FMSYSCore/Shared/Components/AvatarPopover.swift`

**Step 1: Read the current file first, then rewrite**

```swift
// Sources/FMSYSCore/Shared/Components/AvatarPopover.swift
import SwiftUI

public struct AvatarPopover: View {
    public let displayName: String
    public let email: String
    public let role: String
    public let onSignOut: () -> Void

    public init(
        displayName: String,
        email: String,
        role: String,
        onSignOut: @escaping () -> Void
    ) {
        self.displayName = displayName
        self.email = email
        self.role = role
        self.onSignOut = onSignOut
    }

    public var body: some View {
        VStack(spacing: 0) {
            // User info header
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.fmsPrimary.opacity(0.4), Color.fmsPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.fmsBackground)
                        }
                    Circle()
                        .fill(Color.fmsPrimary)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.fmsSurface, lineWidth: 2))
                }

                VStack(spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text(email)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                    Text(role.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.fmsPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.fmsPrimary.opacity(0.15), in: Capsule())
                }
            }
            .padding(.vertical, 16)

            Divider()

            // Menu items
            VStack(spacing: 0) {
                menuRow(systemImage: "person", label: "Account Management") {}
                menuRow(systemImage: "creditcard", label: "Subscription Management") {}
                menuRow(systemImage: "lock.shield", label: "Security & Privacy") {}
                menuRow(systemImage: "person.3", label: "Referral Program") {}
            }
            .padding(.vertical, 4)

            Divider()

            // Sign out
            Button(action: onSignOut) {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.fmsLoss)
                    Text("Sign Out")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.fmsLoss)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(4)
        }
        .frame(width: 280)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func menuRow(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
```

**Step 2: Build**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
```

Expected: `Build complete!`

**Step 3: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/Shared/Components/AvatarPopover.swift
git commit -m "feat: rewrite AvatarPopover with avatar gradient, online dot, and menu rows"
```

---

### Task 5: Wire popovers into MainAppView + preferredColorScheme + delete HTML files

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/App/MainAppView.swift`
- Delete: `notifications_popover.html`, `settings_popover.html`, `share_popover.html`, `user_profile_popover.html`

**Step 1: Add `@AppStorage("isDarkMode")` and apply `preferredColorScheme`**

In `MainAppView`, add this stored property after the existing `@State` declarations:

```swift
@AppStorage("isDarkMode") private var isDarkMode = true
```

Then update `body` to apply `preferredColorScheme`:

```swift
public var body: some View {
    if appState.isAuthenticated {
        appShell
            .preferredColorScheme(isDarkMode ? .dark : .light)
    } else {
        authFlow
    }
}
```

**Step 2: Replace the three stub `toolbarIconButton` closures**

Replace the entire `HStack(spacing: 4)` right controls block in `titleBar`:

```swift
// Right controls
HStack(spacing: 4) {
    toolbarIconButton(systemName: "bell", isPresented: $showNotificationsPopover) {
        NotificationsPopover()
    }
    toolbarIconButton(systemName: "square.and.arrow.up", isPresented: $showSharePopover) {
        SharePopover()
    }
    toolbarIconButton(systemName: "gearshape", isPresented: $showSettingsPopover) {
        SettingsPopover()
    }

    // Avatar
    Button {
        showAvatarPopover.toggle()
    } label: {
        Circle()
            .fill(Color.fmsMuted.opacity(0.3))
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fmsMuted)
            }
    }
    .buttonStyle(.plain)
    .popover(isPresented: $showAvatarPopover, arrowEdge: .top) {
        AvatarPopover(
            displayName: appState.userDisplayName,
            email: appState.userEmail,
            role: appState.userRole,
            onSignOut: {
                showAvatarPopover = false
                appState.markLoggedOut()
            }
        )
    }
    .padding(.leading, 4)
}
.padding(.trailing, 12)
```

**Step 3: Build + run tests**

```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp && swift build 2>&1 | tail -3
swift test 2>&1 | tail -3
```

Expected: `Build complete!` and `193 tests passed`.

**Step 4: Delete HTML reference files**

```bash
cd /Users/stevy/Documents/Git/TLSuite
rm notifications_popover.html settings_popover.html share_popover.html user_profile_popover.html
```

**Step 5: Commit**

```bash
cd /Users/stevy/Documents/Git/TLSuite
git add FMSYSApp/Sources/FMSYSCore/App/MainAppView.swift
git commit -m "feat: wire NotificationsPopover, SharePopover, SettingsPopover into title bar + preferredColorScheme"
git commit --allow-empty -m "chore: remove navbar popover HTML reference files"
```

Note: The HTML files are untracked so the second commit may be empty — that's fine. Use a single combined commit if preferred:

```bash
git add FMSYSApp/Sources/FMSYSCore/App/MainAppView.swift
git commit -m "feat: wire navbar popovers and remove HTML reference files"
```

---

## Quick Reference

### Design tokens used
| Token | Value |
|-------|-------|
| `Color.fmsPrimary` | #13ec80 |
| `Color.fmsLoss` | #ff5f57 |
| `Color.fmsSurface` | card backgrounds |
| `Color.fmsBackground` | window / deep background |
| `Color.fmsOnSurface` | primary text |
| `Color.fmsMuted` | secondary text / icons |

### Popover widths
| Popover | Width |
|---------|-------|
| NotificationsPopover | 380px |
| SettingsPopover | 300px |
| SharePopover | 280px |
| AvatarPopover | 280px |

### Arrow edge
All popovers: `arrowEdge: .top` → arrow points up → popover opens **below** the icon.

### Build + test
```bash
cd /Users/stevy/Documents/Git/TLSuite/FMSYSApp
swift build   # compile check
swift test    # all 193 tests must pass
```
