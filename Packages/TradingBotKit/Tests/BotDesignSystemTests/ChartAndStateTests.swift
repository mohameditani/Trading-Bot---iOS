import Foundation
import Testing
import BotDomain
@testable import BotDesignSystem

@Test func chartReportsWhenItHasNothingToDraw() {
    #expect(EquityCurveChart(points: []).hasData == false)
    #expect(EquityCurveChart(
        points: [CurvePoint(date: .init(timeIntervalSince1970: 0), equity: 1)]
    ).hasData)
}

@Test func chartDomainSpansTheDataWithHeadroom() {
    let points = [
        CurvePoint(date: Date(timeIntervalSince1970: 0), equity: 100),
        CurvePoint(date: Date(timeIntervalSince1970: 86_400), equity: 87.26),
    ]
    let chart = EquityCurveChart(points: points)
    // Padded so the line never touches the frame edge.
    #expect(chart.yDomain.lowerBound < 87.26)
    #expect(chart.yDomain.upperBound > 100)
}

@Test func chartDomainIsStableForAFlatCurve() {
    let points = [
        CurvePoint(date: Date(timeIntervalSince1970: 0), equity: 50),
        CurvePoint(date: Date(timeIntervalSince1970: 10), equity: 50),
    ]
    let chart = EquityCurveChart(points: points)
    // A zero-range curve must still produce a valid, non-empty domain.
    #expect(chart.yDomain.lowerBound < chart.yDomain.upperBound)
}

@Test func chartDomainOfAnEmptyCurveIsStillValid() {
    let chart = EquityCurveChart(points: [])
    #expect(chart.yDomain.lowerBound < chart.yDomain.upperBound)
}

@Test func placeholderCardCarriesTheDesignCopy() {
    let card = PlaceholderCard(
        title: "Veto log",
        description: "Logs every proceed / block decision and tracks the win rate of trades it let through."
    )
    #expect(card.title == "Veto log")
    #expect(card.notEnabledText == "NOT ENABLED YET")
}

@Test func breakdownRowComputesItsBarFromTheGroupSet() {
    let group = BreakdownGroup(key: "SOLUSDT", trades: 14, winRate: 28.6, netPnl: -18.84)
    let row = BreakdownRowView(group: group, maxAbsolute: 18.84)
    #expect(row.barFraction == 1)
    #expect(row.barColor == BotColor.negative)
    #expect(row.winRateColor == BotColor.negative)
}

@Test func breakdownRowUsesPositiveColouringForGains() {
    let group = BreakdownGroup(key: "BTCUSDT", trades: 14, winRate: 50, netPnl: 6.10)
    let row = BreakdownRowView(group: group, maxAbsolute: 18.84)
    #expect(row.barColor == BotColor.positive)
    #expect(row.winRateColor == BotColor.positive)
}
