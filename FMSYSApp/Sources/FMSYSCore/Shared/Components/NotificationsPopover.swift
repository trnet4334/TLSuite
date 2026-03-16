// Sources/FMSYSCore/Shared/Components/NotificationsPopover.swift
import SwiftUI

private struct NotificationItem: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let timestamp: String
    let subtitle: String
}

// MARK: - All Notifications overlay

private struct AllNotificationsView: View {
    let items: [NotificationItem]
    @Binding var readIds: Set<UUID>
    @Binding var unreadCount: Int
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Notifications")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fmsMuted)
                        .frame(width: 28, height: 28)
                        .background(Color.fmsMuted.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()
                .overlay(Color.fmsBorder)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        notificationRow(item)
                        if item.id != items.last?.id {
                            Divider()
                                .padding(.horizontal, 20)
                                .overlay(Color.fmsBorder.opacity(0.4))
                        }
                    }
                }
            }
        }
        .frame(width: 480, height: 560)
        .background(Color.fmsSurface)
    }

    private func notificationRow(_ item: NotificationItem) -> some View {
        let isRead = readIds.contains(item.id)
        let iconColor: Color = isRead ? Color.fmsMuted : Color.fmsPrimary

        return HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

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
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRead {
                readIds.insert(item.id)
                unreadCount = max(0, unreadCount - 1)
            }
        }
    }
}

// MARK: - Notifications popover

public struct NotificationsPopover: View {
    @Binding var unreadCount: Int
    @State private var readIds: Set<UUID> = []
    @State private var showAll = false

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

    public init(unreadCount: Binding<Int>) {
        self._unreadCount = unreadCount
    }

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
                Button("Mark all read") {
                    readIds = Set(items.map(\.id))
                    unreadCount = 0
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.fmsPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Notification rows (max 10)
            VStack(spacing: 0) {
                ForEach(Array(items.prefix(10))) { item in
                    notificationRow(item)
                }
            }

            // Footer
            HStack {
                Button("Read all") {
                    showAll = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.fmsPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.fmsPrimary.opacity(0.05))
        }
        .frame(width: 380)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showAll) {
            AllNotificationsView(
                items: items,
                readIds: $readIds,
                unreadCount: $unreadCount,
                isPresented: $showAll
            )
        }
    }

    private func notificationRow(_ item: NotificationItem) -> some View {
        let isRead = readIds.contains(item.id)
        let iconColor: Color = isRead ? Color.fmsMuted : Color.fmsPrimary

        return HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

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
        .onTapGesture {
            if !isRead {
                readIds.insert(item.id)
                unreadCount = max(0, unreadCount - 1)
            }
        }
    }
}
