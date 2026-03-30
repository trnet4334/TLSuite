// Sources/FMSYSCore/Features/Journal/Views/CSV/ColumnMappingSheet.swift
import SwiftUI

/// Shown when broker format cannot be auto-detected.
/// User maps CSV column names to Trade field names.
public struct ColumnMappingSheet: View {
    @Environment(LanguageManager.self) private var lang

    let csvHeaders: [String]
    let preview: [[String]]   // first 3 rows of raw values, parallel to csvHeaders
    let onConfirm: ([String: String]) -> Void   // [csvHeader: tradeField]
    let onCancel: () -> Void

    // Required Trade fields the user must map
    private static let requiredFields = ["symbol", "entryPrice", "entryTime", "direction", "positionSize"]
    private static let optionalFields = ["exitPrice", "stopLoss", "takeProfit", "notes", "category"]
    private static let allTargetFields = requiredFields + optionalFields

    @State private var mapping: [String: String] = [:]  // csvHeader → tradeField

    public init(
        csvHeaders: [String],
        preview: [[String]],
        onConfirm: @escaping ([String: String]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.csvHeaders = csvHeaders
        self.preview = preview
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("journal.csv.map_columns_title", bundle: lang.bundle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button(String(localized: "common.cancel", bundle: lang.bundle), action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)

            Divider().overlay(Color.fmsBorder)

            // Mapping table
            ScrollView {
                VStack(spacing: 0) {
                    // Column header row
                    HStack {
                        Text("journal.csv.col_header_csv", bundle: lang.bundle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("journal.csv.col_header_sample", bundle: lang.bundle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("journal.csv.col_header_maps_to", bundle: lang.bundle)
                            .frame(width: 180, alignment: .leading)
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    Divider().overlay(Color.fmsBorder)

                    ForEach(csvHeaders, id: \.self) { header in
                        MappingRow(
                            csvHeader: header,
                            sampleValues: sampleValues(for: header),
                            targetFields: Self.allTargetFields,
                            requiredFields: Self.requiredFields,
                            selectedTarget: Binding(
                                get: { mapping[header] ?? "" },
                                set: { mapping[header] = $0.isEmpty ? nil : $0 }
                            )
                        )
                        Divider().overlay(Color.fmsBorder)
                    }
                }
            }

            Divider().overlay(Color.fmsBorder)

            // Footer
            HStack {
                missingRequiredLabel
                Spacer()
                Button(String(localized: "journal.csv.import_button", bundle: lang.bundle)) { onConfirm(mapping) }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(canImport ? Color.fmsPrimary : Color.fmsMuted.opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(canImport ? Color.black : Color.fmsMuted)
                    .disabled(!canImport)
            }
            .padding(16)
        }
        .frame(width: 620, height: 480)
        .background(Color.fmsBackground)
    }

    private func sampleValues(for header: String) -> String {
        guard let idx = csvHeaders.firstIndex(of: header) else { return "—" }
        let vals = preview.compactMap { row in row.indices.contains(idx) ? row[idx] : nil }
        return vals.prefix(2).joined(separator: ", ")
    }

    private var canImport: Bool {
        let mappedTargets = Set(mapping.values)
        return Self.requiredFields.allSatisfy { mappedTargets.contains($0) }
    }

    @ViewBuilder
    private var missingRequiredLabel: some View {
        let missing = Self.requiredFields.filter { !Set(mapping.values).contains($0) }
        if missing.isEmpty {
            Text("journal.csv.all_fields_mapped", bundle: lang.bundle)
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsPrimary)
        } else {
            Text(String(format: String(localized: "journal.csv.missing_fields", bundle: lang.bundle), missing.joined(separator: ", ")))
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsLoss)
        }
    }
}

private struct MappingRow: View {
    @Environment(LanguageManager.self) private var lang
    let csvHeader: String
    let sampleValues: String
    let targetFields: [String]
    let requiredFields: [String]
    @Binding var selectedTarget: String

    var body: some View {
        HStack {
            Text(csvHeader)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(sampleValues)
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $selectedTarget) {
                Text("journal.csv.skip_option", bundle: lang.bundle).tag("")
                ForEach(targetFields, id: \.self) { field in
                    HStack {
                        Text(field)
                        if requiredFields.contains(field) {
                            Text("*").foregroundStyle(Color.fmsLoss)
                        }
                    }.tag(field)
                }
            }
            .frame(width: 180)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
