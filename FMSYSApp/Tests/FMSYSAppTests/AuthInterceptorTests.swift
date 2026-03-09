import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    struct AuthInterceptorTests {

        // MARK: - Shared fixtures

        private let keychain = KeychainManager()
        private static let testURL = URL(string: "https://api.fmsys.io/v1/test")!

        private struct Echo: Decodable, Equatable { let id: String }

        private func echoJSON(_ id: String = "ok") -> Data {
            #"{"id":"\#(id)"}"#.data(using: .utf8)!
        }

        private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
            HTTPURLResponse(url: Self.testURL, statusCode: statusCode,
                            httpVersion: nil, headerFields: nil)!
        }

        private func makeSession(
            _ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
        ) -> URLSession {
            MockURLProtocol.requestHandler = handler
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            return URLSession(configuration: config)
        }

        /// Clears the Keychain, then builds a fully-wired AuthInterceptor.
        /// Callers that need tokens in the Keychain must save them AFTER calling this.
        private func makeInterceptor(
            session: URLSession,
            refreshResult: Result<(accessToken: String, refreshToken: String), Error> = .success(
                (accessToken: "new-access", refreshToken: "new-refresh")
            )
        ) -> AuthInterceptor {
            try? keychain.clearAll()
            let client = APIClient(session: session)
            return AuthInterceptor(
                keychain: keychain,
                client: client,
                refreshTokenCall: { _ in
                    switch refreshResult {
                    case .success(let tokens): return tokens
                    case .failure(let error): throw error
                    }
                }
            )
        }

        // MARK: - Token injection

        @Test func injectsAccessTokenAsBearerHeader() async throws {
            var capturedAuth: String?
            let session = makeSession { request in
                capturedAuth = request.value(forHTTPHeaderField: "Authorization")
                return (self.makeHTTPResponse(statusCode: 200), self.echoJSON())
            }
            let sut = makeInterceptor(session: session)
            // Save AFTER makeInterceptor (which calls clearAll)
            try keychain.save("my-access-token", forKey: .accessToken)

            let _: Echo = try await sut.send(URLRequest(url: Self.testURL))

            #expect(capturedAuth == "Bearer my-access-token")
        }

        @Test func doesNotInjectAuthorizationWhenKeychainEmpty() async throws {
            var capturedAuth: String?
            let session = makeSession { request in
                capturedAuth = request.value(forHTTPHeaderField: "Authorization")
                return (self.makeHTTPResponse(statusCode: 200), self.echoJSON())
            }
            let sut = makeInterceptor(session: session)
            // No token saved — Keychain is empty

            let _: Echo = try await sut.send(URLRequest(url: Self.testURL))

            #expect(capturedAuth == nil)
        }

        // MARK: - Successful passthrough

        @Test func successResponsePassesThrough() async throws {
            let session = makeSession { _ in
                (self.makeHTTPResponse(statusCode: 200), self.echoJSON("pass"))
            }
            let sut = makeInterceptor(session: session)

            let result: Echo = try await sut.send(URLRequest(url: Self.testURL))

            #expect(result.id == "pass")
        }

        // MARK: - 401 → refresh → retry

        @Test func on401RefreshesTokenAndRetries() async throws {
            var callCount = 0
            let session = makeSession { _ in
                callCount += 1
                let code = callCount == 1 ? 401 : 200
                return (self.makeHTTPResponse(statusCode: code), self.echoJSON("retried"))
            }
            let sut = makeInterceptor(session: session)
            // Need a refresh token so the refresh call is attempted
            try keychain.save("old-refresh", forKey: .refreshToken)

            let result: Echo = try await sut.send(URLRequest(url: Self.testURL))

            #expect(result.id == "retried")
            #expect(callCount == 2)
        }

        @Test func on401StoresNewAccessTokenInKeychain() async throws {
            var callCount = 0
            let session = makeSession { _ in
                callCount += 1
                let code = callCount == 1 ? 401 : 200
                return (self.makeHTTPResponse(statusCode: code), self.echoJSON())
            }
            let sut = makeInterceptor(
                session: session,
                refreshResult: .success((accessToken: "fresh-access", refreshToken: "fresh-refresh"))
            )
            try keychain.save("old-refresh", forKey: .refreshToken)

            let _: Echo = try await sut.send(URLRequest(url: Self.testURL))

            #expect((try? keychain.load(forKey: .accessToken)) == "fresh-access")
        }

        @Test func on401StoresNewRefreshTokenInKeychain() async throws {
            var callCount = 0
            let session = makeSession { _ in
                callCount += 1
                let code = callCount == 1 ? 401 : 200
                return (self.makeHTTPResponse(statusCode: code), self.echoJSON())
            }
            let sut = makeInterceptor(
                session: session,
                refreshResult: .success((accessToken: "fresh-access", refreshToken: "fresh-refresh"))
            )
            try keychain.save("old-refresh", forKey: .refreshToken)

            let _: Echo = try await sut.send(URLRequest(url: Self.testURL))

            #expect((try? keychain.load(forKey: .refreshToken)) == "fresh-refresh")
        }

        @Test func on401RetriedRequestUsesNewBearerToken() async throws {
            var capturedAuthOnRetry: String?
            var callCount = 0
            let session = makeSession { request in
                callCount += 1
                if callCount == 1 {
                    return (self.makeHTTPResponse(statusCode: 401), Data())
                } else {
                    capturedAuthOnRetry = request.value(forHTTPHeaderField: "Authorization")
                    return (self.makeHTTPResponse(statusCode: 200), self.echoJSON())
                }
            }
            let sut = makeInterceptor(
                session: session,
                refreshResult: .success((accessToken: "brand-new-token", refreshToken: "r"))
            )
            try keychain.save("old-refresh", forKey: .refreshToken)

            let _: Echo = try await sut.send(URLRequest(url: Self.testURL))

            #expect(capturedAuthOnRetry == "Bearer brand-new-token")
        }

        // MARK: - 401 failure paths

        @Test func on401WithNoRefreshTokenInKeychainThrowsUnauthorized() async throws {
            let session = makeSession { _ in
                (self.makeHTTPResponse(statusCode: 401), Data())
            }
            let sut = makeInterceptor(session: session)
            // Keychain is empty — no refresh token

            await #expect(throws: APIError.unauthorized) {
                let _: Echo = try await sut.send(URLRequest(url: Self.testURL))
            }
        }

        @Test func on401RefreshCallFailurePropagatesError() async throws {
            let session = makeSession { _ in
                (self.makeHTTPResponse(statusCode: 401), Data())
            }
            let sut = makeInterceptor(
                session: session,
                refreshResult: .failure(APIError.httpError(statusCode: 503))
            )
            try keychain.save("old-refresh", forKey: .refreshToken)

            await #expect(throws: APIError.httpError(statusCode: 503)) {
                let _: Echo = try await sut.send(URLRequest(url: Self.testURL))
            }
        }

        @Test func on401RetryAlso401ThrowsWithoutInfiniteLoop() async throws {
            // Both attempts return 401 — interceptor must not recurse.
            let session = makeSession { _ in
                (self.makeHTTPResponse(statusCode: 401), Data())
            }
            let sut = makeInterceptor(session: session)
            try keychain.save("stale-refresh", forKey: .refreshToken)

            await #expect(throws: APIError.unauthorized) {
                let _: Echo = try await sut.send(URLRequest(url: Self.testURL))
            }
        }
    }
}
