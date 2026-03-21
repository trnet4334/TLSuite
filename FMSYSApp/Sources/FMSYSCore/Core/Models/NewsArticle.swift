// Sources/FMSYSCore/Core/Models/NewsArticle.swift
import Foundation
import SwiftUI

public enum NewsCategory: String, CaseIterable, Sendable {
    case all     = "All"
    case general = "General"
    case stocks  = "Stocks"
    case forex   = "Forex"
    case crypto  = "Crypto"

    public var color: Color {
        switch self {
        case .all, .general: return Color.fmsPrimary
        case .stocks:        return Color(red: 0.231, green: 0.510, blue: 0.965)
        case .forex:         return Color(red: 0.663, green: 0.329, blue: 1.0)
        case .crypto:        return Color(red: 1.0,   green: 0.584, blue: 0.0)
        }
    }
}

public struct NewsArticle: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let source: String
    public let summary: String?
    public let url: URL
    public let publishedAt: Date
    public let category: NewsCategory
}
