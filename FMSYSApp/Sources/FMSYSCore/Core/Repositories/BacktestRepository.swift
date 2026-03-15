// Sources/FMSYSCore/Core/Repositories/BacktestRepository.swift
import Foundation
import SwiftData

public struct BacktestRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func findAll() throws -> [BacktestResult] {
        let descriptor = FetchDescriptor<BacktestResult>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func findAll(strategyId: UUID) throws -> [BacktestResult] {
        let id = strategyId
        let descriptor = FetchDescriptor<BacktestResult>(
            predicate: #Predicate { $0.strategyId == id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func create(_ result: BacktestResult) throws {
        context.insert(result)
        try context.save()
    }

    public func delete(_ result: BacktestResult) throws {
        context.delete(result)
        try context.save()
    }

    public func findById(_ id: UUID) throws -> BacktestResult? {
        let localId = id
        let descriptor = FetchDescriptor<BacktestResult>(
            predicate: #Predicate { $0.id == localId }
        )
        return try context.fetch(descriptor).first
    }

    public func save() throws {
        try context.save()
    }

    public func deleteAll(strategyId: UUID) throws {
        let results = try findAll(strategyId: strategyId)
        for result in results {
            context.delete(result)
        }
        try context.save()
    }
}
