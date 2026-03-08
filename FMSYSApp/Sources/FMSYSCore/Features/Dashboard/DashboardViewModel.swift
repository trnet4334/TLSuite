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
}
