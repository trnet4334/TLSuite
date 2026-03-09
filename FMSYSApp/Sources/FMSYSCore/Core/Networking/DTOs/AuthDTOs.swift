import Foundation

// MARK: - Login

public struct LoginRequest: Encodable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }

    // Server expects snake_case; these keys happen to be single words, so
    // CodingKeys isn't strictly required — but explicit is always safer.
    enum CodingKeys: String, CodingKey {
        case email
        case password
    }
}

public struct LoginResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String
    public let userId: String
    public let requiresMFA: Bool
    /// Present only when `requiresMFA == true`; used as the session token for MFA verification.
    public let sessionToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case userId       = "user_id"
        case requiresMFA  = "requires_mfa"
        case sessionToken = "session_token"
    }
}

// MARK: - MFA

public struct MFAVerifyRequest: Encodable {
    public let code: String
    public let sessionToken: String

    public init(code: String, sessionToken: String) {
        self.code = code
        self.sessionToken = sessionToken
    }

    enum CodingKeys: String, CodingKey {
        case code
        case sessionToken = "session_token"
    }
}

public struct MFAVerifyResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
    }
}

// MARK: - Token Refresh

public struct RefreshTokenRequest: Encodable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

public struct RefreshTokenResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
    }
}

// MARK: - Error

public struct AuthErrorResponse: Decodable {
    public let error: String
    public let message: String?
}
