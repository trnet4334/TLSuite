import Foundation

public struct APIClient {

    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    // MARK: - send

    /// Executes `request`, checks the HTTP status code, and decodes the body as `T`.
    ///
    /// - Throws: `APIError.unauthorized` on 401.
    /// - Throws: `APIError.httpError(statusCode:)` on any other non-2xx status.
    /// - Throws: `APIError.invalidResponse` if the response is not an `HTTPURLResponse`.
    /// - Throws: A `DecodingError` if the body cannot be decoded as `T`.
    /// - Throws: Any `URLError` thrown by the underlying session (network failure, timeout, etc.).
    public func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.httpError(statusCode: http.statusCode)
        }
    }
}
