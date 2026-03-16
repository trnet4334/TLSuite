// Tests/FMSYSAppTests/TradingDataServiceTests.swift
import Testing
import Foundation
import SwiftData
@testable import FMSYSCore

@Suite(.serialized)
@MainActor
struct TradingDataServiceTests {

    private func makeService() throws -> (TradingDataService, ModelContainer) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Trade.self, configurations: config)
        let service = TradingDataService(modelContainer: container)
        return (service, container)
    }

    @Test func loadAllReturnsEmptyInitially() async throws {
        let (service, _) = try makeService()
        service.loadAll()
        #expect(service.trades.isEmpty)
    }

    @Test func createTrade() async throws {
        let (service, _) = try makeService()
        let trade = Trade(
            userId: "current-user", asset: "AAPL",
            assetCategory: .stocks, direction: .long,
            entryPrice: 150, stopLoss: 145, takeProfit: 160,
            positionSize: 10, entryAt: Date()
        )
        try service.create(trade)
        #expect(service.trades.count == 1)
        #expect(service.trades[0].asset == "AAPL")
    }

    @Test func deleteTrade() async throws {
        let (service, _) = try makeService()
        let trade = Trade(
            userId: "current-user", asset: "AAPL",
            assetCategory: .stocks, direction: .long,
            entryPrice: 150, stopLoss: 145, takeProfit: 160,
            positionSize: 10, entryAt: Date()
        )
        try service.create(trade)
        #expect(service.trades.count == 1)
        try service.delete(service.trades[0])
        #expect(service.trades.isEmpty)
    }

    @Test func tradesForCategory() async throws {
        let (service, _) = try makeService()
        let t1 = Trade(userId: "current-user", asset: "BTC", assetCategory: .crypto,
                       direction: .long, entryPrice: 60000, stopLoss: 55000,
                       takeProfit: 70000, positionSize: 0.5, entryAt: Date(),
                       journalCategory: .crypto)
        let t2 = Trade(userId: "current-user", asset: "AAPL", assetCategory: .stocks,
                       direction: .long, entryPrice: 150, stopLoss: 145,
                       takeProfit: 160, positionSize: 10, entryAt: Date(),
                       journalCategory: .stocksETFs)
        try service.create(t1)
        try service.create(t2)
        let cryptoTrades = service.trades(for: .crypto)
        #expect(cryptoTrades.count == 1)
        #expect(cryptoTrades[0].asset == "BTC")
    }

    @Test func importTradesBatch() async throws {
        let (service, _) = try makeService()
        let trades = (0..<5).map { i in
            Trade(userId: "current-user", asset: "T\(i)", assetCategory: .stocks,
                  direction: .long, entryPrice: Double(100 + i), stopLoss: 95,
                  takeProfit: 110, positionSize: 1, entryAt: Date())
        }
        try service.importTrades(trades)
        #expect(service.trades.count == 5)
    }
}
