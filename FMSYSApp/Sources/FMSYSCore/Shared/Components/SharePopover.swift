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
