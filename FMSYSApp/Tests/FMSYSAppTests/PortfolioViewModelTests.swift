// Tests/FMSYSAppTests/PortfolioViewModelTests.swift
import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite
    struct PortfolioViewModelTests {

        private func makeTrade(
            asset: String = "AAPL",
            direction: Direction = .long,
            entryPrice: Double = 150,
            exitPrice: Double? = nil,
            positionSize: Double = 10,
            category: JournalCategory = .stocksETFs
        ) -> Trade {
            Trade(
                userId: "current-user", asset: asset,
                assetCategory: .stocks, direction: direction,
                entryPrice: entryPrice, stopLoss: 0, takeProfit: 0,
                positionSize: positionSize, entryAt: Date(),
                exitPrice: exitPrice,
                journalCategory: category
            )
        }

        @Test func defaultRangeIsOneMonth() {
            let sut = PortfolioViewModel()
            #expect(sut.selectedRange == .oneMonth)
        }

        @Test func emptyTradesYieldsZeroKPIs() {
            let sut = PortfolioViewModel()
            #expect(sut.totalPnL == 0)
            #expect(sut.dailyPnL == 0)
            #expect(sut.marginUtilization == 0)
        }

        @Test func totalPnLSumsClosedTrades() {
            let t1 = makeTrade(entryPrice: 100, exitPrice: 120, positionSize: 10)   // +200
            let t2 = makeTrade(entryPrice: 100, exitPrice: 90,  positionSize: 5)    // -50
            let sut = PortfolioViewModel(trades: [t1, t2])
            #expect(sut.totalPnL == 150)
        }

        @Test func openTradesYieldPositions() {
            let t1 = makeTrade(asset: "AAPL", exitPrice: nil)
            let t2 = makeTrade(asset: "BTC",  exitPrice: nil, category: .crypto)
            let sut = PortfolioViewModel(trades: [t1, t2])
            #expect(sut.positions.count == 2)
            let symbols = sut.positions.map(\.id)
            #expect(symbols.contains("AAPL"))
            #expect(symbols.contains("BTC"))
        }

        @Test func performanceCurveFollowsClosedTradeOrder() {
            let t1 = makeTrade(entryPrice: 100, exitPrice: 110, positionSize: 10)  // +100
            let t2 = makeTrade(entryPrice: 100, exitPrice: 120, positionSize: 10)  // +200
            let sut = PortfolioViewModel(trades: [t1, t2])
            let curve = sut.performanceCurve
            #expect(curve.count == 2)
            #expect(curve[0].value == 100)
            #expect(curve[1].value == 300)
        }

        @Test func allocationReflectsCategoryBreakdown() {
            let stock  = makeTrade(asset: "AAPL",    exitPrice: nil, category: .stocksETFs)
            let crypto = makeTrade(asset: "BTC",     exitPrice: nil, category: .crypto)
            let sut = PortfolioViewModel(trades: [stock, crypto])
            let ids = sut.allocation.map(\.id)
            #expect(ids.contains("Stocks/ETFs"))
            #expect(ids.contains("Crypto"))
            let total = sut.allocation.map(\.percent).reduce(0, +)
            #expect(abs(total - 1.0) < 0.01)
        }

        @Test func tradesVarUpdatesPositions() {
            let sut = PortfolioViewModel()
            #expect(sut.positions.isEmpty)
            sut.trades = [makeTrade(asset: "MSFT", exitPrice: nil)]
            #expect(sut.positions.count == 1)
            #expect(sut.positions[0].id == "MSFT")
        }
    }
}
