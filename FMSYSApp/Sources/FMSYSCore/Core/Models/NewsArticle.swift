// Sources/FMSYSCore/Core/Models/NewsArticle.swift
import Foundation

public enum NewsCategory: String, CaseIterable, Sendable {
    case all     = "All"
    case general = "General"
    case stocks  = "Stocks"
    case forex   = "Forex"
    case crypto  = "Crypto"
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
