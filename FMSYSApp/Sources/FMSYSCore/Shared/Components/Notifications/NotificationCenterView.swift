// Sources/FMSYSCore/Shared/Components/Notifications/NotificationCenterView.swift
import SwiftUI


public struct NotificationCenterView: View {
    @Environment(LanguageManager.self) private var lang
    @Binding var unreadCount: Int
    let onDismiss: () -> Void
    let onViewTrade: ((UUID?) -> Void)?
    let onOpenURL: ((URL) -> Void)?
    let onViewSecurity: (() -> Void)?
    let onViewAccount: (() -> Void)?

    @State private var notifications: [AppNotification] = AppNotification.samples.map {
        var n = $0; n.isRead = false; return n
    }
    @State private var activeFilter: FilterTab = .all
    @State private var isCompact = false
    @State private var selectedNotification: AppNotification? = nil

    private enum FilterTab: Equatable {
        case all
        case type(NotificationType)
        case achieved

        func label(bundle: Bundle) -> String {
            switch self {
            case .all:           return String(localized: "notif.filter_all",      bundle: bundle)
            case .type(let t):   return t.localizedName(bundle: bundle)
            case .achieved:      return String(localized: "notif.filter_achieved", bundle: bundle)
            }
        }
    }

    private var filtered: [AppNotification] {
        switch activeFilter {
        case .all:
            return notifications.filter { !$0.isAchieved }
        case .type(let type):
            return notifications.filter { $0.type == type && !$0.isAchieved }
        case .achieved:
            return notifications.filter { $0.isAchieved }
        }
    }

    public init(
        unreadCount: Binding<Int>,
        onDismiss: @escaping () -> Void,
        onViewTrade: ((UUID?) -> Void)? = nil,
        onOpenURL: ((URL) -> Void)? = nil,
        onViewSecurity: (() -> Void)? = nil,
        onViewAccount: (() -> Void)? = nil
    ) {
        self._unreadCount = unreadCount
        self.onDismiss = onDismiss
        self.onViewTrade = onViewTrade
        self.onOpenURL = onOpenURL
        self.onViewSecurity = onViewSecurity
        self.onViewAccount = onViewAccount
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            filterBar
            Divider()
            notificationList
        }
        .frame(width: 600, height: 680)
        .background(Color.fmsSurface)
        .sheet(item: $selectedNotification) { notification in
            detailView(for: notification)
                .environment(LanguageManager.shared)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("notif.title", bundle: lang.bundle)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("notif.subtitle", bundle: lang.bundle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }

            Spacer()

            // View toggle
            HStack(spacing: 2) {
                Button {
                    isCompact = false
                } label: {
                    Image(systemName: "rectangle.grid.1x2")
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                        .background(!isCompact ? Color.fmsSurface : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(!isCompact ? Color.fmsOnSurface : Color.fmsMuted)
                }
                .buttonStyle(.plain)
                Button {
                    isCompact = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                        .background(isCompact ? Color.fmsSurface : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(isCompact ? Color.fmsOnSurface : Color.fmsMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(3)
            .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            // Mark all read
            Button {
                markAllRead()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12))
                    Text("notif.mark_all_read", bundle: lang.bundle)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.fmsPrimary)
            }
            .buttonStyle(.plain)

            // Close
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.fmsMuted.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                filterButton(.all)
                ForEach(NotificationType.allCases, id: \.self) { type in
                    filterButton(.type(type))
                }
                filterButton(.achieved)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
        .background(Color.fmsMuted.opacity(0.04))
    }

    private func filterButton(_ tab: FilterTab) -> some View {
        let isSelected = activeFilter == tab
        let isAchieved = tab == .achieved
        return Button {
            activeFilter = tab
        } label: {
            Text(tab.label(bundle: lang.bundle))
                .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                .foregroundStyle(
                    isSelected
                        ? (isAchieved ? Color.fmsPrimary : Color.fmsOnSurface)
                        : Color.fmsMuted
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.fmsSurface : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(
                            isSelected
                                ? (isAchieved ? Color.fmsPrimary.opacity(0.3) : Color.fmsMuted.opacity(0.15))
                                : Color.clear
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notification list

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: isCompact ? 0 : 10) {
                ForEach(filtered) { notification in
                    if isCompact {
                        compactRow(notification)
                        if notification.id != filtered.last?.id {
                            Divider().padding(.horizontal, 16)
                        }
                    } else {
                        detailedCard(notification)
                    }
                }
            }
            .padding(isCompact ? 0 : 16)
        }
    }

    // MARK: - Detailed card

    private func detailedCard(_ notification: AppNotification) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(notification.type.color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: notification.type.systemImage)
                        .font(.system(size: 20))
                        .foregroundStyle(notification.type.color)
                }
                if notification.isAchieved {
                    ZStack {
                        Circle()
                            .fill(Color.fmsPrimary)
                            .frame(width: 16, height: 16)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.fmsBackground)
                    }
                    .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 5) {
                        Text(notification.type.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(notification.type.color)
                            .tracking(0.8)
                        if !notification.isRead {
                            Circle()
                                .fill(notification.type.color)
                                .frame(width: 5, height: 5)
                        }
                    }
                    Spacer()
                    Text(notification.timestamp)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }

                Text(notification.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                    .lineLimit(2)

                Text(notification.body)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                    .lineSpacing(2)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Button(String(localized: "notif.view_details", bundle: lang.bundle)) {
                        markRead(notification)
                        selectedNotification = notification
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.fmsOnSurface, in: RoundedRectangle(cornerRadius: 7))
                    .foregroundStyle(Color.fmsSurface)

                    if !notification.isAchieved {
                        Button(String(localized: "notif.achieve", bundle: lang.bundle)) {
                            achieve(notification)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.fmsPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                        .foregroundStyle(Color.fmsPrimary)
                    }

                    Button(String(localized: "notif.dismiss", bundle: lang.bundle)) {
                        remove(notification)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.fmsMuted.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                    .foregroundStyle(Color.fmsMuted)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.fmsMuted.opacity(notification.isRead ? 0.03 : 0.06),
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.fmsMuted.opacity(0.1))
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            markRead(notification)
            selectedNotification = notification
        }
    }

    // MARK: - Compact row

    private func compactRow(_ notification: AppNotification) -> some View {
        HStack(spacing: 10) {
            // Unread dot
            Circle()
                .fill(notification.isRead ? Color.clear : notification.type.color)
                .frame(width: 6, height: 6)

            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(notification.type.color.opacity(0.1))
                    .frame(width: 30, height: 30)
                Image(systemName: notification.type.systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(notification.type.color)
            }

            // Title + body inline
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(notification.title)
                    .font(.system(size: 13, weight: notification.isRead ? .medium : .bold))
                    .foregroundStyle(notification.isRead ? Color.fmsMuted : Color.fmsOnSurface)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: false)

                Text(notification.body)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Category badge
            Text(notification.type.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(notification.type.color)
                .tracking(0.6)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(notification.type.color.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 4))

            // Timestamp
            Text(notification.timestamp)
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            markRead(notification)
            selectedNotification = notification
        }
    }

    // MARK: - Detail view router

    @ViewBuilder
    private func detailView(for notification: AppNotification) -> some View {
        switch notification.type {
        case .priceAlert:
            PriceAlertDetailView(
                notification: notification,
                onDismiss: { selectedNotification = nil },
                onRemove: { remove(notification); selectedNotification = nil },
                onViewTrade: {
                    selectedNotification = nil
                    onViewTrade?(notification.tradeId)
                },
                onAchieve: {
                    achieve(notification)
                    selectedNotification = nil
                }
            )
        case .security:
            SecurityAlertDetailView(
                notification: notification,
                onDismiss: { selectedNotification = nil },
                onRemove: { remove(notification); selectedNotification = nil },
                onViewSettings: {
                    selectedNotification = nil
                    onViewSecurity?()
                },
                onAchieve: {
                    achieve(notification)
                    selectedNotification = nil
                }
            )
        case .user:
            UserNotificationDetailView(
                notification: notification,
                onDismiss: { selectedNotification = nil },
                onRemove: { remove(notification); selectedNotification = nil },
                onViewAccount: {
                    selectedNotification = nil
                    onViewAccount?()
                },
                onAchieve: {
                    achieve(notification)
                    selectedNotification = nil
                }
            )
        }
    }

    // MARK: - Helpers

    private func markRead(_ notification: AppNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        if !notifications[index].isRead {
            notifications[index].isRead = true
            unreadCount = max(0, unreadCount - 1)
        }
    }

    private func markAllRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        unreadCount = 0
    }

    private func remove(_ notification: AppNotification) {
        if !notification.isRead {
            unreadCount = max(0, unreadCount - 1)
        }
        notifications.removeAll { $0.id == notification.id }
    }

    private func achieve(_ notification: AppNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        if !notifications[index].isAchieved {
            notifications[index].isAchieved = true
            // Also mark as read so the unread count stays consistent
            if !notifications[index].isRead {
                notifications[index].isRead = true
                unreadCount = max(0, unreadCount - 1)
            }
        }
    }
}
