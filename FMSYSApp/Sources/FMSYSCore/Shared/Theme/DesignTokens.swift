import SwiftUI

// MARK: - Border radius
public enum FMSRadius {
    /// Window chrome — 16pt
    public static let window: CGFloat = 16
    /// Cards and input fields — 8pt
    public static let card: CGFloat = 8
    /// Buttons — 6pt
    public static let button: CGFloat = 6
}

// MARK: - Shadow
private struct FMSShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            // Dark mode: deeper, wider spread
            content
                .shadow(color: .black.opacity(0.40), radius: 30, x: 0, y: 30)
                .shadow(color: .black.opacity(0.20), radius: 1,  x: 0, y: 0)
        } else {
            // Light mode: standard macOS shadow
            content
                .shadow(color: .black.opacity(0.12), radius: 30, x: 0, y: 30)
                .shadow(color: .black.opacity(0.10), radius: 0.5, x: 0, y: 0)
        }
    }
}

public extension View {
    /// Adaptive window-level shadow (deeper in dark mode per spec)
    func fmsShadow() -> some View {
        modifier(FMSShadowModifier())
    }
}

// MARK: - Primary glow
private struct FMSPrimaryGlowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.shadow(color: Color.fmsPrimary.opacity(0.30), radius: 8, x: 0, y: 0)
        } else {
            content
        }
    }
}

public extension View {
    /// Adds a green glow in dark mode only (spec: drop-shadow 0 0 8px rgba(19,236,128,0.3))
    func fmsPrimaryGlow() -> some View {
        modifier(FMSPrimaryGlowModifier())
    }
}

// MARK: - Border stroke modifier
public extension View {
    /// Adaptive 1px stroke matching design spec
    func fmsBorderOverlay(cornerRadius: CGFloat = FMSRadius.card) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.fmsBorder, lineWidth: 1)
        )
    }
}
