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
