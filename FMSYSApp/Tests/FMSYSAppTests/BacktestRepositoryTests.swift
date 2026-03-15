// Tests/FMSYSAppTests/BacktestRepositoryTests.swift
import Foundation
import Testing
import SwiftData
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    @MainActor
    struct BacktestRepositoryTests {

        // MARK: Helpers

        func makeRepository() throws -> (BacktestRepository, ModelContext, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: BacktestResult.self, configurations: config)
            let context = ModelContext(container)
            return (BacktestRepository(context: context), context, container)
        }

        func makeResult(strategyId: UUID = UUID(), createdAt: Date = Date()) throws -> BacktestResult {
            let curve = try JSONEncoder().encode([
                BacktestEquityPoint(tradeNumber: 1, equity: 10_000),
                BacktestEquityPoint(tradeNumber: 2, equity: 10_500)
            ])
            let log = try JSONEncoder().encode([
                BacktestTradeEntry(date: Date(), symbol: "BTC/USDT", strategy: "Test", direction: .long, netProfit: 500)
            ])
            return BacktestResult(
                strategyId: strategyId,
                strategyName: "Test Strategy",
                assetPair: "BTC/USDT",
                timeframe: .h1,
                startDate: Date(),
                endDate: Date(),
                totalTrades: 2,
                winRate: 0.5,
                profitFactor: 1.5,
                maxDrawdown: 0.05,
                sharpeRatio: 1.0,
                equityCurveData: curve,
                tradeLogData: log,
                createdAt: createdAt
            )
        }

        // MARK: Tests

        @Test func createAndFindAll() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            let all = try repo.findAll()
            #expect(all.count == 1)
        }

        @Test func findAllByStrategyId_filtersCorrectly() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let sid1 = UUID()
            let sid2 = UUID()
            try repo.create(try makeResult(strategyId: sid1))
            try repo.create(try makeResult(strategyId: sid2))
            let filtered = try repo.findAll(strategyId: sid1)
            #expect(filtered.count == 1)
            #expect(filtered[0].strategyId == sid1)
        }

        @Test func delete_removesResult() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            try repo.delete(result)
            #expect(try repo.findAll().count == 0)
        }

        @Test func findAll_sortedDescending() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let now = Date()
            let older = try makeResult(createdAt: now.addingTimeInterval(-10))
            let newer = try makeResult(createdAt: now)
            try repo.create(older)
            try repo.create(newer)
            let all = try repo.findAll()
            #expect(all.count == 2)
            #expect(all[0].createdAt >= all[1].createdAt)
        }

        @Test func equityCurveDecodable() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            let fetched = try repo.findAll().first!
            #expect(fetched.equityCurve.count == 2)
            #expect(fetched.equityCurve[0].tradeNumber == 1)
        }

        @Test func tradeLogDecodable() throws {
            let (repo, _, _container) = try makeRepository()
            _ = _container
            let result = try makeResult()
            try repo.create(result)
            let fetched = try repo.findAll().first!
            #expect(fetched.tradeLog.count == 1)
            #expect(fetched.tradeLog[0].symbol == "BTC/USDT")
        }
    }
}
