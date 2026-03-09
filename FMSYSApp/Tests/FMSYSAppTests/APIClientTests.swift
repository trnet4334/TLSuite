import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite(.serialized)
    struct APIClientTests {

        private static let testURL = URL(string: "https://api.fmsys.io/test")!

        private struct Echo: Decodable, Equatable {
            let id: String
            let value: Int
        }

        // MARK: - Helpers

        private func makeClient(
            statusCode: Int,
            body: Data
        ) -> APIClient {
            let session = MockURLProtocol.makeSession { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, body)
            }
            return APIClient(session: session)
        }

        private func echoJSON(_ id: String = "abc", value: Int = 42) -> Data {
            #"{"id":"\#(id)","value":\#(value)}"#.data(using: .utf8)!
        }

        private func makeRequest(
            method: String = "GET",
            headers: [String: String] = [:]
        ) -> URLRequest {
            var r = URLRequest(url: Self.testURL)
            r.httpMethod = method
            for (k, v) in headers { r.setValue(v, forHTTPHeaderField: k) }
            return r
        }

        // MARK: - 2xx success

        @Test func successResponseDecodesBody() async throws {
            let sut = makeClient(statusCode: 200, body: echoJSON())
            let result: Echo = try await sut.send(makeRequest())
            #expect(result == Echo(id: "abc", value: 42))
        }

        @Test func status201AlsoDecodesBody() async throws {
            let sut = makeClient(statusCode: 201, body: echoJSON("created", value: 1))
            let result: Echo = try await sut.send(makeRequest())
            #expect(result == Echo(id: "created", value: 1))
        }

        // MARK: - 4xx errors

        @Test func status401ThrowsUnauthorized() async throws {
            let sut = makeClient(statusCode: 401, body: Data())
            await #expect(throws: APIError.unauthorized) {
                let _: Echo = try await sut.send(makeRequest())
            }
        }

        @Test func status403ThrowsHTTPError() async throws {
            let sut = makeClient(statusCode: 403, body: Data())
            await #expect(throws: APIError.httpError(statusCode: 403)) {
                let _: Echo = try await sut.send(makeRequest())
            }
        }

        @Test func status404ThrowsHTTPError() async throws {
            let sut = makeClient(statusCode: 404, body: Data())
            await #expect(throws: APIError.httpError(statusCode: 404)) {
                let _: Echo = try await sut.send(makeRequest())
            }
        }

        // MARK: - 5xx errors

        @Test func status500ThrowsHTTPError() async throws {
            let sut = makeClient(statusCode: 500, body: Data())
            await #expect(throws: APIError.httpError(statusCode: 500)) {
                let _: Echo = try await sut.send(makeRequest())
            }
        }

        @Test func status503ThrowsHTTPError() async throws {
            let sut = makeClient(statusCode: 503, body: Data())
            await #expect(throws: APIError.httpError(statusCode: 503)) {
                let _: Echo = try await sut.send(makeRequest())
            }
        }

        // MARK: - Decoding failure

        @Test func malformedJSONWithStatus200ThrowsDecodingError() async throws {
            let sut = makeClient(statusCode: 200, body: "not-json".data(using: .utf8)!)
            await #expect(throws: (any Error).self) {
                let _: Echo = try await sut.send(makeRequest())
            }
        }

        // MARK: - Network failure

        @Test func networkFailurePropagatesError() async throws {
            MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let sut = APIClient(session: URLSession(configuration: config))

            await #expect(throws: (any Error).self) {
                let _: Echo = try await sut.send(makeRequest())
            }
        }

        // MARK: - Request passthrough

        @Test func sendsRequestWithCorrectHTTPMethod() async throws {
            var capturedMethod: String?
            MockURLProtocol.requestHandler = { request in
                capturedMethod = request.httpMethod
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                               httpVersion: nil, headerFields: nil)!
                return (response, self.echoJSON())
            }
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let sut = APIClient(session: URLSession(configuration: config))

            let _: Echo = try await sut.send(makeRequest(method: "POST"))

            #expect(capturedMethod == "POST")
        }

        @Test func sendsCustomHeadersThrough() async throws {
            var capturedAuth: String?
            MockURLProtocol.requestHandler = { request in
                capturedAuth = request.value(forHTTPHeaderField: "Authorization")
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                               httpVersion: nil, headerFields: nil)!
                return (response, self.echoJSON())
            }
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let sut = APIClient(session: URLSession(configuration: config))

            let _: Echo = try await sut.send(
                makeRequest(headers: ["Authorization": "Bearer test-token"])
            )

            #expect(capturedAuth == "Bearer test-token")
        }
    }
}
