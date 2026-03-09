import Foundation
import Observation

@Observable
public final class AppState {

    public var isAuthenticated: Bool

    private let keychain: KeychainManager

    public init(keychain: KeychainManager = KeychainManager()) {
        self.keychain = keychain
        self.isAuthenticated = (try? keychain.load(forKey: .accessToken)) != nil
    }

    public func markAuthenticated() {
        isAuthenticated = true
    }

    public func markLoggedOut() {
        isAuthenticated = false
    }
}
