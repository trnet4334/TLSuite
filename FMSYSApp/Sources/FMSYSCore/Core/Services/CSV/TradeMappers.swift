// Sources/FMSYSCore/Core/Services/CSV/TradeMappers.swift
import Foundation

public enum CSVMappingError: Error, LocalizedError {
    case missingRequiredField(String)
    case invalidNumber(String)
    case invalidDate(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredField(let f): return "Missing required field: \(f)"
        case .invalidNumber(let v):        return "Invalid number: \(v)"
        case .invalidDate(let v):          return "Invalid date: \(v)"
        }
    }
}

// MARK: - Shared helpers

private let dateFormatters: [DateFormatter] = {
    ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy"].map {
        let f = DateFormatter()
        f.dateFormat = $0
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }
}()

func parseDate(_ str: String) throws -> Date {
    for f in dateFormatters {
        if let d = f.date(from: str) { return d }
    }
    throw CSVMappingError.invalidDate(str)
}

func parseDouble(_ str: String) throws -> Double {
    let cleaned = str.replacingOccurrences(of: "[,$]", with: "", options: .regularExpression)
    guard let d = Double(cleaned) else { throw CSVMappingError.invalidNumber(str) }
    return d
}

func required(_ row: [String: String], _ key: String) throws -> String {
    guard let v = row[key], !v.isEmpty else { throw CSVMappingError.missingRequiredField(key) }
    return v
}

// MARK: - Generic mapper (our own format)

public struct GenericTradeMapper {
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let symbol    = try required(row, "symbol")
        let price     = try parseDouble(try required(row, "entryPrice"))
        let date      = try parseDate(try required(row, "entryTime"))
        let dirStr    = row["direction"] ?? "long"
        let direction = Direction(rawValue: dirStr.lowercased()) ?? .long
        let size      = try parseDouble(try required(row, "positionSize"))
        let sl        = (try? parseDouble(row["stopLoss"] ?? "")) ?? 0
        let tp        = (try? parseDouble(row["takeProfit"] ?? "")) ?? 0
        let exitPrice = row["exitPrice"].flatMap { try? parseDouble($0) }
        let catStr    = row["category"] ?? "Stocks/ETFs"
        let category  = JournalCategory(rawValue: catStr) ?? .stocksETFs

        return Trade(
            userId: userId, asset: symbol,
            assetCategory: category.assetCategory,
            direction: direction,
            entryPrice: price, stopLoss: sl, takeProfit: tp,
            positionSize: size, entryAt: date,
            exitPrice: exitPrice,
            notes: row["notes"],
            journalCategory: category
        )
    }
}

// MARK: - IBKR mapper

public struct IBKRTradeMapper {
    // IBKR columns: Symbol, Quantity, T. Price, C. Price, Proceeds, Comm/Fee, Date/Time
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let symbol    = try required(row, "Symbol")
        let price     = try parseDouble(try required(row, "T. Price"))
        let date      = try parseDate(try required(row, "Date/Time"))
        let qty       = try parseDouble(try required(row, "Quantity"))
        let direction: Direction = qty >= 0 ? .long : .short

        return Trade(
            userId: userId, asset: symbol,
            assetCategory: .stocks,
            direction: direction,
            entryPrice: price, stopLoss: 0, takeProfit: 0,
            positionSize: abs(qty), entryAt: date,
            journalCategory: .stocksETFs
        )
    }
}

// MARK: - Binance mapper

public struct BinanceTradeMapper {
    // Binance columns: Date(UTC), Pair, Side, Price, Executed, Amount, Fee
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let pair      = try required(row, "Pair")
        let price     = try parseDouble(try required(row, "Price"))
        let date      = try parseDate(try required(row, "Date(UTC)"))
        let sideStr   = try required(row, "Side")
        let direction: Direction = sideStr.uppercased() == "BUY" ? .long : .short
        let qty       = try parseDouble(try required(row, "Executed"))

        return Trade(
            userId: userId, asset: pair,
            assetCategory: .crypto,
            direction: direction,
            entryPrice: price, stopLoss: 0, takeProfit: 0,
            positionSize: qty, entryAt: date,
            journalCategory: .crypto
        )
    }
}

// MARK: - TD Ameritrade mapper

public struct TDTradeMapper {
    // TD columns: Symbol, Qty, Price, Gross Amount, Reg Fee, Net Amount, Date
    public static func map(row: [String: String], userId: String) throws -> Trade {
        let symbol    = try required(row, "Symbol")
        let price     = try parseDouble(try required(row, "Price"))
        let date      = try parseDate(try required(row, "Date"))
        let qty       = try parseDouble(try required(row, "Qty"))
        let direction: Direction = qty >= 0 ? .long : .short

        return Trade(
            userId: userId, asset: symbol,
            assetCategory: .stocks,
            direction: direction,
            entryPrice: price, stopLoss: 0, takeProfit: 0,
            positionSize: abs(qty), entryAt: date,
            journalCategory: .stocksETFs
        )
    }
}
