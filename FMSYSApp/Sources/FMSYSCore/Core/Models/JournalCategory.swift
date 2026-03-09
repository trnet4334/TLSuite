import Foundation

public enum JournalCategory: String, Codable, CaseIterable, Hashable {
    case all        = "All"
    case stocksETFs = "Stocks/ETFs"
    case forex      = "Forex"
    case crypto     = "Crypto"
    case options    = "Options"
}
