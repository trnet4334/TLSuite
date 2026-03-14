// Sources/FMSYSCore/Features/Portfolio/PortfolioViewModel.swift
import Foundation
import Observation
import SwiftUI

// MARK: - Supporting types

public struct PortfolioPosition: Identifiable {
    public let id: String        // ticker symbol
    public let name: String
    public let qty: Double
    public let lastPrice: Double
    public let marketValue: Double
    public let unrealizedPnL: Double
}

public struct AllocationSlice: Identifiable {
    public let id: String
    public let name: String
    public let percent: Double   // 0.0 – 1.0
    public let color: Color
}

public enum PortfolioRange: String, CaseIterable {
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case ytd         = "YTD"
    case all         = "ALL"
}

// MARK: - PortfolioViewModel

@Observable
public final class PortfolioViewModel {
    public let totalNetLiquidity: Double = 142_500.42
    public let dailyPnL: Double          = 1_842.20
    public let buyingPower: Double       = 58_210.15
    public var selectedRange: PortfolioRange = .ytd
    public let betaWeighting: Double     = 1.12
    public let marginUtilization: Double = 0.32

    public var performanceCurve: [EquityPoint] {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year], from: now)) ?? now
        let values: [Double] = [100_000, 108_000, 115_000, 112_000, 128_000, 135_000, 142_500.42]
        let step = now.timeIntervalSince(start) / Double(values.count - 1)
        return values.enumerated().map { idx, val in
            EquityPoint(date: start.addingTimeInterval(Double(idx) * step), value: val)
        }
    }

    public let positions: [PortfolioPosition] = [
        PortfolioPosition(id: "AAPL", name: "Apple Inc.",      qty: 150,  lastPrice: 192.42,    marketValue: 28_863.00, unrealizedPnL:  1_420.15),
        PortfolioPosition(id: "MSFT", name: "Microsoft Corp.", qty: 45,   lastPrice: 425.22,    marketValue: 19_134.90, unrealizedPnL:    682.40),
        PortfolioPosition(id: "BTC",  name: "Bitcoin",         qty: 0.82, lastPrice: 64_310.00, marketValue: 52_734.20, unrealizedPnL:   -412.00),
    ]

    public let allocation: [AllocationSlice] = [
        AllocationSlice(id: "Stocks", name: "Stocks", percent: 0.452, color: Color(red: 0.231, green: 0.510, blue: 0.965)),
        AllocationSlice(id: "ETFs",   name: "ETFs",   percent: 0.248, color: Color.fmsPrimary),
        AllocationSlice(id: "Crypto", name: "Crypto", percent: 0.195, color: Color(red: 1.0,   green: 0.584, blue: 0.0)),
        AllocationSlice(id: "Forex",  name: "Forex",  percent: 0.105, color: Color(red: 0.663, green: 0.329, blue: 1.0)),
    ]
}
