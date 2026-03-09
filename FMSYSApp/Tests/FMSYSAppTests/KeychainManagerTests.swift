import Testing
@testable import FMSYSCore

extension FMSYSTests {
    // Nested under FMSYSTests so it is serialized relative to APIClientTests
    // and AuthInterceptorTests (all share the same Keychain service keys).
    @Suite(.serialized)
    struct KeychainManagerTests {

        // MARK: - save & load

        @Test func storeAndRetrieveAccessToken() throws {
            let sut = KeychainManager()
            defer { try? sut.delete(forKey: .accessToken) }

            try sut.save("eyJhbGciOiJIUzI1NiJ9.test", forKey: .accessToken)
            let result = try sut.load(forKey: .accessToken)

            #expect(result == "eyJhbGciOiJIUzI1NiJ9.test")
        }

        @Test func storeAndRetrieveRefreshToken() throws {
            let sut = KeychainManager()
            defer { try? sut.delete(forKey: .refreshToken) }

            try sut.save("refresh-abc-123", forKey: .refreshToken)
            let result = try sut.load(forKey: .refreshToken)

            #expect(result == "refresh-abc-123")
        }

        // MARK: - overwrite (upsert)

        @Test func overwritingExistingTokenReturnsNewValue() throws {
            let sut = KeychainManager()
            defer { try? sut.delete(forKey: .accessToken) }

            try sut.save("old-token", forKey: .accessToken)
            try sut.save("new-token", forKey: .accessToken)
            let result = try sut.load(forKey: .accessToken)

            #expect(result == "new-token")
        }

        // MARK: - delete

        @Test func deleteTokenMakesLoadThrow() throws {
            let sut = KeychainManager()
            try sut.save("token-to-delete", forKey: .accessToken)

            try sut.delete(forKey: .accessToken)

            #expect(throws: KeychainError.itemNotFound) {
                try sut.load(forKey: .accessToken)
            }
        }

        @Test func deletingNonExistentKeyDoesNotThrow() throws {
            let sut = KeychainManager()
            try? sut.delete(forKey: .userId)
            try sut.delete(forKey: .userId)
        }

        // MARK: - load missing

        @Test func loadingNonExistentKeyThrowsItemNotFound() throws {
            let sut = KeychainManager()
            try? sut.delete(forKey: .accessToken)

            #expect(throws: KeychainError.itemNotFound) {
                try sut.load(forKey: .accessToken)
            }
        }

        // MARK: - clearAll

        @Test func clearAllRemovesAllFMSYSKeys() throws {
            let sut = KeychainManager()
            try sut.save("tok", forKey: .accessToken)
            try sut.save("ref", forKey: .refreshToken)
            try sut.save("uid", forKey: .userId)

            try sut.clearAll()

            #expect(throws: KeychainError.itemNotFound) { try sut.load(forKey: .accessToken) }
            #expect(throws: KeychainError.itemNotFound) { try sut.load(forKey: .refreshToken) }
            #expect(throws: KeychainError.itemNotFound) { try sut.load(forKey: .userId) }
        }

        // MARK: - UTF-8 round-trip

        @Test func savedTokenCanBeRoundTrippedWithUTF8() throws {
            let sut = KeychainManager()
            defer { try? sut.delete(forKey: .userId) }

            let value = "user-\u{1F4B0}-id-123"
            try sut.save(value, forKey: .userId)
            let result = try sut.load(forKey: .userId)

            #expect(result == value)
        }
    }
}
