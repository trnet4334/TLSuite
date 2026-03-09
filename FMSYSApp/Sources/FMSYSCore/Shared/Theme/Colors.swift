import SwiftUI

public extension Color {
    static let fmsPrimary    = Color(hex: "#13ec80")
    static let fmsLoss       = Color(hex: "#ff5f57")
    static let fmsWarning    = Color(hex: "#ffbd2e")
    static let fmsSurface    = Color(hex: "#1C1C1E")
    static let fmsBackground = Color(hex: "#111113")
    static let fmsOnSurface  = Color(hex: "#EBEBF0")
    static let fmsMuted      = Color(hex: "#8E8E93")
}

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
