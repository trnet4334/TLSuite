import SwiftUI

// MARK: - Manrope font helpers
// Falls back to system font if Manrope is not available.

public extension Font {

    // MARK: Headers
    /// H1 — 32pt ExtraBold (logo / hero)
    static let fmsH1 = manrope(size: 32, weight: .heavy)

    /// H2 — 20pt Bold (page title)
    static let fmsH2 = manrope(size: 20, weight: .bold)

    /// H3 — 15pt SemiBold (module / card title)
    static let fmsH3 = manrope(size: 15, weight: .semibold)

    /// Sidebar group label — 11pt ExtraBold uppercase
    static let fmsSidebarGroup = manrope(size: 11, weight: .heavy)

    // MARK: Body & controls
    /// Body — 13pt Medium
    static let fmsBody = manrope(size: 13, weight: .medium)

    /// Small detail / timestamp — 11pt Medium
    static let fmsSmall = manrope(size: 11, weight: .medium)

    /// Button label — 13pt Bold
    static let fmsButton = manrope(size: 13, weight: .bold)

    /// Input label — 11pt Bold uppercase
    static let fmsInputLabel = manrope(size: 11, weight: .bold)

    // MARK: - Private helper
    private static func manrope(size: CGFloat, weight: Font.Weight) -> Font {
        if NSFont(name: "Manrope", size: size) != nil {
            return .custom("Manrope", size: size).weight(weight)
        }
        return .system(size: size, weight: weight)
    }
}
