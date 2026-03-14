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
            exitAt: Date? = nil,
            emotionTag: EmotionTag? = nil
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
                exitAt: exitAt ?? (exitPrice != nil ? Date() : nil),
                emotionTag: emotionTag
            )
            context.insert(trade)
            return trade
        }

        // MARK: - Task 1 test

        @Test func dashboardRangeNewLabels() {
            #expect(DashboardRange.oneWeek.label == "1W")
            #expect(DashboardRange.oneMonth.label == "1M")
            #expect(DashboardRange.threeMonths.label == "3M")
            #expect(DashboardRange.ytd.label == "YTD")
            #expect(DashboardRange.allCases.count == 4)
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

        // MARK: - Task 4 tests

        @Test func bestStreakCountsLongestWinRun() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let base = Date()
            func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
            // W W L W W W → best = 3
            let trades = [
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(0)),
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(1)),
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(2)),
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(3)),
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(4)),
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(5)),
            ]
            let sut = DashboardViewModel(trades: trades)
            #expect(sut.bestStreak == 3)
        }

        @Test func bestStreakIs0WithNoClosedTrades() throws {
            let sut = DashboardViewModel(trades: [])
            #expect(sut.bestStreak == 0)
        }

        @Test func currentStreakPositiveForWins() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let base = Date()
            func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
            let trades = [
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(0)),  // L
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(1)),  // W
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(2)),  // W
            ]
            let sut = DashboardViewModel(trades: trades)
            #expect(sut.currentStreak == 2)
        }

        @Test func currentStreakNegativeForLosses() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let base = Date()
            func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
            let trades = [
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(0)),  // W
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(1)),  // L
                makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, exitAt: date(2)),  // L
            ]
            let sut = DashboardViewModel(trades: trades)
            #expect(sut.currentStreak == -2)
        }

        // MARK: - Task 5 tests

        @Test func equityCurveAllTimeReturnsCumulativePnL() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let base = Date()
            func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
            let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, positionSize: 1.0, exitAt: date(-2)) // +0.5
            let t2 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.8, positionSize: 1.0, exitAt: date(-1)) // -0.2
            let sut = DashboardViewModel(trades: [t1, t2])
            let curve = sut.equityCurve(range: .oneMonth)
            #expect(curve.count == 2)
            #expect(abs(curve[0].value - 0.5) < 0.0001)
            #expect(abs(curve[1].value - 0.3) < 0.0001)
        }

        @Test func equityCurveFiltersBy1Week() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let base = Date()
            func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
            let old    = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-10))
            let recent = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-2))
            let sut = DashboardViewModel(trades: [old, recent])
            let curve = sut.equityCurve(range: .oneWeek)
            #expect(curve.count == 1)
        }

        @Test func equityCurveExcludesOpenTrades() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let closed = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: Date())
            let open   = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: nil)
            let sut = DashboardViewModel(trades: [closed, open])
            let curve = sut.equityCurve(range: .oneMonth)
            #expect(curve.count == 1)
        }

        // MARK: - New range tests

        @Test func equityCurveFiltersBy1Month() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let base = Date()
            func date(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }
            let old    = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-40))
            let recent = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, exitAt: date(-10))
            let sut = DashboardViewModel(trades: [old, recent])
            let curve = sut.equityCurve(range: .oneMonth)
            #expect(curve.count == 1)
        }

        // MARK: - psychAnalytics tests

        @Test func disciplineScoreIs1WhenAllCalm() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .calm)
            let t2 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .confident)
            let sut = DashboardViewModel(trades: [t1, t2])
            #expect(abs(sut.psychAnalytics.disciplineScore - 1.0) < 0.001)
        }

        @Test func disciplineScoreIs0WhenAllFearful() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let t = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, emotionTag: .fearful)
            let sut = DashboardViewModel(trades: [t])
            #expect(sut.psychAnalytics.disciplineScore == 0.0)
        }

        @Test func patienceIndexExcludesFrustratedTrades() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let patient   = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .calm)
            let impatient = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, emotionTag: .frustrated)
            let sut = DashboardViewModel(trades: [patient, impatient])
            #expect(abs(sut.psychAnalytics.patienceIndex - 0.5) < 0.001)
        }

        @Test func heatmapCellsCountByEmotionAndPL() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let t1 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 0.5, emotionTag: .fearful)
            let t2 = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .fearful)
            let sut = DashboardViewModel(trades: [t1, t2])
            let cells = sut.psychAnalytics.heatmapCells
            let fearLoss   = cells.first { $0.emotion == "Fear" && $0.plBucket == .loss }
            let fearProfit = cells.first { $0.emotion == "Fear" && $0.plBucket == .profit }
            #expect(fearLoss?.count == 1)
            #expect(fearProfit?.count == 1)
        }

        @Test func heatmapExcludesTradesWithNoEmotionTag() throws {
            let (ctx, _container) = try makeContainer(); _ = _container
            let noTag  = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5)
            let tagged = makeTrade(context: ctx, entryPrice: 1.0, exitPrice: 1.5, emotionTag: .calm)
            let sut = DashboardViewModel(trades: [noTag, tagged])
            let cells = sut.psychAnalytics.heatmapCells
            let total = cells.reduce(0) { $0 + $1.count }
            #expect(total == 1)
        }
    }
}
