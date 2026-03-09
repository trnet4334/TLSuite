import Foundation
import SwiftData
import Testing
@testable import FMSYSCore

@MainActor
@Suite(.serialized)
struct TradeRepositoryTests {

    // MARK: - Factory

    /// Returns both container (kept alive) and a fresh repository backed by it.
    private func makeRepository() throws -> (TradeRepository, ModelContext, ModelContainer) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Trade.self, configurations: config)
        let context = container.mainContext
        return (TradeRepository(context: context), context, container)
    }

    private func makeTrade(
        userId: String = "user-1",
        asset: String = "EUR/USD",
        direction: Direction = .long,
        entryAt: Date = Date(),
        pendingSync: Bool = false,
        journalCategory: JournalCategory = .stocksETFs
    ) -> Trade {
        Trade(
            userId: userId,
            asset: asset,
            assetCategory: .forex,
            direction: direction,
            entryPrice: 1.1000,
            stopLoss: 1.0950,
            takeProfit: 1.1100,
            positionSize: 1.0,
            entryAt: entryAt,
            pendingSync: pendingSync,
            journalCategory: journalCategory
        )
    }

    // MARK: - create

    @Test func createInsertsTrade() throws {
        let (sut, context, _container) = try makeRepository()
        _ = _container
        let trade = makeTrade()

        try sut.create(trade)

        let fetched = try context.fetch(FetchDescriptor<Trade>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.asset == "EUR/USD")
    }

    @Test func createPersistsAllFields() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let entry = Date()
        let trade = makeTrade(userId: "u-99", asset: "GBP/USD", direction: .short, entryAt: entry)

        try sut.create(trade)

        let fetched = try sut.findAll(userId: "u-99")
        let saved = try #require(fetched.first)
        #expect(saved.userId == "u-99")
        #expect(saved.asset == "GBP/USD")
        #expect(saved.direction == .short)
        #expect(saved.entryPrice == 1.1000)
    }

    // MARK: - findAll

    @Test func findAllReturnsOnlyCurrentUsersTrades() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        try sut.create(makeTrade(userId: "user-A"))
        try sut.create(makeTrade(userId: "user-B"))
        try sut.create(makeTrade(userId: "user-A"))

        let results = try sut.findAll(userId: "user-A")

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.userId == "user-A" })
    }

    @Test func findAllReturnsSortedByEntryDateDescending() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let older = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -60)
        try sut.create(makeTrade(entryAt: older))
        try sut.create(makeTrade(entryAt: newer))

        let results = try sut.findAll(userId: "user-1")

        #expect(results.count == 2)
        #expect(results[0].entryAt >= results[1].entryAt)
    }

    @Test func findAllReturnsEmptyWhenNoTrades() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container

        let results = try sut.findAll(userId: "nobody")

        #expect(results.isEmpty)
    }

    // MARK: - findById

    @Test func findByIdReturnsTrade() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let trade = makeTrade()
        try sut.create(trade)

        let found = try sut.findById(trade.id)

        #expect(found?.id == trade.id)
    }

    @Test func findByIdReturnsNilForUnknownId() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container

        let found = try sut.findById(UUID())

        #expect(found == nil)
    }

    // MARK: - save (update)

    @Test func saveUpdatesPersistsChanges() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let trade = makeTrade()
        try sut.create(trade)
        trade.exitPrice = 1.1050
        trade.exitAt = Date()

        try sut.save()

        let fetched = try sut.findById(trade.id)
        #expect(fetched?.exitPrice == 1.1050)
    }

    // MARK: - delete

    @Test func deleteRemovesTrade() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let trade = makeTrade()
        try sut.create(trade)

        try sut.delete(trade)

        let results = try sut.findAll(userId: "user-1")
        #expect(results.isEmpty)
    }

    // MARK: - findPendingSync

    @Test func findPendingSyncReturnsOnlyPendingTrades() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        try sut.create(makeTrade(pendingSync: true))
        try sut.create(makeTrade(pendingSync: false))
        try sut.create(makeTrade(pendingSync: true))

        let results = try sut.findPendingSync(userId: "user-1")

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.pendingSync })
    }

    @Test func findPendingSyncReturnsEmptyWhenAllSynced() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        try sut.create(makeTrade(pendingSync: false))

        let results = try sut.findPendingSync(userId: "user-1")

        #expect(results.isEmpty)
    }

    // MARK: - JournalCategory

    @Test func tradeDefaultJournalCategoryIsStocksETFs() throws {
        let trade = makeTrade()
        #expect(trade.journalCategory == .stocksETFs)
    }

    @Test func tradeStoresCryptoJournalCategory() throws {
        let trade = makeTrade()
        trade.journalCategory = .crypto
        #expect(trade.journalCategory == .crypto)
    }

    @Test func tradeCategorySpecificFieldsDefaultToNil() throws {
        let trade = makeTrade()
        #expect(trade.leverage == nil)
        #expect(trade.fundingRate == nil)
        #expect(trade.walletAddress == nil)
        #expect(trade.pipValue == nil)
        #expect(trade.lotSize == nil)
        #expect(trade.exposure == nil)
        #expect(trade.sessionNotes == nil)
        #expect(trade.strikePrice == nil)
        #expect(trade.expirationDate == nil)
        #expect(trade.costBasis == nil)
        #expect(trade.greeksDelta == nil)
        #expect(trade.greeksGamma == nil)
        #expect(trade.greeksTheta == nil)
        #expect(trade.greeksVega == nil)
    }

    @Test func tradeCryptoFieldsCanBeSet() throws {
        let trade = makeTrade()
        trade.journalCategory = .crypto
        trade.leverage = 20.0
        trade.fundingRate = 0.01
        trade.walletAddress = "0x71C7b...3921"
        #expect(trade.leverage == 20.0)
        #expect(trade.fundingRate == 0.01)
        #expect(trade.walletAddress == "0x71C7b...3921")
    }

    @Test func tradeOptionsGreeksCanBeSet() throws {
        let trade = makeTrade()
        trade.journalCategory = .options
        trade.greeksDelta = 0.65
        trade.greeksGamma = 0.04
        trade.greeksTheta = -0.12
        trade.greeksVega = 0.28
        #expect(trade.greeksDelta == 0.65)
        #expect(trade.greeksGamma == 0.04)
        #expect(trade.greeksTheta == -0.12)
        #expect(trade.greeksVega == 0.28)
    }
}
