import Foundation

/// Abstraction over AuthService that enables ViewModel testing with mocks.
public protocol AuthServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> AuthResult
    func verifyMFA(code: String, sessionToken: String) async throws
    func logout() async throws
    func isAuthenticated() async -> Bool
}

// Make the actor conform automatically
extension AuthService: AuthServiceProtocol {}
