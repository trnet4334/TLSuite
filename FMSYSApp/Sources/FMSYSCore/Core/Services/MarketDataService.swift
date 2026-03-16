// Sources/FMSYSCore/Core/Services/MarketDataService.swift
import Foundation

// MARK: - Types

public struct MarketQuoteResult {
    public let symbol: String
    public let name: String
    public let price: Double
    public let changePercent: Double
    public let sparkline: [Double]

    public init(symbol: String, name: String, price: Double, changePercent: Double, sparkline: [Double]) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.changePercent = changePercent
        self.sparkline = sparkline
    }
}

public struct PricePoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let price: Double

    public init(date: Date, price: Double) {
        self.date = date
        self.price = price
    }
}

// MARK: - Protocol

public protocol MarketDataServiceProtocol: Sendable {
    func quote(for symbol: String) async -> MarketQuoteResult
    func historicalPrices(symbol: String, range: DashboardRange) async -> [PricePoint]
}

// MARK: - Mock implementation

public struct MockMarketDataService: MarketDataServiceProtocol {

    private static let mockData: [String: (name: String, price: Double, change: Double, sparkline: [Double])] = [
        "BTC":     ("Bitcoin",          64_231.50,  2.4,  [60_000, 61_200, 59_800, 62_500, 63_100, 64_231]),
        "ETH":     ("Ethereum",          3_420.12, -1.2,  [3_500, 3_480, 3_510, 3_450, 3_430, 3_420]),
        "AAPL":    ("Apple Inc.",          192.42,  0.8,  [188, 189, 191, 190, 192, 192.42]),
        "MSFT":    ("Microsoft Corp.",     425.22,  1.1,  [415, 418, 420, 422, 424, 425.22]),
        "EUR/USD": ("Euro / USD",            1.085, -0.3, [1.09, 1.088, 1.087, 1.086, 1.085, 1.085]),
    ]

    public init() {}

    public func quote(for symbol: String) async -> MarketQuoteResult {
        if let d = Self.mockData[symbol] {
            return MarketQuoteResult(symbol: symbol, name: d.name, price: d.price,
                                    changePercent: d.change, sparkline: d.sparkline)
        }
        return MarketQuoteResult(symbol: symbol, name: symbol, price: 0,
                                 changePercent: 0, sparkline: [])
    }

    public func historicalPrices(symbol: String, range: DashboardRange) async -> [PricePoint] {
        let base = Self.mockData[symbol]?.price ?? 100
        let cal = Calendar.current
        let now = Date()
        let cutoff = range.cutoffDate
        let days = max(1, Int(now.timeIntervalSince(cutoff) / 86_400))
        return (0...days).map { i in
            let date = cal.date(byAdding: .day, value: -(days - i), to: now) ?? now
            let noise = Double.random(in: -0.02...0.02)
            return PricePoint(date: date, price: base * (1 + noise * Double(i) / Double(days)))
        }
    }
}
