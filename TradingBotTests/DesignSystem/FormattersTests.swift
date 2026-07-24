import Testing
@testable import TradingBot

@Suite("Formatters")
struct FormattersTests {
    @Test func currencyPositive() {
        #expect(Formatters.currency(179.79) == "$179.79")
    }

    @Test func currencyNegativePlacesMinusBeforeDollar() {
        #expect(Formatters.currency(-21.70) == "-$21.70")
    }

    @Test func currencyZero() {
        #expect(Formatters.currency(0) == "$0.00")
    }

    @Test func percentOneDecimal() {
        #expect(Formatters.percent(0.222) == "22.2%")
    }

    @Test func priceGroupingOneDecimal() {
        #expect(Formatters.price(65413.1) == "65,413.1")
    }

    @Test func priceSmallValue() {
        #expect(Formatters.price(78.3) == "78.3")
    }
}
