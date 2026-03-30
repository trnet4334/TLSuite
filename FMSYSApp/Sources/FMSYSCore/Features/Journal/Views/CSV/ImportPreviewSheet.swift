// Sources/FMSYSCore/Features/Journal/Views/CSV/ImportPreviewSheet.swift
import SwiftUI

public struct ImportPreviewSheet: View {
    @Environment(LanguageManager.self) private var lang

    let result: CSVImportResult
    let onConfirm: () -> Void
    let onCancel: () -> Void

    public init(result: CSVImportResult, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.result = result
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("journal.csv.preview_title", bundle: lang.bundle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text(String(format: String(localized: "journal.csv.preview_subtitle", bundle: lang.bundle), formatLabel, result.trades.count, result.failedRows.count))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Button(String(localized: "common.cancel", bundle: lang.bundle), action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)

            Divider().overlay(Color.fmsBorder)

            // Preview table (first 5 trades)
            VStack(spacing: 0) {
                HStack {
                    Text("journal.csv.col.symbol", bundle: lang.bundle).frame(width: 80, alignment: .leading)
                    Text("journal.csv.col.direction", bundle: lang.bundle).frame(width: 80, alignment: .leading)
                    Text("journal.csv.col.entry", bundle: lang.bundle).frame(width: 100, alignment: .trailing)
                    Text("journal.csv.col.size", bundle: lang.bundle).frame(width: 80, alignment: .trailing)
                    Text("journal.csv.col.date", bundle: lang.bundle).frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().overlay(Color.fmsBorder)

                ForEach(Array(result.trades.prefix(5).enumerated()), id: \.offset) { _, trade in
                    HStack {
                        Text(trade.asset).frame(width: 80, alignment: .leading)
                            .font(.system(size: 12, weight: .semibold))
                        Text(trade.directionRaw.capitalized).frame(width: 80, alignment: .leading)
                            .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
                            .font(.system(size: 12))
                        Text(String(format: "$%.2f", trade.entryPrice)).frame(width: 100, alignment: .trailing)
                            .font(.system(size: 12).monospacedDigit())
                        Text(String(format: "%.2f", trade.positionSize)).frame(width: 80, alignment: .trailing)
                            .font(.system(size: 12).monospacedDigit())
                        Text(trade.entryAt, style: .date).frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.fmsMuted)
                    }
                    .foregroundStyle(Color.fmsOnSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    Divider().overlay(Color.fmsBorder)
                }

                if result.trades.count > 5 {
                    Text(String(format: String(localized: "journal.csv.more_trades", bundle: lang.bundle), result.trades.count - 5))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                        .padding(12)
                }
            }

            // Errors (if any)
            if !result.failedRows.isEmpty {
                Divider().overlay(Color.fmsBorder)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: String(localized: "journal.csv.rows_with_errors", bundle: lang.bundle), result.failedRows.count))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.fmsLoss)
                        ForEach(result.failedRows.prefix(10), id: \.rowIndex) { row, error in
                            Text(String(format: String(localized: "journal.csv.row_error", bundle: lang.bundle), row, error.localizedDescription))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.fmsLoss.opacity(0.8))
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 100)
            }

            Spacer()
            Divider().overlay(Color.fmsBorder)

            // Footer
            HStack {
                Spacer()
                Button(String(format: String(localized: "journal.csv.confirm_import", bundle: lang.bundle), result.trades.count)) { onConfirm() }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(Color.black)
                    .disabled(result.trades.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 580, height: 420)
        .background(Color.fmsBackground)
    }

    private var formatLabel: String {
        switch result.detectedFormat {
        case .ibkr:         return "IBKR"
        case .tdAmeritrade: return "TD Ameritrade"
        case .binance:      return "Binance"
        case .generic:      return "Generic"
        case .unknown:      return "Custom"
        }
    }
}
