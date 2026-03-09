import Foundation

/// URLProtocol subclass that intercepts all requests in a test URLSession.
///
/// Usage:
/// ```swift
/// let session = MockURLProtocol.makeSession { request in
///     let data = #"{"id":"1"}"#.data(using: .utf8)!
///     let response = HTTPURLResponse(url: request.url!, statusCode: 200,
///                                    httpVersion: nil, headerFields: nil)!
///     return (response, data)
/// }
/// let sut = APIClient(session: session)
/// ```
final class MockURLProtocol: URLProtocol {

    // Set before each test, cleared after.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    // MARK: - Factory

    /// Creates an ephemeral URLSession that routes all traffic through this mock.
    static func makeSession(
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> URLSession {
        requestHandler = handler
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
