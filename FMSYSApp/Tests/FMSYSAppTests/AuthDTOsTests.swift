import Foundation
import Testing
@testable import FMSYSCore

// Pure Codable round-trip tests — no networking, no async.
// Server uses snake_case JSON; Swift structs use camelCase.
struct AuthDTOsTests {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys  // deterministic output for assertions
        return e
    }()

    private let decoder = JSONDecoder()

    // MARK: - LoginRequest (Encodable)

    @Test func loginRequestEncodesEmailAndPassword() throws {
        let request = LoginRequest(email: "trader@fmsys.io", password: "Secret1!")
        let json = try encoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: json) as! [String: String]

        #expect(dict["email"] == "trader@fmsys.io")
        #expect(dict["password"] == "Secret1!")
    }

    @Test func loginRequestUsesSnakeCaseKeys() throws {
        // Ensures we don't accidentally send camelCase to the server.
        let request = LoginRequest(email: "a@b.com", password: "Abc123!")
        let json = try encoder.encode(request)
        let raw = String(data: json, encoding: .utf8)!

        #expect(raw.contains("\"email\""))
        #expect(raw.contains("\"password\""))
        // No camelCase keys in this DTO — both fields are single words.
    }

    // MARK: - LoginResponse (Decodable)

    @Test func loginResponseDecodesAllFields() throws {
        let json = """
        {
            "access_token": "eyAccess",
            "refresh_token": "eyRefresh",
            "user_id": "uuid-1234",
            "requires_mfa": false
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(LoginResponse.self, from: json)

        #expect(response.accessToken == "eyAccess")
        #expect(response.refreshToken == "eyRefresh")
        #expect(response.userId == "uuid-1234")
        #expect(response.requiresMFA == false)
    }

    @Test func loginResponseDecodesMFARequired() throws {
        let json = """
        {
            "access_token": "",
            "refresh_token": "",
            "user_id": "uuid-5678",
            "requires_mfa": true
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(LoginResponse.self, from: json)

        #expect(response.requiresMFA == true)
        #expect(response.userId == "uuid-5678")
    }

    @Test func loginResponseThrowsWhenRequiredFieldMissing() {
        let json = """
        {
            "access_token": "eyAccess",
            "refresh_token": "eyRefresh"
        }
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try self.decoder.decode(LoginResponse.self, from: json)
        }
    }

    // MARK: - MFAVerifyRequest (Encodable)

    @Test func mfaVerifyRequestEncodesCodeAndSessionToken() throws {
        let request = MFAVerifyRequest(code: "123456", sessionToken: "sess-abc")
        let json = try encoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: json) as! [String: String]

        #expect(dict["code"] == "123456")
        #expect(dict["session_token"] == "sess-abc")
    }

    @Test func mfaVerifyRequestUsesSnakeCaseForSessionToken() throws {
        let request = MFAVerifyRequest(code: "000000", sessionToken: "tok")
        let json = try encoder.encode(request)
        let raw = String(data: json, encoding: .utf8)!

        #expect(raw.contains("\"session_token\""))
        #expect(!raw.contains("\"sessionToken\""))
    }

    // MARK: - MFAVerifyResponse (Decodable)

    @Test func mfaVerifyResponseDecodesTokens() throws {
        let json = """
        {
            "access_token": "eyMFAAccess",
            "refresh_token": "eyMFARefresh"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(MFAVerifyResponse.self, from: json)

        #expect(response.accessToken == "eyMFAAccess")
        #expect(response.refreshToken == "eyMFARefresh")
    }

    // MARK: - RefreshTokenRequest (Encodable)

    @Test func refreshTokenRequestEncodesRefreshToken() throws {
        let request = RefreshTokenRequest(refreshToken: "eyOldRefresh")
        let json = try encoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: json) as! [String: String]

        #expect(dict["refresh_token"] == "eyOldRefresh")
    }

    @Test func refreshTokenRequestUsesSnakeCaseKey() throws {
        let request = RefreshTokenRequest(refreshToken: "tok")
        let json = try encoder.encode(request)
        let raw = String(data: json, encoding: .utf8)!

        #expect(raw.contains("\"refresh_token\""))
        #expect(!raw.contains("\"refreshToken\""))
    }

    // MARK: - RefreshTokenResponse (Decodable)

    @Test func refreshTokenResponseDecodesTokens() throws {
        let json = """
        {
            "access_token": "eyNewAccess",
            "refresh_token": "eyNewRefresh"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(RefreshTokenResponse.self, from: json)

        #expect(response.accessToken == "eyNewAccess")
        #expect(response.refreshToken == "eyNewRefresh")
    }

    // MARK: - AuthErrorResponse (Decodable)

    @Test func authErrorResponseDecodesWithMessage() throws {
        let json = """
        {
            "error": "invalid_credentials",
            "message": "Email or password is incorrect."
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AuthErrorResponse.self, from: json)

        #expect(response.error == "invalid_credentials")
        #expect(response.message == "Email or password is incorrect.")
    }

    @Test func authErrorResponseDecodesWithoutMessage() throws {
        // message is optional — server may omit it
        let json = """
        {
            "error": "mfa_required"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AuthErrorResponse.self, from: json)

        #expect(response.error == "mfa_required")
        #expect(response.message == nil)
    }

    @Test func authErrorResponseThrowsWhenErrorKeyMissing() {
        let json = """
        { "message": "Something went wrong." }
        """.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try self.decoder.decode(AuthErrorResponse.self, from: json)
        }
    }

    // MARK: - LoginResponse.sessionToken (MFA challenge field)

    @Test func loginResponseDecodesSessionTokenWhenPresent() throws {
        let json = """
        {
            "access_token": "",
            "refresh_token": "",
            "user_id": "uid-456",
            "requires_mfa": true,
            "session_token": "sess-abc"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(LoginResponse.self, from: json)

        #expect(response.sessionToken == "sess-abc")
    }

    @Test func loginResponseSessionTokenIsNilWhenAbsent() throws {
        let json = """
        {
            "access_token": "tok",
            "refresh_token": "ref",
            "user_id": "uid-123",
            "requires_mfa": false
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(LoginResponse.self, from: json)

        #expect(response.sessionToken == nil)
    }
}
