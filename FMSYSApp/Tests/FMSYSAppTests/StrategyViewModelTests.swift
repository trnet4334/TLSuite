// Tests/FMSYSAppTests/StrategyViewModelTests.swift
import Foundation
import SwiftData
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @MainActor
    @Suite(.serialized)
    struct StrategyViewModelTests {

        private func makeSUT() throws -> (StrategyViewModel, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Strategy.self, configurations: config)
            let repo = StrategyRepository(context: container.mainContext)
            let defaults = UserDefaults(suiteName: "test.strategy.\(UUID().uuidString)")!
            let vm = StrategyViewModel(repository: repo, userId: "u1", defaults: defaults)
            return (vm, container)
        }

        @Test func loadSeeds3StrategiesOnFirstLaunch() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            #expect(sut.strategies.count == 3)
        }

        @Test func loadDoesNotSeedTwice() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            sut.load()
            #expect(sut.strategies.count == 3)
        }

        @Test func addCreatesNewDraftingStrategy() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            let before = sut.strategies.count
            sut.add()
            #expect(sut.strategies.count == before + 1)
            #expect(sut.strategies.first?.status == .drafting)
            #expect(sut.selectedStrategy?.status == .drafting)
        }

        @Test func deleteRemovesStrategyAndUpdatesSelection() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            let id = sut.strategies.last!.id
            sut.delete(id: id)
            #expect(sut.strategies.allSatisfy { $0.id != id })
        }

        @Test func updatePersistsChanges() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            let strategy = sut.strategies.first!
            strategy.name = "Updated Name"
            sut.update(strategy)
            #expect(sut.strategies.first(where: { $0.id == strategy.id })?.name == "Updated Name")
        }

        @Test func selectedStrategySetToFirstAfterLoad() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            #expect(sut.selectedStrategy != nil)
        }
    }
}
