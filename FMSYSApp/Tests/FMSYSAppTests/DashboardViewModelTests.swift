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
    }
}
