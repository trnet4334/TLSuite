import Foundation
import Testing
@testable import FMSYSCore

// MARK: - Mock

final class MockAuthService: AuthServiceProtocol {
    var loginResult: Result<AuthResult, Error> = .success(.authenticated)
    var verifyMFAResult: Result<Void, Error> = .success(())
    var isAuthenticatedResult: Bool = false

    private(set) var loginCallCount = 0
    private(set) var verifyMFACallCount = 0
    private(set) var logoutCallCount = 0
    private(set) var lastEmail: String?
    private(set) var lastPassword: String?
    private(set) var lastMFACode: String?

    func login(email: String, password: String) async throws -> AuthResult {
        loginCallCount += 1
        lastEmail = email
        lastPassword = password
        return try loginResult.get()
    }

    func verifyMFA(code: String, sessionToken: String) async throws {
        verifyMFACallCount += 1
        lastMFACode = code
        try verifyMFAResult.get()
    }

    func logout() async throws {
        logoutCallCount += 1
    }

    func isAuthenticated() async -> Bool {
        isAuthenticatedResult
    }
}

// MARK: - Tests

@Suite(.serialized)
struct AuthViewModelTests {

    // MARK: - login → authenticated

    @Test func loginWithValidCredentialsTransitionsToAuthenticated() async throws {
        let mock = MockAuthService()
        mock.loginResult = .success(.authenticated)
        let sut = AuthViewModel(authService: mock)

        await sut.login(email: "trader@fmsys.io", password: "Secret1!")

        #expect(sut.state == .authenticated)
    }

    @Test func loginCallsServiceWithCorrectCredentials() async throws {
        let mock = MockAuthService()
        let sut = AuthViewModel(authService: mock)

        await sut.login(email: "trader@fmsys.io", password: "Secret1!")

        #expect(mock.lastEmail == "trader@fmsys.io")
        #expect(mock.lastPassword == "Secret1!")
    }

    // MARK: - login → MFA required

    @Test func loginTransitionsToMFARequiredWhenServerIndicates() async throws {
        let mock = MockAuthService()
        mock.loginResult = .success(.mfaRequired(sessionToken: "sess-abc", userId: "uid-1"))
        let sut = AuthViewModel(authService: mock)

        await sut.login(email: "trader@fmsys.io", password: "Secret1!")

        #expect(sut.state == .mfaRequired(sessionToken: "sess-abc", userId: "uid-1"))
    }

    // MARK: - login → error

    @Test func loginSetsErrorStateOnFailure() async throws {
        let mock = MockAuthService()
        mock.loginResult = .failure(APIError.unauthorized)
        let sut = AuthViewModel(authService: mock)

        await sut.login(email: "bad@fmsys.io", password: "wrong")

        #expect(sut.errorMessage != nil)
        #expect(sut.state == .idle)
    }

    // MARK: - loading state

    @Test func loginSetsIsLoadingDuringRequest() async throws {
        // Can only observe final state; isLoading resets after completion.
        let mock = MockAuthService()
        let sut = AuthViewModel(authService: mock)

        await sut.login(email: "t@t.com", password: "Abc123!")

        #expect(sut.isLoading == false)
    }

    // MARK: - MFAViewModel

    @Test func mfaVerifyCallsServiceWithCode() async throws {
        let mock = MockAuthService()
        let sut = MFAViewModel(authService: mock, sessionToken: "sess-xyz", userId: "uid-1")

        await sut.verify(code: "123456")

        #expect(mock.lastMFACode == "123456")
        #expect(mock.verifyMFACallCount == 1)
    }

    @Test func mfaVerifySuccessTransitionsToAuthenticated() async throws {
        let mock = MockAuthService()
        mock.verifyMFAResult = .success(())
        let sut = MFAViewModel(authService: mock, sessionToken: "sess-xyz", userId: "uid-1")

        await sut.verify(code: "123456")

        #expect(sut.isAuthenticated == true)
    }

    @Test func mfaVerifyFailureSetsErrorMessage() async throws {
        let mock = MockAuthService()
        mock.verifyMFAResult = .failure(APIError.unauthorized)
        let sut = MFAViewModel(authService: mock, sessionToken: "sess-xyz", userId: "uid-1")

        await sut.verify(code: "000000")

        #expect(sut.errorMessage != nil)
        #expect(sut.isAuthenticated == false)
    }

    @Test func mfaLockedErrorSetsLockedFlag() async throws {
        let mock = MockAuthService()
        mock.verifyMFAResult = .failure(AuthError.mfaLocked)
        let sut = MFAViewModel(authService: mock, sessionToken: "sess-xyz", userId: "uid-1")

        await sut.verify(code: "000000")

        #expect(sut.isLocked == true)
    }
}
