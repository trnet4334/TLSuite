// Sources/FMSYSCore/Features/Backtesting/BacktestViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
public final class BacktestViewModel {

    // MARK: State
    public var results: [BacktestResult] = []
    public var selectedResult: BacktestResult?
    public var errorMessage: String?

    // MARK: Private
    private let repository: BacktestRepository
    private let seededKey = "fmsys.backtestSeeded"

    // MARK: Init
    public init(context: ModelContext) {
        self.repository = BacktestRepository(context: context)
    }

    // MARK: Load

    @MainActor
    public func load() {
        do {
            results = try repository.findAll()
            if selectedResult == nil {
                selectedResult = results.first
            }
            seedIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Delete

    @MainActor
    public func delete(_ result: BacktestResult) {
        do {
            if selectedResult?.id == result.id {
                selectedResult = nil
            }
            try repository.delete(result)
            results = try repository.findAll()
            if selectedResult == nil {
                selectedResult = results.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Seed

    private func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        do {
            let seed = try Self.makeSeedResult()
            try repository.create(seed)
            results = try repository.findAll()
            selectedResult = results.first
            UserDefaults.standard.set(true, forKey: seededKey)
        } catch {
            // Do NOT write flag — will retry on next launch
            #if DEBUG
            print("BacktestViewModel: seed failed — \(error)")
            #endif
        }
    }

    // MARK: Seed factory (public for testability)

    public static func makeSeedResult() throws -> BacktestResult {
        let now = Date()
        let calendar = Calendar.current

        // Build 250 equity points (random walk from 10,000)
        var equity = 10_000.0
        var equityPoints: [BacktestEquityPoint] = []
        // Non-deterministic random walk — equity values differ each launch (KPI fields are hardcoded)
        var rng = SystemRandomNumberGenerator()
        for i in 1...250 {
            let delta = Double.random(in: -200...350, using: &rng)
            equity = max(5_000, equity + delta)
            equityPoints.append(BacktestEquityPoint(tradeNumber: i, equity: equity))
        }

        // 4 representative trade log entries matching the HTML prototype
        let log: [BacktestTradeEntry] = [
            BacktestTradeEntry(
                date: calendar.date(byAdding: .hour, value: -20, to: now) ?? now,
                symbol: "BTC/USDT", strategy: "Mean Reversion", direction: .long,  netProfit:  1420.50),
            BacktestTradeEntry(
                date: calendar.date(byAdding: .hour, value: -25, to: now) ?? now,
                symbol: "ETH/USDT", strategy: "Mean Reversion", direction: .short, netProfit: -450.20),
            BacktestTradeEntry(
                date: calendar.date(byAdding: .day,  value:  -2, to: now) ?? now,
                symbol: "BTC/USDT", strategy: "Mean Reversion", direction: .long,  netProfit:  2890.00),
            BacktestTradeEntry(
                date: calendar.date(byAdding: .day,  value:  -2, to: now) ?? now,
                symbol: "SOL/USDT", strategy: "Mean Reversion", direction: .long,  netProfit:   820.15),
        ]

        let curveData = try JSONEncoder().encode(equityPoints)
        let logData   = try JSONEncoder().encode(log)

        return BacktestResult(
            strategyId:      UUID(),
            strategyName:    "Mean Reversion V3.1",
            assetPair:       "BTC/USDT",
            timeframe:       .h1,
            startDate:       calendar.date(byAdding: .month, value: -6, to: now) ?? now,
            endDate:         now,
            totalTrades:     250,
            winRate:         0.642,
            profitFactor:    2.84,
            maxDrawdown:     0.0842,
            sharpeRatio:     1.87,
            equityCurveData: curveData,
            tradeLogData:    logData
        )
    }
}
