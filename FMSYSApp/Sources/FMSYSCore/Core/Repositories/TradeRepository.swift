import Foundation
import SwiftData

public struct TradeRepository {

    public let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    public func create(_ trade: Trade) throws {
        context.insert(trade)
        try context.save()
    }

    // MARK: - Read

    public func findAll(userId: String) throws -> [Trade] {
        let uid = userId
        let descriptor = FetchDescriptor<Trade>(
            predicate: #Predicate { $0.userId == uid },
            sortBy: [SortDescriptor(\.entryAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func findAll(userId: String, journalCategory: JournalCategory) throws -> [Trade] {
        if journalCategory == .all {
            return try findAll(userId: userId)
        }
        let uid = userId
        let catRaw = journalCategory.rawValue
        let descriptor = FetchDescriptor<Trade>(
            predicate: #Predicate { $0.userId == uid && $0.journalCategoryRaw == catRaw },
            sortBy: [SortDescriptor(\.entryAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func findById(_ id: UUID) throws -> Trade? {
        let targetId = id
        var descriptor = FetchDescriptor<Trade>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    public func findPendingSync(userId: String) throws -> [Trade] {
        let uid = userId
        let descriptor = FetchDescriptor<Trade>(
            predicate: #Predicate { $0.userId == uid && $0.pendingSync == true }
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Update

    public func save() throws {
        try context.save()
    }

    // MARK: - Delete

    public func delete(_ trade: Trade) throws {
        context.delete(trade)
        try context.save()
    }
}
