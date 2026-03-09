import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    struct AuthServiceTests {

        // MARK: - Fixtures

        private let keychain = KeychainManager()
        private static let baseURL = URL(string: "https://api.fmsys.io/v1")!

        private struct Echo: Decodable { let ok: Bool }

        // MARK: - Response JSON helpers

        private func loginSuccessJSON(
            access: String = "eyAccess",
            refresh: String = "eyRefresh",
            userId: String = "uid-123"
        ) -> Data {
            """
            {
                "access_token": "\(access)",
                "refresh_token": "\(refresh)",
                "user_id": "\(userId)",
                "requires_mfa": false
            }
            """.data(using: .utf8)!
        }

        private func loginMFAJSON(
            userId: String = "uid-456",
            sessionToken: String = "sess-abc"
        ) -> Data {
            """
            {
                "access_token": "",
                "refresh_token": "",
                "user_id": "\(userId)",
                "requires_mfa": true,
                "session_token": "\(sessionToken)"
            }
            """.data(using: .utf8)!
        }

        private func mfaSuccessJSON(
            access: String = "eyMFAAccess",
            refresh: String = "eyMFARefresh"
        ) -> Data {
            """
            {
                "access_token": "\(access)",
                "refresh_token": "\(refresh)"
            }
            """.data(using: .utf8)!
        }

        private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
            HTTPURLResponse(url: Self.baseURL, statusCode: statusCode,
                            httpVersion: nil, headerFields: nil)!
        }

        /// Builds a URLSession whose requests are intercepted, and a fresh AuthService.
        /// Clears the Keychain first so every test starts from a clean state.
        private func makeService(
            _ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
        ) -> AuthService {
            try? keychain.clearAll()
            MockURLProtocol.requestHandler = handler
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            return AuthService(
                client: APIClient(session: session),
                keychain: keychain,
                baseURL: Self.baseURL
            )
        }

        // MARK: - login → authenticated

        @Test func loginStoresAccessTokenOnSuccess() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON()) }

            _ = try await sut.login(email: "trader@fmsys.io", password: "Secret1!")

            #expect((try? keychain.load(forKey: .accessToken)) == "eyAccess")
        }

        @Test func loginStoresRefreshTokenOnSuccess() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON()) }

            _ = try await sut.login(email: "trader@fmsys.io", password: "Secret1!")

            #expect((try? keychain.load(forKey: .refreshToken)) == "eyRefresh")
        }

        @Test func loginReturnsAuthenticatedOnSuccess() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON()) }

            let result = try await sut.login(email: "trader@fmsys.io", password: "Secret1!")

            #expect(result == .authenticated)
        }

        // MARK: - login → MFA required

        @Test func loginReturnsMFARequiredWhenServerIndicates() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginMFAJSON()) }

            let result = try await sut.login(email: "trader@fmsys.io", password: "Secret1!")

            #expect(result == .mfaRequired(sessionToken: "sess-abc", userId: "uid-456"))
        }

        @Test func loginDoesNotStoreTokensWhenMFARequired() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginMFAJSON()) }

            _ = try await sut.login(email: "trader@fmsys.io", password: "Secret1!")

            #expect(throws: KeychainError.itemNotFound) { try keychain.load(forKey: .accessToken) }
            #expect(throws: KeychainError.itemNotFound) { try keychain.load(forKey: .refreshToken) }
        }

        // MARK: - login → error

        @Test func loginWithBadCredentialsThrowsUnauthorized() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 401), Data()) }

            await #expect(throws: APIError.unauthorized) {
                _ = try await sut.login(email: "bad@fmsys.io", password: "wrong")
            }
        }

        // MARK: - login request format

        @Test func loginSendsJSONContentTypeHeader() async throws {
            var capturedContentType: String?
            let sut = makeService { request in
                capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
                return (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON())
            }

            _ = try await sut.login(email: "t@t.com", password: "Abc123!")

            #expect(capturedContentType == "application/json")
        }

        @Test func loginSendsCredentialsInRequestBody() async throws {
            var capturedBody: Data?
            let sut = makeService { request in
                // URLSession converts httpBody → httpBodyStream before URLProtocol sees it.
                capturedBody = Self.drainBody(from: request)
                return (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON())
            }

            _ = try await sut.login(email: "trader@fmsys.io", password: "Secret1!")

            let dict = try JSONSerialization.jsonObject(with: capturedBody!) as! [String: String]
            #expect(dict["email"] == "trader@fmsys.io")
            #expect(dict["password"] == "Secret1!")
        }

        /// Reads the HTTP body from whichever field URLSession populated.
        private static func drainBody(from request: URLRequest) -> Data? {
            if let data = request.httpBody { return data }
            guard let stream = request.httpBodyStream else { return nil }
            stream.open()
            defer { stream.close() }
            var result = Data()
            var buf = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let n = stream.read(&buf, maxLength: buf.count)
                guard n > 0 else { break }
                result.append(contentsOf: buf.prefix(n))
            }
            return result.isEmpty ? nil : result
        }

        // MARK: - verifyMFA → success

        @Test func verifyMFAStoresAccessToken() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.mfaSuccessJSON()) }

            try await sut.verifyMFA(code: "123456", sessionToken: "sess-abc")

            #expect((try? keychain.load(forKey: .accessToken)) == "eyMFAAccess")
        }

        @Test func verifyMFAStoresRefreshToken() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.mfaSuccessJSON()) }

            try await sut.verifyMFA(code: "123456", sessionToken: "sess-abc")

            #expect((try? keychain.load(forKey: .refreshToken)) == "eyMFARefresh")
        }

        // MARK: - verifyMFA → failure

        @Test func verifyMFAWithWrongCodeThrowsUnauthorized() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 401), Data()) }

            await #expect(throws: APIError.unauthorized) {
                try await sut.verifyMFA(code: "000000", sessionToken: "sess")
            }
        }

        // MARK: - verifyMFA → lockout

        @Test func verifyMFALocksAfterFiveConsecutiveFailures() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 401), Data()) }

            // 5 failures — each increments the actor's counter
            for _ in 0..<5 {
                try? await sut.verifyMFA(code: "000000", sessionToken: "sess")
            }

            // 6th attempt must be rejected locally (not hitting the network)
            await #expect(throws: AuthError.mfaLocked) {
                try await sut.verifyMFA(code: "111111", sessionToken: "sess")
            }
        }

        @Test func verifyMFASuccessResetsFailureCount() async throws {
            // Use a response queue so success/failure interleave correctly
            let maxAttempts = AuthService.maxMFAAttempts  // 5
            var responses: [(Int, Data)] =
                Array(repeating: (401, Data()), count: maxAttempts - 1)  // 4 failures
                + [(200, mfaSuccessJSON())]                               // success → reset
                + Array(repeating: (401, Data()), count: maxAttempts - 1) // 4 more failures
                + [(200, mfaSuccessJSON())]                               // still not locked

            MockURLProtocol.requestHandler = { _ in
                let (code, data) = responses.removeFirst()
                return (self.makeHTTPResponse(statusCode: code), data)
            }
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let sut = AuthService(
                client: APIClient(session: URLSession(configuration: config)),
                keychain: keychain,
                baseURL: Self.baseURL
            )
            try? keychain.clearAll()

            // 4 failures
            for _ in 0..<(maxAttempts - 1) {
                try? await sut.verifyMFA(code: "000000", sessionToken: "sess")
            }
            // success → resets counter
            try await sut.verifyMFA(code: "999999", sessionToken: "sess")

            // 4 more failures
            for _ in 0..<(maxAttempts - 1) {
                try? await sut.verifyMFA(code: "000000", sessionToken: "sess")
            }
            // Should still be able to call (count is 4, not 5)
            try await sut.verifyMFA(code: "999999", sessionToken: "sess")
        }

        // MARK: - logout

        @Test func logoutClearsAccessToken() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON()) }
            _ = try await sut.login(email: "t@t.com", password: "Abc123!")

            try await sut.logout()

            #expect(throws: KeychainError.itemNotFound) { try keychain.load(forKey: .accessToken) }
        }

        @Test func logoutClearsRefreshToken() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON()) }
            _ = try await sut.login(email: "t@t.com", password: "Abc123!")

            try await sut.logout()

            #expect(throws: KeychainError.itemNotFound) { try keychain.load(forKey: .refreshToken) }
        }

        // MARK: - isAuthenticated

        @Test func isAuthenticatedTrueWhenAccessTokenExists() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), self.loginSuccessJSON()) }
            _ = try await sut.login(email: "t@t.com", password: "Abc123!")

            let result = await sut.isAuthenticated()

            #expect(result == true)
        }

        @Test func isAuthenticatedFalseWhenKeychainEmpty() async throws {
            let sut = makeService { _ in (self.makeHTTPResponse(statusCode: 200), Data()) }
            // Keychain cleared by makeService, no login called

            let result = await sut.isAuthenticated()

            #expect(result == false)
        }
    }
}
