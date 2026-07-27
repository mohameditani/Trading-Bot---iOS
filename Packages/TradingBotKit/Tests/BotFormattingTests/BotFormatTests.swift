import Foundation
import Testing
@testable import BotFormatting

// Every expectation below is a literal from the design mockup.

@Test func currencyMatchesTheDesign() {
    #expect(BotFormat.currency(87.26) == "$87.26")
    #expect(BotFormat.currency(116.40) == "$116.40")
    #expect(BotFormat.currency(29.24) == "$29.24")
    #expect(BotFormat.currency(0) == "$0.00")
}

@Test func currencyRendersNegativesWithALeadingMinus() {
    #expect(BotFormat.currency(-5.5) == "-$5.50")
}

@Test func signedCurrencyAlwaysCarriesItsSign() {
    #expect(BotFormat.signedCurrency(1.76) == "+$1.76")
    #expect(BotFormat.signedCurrency(-12.74) == "-$12.74")
    #expect(BotFormat.signedCurrency(-2.22) == "-$2.22")
}

@Test func signedCurrencyOfZeroHasNoSign() {
    #expect(BotFormat.signedCurrency(0) == "$0.00")
}

@Test func signedCurrencyOfNilIsAnEmDash() {
    #expect(BotFormat.signedCurrency(nil) == "—")
}

@Test func priceDropsDecimalsAtOrAboveOneThousand() {
    #expect(BotFormat.price(58800.0) == "58,800")
    #expect(BotFormat.price(58288.8) == "58,289")
    #expect(BotFormat.price(1000) == "1,000")
}

@Test func priceKeepsTwoDecimalsBelowOneThousand() {
    #expect(BotFormat.price(73.10) == "73.10")
    #expect(BotFormat.price(999.99) == "999.99")
    #expect(BotFormat.price(70.91) == "70.91")
}

@Test func priceOfNilIsAnEmDash() {
    #expect(BotFormat.price(nil) == "—")
}

@Test func percentKeepsOneDecimal() {
    #expect(BotFormat.percent(39.3) == "39.3%")
    #expect(BotFormat.percent(41.7) == "41.7%")
    #expect(BotFormat.percent(50) == "50.0%")
    #expect(BotFormat.percent(28.6) == "28.6%")
}

@Test func dayIsMonthAndDayInUTC() {
    // 2026-06-20T00:00:00Z
    #expect(BotFormat.day(Date(timeIntervalSince1970: 1_781_913_600)) == "Jun 20")
}

@Test func stampIsMonthDayAndUTCClockTime() {
    // 2026-06-30T14:31:00Z
    #expect(BotFormat.stamp(Date(timeIntervalSince1970: 1_782_829_860)) == "Jun 30 14:31")
}

@Test func stampDoesNotShiftWithTheHostTimeZone() {
    // Same instant must render identically no matter where the machine is.
    let instant = Date(timeIntervalSince1970: 1_782_829_860)
    #expect(BotFormat.stamp(instant) == "Jun 30 14:31")
    #expect(BotFormat.stamp(instant).hasPrefix("Jun 30"))
}

@Test func durationUnderAnHourIsMinutesOnly() {
    #expect(BotFormat.duration(45 * 60) == "45m")
    #expect(BotFormat.duration(59 * 60) == "59m")
    #expect(BotFormat.duration(0) == "0m")
}

@Test func durationOverAnHourCombinesHoursAndMinutes() {
    #expect(BotFormat.duration(4_920) == "1h 22m")
    #expect(BotFormat.duration(2 * 3_600 + 5 * 60) == "2h 5m")
}

@Test func durationOnAnExactHourOmitsMinutes() {
    #expect(BotFormat.duration(3_600) == "1h")
    #expect(BotFormat.duration(2 * 3_600) == "2h")
}

@Test func durationClampsNegativeIntervals() {
    #expect(BotFormat.duration(-120) == "0m")
}

@Test func freshnessReadsJustNowForTheFirstThreeSeconds() {
    #expect(BotFormat.freshness(seconds: 0) == "just now")
    #expect(BotFormat.freshness(seconds: 2) == "just now")
}

@Test func freshnessCountsSecondsAfterThree() {
    #expect(BotFormat.freshness(seconds: 3) == "3s ago")
    #expect(BotFormat.freshness(seconds: 12) == "12s ago")
    #expect(BotFormat.freshness(seconds: 30) == "30s ago")
}

@Test func quantityKeepsTwoDecimals() {
    #expect(BotFormat.quantity(0.8) == "0.80")
    #expect(BotFormat.quantity(1.2) == "1.20")
}

@Test func leverageIsSuffixedWithACross() {
    #expect(BotFormat.leverage(2) == "2×")
}
