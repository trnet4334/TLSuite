import Foundation
import Observation

// MARK: - AuthViewState

public enum AuthViewState: Equatable {
    case idle
    case authenticated
    case mfaRequired(sessionToken: String, userId: String)
}

// MARK: - AuthViewModel

@Observable
public final class AuthViewModel {

    public var state: AuthViewState = .idle
    public var isLoading: Bool = false
    public var errorMessage: String?

    private let authService: any AuthServiceProtocol

    public init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    public func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await authService.login(email: email, password: password)
            switch result {
            case .authenticated:
                state = .authenticated
            case .mfaRequired(let sessionToken, let userId):
                state = .mfaRequired(sessionToken: sessionToken, userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
            state = .idle
        }
    }

    public func logout() {
        Task { try? await authService.logout() }
        state = .idle
    }
}
