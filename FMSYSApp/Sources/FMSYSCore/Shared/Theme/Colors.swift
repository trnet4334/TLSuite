import SwiftUI
import AppKit

// MARK: - Adaptive color helper
private extension Color {
    init(light: Color, dark: Color) {
        self.init(NSColor(name: nil, dynamicProvider: { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua: return NSColor(dark)
            default:        return NSColor(light)
            }
        }))
    }
}

// MARK: - Design tokens
public extension Color {

    // MARK: Brand (non-adaptive)
    static let fmsPrimary      = Color(hex: "#13ec80")
    static let fmsSecondary    = Color(hex: "#3b82f6")
    static let fmsAccentOrange = Color(hex: "#f59e0b")
    static let fmsAccentPurple = Color(hex: "#8b5cf6")
    static let fmsWarning      = Color(hex: "#ffbd2e")

    // MARK: Status (adaptive)
    /// Loss / warning red — #ff5f57 light, #ef4444 dark
    static let fmsLoss = Color(
        light: Color(hex: "#ff5f57"),
        dark:  Color(hex: "#ef4444")
    )

    // MARK: Backgrounds
    /// Main window background — #ffffff light, #1c1c1e dark
    static let fmsBackground = Color(
        light: Color(hex: "#ffffff"),
        dark:  Color(hex: "#1c1c1e")
    )

    /// Content area — #f6f8f7 light, #2c2c2e dark
    static let fmsPageBackground = Color(
        light: Color(hex: "#f6f8f7"),
        dark:  Color(hex: "#2c2c2e")
    )

    /// Sidebar / toolbar surface — #f5f5f7 light, #1c1c1e dark
    /// Glass effect is applied via .thickMaterial at the view level.
    static let fmsSurface = Color(
        light: Color(hex: "#f5f5f7"),
        dark:  Color(hex: "#1c1c1e")
    )

    /// Card / input fill — rgba(0,0,0,0.03) light, rgba(255,255,255,0.05) dark
    static let fmsCardBackground = Color(
        light: Color.black.opacity(0.03),
        dark:  Color.white.opacity(0.05)
    )

    // MARK: Text
    /// Primary text — #0f172a light, #ffffff dark
    static let fmsOnSurface = Color(
        light: Color(hex: "#0f172a"),
        dark:  Color(hex: "#ffffff")
    )

    /// Secondary text — #64748b light, #a1a1aa dark
    static let fmsSecondaryText = Color(
        light: Color(hex: "#64748b"),
        dark:  Color(hex: "#a1a1aa")
    )

    /// Muted / placeholder — rgba(15,23,42,0.4) light, rgba(255,255,255,0.3) dark
    static let fmsMuted = Color(
        light: Color(NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.4)),
        dark:  Color(NSColor(white: 1, alpha: 0.3))
    )

    // MARK: Borders
    /// Subtle 1px separator — rgba(0,0,0,0.05) light, rgba(255,255,255,0.1) dark
    static let fmsBorder = Color(
        light: Color.black.opacity(0.05),
        dark:  Color.white.opacity(0.1)
    )
}

// MARK: - Hex initialiser
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
