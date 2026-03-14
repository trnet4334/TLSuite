import Foundation
import SwiftData

public struct StrategyRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

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

    public func insert(_ strategy: Strategy) throws {
        context.insert(strategy)
        try context.save()
    }

    public func save() throws {
        try context.save()
    }

    public func delete(_ strategy: Strategy) throws {
        context.delete(strategy)
        try context.save()
    }
}
