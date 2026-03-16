// Sources/FMSYSCore/Core/Services/TradingDataService.swift
import Foundation
import SwiftData
import Observation

@MainActor
@Observable
public final class TradingDataService {

    public private(set) var trades: [Trade] = []

    public let modelContainer: ModelContainer
    private let userId = "current-user"

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Read

    public func loadAll() {
        let repo = TradeRepository(context: modelContainer.mainContext)
        trades = (try? repo.findAll(userId: userId)) ?? []
    }

    public func trades(for category: JournalCategory) -> [Trade] {
        guard category != .all else { return trades }
        return trades.filter { $0.journalCategory == category }
    }

    // MARK: - Write

    public func create(_ trade: Trade) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        try repo.create(trade)
        loadAll()
    }

    public func update(_ trade: Trade) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        try repo.save()
        loadAll()
    }

    public func delete(_ trade: Trade) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        try repo.delete(trade)
        loadAll()
    }

    public func importTrades(_ newTrades: [Trade]) throws {
        let repo = TradeRepository(context: modelContainer.mainContext)
        for trade in newTrades {
            try repo.create(trade)
        }
        loadAll()
    }
}
