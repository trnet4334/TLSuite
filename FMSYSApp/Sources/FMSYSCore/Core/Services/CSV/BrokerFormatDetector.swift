// Sources/FMSYSCore/Core/Services/CSV/BrokerFormatDetector.swift
import Foundation

public enum BrokerFormat: Equatable {
    case ibkr
    case tdAmeritrade
    case binance
    case generic
    case unknown
}

public struct BrokerFormatDetector {

    private static let ibkrSignature    = Set(["Symbol", "T. Price", "Proceeds", "Comm/Fee"])
    private static let tdSignature      = Set(["Symbol", "Qty", "Price", "Gross Amount", "Reg Fee"])
    private static let binanceSignature = Set(["Date(UTC)", "Pair", "Side", "Executed", "Fee"])
    private static let genericRequired  = Set(["symbol", "entryPrice", "entryTime"])

    public static func detect(headers: [String]) -> BrokerFormat {
        let headerSet = Set(headers)
        if ibkrSignature.isSubset(of: headerSet)    { return .ibkr }
        if tdSignature.isSubset(of: headerSet)      { return .tdAmeritrade }
        if binanceSignature.isSubset(of: headerSet) { return .binance }
        if genericRequired.isSubset(of: headerSet)  { return .generic }
        return .unknown
    }
}
