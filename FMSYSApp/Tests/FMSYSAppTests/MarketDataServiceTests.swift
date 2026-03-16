// Tests/FMSYSAppTests/MarketDataServiceTests.swift
import Testing
@testable import FMSYSCore

struct MarketDataServiceTests {

    @Test func mockQuoteReturnsDataForKnownSymbol() async {
        let service = MockMarketDataService()
        let quote = await service.quote(for: "BTC")
        #expect(quote.symbol == "BTC")
        #expect(quote.price > 0)
    }

    @Test func mockQuoteReturnsPlaceholderForUnknownSymbol() async {
        let service = MockMarketDataService()
        let quote = await service.quote(for: "UNKNOWN")
        #expect(quote.symbol == "UNKNOWN")
        #expect(quote.price == 0)
    }

    @Test func mockHistoricalPricesReturnNonEmptyArray() async {
        let service = MockMarketDataService()
        let prices = await service.historicalPrices(symbol: "BTC", range: .oneMonth)
        #expect(!prices.isEmpty)
    }
}
