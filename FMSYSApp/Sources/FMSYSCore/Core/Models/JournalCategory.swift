import Foundation

public enum JournalCategory: String, Codable, CaseIterable, Hashable {
    case all        = "All"
    case stocksETFs = "Stocks/ETFs"
    case forex      = "Forex"
    case crypto     = "Crypto"
    case options    = "Options"

    public var assetCategory: AssetCategory {
        switch self {
        case .stocksETFs, .all: return .stocks
        case .forex:            return .forex
        case .crypto:           return .crypto
        case .options:          return .options
        }
    }
}
