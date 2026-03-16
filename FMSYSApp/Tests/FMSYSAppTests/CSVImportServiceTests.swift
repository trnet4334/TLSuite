// Tests/FMSYSAppTests/CSVImportServiceTests.swift
import Testing
@testable import FMSYSCore

struct CSVParserTests {
    @Test func parsesHeaderAndRows() {
        let csv = "symbol,price,date\nAAPL,150.0,2024-01-15\nMSFT,425.0,2024-01-16"
        let rows = CSVParser.parse(csv)
        #expect(rows.count == 2)
        #expect(rows[0]["symbol"] == "AAPL")
        #expect(rows[0]["price"] == "150.0")
        #expect(rows[1]["symbol"] == "MSFT")
    }

    @Test func handlesQuotedFields() {
        let csv = "name,notes\n\"Apple, Inc.\",\"buy low, sell high\""
        let rows = CSVParser.parse(csv)
        #expect(rows.count == 1)
        #expect(rows[0]["name"] == "Apple, Inc.")
        #expect(rows[0]["notes"] == "buy low, sell high")
    }
}

struct BrokerFormatDetectorTests {
    @Test func detectsIBKR() {
        let headers = ["Symbol", "Quantity", "T. Price", "C. Price", "Proceeds", "Comm/Fee", "Date/Time"]
        #expect(BrokerFormatDetector.detect(headers: headers) == .ibkr)
    }

    @Test func detectsBinance() {
        let headers = ["Date(UTC)", "Pair", "Side", "Price", "Executed", "Amount", "Fee"]
        #expect(BrokerFormatDetector.detect(headers: headers) == .binance)
    }

    @Test func returnsUnknownForUnrecognized() {
        let headers = ["foo", "bar", "baz"]
        #expect(BrokerFormatDetector.detect(headers: headers) == .unknown)
    }
}

struct TradeMapperTests {
    @Test func genericMapperMapsRequiredFields() throws {
        let row: [String: String] = [
            "symbol": "AAPL",
            "direction": "long",
            "entryPrice": "150.0",
            "entryTime": "2024-01-15T09:30:00Z",
            "positionSize": "10",
            "stopLoss": "145",
            "takeProfit": "160"
        ]
        let trade = try GenericTradeMapper.map(row: row, userId: "test-user")
        #expect(trade.asset == "AAPL")
        #expect(trade.direction == .long)
        #expect(trade.entryPrice == 150.0)
        #expect(trade.positionSize == 10)
    }

    @Test func mapperThrowsOnMissingRequiredField() {
        let row: [String: String] = ["symbol": "AAPL"]   // missing price, time, etc.
        #expect(throws: CSVMappingError.self) {
            _ = try GenericTradeMapper.map(row: row, userId: "test-user")
        }
    }
}
