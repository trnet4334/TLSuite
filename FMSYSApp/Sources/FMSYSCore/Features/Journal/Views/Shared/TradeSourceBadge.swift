import SwiftUI

/// Compact pill showing the data source of a trade (Manual / CSV filename / API).
public struct TradeSourceBadge: View {
    let source: String

    public init(source: String) {
        self.source = source
    }

    public var body: some View {
        Label(displayText, systemImage: icon)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
            .lineLimit(1)
    }

    private var isManual: Bool { source == "Manual" }
    private var isAPI: Bool { source.hasPrefix("API:") }

    private var displayText: String {
        if isManual { return "Manual" }
        if isAPI { return source }
        // CSV: strip "CSV: " prefix and truncate long filenames
        let name = source.replacingOccurrences(of: "CSV: ", with: "")
        return name.count > 18 ? String(name.prefix(16)) + "…" : name
    }

    private var icon: String {
        if isManual { return "pencil" }
        if isAPI    { return "antenna.radiowaves.left.and.right" }
        return "square.and.arrow.down"
    }

    private var color: Color {
        if isManual { return Color.fmsMuted }
        if isAPI    { return Color.blue }
        return Color.fmsPrimary
    }
}
