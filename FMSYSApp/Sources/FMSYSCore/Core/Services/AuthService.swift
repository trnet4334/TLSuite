import Foundation

// MARK: - AuthResult

public enum AuthResult: Equatable {
    case authenticated
    case mfaRequired(sessionToken: String, userId: String)
}

// MARK: - AuthError

public enum AuthError: Error, Equatable {
    /// Thrown when MFA verification is attempted after too many consecutive failures.
    case mfaLocked
}

// MARK: - AuthService

/// Orchestrates the full authentication lifecycle:
/// login → (MFA verification) → session storage → logout.
///
/// Declared as `actor` so MFA failure counting is race-free.
public actor AuthService {

    private let client: APIClient
    private let keychain: KeychainManager
    private let baseURL: URL

    private var mfaFailureCount = 0

    /// Number of consecutive MFA failures before the session is locally locked.
    public static let maxMFAAttempts = 5

    public init(client: APIClient, keychain: KeychainManager, baseURL: URL) {
        self.client = client
        self.keychain = keychain
        self.baseURL = baseURL
    }

    // MARK: - login

    /// Submits credentials to the login endpoint.
    ///
    /// - Returns: `.authenticated` if the server issued tokens, or
    ///   `.mfaRequired(sessionToken:userId:)` if a second factor is needed.
    /// - Throws: `APIError` on network or HTTP errors.
    public func login(email: String, password: String) async throws -> AuthResult {
        let body = LoginRequest(email: email, password: password)
        let request = try buildRequest(path: "auth/login", method: "POST", body: body)

        let response: LoginResponse = try await client.send(request)

        if response.requiresMFA {
            let sessionToken = response.sessionToken ?? response.userId
            return .mfaRequired(sessionToken: sessionToken, userId: response.userId)
        }

        try keychain.save(response.accessToken, forKey: .accessToken)
        try keychain.save(response.refreshToken, forKey: .refreshToken)
        try keychain.save(response.userId, forKey: .userId)
        return .authenticated
    }

    // MARK: - verifyMFA

    /// Submits a one-time password to complete MFA.
    ///
    /// - Throws: `AuthError.mfaLocked` after `maxMFAAttempts` consecutive failures.
    /// - Throws: `APIError` on network or HTTP errors.
    public func verifyMFA(code: String, sessionToken: String) async throws {
        guard mfaFailureCount < AuthService.maxMFAAttempts else {
            throw AuthError.mfaLocked
        }

        let body = MFAVerifyRequest(code: code, sessionToken: sessionToken)
        let request = try buildRequest(path: "auth/mfa/verify", method: "POST", body: body)

        do {
            let response: MFAVerifyResponse = try await client.send(request)
            mfaFailureCount = 0
            try keychain.save(response.accessToken, forKey: .accessToken)
            try keychain.save(response.refreshToken, forKey: .refreshToken)
        } catch {
            mfaFailureCount += 1
            throw error
        }
    }

    // MARK: - logout

    /// Removes all stored credentials from the Keychain.
    public func logout() async throws {
        try keychain.clearAll()
    }

    // MARK: - isAuthenticated

    /// Returns `true` if an access token is present in the Keychain.
    public func isAuthenticated() -> Bool {
        (try? keychain.load(forKey: .accessToken)) != nil
    }

    // MARK: - Private

    private func buildRequest<T: Encodable>(
        path: String,
        method: String,
        body: T
    ) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
}
