import Foundation
import Testing
import SwiftData
@testable import FMSYSCore

extension FMSYSTests {
    @MainActor
    @Suite(.serialized)
    struct DashboardViewModelTests {

        // MARK: - Helpers

        private func makeContainer() throws -> (ModelContext, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Trade.self, configurations: config)
            return (container.mainContext, container)
        }

        private func makeTrade(
            context: ModelContext,
            entryPrice: Double,
            exitPrice: Double? = nil,
            direction: Direction = .long,
            stopLoss: Double? = nil,
            takeProfit: Double? = nil,
            positionSize: Double = 1.0,
            exitAt: Date? = nil
        ) -> Trade {
            let sl = stopLoss ?? (direction == .long ? entryPrice - 10 : entryPrice + 10)
            let tp = takeProfit ?? (direction == .long ? entryPrice + 20 : entryPrice - 20)
            let trade = Trade(
                userId: "u1",
                asset: "EUR/USD",
                assetCategory: .forex,
                direction: direction,
                entryPrice: entryPrice,
                stopLoss: sl,
                takeProfit: tp,
                positionSize: positionSize,
                entryAt: Date(),
                exitPrice: exitPrice,
                exitAt: exitAt ?? (exitPrice != nil ? Date() : nil)
            )
            context.insert(trade)
            return trade
        }

        // MARK: - Task 1 test

        @Test func dashboardRangeAllCasesExist() {
            let ranges = DashboardRange.allCases
            #expect(ranges.count == 4)
            #expect(DashboardRange.sevenDays.label == "7D")
            #expect(DashboardRange.thirtyDays.label == "30D")
            #expect(DashboardRange.ninetyDays.label == "90D")
            #expect(DashboardRange.allTime.label == "All")
        }

        @Test func totalPnLSumsClosedLongTrades() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, positionSize: 2.0) // +1.0
            let t2 = makeTrade(context: ctx, entryPrice: 2.0, exitPrice: 1.8, positionSize: 1.0) // -0.2
            let sut = DashboardViewModel(trades: [t1, t2])
            #expect(abs(sut.totalPnL - 0.8) < 0.0001)
        }

        @Test func totalPnLHandlesShortTrades() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let t = makeTrade(context: ctx, entryPrice: 2.0, exitPrice: 1.5, direction: .short, positionSize: 1.0) // +0.5
            let sut = DashboardViewModel(trades: [t])
            #expect(abs(sut.totalPnL - 0.5) < 0.0001)
        }

        @Test func totalPnLIgnoresOpenTrades() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let closed = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 2.0)
            let open   = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
            let sut = DashboardViewModel(trades: [closed, open])
            #expect(abs(sut.totalPnL - 1.0) < 0.0001)
        }

        @Test func totalTradesCountsAll() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let trades = [
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5),
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
            ]
            let sut = DashboardViewModel(trades: trades)
            #expect(sut.totalTrades == 2)
        }

        // MARK: - Task 3 tests

        @Test func winRateIs1WhenAllWins() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let trades = [
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5),
                makeTrade(context: ctx, entryPrice: 2.0, exitPrice: 2.5)
            ]
            let sut = DashboardViewModel(trades: trades)
            #expect(abs(sut.winRate - 1.0) < 0.0001)
        }

        @Test func winRateIs0WhenNoClosedTrades() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let open = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
            let sut = DashboardViewModel(trades: [open])
            #expect(sut.winRate == 0.0)
        }

        @Test func winRateCalculatesMixed() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let win  = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5)
            let loss = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5)
            let sut = DashboardViewModel(trades: [win, loss])
            #expect(abs(sut.winRate - 0.5) < 0.0001)
        }

        @Test func avgRRCalculatesRatio() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            // entry=1.0, sl=0.9 (risk=0.1), tp=1.3 (reward=0.3) → R:R = 3.0
            let t = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil,
                              stopLoss: 0.9, takeProfit: 1.3)
            let sut = DashboardViewModel(trades: [t])
            #expect(abs(sut.avgRR - 3.0) < 0.0001)
        }

        @Test func avgRRIs0WhenNoTrades() throws {
            let sut = DashboardViewModel(trades: [])
            #expect(sut.avgRR == 0.0)
        }
    }
}
