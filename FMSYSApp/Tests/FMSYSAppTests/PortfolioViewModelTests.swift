// Tests/FMSYSAppTests/PortfolioViewModelTests.swift
import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite
    struct PortfolioViewModelTests {

        @Test func kpiValuesMatchStubs() {
            let sut = PortfolioViewModel()
            #expect(sut.totalNetLiquidity == 142_500.42)
            #expect(sut.dailyPnL == 1_842.20)
            #expect(sut.buyingPower == 58_210.15)
        }

        @Test func defaultRangeIsYTD() {
            let sut = PortfolioViewModel()
            #expect(sut.selectedRange == .ytd)
        }

        @Test func performanceCurveHasPoints() {
            let sut = PortfolioViewModel()
            #expect(sut.performanceCurve.count > 0)
        }

        @Test func positionsContainsThreeStubs() {
            let sut = PortfolioViewModel()
            #expect(sut.positions.count == 3)
            let symbols = sut.positions.map { $0.id }
            #expect(symbols.contains("AAPL"))
            #expect(symbols.contains("MSFT"))
            #expect(symbols.contains("BTC"))
        }

        @Test func allocationPercentsApproximatelySum100() {
            let sut = PortfolioViewModel()
            let total = sut.allocation.reduce(0) { $0 + $1.percent }
            #expect(abs(total - 1.0) < 0.01)
        }

        @Test func riskMetricsArePositive() {
            let sut = PortfolioViewModel()
            #expect(sut.betaWeighting > 0)
            #expect(sut.marginUtilization > 0)
            #expect(sut.marginUtilization <= 1.0)
        }
    }
}
