import Foundation
import Observation
import SwiftData

// MARK: - Supporting types

public enum DashboardRange: String, CaseIterable {
    case sevenDays, thirtyDays, ninetyDays, allTime

    public var label: String {
        switch self {
        case .sevenDays:  return "7D"
        case .thirtyDays: return "30D"
        case .ninetyDays: return "90D"
        case .allTime:    return "All"
        }
    }

    var days: Int? {
        switch self {
        case .sevenDays:  return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime:    return nil
        }
    }
}

public struct EquityPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
}

// MARK: - ViewModel

@Observable
public final class DashboardViewModel {
    public let trades: [Trade]
    public var selectedRange: DashboardRange = .thirtyDays

    public init(trades: [Trade]) {
        self.trades = trades
    }

    public var closedTrades: [Trade] {
        trades.filter { $0.exitPrice != nil }
    }

    public var totalTrades: Int { trades.count }

    public var totalPnL: Double {
        closedTrades.reduce(0.0) { sum, trade in
            guard let exitPrice = trade.exitPrice else { return sum }
            let multiplier = trade.direction == .long ? 1.0 : -1.0
            return sum + (exitPrice - trade.entryPrice) * multiplier * trade.positionSize
        }
    }

    public var winRate: Double {
        guard !closedTrades.isEmpty else { return 0 }
        let wins = closedTrades.filter { trade in
            guard let exitPrice = trade.exitPrice else { return false }
            let multiplier = trade.direction == .long ? 1.0 : -1.0
            return (exitPrice - trade.entryPrice) * multiplier > 0
        }
        return Double(wins.count) / Double(closedTrades.count)
    }

    public var avgRR: Double {
        guard !trades.isEmpty else { return 0 }
        let rrs = trades.compactMap { trade -> Double? in
            let reward = abs(trade.takeProfit - trade.entryPrice)
            let risk   = abs(trade.entryPrice - trade.stopLoss)
            guard risk > 0 else { return nil }
            return reward / risk
        }
        guard !rrs.isEmpty else { return 0 }
        return rrs.reduce(0, +) / Double(rrs.count)
    }

    // MARK: - Task 4: Streak metrics

    private func sortedClosed() -> [Trade] {
        closedTrades.sorted { ($0.exitAt ?? $0.entryAt) < ($1.exitAt ?? $1.entryAt) }
    }

    private func isWin(_ trade: Trade) -> Bool {
        guard let exitPrice = trade.exitPrice else { return false }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exitPrice - trade.entryPrice) * multiplier > 0
    }

    public var bestStreak: Int {
        var best = 0, current = 0
        for trade in sortedClosed() {
            if isWin(trade) { current += 1; best = max(best, current) }
            else { current = 0 }
        }
        return best
    }

    public var currentStreak: Int {
        let sorted = sortedClosed()
        guard let last = sorted.last else { return 0 }
        let targetWin = isWin(last)
        var streak = 0
        for trade in sorted.reversed() {
            guard isWin(trade) == targetWin else { break }
            streak += targetWin ? 1 : -1
        }
        return streak
    }
}
