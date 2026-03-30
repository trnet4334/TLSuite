// Sources/FMSYSCore/Features/Auth/LocalAuthService.swift
import Foundation

/// Offline auth service using hardcoded recovery credentials.
/// Replace with real AuthService when backend is ready.
public actor LocalAuthService: AuthServiceProtocol {

    // MARK: - Recovery credentials (temporary)
    static let recoveryAccount  = "admin@fmsys.app"
    static let recoveryPassword = "fmsys2024"
    static let recoveryMFACode  = "123456"

    private let keychain: KeychainManager

    public init(keychain: KeychainManager = KeychainManager()) {
        self.keychain = keychain
    }

    // MARK: - AuthServiceProtocol

    public func login(email: String, password: String) async throws -> AuthResult {
        // Simulate brief network delay
        try await Task.sleep(nanoseconds: 400_000_000)

        guard email == Self.recoveryAccount, password == Self.recoveryPassword else {
            throw LocalAuthError.invalidCredentials
        }
        return .mfaRequired(sessionToken: "local-session-token", userId: "local-user")
    }

    public func verifyMFA(code: String, sessionToken: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard code == Self.recoveryMFACode else {
            throw LocalAuthError.invalidMFACode
        }
        try keychain.save("local-access-token",  forKey: .accessToken)
        try keychain.save("local-refresh-token", forKey: .refreshToken)
        try keychain.save("local-user",          forKey: .userId)
    }

    public func logout() async throws {
        try keychain.clearAll()
    }

    public func isAuthenticated() async -> Bool {
        (try? keychain.load(forKey: .accessToken)) != nil
    }
}

// MARK: - LocalAuthError

public enum LocalAuthError: LocalizedError {
    case invalidCredentials
    case invalidMFACode

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Incorrect account or password."
        case .invalidMFACode:     return "Invalid MFA code. Use 123456."
        }
    }
}
