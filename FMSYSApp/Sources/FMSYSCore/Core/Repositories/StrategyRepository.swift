import Foundation
import SwiftData

public struct StrategyRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Read

    public func findAll(userId: String) throws -> [Strategy] {
        let uid = userId
        let descriptor = FetchDescriptor<Strategy>(
            predicate: #Predicate { $0.userId == uid },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func findAll(userId: String, status: StrategyStatus) throws -> [Strategy] {
        let uid = userId
        let raw = status.rawValue
        let descriptor = FetchDescriptor<Strategy>(
            predicate: #Predicate { $0.userId == uid && $0.statusRaw == raw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func findById(_ id: UUID) throws -> Strategy? {
        let targetId = id
        var descriptor = FetchDescriptor<Strategy>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Create

    public func create(_ strategy: Strategy) throws {
        context.insert(strategy)
        try context.save()
    }

    // MARK: - Update

    public func save() throws {
        try context.save()
    }

    // MARK: - Delete

    public func delete(_ strategy: Strategy) throws {
        context.delete(strategy)
        try context.save()
    }
}
