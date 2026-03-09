import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    struct AppStateTests {

        private let keychain = KeychainManager()

        // MARK: - Session restoration

        @Test func isAuthenticatedFalseOnInitWhenKeychainEmpty() throws {
            try? keychain.clearAll()
            let sut = AppState(keychain: keychain)

            #expect(sut.isAuthenticated == false)
        }

        @Test func isAuthenticatedTrueOnInitWhenAccessTokenExists() throws {
            try? keychain.clearAll()
            try keychain.save("existing-token", forKey: .accessToken)

            let sut = AppState(keychain: keychain)

            #expect(sut.isAuthenticated == true)
        }

        // MARK: - State transitions

        @Test func markAuthenticatedSetsIsAuthenticatedTrue() throws {
            try? keychain.clearAll()
            let sut = AppState(keychain: keychain)

            sut.markAuthenticated()

            #expect(sut.isAuthenticated == true)
        }

        @Test func markLoggedOutSetsIsAuthenticatedFalse() throws {
            try? keychain.clearAll()
            try keychain.save("tok", forKey: .accessToken)
            let sut = AppState(keychain: keychain)

            sut.markLoggedOut()

            #expect(sut.isAuthenticated == false)
        }
    }
}
