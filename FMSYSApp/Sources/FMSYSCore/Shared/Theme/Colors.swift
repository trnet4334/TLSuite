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

    // Brand / status (non-adaptive)
    static let fmsPrimary      = Color(hex: "#13ec80")
    static let fmsSecondary    = Color(hex: "#3b82f6")
    static let fmsAccentOrange = Color(hex: "#f59e0b")
    static let fmsAccentPurple = Color(hex: "#8b5cf6")
    static let fmsLoss         = Color(hex: "#ff5f57")
    static let fmsWarning      = Color(hex: "#ffbd2e")

    // App background
    static let fmsBackground = Color(
        light: Color(hex: "#ffffff"),
        dark:  Color(hex: "#1c1c1e")
    )

    // Page / content area background
    static let fmsPageBackground = Color(
        light: Color(hex: "#f6f8f7"),
        dark:  Color(hex: "#111113")
    )

    // Sidebar / toolbar surface
    // Light: rgba(245,245,247,0.7) — applied as .regularMaterial in views
    // Dark:  rgba(28,28,30,0.8)
    static let fmsSurface = Color(
        light: Color(hex: "#f5f5f7"),
        dark:  Color(hex: "#1c1c1e")
    )

    // Primary text
    static let fmsOnSurface = Color(
        light: Color(hex: "#0f172a"),
        dark:  Color(hex: "#ebebf0")
    )

    // Secondary text
    static let fmsSecondaryText = Color(
        light: Color(hex: "#64748b"),
        dark:  Color(hex: "#8e8e93")
    )

    // Muted / placeholder — light: rgba(15,23,42,0.4), dark: #8e8e93
    static let fmsMuted = Color(
        light: Color(NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.4)),
        dark:  Color(hex: "#8e8e93")
    )

    // Separator / stroke
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
