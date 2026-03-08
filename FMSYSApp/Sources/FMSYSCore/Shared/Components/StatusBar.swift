import SwiftUI

public struct StatusBar: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            statusDot(color: Color.fmsPrimary, label: "Engine: Ready")
            divider
            Text("Latency: 4ms")
                .foregroundStyle(Color.fmsMuted)
            Spacer()
            Text("Core Version: 2.1.0")
                .foregroundStyle(Color.fmsMuted)
            divider
            Text("macOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
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
