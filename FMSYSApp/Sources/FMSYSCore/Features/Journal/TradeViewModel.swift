import Foundation
import Observation
import SwiftData

@Observable
public final class TradeViewModel {

    public var trades: [Trade] = []
    public var isLoading = false
    public var errorMessage: String?
    public var journalCategory: JournalCategory = .all

    private let repository: TradeRepository
    private let userId: String

    public init(repository: TradeRepository, userId: String) {
        self.repository = repository
        self.userId = userId
    }

    @MainActor
    public func loadTrades() {
        do {
            trades = try repository.findAll(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func loadTrades(category: JournalCategory = .all) {
        journalCategory = category
        do {
            trades = try repository.findAll(userId: userId, journalCategory: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func updateTrade(_ trade: Trade) {
        do {
            try repository.save()
            trades = try repository.findAll(userId: userId, journalCategory: journalCategory)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func createTrade(
        asset: String,
        assetCategory: AssetCategory,
        direction: Direction,
        entryPrice: Double,
        stopLoss: Double,
        takeProfit: Double,
        positionSize: Double
    ) {
        let trade = Trade(
            userId: userId,
            asset: asset,
            assetCategory: assetCategory,
            direction: direction,
            entryPrice: entryPrice,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            positionSize: positionSize,
            entryAt: Date()
        )
        do {
            try repository.create(trade)
            trades = try repository.findAll(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func deleteTrade(_ trade: Trade) {
        do {
            try repository.delete(trade)
            trades = try repository.findAll(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
