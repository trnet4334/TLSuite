// Sources/FMSYSCore/Core/Services/CSV/CSVImportService.swift
import Foundation

public struct CSVImportResult {
    public let trades: [Trade]
    public let failedRows: [(rowIndex: Int, error: Error)]
    public let detectedFormat: BrokerFormat
    public let requiresMapping: Bool   // true if format == .unknown
}

public struct CSVImportService {

    private let userId: String

    public init(userId: String = "current-user") {
        self.userId = userId
    }

    /// Phase 1: Detect format and parse rows.
    /// Returns `requiresMapping = true` if the format is .unknown — caller shows ColumnMappingSheet.
    public func analyze(csvText: String) -> (format: BrokerFormat, headers: [String], preview: [[String]]) {
        let headers = CSVParser.headers(from: csvText)
        let format  = BrokerFormatDetector.detect(headers: headers)
        let preview = CSVParser.preview(text: csvText, maxRows: 3)
        return (format, headers, preview)
    }

    /// Phase 2: Map rows to Trade objects using the detected (or user-supplied) format.
    /// `sourceLabel` is stored on every imported trade (e.g. "CSV: ibkr-trades.csv").
    public func map(csvText: String, format: BrokerFormat, columnMapping: [String: String] = [:], sourceLabel: String = "") -> CSVImportResult {
        let rows = CSVParser.parse(csvText)
        var trades: [Trade] = []
        var failed: [(Int, Error)] = []

        for (idx, var row) in rows.enumerated() {
            // Apply user-provided column mapping (renames CSV keys to expected keys)
            if !columnMapping.isEmpty {
                var remapped: [String: String] = [:]
                for (csvKey, tradeKey) in columnMapping {
                    if let val = row[csvKey] { remapped[tradeKey] = val }
                }
                row = remapped
            }

            do {
                let trade: Trade
                switch format {
                case .ibkr:          trade = try IBKRTradeMapper.map(row: row, userId: userId)
                case .tdAmeritrade:  trade = try TDTradeMapper.map(row: row, userId: userId)
                case .binance:       trade = try BinanceTradeMapper.map(row: row, userId: userId)
                case .generic, .unknown:
                    trade = try GenericTradeMapper.map(row: row, userId: userId)
                }
                if !sourceLabel.isEmpty { trade.dataSource = sourceLabel }
                trades.append(trade)
            } catch {
                failed.append((idx + 2, error))   // +2: 1-indexed, skip header
            }
        }

        return CSVImportResult(
            trades: trades,
            failedRows: failed,
            detectedFormat: format,
            requiresMapping: format == .unknown
        )
    }
}
