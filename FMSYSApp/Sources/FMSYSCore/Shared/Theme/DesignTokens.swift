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
public extension View {
    /// Standard macOS window-level shadow
    func fmsShadow() -> some View {
        self.shadow(color: .black.opacity(0.12), radius: 30, x: 0, y: 30)
            .shadow(color: .black.opacity(0.10), radius: 0.5, x: 0, y: 0)
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
