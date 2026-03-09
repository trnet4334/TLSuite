import Foundation

public enum APIError: Error, Equatable {
    case unauthorized               // 401
    case httpError(statusCode: Int) // all other non-2xx
    case invalidResponse            // response is not HTTPURLResponse
}
