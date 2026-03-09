import Foundation

// MARK: - ValidationError

public enum ValidationError: Error, Equatable {
    case empty
    case tooShort(min: Int)
    case tooLong(max: Int)
    case invalidFormat
    case outOfRange
}

// MARK: - Validators

public enum Validators {

    // MARK: email

    /// Accepts standard email addresses (local@domain.tld).
    /// Rejects empty strings, missing @, missing domain, and embedded spaces.
    public static func email(_ value: String) throws {
        guard !value.isEmpty else { throw ValidationError.empty }
        // Simple but effective pattern: local@domain — no spaces, has a dot after @
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        guard value.range(of: pattern, options: .regularExpression) != nil else {
            throw ValidationError.invalidFormat
        }
    }

    // MARK: password

    /// Min 8 chars; must contain at least one uppercase, one lowercase, one digit.
    public static func password(_ value: String) throws {
        guard !value.isEmpty else { throw ValidationError.empty }
        guard value.count >= 8 else { throw ValidationError.tooShort(min: 8) }
        guard value.range(of: "[A-Z]", options: .regularExpression) != nil,
              value.range(of: "[a-z]", options: .regularExpression) != nil,
              value.range(of: "[0-9]", options: .regularExpression) != nil else {
            throw ValidationError.invalidFormat
        }
    }

    // MARK: assetPair

    /// Accepts uppercase pairs separated by a slash: "BTC/USDT", "EUR/USD".
    /// Both base and quote must be non-empty uppercase letters only.
    public static func assetPair(_ value: String) throws {
        guard !value.isEmpty else { throw ValidationError.empty }
        let pattern = #"^[A-Z]+/[A-Z]+$"#
        guard value.range(of: pattern, options: .regularExpression) != nil else {
            throw ValidationError.invalidFormat
        }
    }

    // MARK: positiveDecimal

    /// Rejects zero and negative values.
    public static func positiveDecimal(_ value: Decimal) throws {
        guard value > 0 else { throw ValidationError.outOfRange }
    }

    // MARK: strategyName

    /// Non-empty (after trimming whitespace), max 100 characters.
    public static func strategyName(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw ValidationError.empty }
        guard trimmed.count <= 100 else { throw ValidationError.tooLong(max: 100) }
    }
}
