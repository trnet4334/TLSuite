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
}
