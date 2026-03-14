import Foundation
import Observation

@Observable
public final class AppState {

    public var isAuthenticated: Bool

    // User profile — populated from auth response when available; placeholders until then
    public var userDisplayName: String = "Trading Desk"
    public var userEmail: String = "trader@fmsys.app"
    public var userRole: String = "Trader"

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
