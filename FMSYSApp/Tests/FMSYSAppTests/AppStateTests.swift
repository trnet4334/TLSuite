import Foundation
import Testing
import SwiftData
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    struct AppStateTests {

        private let keychain = KeychainManager()

        @MainActor private func makeStore() throws -> AppStore {
            let container = try ModelContainer(
                for: Trade.self, Strategy.self, BacktestResult.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            return AppStore(keychain: keychain, modelContainer: container)
        }

        // MARK: - Session restoration

        @Test @MainActor func isAuthenticatedFalseOnInitWhenKeychainEmpty() throws {
            try? keychain.clearAll()
            let sut = try makeStore()
            #expect(sut.isAuthenticated == false)
        }

        @Test @MainActor func isAuthenticatedTrueOnInitWhenAccessTokenExists() throws {
            try? keychain.clearAll()
            try keychain.save("existing-token", forKey: .accessToken)
            let sut = try makeStore()
            #expect(sut.isAuthenticated == true)
        }

        // MARK: - State transitions

        @Test @MainActor func markAuthenticatedSetsIsAuthenticatedTrue() throws {
            try? keychain.clearAll()
            let sut = try makeStore()
            sut.markAuthenticated()
            #expect(sut.isAuthenticated == true)
        }

        @Test @MainActor func markLoggedOutSetsIsAuthenticatedFalse() throws {
            try? keychain.clearAll()
            try keychain.save("tok", forKey: .accessToken)
            let sut = try makeStore()
            sut.markLoggedOut()
            #expect(sut.isAuthenticated == false)
        }

        // MARK: - User profile

        @Test @MainActor func userDisplayNameDefaultsToTradingDesk() throws {
            try? keychain.clearAll()
            let sut = try makeStore()
            #expect(sut.userDisplayName == "Trading Desk")
        }

        @Test @MainActor func userEmailDefaultsToPlaceholder() throws {
            try? keychain.clearAll()
            let sut = try makeStore()
            #expect(sut.userEmail == "trader@fmsys.app")
        }

        @Test @MainActor func userRoleDefaultsToTrader() throws {
            try? keychain.clearAll()
            let sut = try makeStore()
            #expect(sut.userRole == "Trader")
        }
    }
}
