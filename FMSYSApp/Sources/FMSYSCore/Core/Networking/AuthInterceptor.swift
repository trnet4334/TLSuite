import Foundation

/// Wraps `APIClient.send` with automatic Bearer-token injection and a single
/// silent refresh+retry on 401 Unauthorized.
///
/// The `refreshTokenCall` closure is injected at init time so callers (and
/// tests) can swap out the network implementation without touching this type.
public struct AuthInterceptor {

    private let keychain: KeychainManager
    private let client: APIClient
    private let refreshTokenCall:
        (_ refreshToken: String) async throws -> (accessToken: String, refreshToken: String)

    public init(
        keychain: KeychainManager,
        client: APIClient,
        refreshTokenCall: @escaping (_ refreshToken: String)
            async throws -> (accessToken: String, refreshToken: String)
    ) {
        self.keychain = keychain
        self.client = client
        self.refreshTokenCall = refreshTokenCall
    }

    // MARK: - send

    /// Executes `request` with an injected Bearer token.
    /// On a 401 response it attempts one silent token refresh, then retries.
    public func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let adapted = injectToken(into: request)

        do {
            return try await client.send(adapted)
        } catch APIError.unauthorized {
            return try await refreshAndRetry(original: request)
        }
    }

    // MARK: - Private helpers

    private func injectToken(into request: URLRequest) -> URLRequest {
        guard let token = try? keychain.load(forKey: .accessToken) else { return request }
        var r = request
        r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return r
    }

    private func refreshAndRetry<T: Decodable>(original: URLRequest) async throws -> T {
        guard let storedRefresh = try? keychain.load(forKey: .refreshToken) else {
            throw APIError.unauthorized
        }

        // Call the refresh endpoint — may throw (network error, 4xx, etc.)
        let tokens = try await refreshTokenCall(storedRefresh)

        // Persist the new token pair
        try keychain.save(tokens.accessToken, forKey: .accessToken)
        try keychain.save(tokens.refreshToken, forKey: .refreshToken)

        // Retry once with the fresh access token — does NOT recurse into send()
        // so a second 401 on the retry propagates directly without looping.
        var retried = original
        retried.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        return try await client.send(retried)
    }
}
