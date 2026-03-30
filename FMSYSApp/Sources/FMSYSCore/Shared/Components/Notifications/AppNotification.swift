// Sources/FMSYSCore/Shared/Components/Notifications/AppNotification.swift
import SwiftUI

public enum NotificationType: String, CaseIterable {
    case priceAlert = "Trade Alert"
    case security   = "Security Alert"
    case user       = "User"

    public var color: Color {
        switch self {
        case .priceAlert: return Color.fmsPrimary
        case .security:   return Color.orange
        case .user:       return Color.purple
        }
    }

    public var systemImage: String {
        switch self {
        case .priceAlert: return "chart.line.uptrend.xyaxis"
        case .security:   return "exclamationmark.shield.fill"
        case .user:       return "person.circle.fill"
        }
    }

    public func localizedName(bundle: Bundle) -> String {
        switch self {
        case .priceAlert: return String(localized: "notif.type.trade_alert", bundle: bundle)
        case .security:   return String(localized: "notif.type.security",    bundle: bundle)
        case .user:       return String(localized: "notif.type.user",        bundle: bundle)
        }
    }
}

public struct AppNotification: Identifiable {
    public let id: UUID
    public let type: NotificationType
    public let title: String
    public let body: String
    public let timestamp: String
    public var isRead: Bool
    public var isAchieved: Bool
    /// For `.priceAlert` — links to the corresponding trade in the Journal.
    public let tradeId: UUID?
    /// For `.marketing` — opens this URL in the default browser.
    public let url: URL?

    public init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        body: String,
        timestamp: String,
        isRead: Bool = false,
        isAchieved: Bool = false,
        tradeId: UUID? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.timestamp = timestamp
        self.isRead = isRead
        self.isAchieved = isAchieved
        self.tradeId = tradeId
        self.url = url
    }
}

// MARK: - Sample data

public extension AppNotification {
    static let samples: [AppNotification] = [
        AppNotification(
            type: .priceAlert,
            title: "BTC/USDT Take Profit hit at $67,500",
            body: "Your automated exit strategy was executed perfectly. Total net profit: +$1,240.42.",
            timestamp: "2 min ago"
        ),
        AppNotification(
            type: .security,
            title: "New login detected from a new device",
            body: "A successful login was registered from a Chrome browser on macOS located in San Francisco, USA.",
            timestamp: "5 hours ago"
        ),
        AppNotification(
            type: .user,
            title: "Your Pro Plan subscription will renew in 3 days.",
            body: "Your monthly subscription to Trading Suite Pro ($49.99) is scheduled for renewal. Make sure your payment method is up to date.",
            timestamp: "1 day ago"
        ),
    ]
}
