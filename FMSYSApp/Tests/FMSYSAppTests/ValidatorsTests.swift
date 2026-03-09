import Foundation
import Testing
@testable import FMSYSCore

// Pure function tests — no Keychain, no async, fully parallelizable.
struct ValidatorsTests {

    // MARK: - email

    @Test func validEmailPasses() throws {
        try Validators.email("user@example.com")
    }

    @Test func validEmailWithSubdomainPasses() throws {
        try Validators.email("trader@mail.exchange.io")
    }

    @Test func emptyEmailThrowsEmpty() {
        #expect(throws: ValidationError.empty) {
            try Validators.email("")
        }
    }

    @Test func emailWithoutAtThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.email("notanemail")
        }
    }

    @Test func emailWithoutDomainThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.email("user@")
        }
    }

    @Test func emailWithSpaceThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.email("user @example.com")
        }
    }

    // MARK: - password

    @Test func validPasswordPasses() throws {
        try Validators.password("Secret1!")
    }

    @Test func emptyPasswordThrowsEmpty() {
        #expect(throws: ValidationError.empty) {
            try Validators.password("")
        }
    }

    @Test func passwordTooShortThrows() {
        #expect(throws: ValidationError.tooShort(min: 8)) {
            try Validators.password("Ab1!")   // 4 chars
        }
    }

    @Test func passwordWithNoUppercaseThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.password("secret1!")   // no uppercase
        }
    }

    @Test func passwordWithNoDigitThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.password("SecretABC!")  // no digit
        }
    }

    @Test func passwordWithNoLowercaseThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.password("SECRET1!")   // no lowercase
        }
    }

    // MARK: - assetPair

    @Test func validCryptoPairPasses() throws {
        try Validators.assetPair("BTC/USDT")
    }

    @Test func validForexPairPasses() throws {
        try Validators.assetPair("EUR/USD")
    }

    @Test func emptyAssetPairThrowsEmpty() {
        #expect(throws: ValidationError.empty) {
            try Validators.assetPair("")
        }
    }

    @Test func assetPairWithoutSlashThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.assetPair("BTCUSDT")
        }
    }

    @Test func assetPairWithLowercaseThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.assetPair("btc/usdt")
        }
    }

    @Test func assetPairMissingBaseThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.assetPair("/USDT")
        }
    }

    @Test func assetPairMissingQuoteThrowsInvalidFormat() {
        #expect(throws: ValidationError.invalidFormat) {
            try Validators.assetPair("BTC/")
        }
    }

    // MARK: - positiveDecimal

    @Test func positiveDecimalPasses() throws {
        try Validators.positiveDecimal(Decimal(string: "0.001")!)
    }

    @Test func largePositiveDecimalPasses() throws {
        try Validators.positiveDecimal(Decimal(99_999))
    }

    @Test func zeroDecimalThrowsOutOfRange() {
        #expect(throws: ValidationError.outOfRange) {
            try Validators.positiveDecimal(0)
        }
    }

    @Test func negativeDecimalThrowsOutOfRange() {
        #expect(throws: ValidationError.outOfRange) {
            try Validators.positiveDecimal(Decimal(-1))
        }
    }

    // MARK: - strategyName

    @Test func validStrategyNamePasses() throws {
        try Validators.strategyName("MACD Crossover v2")
    }

    @Test func emptyStrategyNameThrowsEmpty() {
        #expect(throws: ValidationError.empty) {
            try Validators.strategyName("")
        }
    }

    @Test func whitespaceOnlyStrategyNameThrowsEmpty() {
        #expect(throws: ValidationError.empty) {
            try Validators.strategyName("   ")
        }
    }

    @Test func strategyNameAtMaxLengthPasses() throws {
        let name = String(repeating: "A", count: 100)
        try Validators.strategyName(name)
    }

    @Test func strategyNameExceedingMaxLengthThrows() {
        let name = String(repeating: "A", count: 101)
        #expect(throws: ValidationError.tooLong(max: 100)) {
            try Validators.strategyName(name)
        }
    }
}
