import Foundation
import Observation
import SwiftData

// MARK: - DashboardRange

public enum DashboardRange: String, CaseIterable {
    case oneWeek     = "1W"
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case ytd         = "YTD"

    public var label: String { rawValue }

    /// The earliest date included when filtering the equity curve.
    public var cutoffDate: Date {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .oneWeek:
            return cal.date(byAdding: .day, value: -7, to: now)!
        case .oneMonth:
            return cal.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths:
            return cal.date(byAdding: .month, value: -3, to: now)!
        case .ytd:
            return cal.date(from: cal.dateComponents([.year], from: now))!
        }
    }
}

// MARK: - EquityPoint

public struct EquityPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
}

// MARK: - MarketQuote

public struct MarketQuote: Identifiable {
    public let id: String
    public let name: String
    public let price: Double
    public let changePercent: Double
    public let sparkline: [Double]
}

// MARK: - PsychAnalytics

public enum PLBucket: String { case loss, neutral, profit }

public struct HeatmapCell: Identifiable {
    public let id: String
    public let emotion: String
    public let plBucket: PLBucket
    public let count: Int
}

public struct PsychAnalytics {
    public let disciplineScore: Double
    public let patienceIndex: Double
    public let heatmapCells: [HeatmapCell]
}

// MARK: - ViewModel

@Observable
public final class DashboardViewModel {
    public let trades: [Trade]
    public var selectedRange: DashboardRange = .oneMonth

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

    // MARK: - Streak metrics

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

    // MARK: - Equity curve

    public func equityCurve(range: DashboardRange) -> [EquityPoint] {
        let cutoff = range.cutoffDate
        let filtered = sortedClosed().filter { ($0.exitAt ?? $0.entryAt) >= cutoff }
        var cumulative = 0.0
        return filtered.map { trade in
            let exitPrice = trade.exitPrice ?? trade.entryPrice
            let multiplier = trade.direction == .long ? 1.0 : -1.0
            cumulative += (exitPrice - trade.entryPrice) * multiplier * trade.positionSize
            return EquityPoint(date: trade.exitAt ?? trade.entryAt, value: cumulative)
        }
    }

    // MARK: - Market quotes (static stubs)

    public var marketQuotes: [MarketQuote] {
        [
            MarketQuote(
                id: "BTC",
                name: "Bitcoin",
                price: 64231.50,
                changePercent: 2.4,
                sparkline: [60000, 61200, 59800, 62500, 63100, 64231]
            ),
            MarketQuote(
                id: "ETH",
                name: "Ethereum",
                price: 3420.12,
                changePercent: -1.2,
                sparkline: [3500, 3480, 3510, 3450, 3430, 3420]
            )
        ]
    }

    // MARK: - Psychological analytics

    public var psychAnalytics: PsychAnalytics {
        let tagged = Array(trades.filter { $0.emotionTag != nil }.suffix(30))
        guard !tagged.isEmpty else {
            return PsychAnalytics(disciplineScore: 0, patienceIndex: 0, heatmapCells: [])
        }
        let total = Double(tagged.count)
        let disciplined = tagged.filter { $0.emotionTag == .calm || $0.emotionTag == .confident }
        let disciplineScore = Double(disciplined.count) / total
        let patient = tagged.filter { $0.emotionTag != .frustrated && $0.emotionTag != .neutral }
        let patienceIndex = Double(patient.count) / total
        var counts: [String: [PLBucket: Int]] = [:]
        for trade in tagged {
            guard let tag = trade.emotionTag else { continue }
            let col = tag.displayName
            let bucket = plBucket(for: trade)
            counts[col, default: [:]][bucket, default: 0] += 1
        }
        var cells: [HeatmapCell] = []
        for (emotion, buckets) in counts {
            for (bucket, count) in buckets {
                cells.append(HeatmapCell(
                    id: "\(emotion)-\(bucket.rawValue)",
                    emotion: emotion,
                    plBucket: bucket,
                    count: count
                ))
            }
        }
        return PsychAnalytics(
            disciplineScore: disciplineScore,
            patienceIndex: patienceIndex,
            heatmapCells: cells
        )
    }

    private func plBucket(for trade: Trade) -> PLBucket {
        guard let exitPrice = trade.exitPrice else { return .neutral }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        let pnl = (exitPrice - trade.entryPrice) * multiplier
        if pnl > 0 { return .profit }
        if pnl < 0 { return .loss }
        return .neutral
    }
}
