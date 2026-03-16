// Sources/FMSYSCore/Core/Services/CSV/CSVParser.swift
import Foundation

public struct CSVParser {

    /// Parses CSV text into an array of [header: value] dictionaries.
    public static func parse(_ text: String) -> [[String: String]] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let headerLine = lines.first else { return [] }
        let headers = parseRow(headerLine)
        return lines.dropFirst().compactMap { line -> [String: String]? in
            let values = parseRow(line)
            guard values.count == headers.count else { return nil }
            return Dictionary(uniqueKeysWithValues: zip(headers, values))
        }
    }

    public static func headers(from text: String) -> [String] {
        guard let firstLine = text.components(separatedBy: .newlines).first else { return [] }
        return parseRow(firstLine)
    }

    public static func preview(text: String, maxRows: Int = 3) -> [[String]] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return Array(lines.dropFirst().prefix(maxRows)).map { parseRow($0) }
    }

    // MARK: - Row parser (handles quoted fields with commas)

    static func parseRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}
