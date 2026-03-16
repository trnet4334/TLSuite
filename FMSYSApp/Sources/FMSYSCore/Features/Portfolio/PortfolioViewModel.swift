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

    public var trades: [Trade]
    public var selectedRange: PortfolioRange = .ytd

    public init(trades: [Trade] = []) {
        self.trades = trades
    }

    // MARK: - Closed / open split

    public var openTrades: [Trade] {
        trades.filter { $0.exitPrice == nil }
    }

    public var closedTrades: [Trade] {
        trades.filter { $0.exitPrice != nil }
    }

    // MARK: - KPIs

    public var totalPnL: Double {
        closedTrades.reduce(0.0) { sum, t in
            guard let exit = t.exitPrice else { return sum }
            let m = t.direction == .long ? 1.0 : -1.0
            return sum + (exit - t.entryPrice) * m * t.positionSize
        }
    }

    public var dailyPnL: Double {
        let todayStart = Calendar.current.startOfDay(for: Date())
        return closedTrades
            .filter { ($0.exitAt ?? $0.entryAt) >= todayStart }
            .reduce(0.0) { sum, t in
                guard let exit = t.exitPrice else { return sum }
                let m = t.direction == .long ? 1.0 : -1.0
                return sum + (exit - t.entryPrice) * m * t.positionSize
            }
    }

    public var marginUtilization: Double {
        guard !trades.isEmpty else { return 0 }
        return Double(openTrades.count) / Double(max(trades.count, 1))
    }

    // MARK: - Equity curve

    public var performanceCurve: [EquityPoint] {
        let sorted = closedTrades.sorted { ($0.exitAt ?? $0.entryAt) < ($1.exitAt ?? $1.entryAt) }
        var cumulative = 0.0
        return sorted.map { t in
            let exit = t.exitPrice ?? t.entryPrice
            let m = t.direction == .long ? 1.0 : -1.0
            cumulative += (exit - t.entryPrice) * m * t.positionSize
            return EquityPoint(date: t.exitAt ?? t.entryAt, value: cumulative)
        }
    }

    // MARK: - Positions (group open trades by asset)

    public var positions: [PortfolioPosition] {
        var grouped: [String: [Trade]] = [:]
        for trade in openTrades { grouped[trade.asset, default: []].append(trade) }
        return grouped.map { symbol, group in
            let avgEntry = group.map(\.entryPrice).reduce(0, +) / Double(group.count)
            let totalSize = group.map(\.positionSize).reduce(0, +)
            let marketValue = avgEntry * totalSize
            return PortfolioPosition(
                id: symbol, name: symbol,
                qty: totalSize,
                lastPrice: avgEntry,
                marketValue: marketValue,
                unrealizedPnL: 0   // updated when live prices available
            )
        }.sorted { $0.marketValue > $1.marketValue }
    }

    // MARK: - Asset allocation (by journalCategory of open trades)

    public var allocation: [AllocationSlice] {
        let colors: [JournalCategory: Color] = [
            .stocksETFs: Color(red: 0.231, green: 0.510, blue: 0.965),
            .crypto:     Color(red: 1.0,   green: 0.584, blue: 0.0),
            .forex:      Color(red: 0.663, green: 0.329, blue: 1.0),
            .options:    Color.fmsPrimary,
        ]
        let total = Double(max(openTrades.count, 1))
        return JournalCategory.allCases
            .filter { $0 != .all }
            .compactMap { cat -> AllocationSlice? in
                let count = openTrades.filter { $0.journalCategory == cat }.count
                guard count > 0 else { return nil }
                return AllocationSlice(
                    id: cat.rawValue, name: cat.rawValue,
                    percent: Double(count) / total,
                    color: colors[cat] ?? .gray
                )
            }
    }
}
