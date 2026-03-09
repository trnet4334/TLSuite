import Foundation
import Observation

@Observable
public final class MFAViewModel {

    public var isAuthenticated: Bool = false
    public var isLoading: Bool = false
    public var isLocked: Bool = false
    public var errorMessage: String?

    public let sessionToken: String
    public let userId: String

    private let authService: any AuthServiceProtocol

    public init(authService: any AuthServiceProtocol, sessionToken: String, userId: String) {
        self.authService = authService
        self.sessionToken = sessionToken
        self.userId = userId
    }

    public func verify(code: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.verifyMFA(code: code, sessionToken: sessionToken)
            isAuthenticated = true
        } catch AuthError.mfaLocked {
            isLocked = true
            errorMessage = "Too many attempts. Session locked."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
