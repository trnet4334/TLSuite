// Sources/FMSYSCore/Core/Models/BacktestResult.swift
import Foundation
import SwiftData

// MARK: - Value types stored as JSON blobs inside BacktestResult

public struct BacktestEquityPoint: Codable {
    public let tradeNumber: Int
    public let equity: Double

    public init(tradeNumber: Int, equity: Double) {
        self.tradeNumber = tradeNumber
        self.equity = equity
    }
}

public struct BacktestTradeEntry: Codable, Identifiable {
    public var id: UUID
    public let date: Date
    public let symbol: String
    public let strategy: String
    public let directionRaw: String   // "long" / "short" — avoids importing Direction across contexts
    public let netProfit: Double

    public var direction: Direction {
        Direction(rawValue: directionRaw) ?? .long
    }

    public init(id: UUID = UUID(), date: Date, symbol: String, strategy: String, direction: Direction, netProfit: Double) {
        self.id = id
        self.date = date
        self.symbol = symbol
        self.strategy = strategy
        self.directionRaw = direction.rawValue
        self.netProfit = netProfit
    }
}

// MARK: - SwiftData model

@Model
public final class BacktestResult {

    public var id: UUID
    public var strategyId: UUID
    public var strategyName: String
    public var assetPair: String
    public var timeframeRaw: String

    public var startDate: Date
    public var endDate: Date

    public var totalTrades: Int
    public var winRate: Double        // 0.0–1.0
    public var profitFactor: Double
    public var maxDrawdown: Double    // 0.0–1.0
    public var sharpeRatio: Double

    // JSON-encoded blobs
    public var equityCurveData: Data  // [BacktestEquityPoint]
    public var tradeLogData: Data     // [BacktestTradeEntry]

    public var createdAt: Date

    // MARK: Computed wrappers

    public var timeframe: Timeframe {
        get { Timeframe(rawValue: timeframeRaw) ?? .h1 }
        set { timeframeRaw = newValue.rawValue }
    }

    public var equityCurve: [BacktestEquityPoint] {
        (try? JSONDecoder().decode([BacktestEquityPoint].self, from: equityCurveData)) ?? []
    }

    public var tradeLog: [BacktestTradeEntry] {
        (try? JSONDecoder().decode([BacktestTradeEntry].self, from: tradeLogData)) ?? []
    }

    // MARK: Init

    public init(
        id: UUID = UUID(),
        strategyId: UUID,
        strategyName: String,
        assetPair: String,
        timeframe: Timeframe,
        startDate: Date,
        endDate: Date,
        totalTrades: Int,
        winRate: Double,
        profitFactor: Double,
        maxDrawdown: Double,
        sharpeRatio: Double,
        equityCurveData: Data,
        tradeLogData: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.strategyId = strategyId
        self.strategyName = strategyName
        self.assetPair = assetPair
        self.timeframeRaw = timeframe.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.totalTrades = totalTrades
        self.winRate = winRate
        self.profitFactor = profitFactor
        self.maxDrawdown = maxDrawdown
        self.sharpeRatio = sharpeRatio
        self.equityCurveData = equityCurveData
        self.tradeLogData = tradeLogData
        self.createdAt = createdAt
    }
}
