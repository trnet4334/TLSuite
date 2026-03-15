// Tests/FMSYSAppTests/BacktestViewModelTests.swift
import Foundation
import Testing
import SwiftData
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    @MainActor
    struct BacktestViewModelTests {

        private let seedKey = "fmsys.backtestSeeded"

        init() {
            UserDefaults.standard.removeObject(forKey: "fmsys.backtestSeeded")
        }

        func makeViewModel() throws -> (BacktestViewModel, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: BacktestResult.self, configurations: config)
            let context = ModelContext(container)
            return (BacktestViewModel(context: context), container)
        }

        @Test func loadWithoutSeed_isEmpty() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.set(true, forKey: seedKey)   // prevent seed
            vm.load()
            #expect(vm.results.isEmpty)
            #expect(vm.selectedResult == nil)
        }

        @Test func seedOnFirstLoad_populatesResults() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            #expect(vm.results.count == 1)
            #expect(vm.selectedResult != nil)
        }

        @Test func selectedResultIsFirstResult() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            #expect(vm.selectedResult?.id == vm.results.first?.id)
        }

        @Test func delete_removesFromResults() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            guard let first = vm.results.first else {
                Issue.record("Expected at least one result after seed")
                return
            }
            let countBefore = vm.results.count
            vm.delete(first)
            #expect(vm.results.count == countBefore - 1)
        }

        @Test func delete_clearsSelectedIfDeleted() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            guard let first = vm.results.first else { return }
            vm.selectedResult = first
            vm.delete(first)
            #expect(vm.selectedResult == nil)
        }

        @Test func makeSeedResult_has250EquityPoints() throws {
            let result = try BacktestViewModel.makeSeedResult()
            #expect(result.equityCurve.count == 250)
            #expect(result.totalTrades == 250)
        }

        @Test func errorMessageIsNilOnCleanLoad() throws {
            let (vm, _container) = try makeViewModel()
            _ = _container
            UserDefaults.standard.removeObject(forKey: seedKey)
            vm.load()
            #expect(vm.errorMessage == nil)
        }

        @Test func makeSeedResult_kpisMatchDesign() throws {
            let result = try BacktestViewModel.makeSeedResult()
            #expect(result.winRate == 0.642)
            #expect(result.profitFactor == 2.84)
            #expect(result.maxDrawdown == 0.0842)
        }
    }
}
