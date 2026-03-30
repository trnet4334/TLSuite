// Sources/FMSYSCore/Features/Settings/SettingsTab.swift
import Foundation

public enum SettingsTab: String, CaseIterable, Identifiable {
    case account      = "Account"
    case preferences  = "Preferences"
    case security     = "Security"
    case subscription = "Subscription"
    case referral     = "Referral"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .account:      return "person.circle"
        case .preferences:  return "gearshape"
        case .security:     return "lock.shield"
        case .subscription: return "creditcard"
        case .referral:     return "person.3"
        }
    }
}
