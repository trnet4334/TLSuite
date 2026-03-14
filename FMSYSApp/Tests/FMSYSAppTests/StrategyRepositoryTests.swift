// Tests/FMSYSAppTests/StrategyRepositoryTests.swift
import Foundation
import SwiftData
import Testing
@testable import FMSYSCore

@MainActor
@Suite(.serialized)
struct StrategyRepositoryTests {

    private func makeContainer() throws -> (ModelContext, ModelContainer) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Strategy.self, configurations: config)
        return (container.mainContext, container)
    }

    @Test func strategyModelInitializesCorrectly() throws {
        let (_, _container) = try makeContainer()
        _ = _container
        let s = Strategy(userId: "u1", name: "Test", indicatorTag: "EMA", status: .active)
        #expect(s.name == "Test")
        #expect(s.status == .active)
        #expect(s.emaFastPeriod == 9)
        #expect(s.emaSlowPeriod == 21)
        #expect(s.winRate == nil)
    }

    // MARK: - StrategyRepository Tests

    private func makeRepository() throws -> (StrategyRepository, ModelContext, ModelContainer) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Strategy.self, configurations: config)
        let context = container.mainContext
        return (StrategyRepository(context: context), context, container)
    }

    private func makeStrategy(
        userId: String = "u1",
        name: String = "Test Strategy",
        status: StrategyStatus = .active
    ) -> Strategy {
        Strategy(userId: userId, name: name, indicatorTag: "EMA", status: status)
    }

    @Test func insertAndFindAll() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let s = makeStrategy()
        try sut.create(s)
        let all = try sut.findAll(userId: "u1")
        #expect(all.count == 1)
        #expect(all.first?.name == "Test Strategy")
    }

    @Test func findAllFiltersByUserId() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        try sut.create(makeStrategy(userId: "u1"))
        try sut.create(makeStrategy(userId: "u2"))
        let result = try sut.findAll(userId: "u1")
        #expect(result.count == 1)
    }

    @Test func findAllByStatusFilters() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        try sut.create(makeStrategy(status: .active))
        try sut.create(makeStrategy(status: .paused))
        try sut.create(makeStrategy(status: .drafting))
        let active = try sut.findAll(userId: "u1", status: .active)
        #expect(active.count == 1)
        #expect(active.first?.status == .active)
    }

    @Test func deleteRemovesStrategy() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let s = makeStrategy()
        try sut.create(s)
        try sut.delete(s)
        let all = try sut.findAll(userId: "u1")
        #expect(all.isEmpty)
    }

    @Test func findAllReturnsSortedByCreatedAtDescending() throws {
        let (sut, _, _container) = try makeRepository()
        _ = _container
        let older = makeStrategy(name: "Older")
        // Insert older first, then newer — repository should return newer first
        try sut.create(older)
        let newer = makeStrategy(name: "Newer")
        // Manually set createdAt to simulate time difference
        newer.createdAt = older.createdAt.addingTimeInterval(60)
        try sut.create(newer)
        let all = try sut.findAll(userId: "u1")
        #expect(all.first?.name == "Newer")
    }
}
