import Foundation
import Testing
import BotDomain
@testable import BotDataKit

@Test func decodesTheSummary() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.summary.balance == 87.26)
    #expect(snapshot.summary.equity == 116.40)
    #expect(snapshot.summary.total == 28)
    #expect(snapshot.summary.wins == 11)
    #expect(snapshot.summary.winRate == 39.3)
    #expect(snapshot.summary.totalPnl == -12.74)
    #expect(snapshot.summary.todayPnl == -2.22)
}

@Test func decodesGeneratedAtAsAnISO8601Instant() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.generatedAt == Date(timeIntervalSince1970: 1_782_832_965))
}

@Test func decodesCurveDatesFromYearMonthDay() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.curve.count == 2)
    #expect(snapshot.curve[0].equity == 100.0)
    #expect(snapshot.curve[0].date == Date(timeIntervalSince1970: 1_781_913_600))
}

@Test func decodesTheOpenPosition() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    let position = try #require(snapshot.openPositions.first)
    #expect(position.pair == "SOLUSDT")
    #expect(position.direction == .short)
    #expect(position.entryPrice == 73.10)
    #expect(position.leverage == 2)
    #expect(position.takeProfit == 70.91)
    #expect(position.stopLoss == 74.20)
    #expect(position.exchangeStops)
}

@Test func decodesAClosedTradeIncludingItsOpenTimestamp() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    let trade = try #require(snapshot.closedTrades.first)
    #expect(trade.pair == "SOLUSDT")
    #expect(trade.direction == .short)
    #expect(trade.status == .stopLoss)
    #expect(trade.confidence == 7)
    // closed 14:31, opened 12:05 -> 2h 26m
    #expect(trade.holdDuration == 8_760)
}

@Test func decodesTheReviewLayerWhenPresent() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    let report = try #require(snapshot.aiReport)
    #expect(report.date == "2026-06-30")
    #expect(report.narrative == "Choppy fortnight.")
    #expect(report.whatsWorking == ["BTC entries in clear trends"])
    #expect(report.configSuggestions.first?.param == "ADX_TREND_MIN_SOLUSDT")
    #expect(report.configSuggestions.first?.suggested == "30")

    let veto = try #require(snapshot.veto)
    #expect(veto.proceed == 26)
    #expect(veto.proceedWinRate == 41.7)
    #expect(veto.rows.first?.signal == .sell)
    #expect(veto.rows.first?.outcome == .loss)
    #expect(veto.rows.first?.displayFlags == ["low_adx_chop"])

    #expect(snapshot.lessons.first?.failurePattern == "shorted into support")
    #expect(snapshot.lessons.first?.tags == ["support", "ranging", "short"])
    #expect(snapshot.hasReviewLayer)
}

// The design's fourth screen exists purely because these three fields are nullable.
@Test func decodesAnAbsentReviewLayerAsNil() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.aiNull)
    #expect(snapshot.aiReport == nil)
    #expect(snapshot.veto == nil)
    #expect(snapshot.lessons.isEmpty)
    #expect(snapshot.hasReviewLayer == false)
    // The rest of the snapshot still decodes normally.
    #expect(snapshot.summary.total == 28)
}

@Test func decodesMissingReviewKeysEntirelyAsNil() throws {
    let withoutKeys = Data("""
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 1, "equity": 1, "open": 0, "total": 0, "wins": 0,
        "losses": 0, "win_rate": 0, "total_pnl": 0, "today_total": 0,
        "today_wins": 0, "today_losses": 0, "today_pnl": 0 },
      "curve": [], "open_positions": [], "closed_trades": [],
      "by_symbol": [], "by_regime": []
    }
    """.utf8)
    let snapshot = try SnapshotDecoder.decode(withoutKeys)
    #expect(snapshot.aiReport == nil)
    #expect(snapshot.veto == nil)
    #expect(snapshot.lessons.isEmpty)
}

// Tolerating unknown enum values keeps one odd row from blanking the whole screen.
@Test func unknownEnumValuesFallBackInsteadOfThrowing() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.unknownEnums)
    let trade = try #require(snapshot.closedTrades.first)
    #expect(trade.direction == .unknown)
    #expect(trade.status == .unknown)
    #expect(trade.regime == "chop")
    #expect(trade.pair == "XRPUSDT")
}

// Malformed JSON is a real failure and must surface.
@Test func malformedJSONThrows() {
    #expect(throws: (any Error).self) {
        try SnapshotDecoder.decode(Fixtures.malformed)
    }
}

@Test func missingRequiredFieldThrows() {
    let missingSummary = Data("""
    { "generated_at": "2026-06-30T15:22:45Z", "curve": [], "open_positions": [],
      "closed_trades": [], "by_symbol": [], "by_regime": [] }
    """.utf8)
    #expect(throws: (any Error).self) {
        try SnapshotDecoder.decode(missingSummary)
    }
}

@Test func decodesBreakdownGroups() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.bySymbol.first?.key == "BTCUSDT")
    #expect(snapshot.bySymbol.first?.netPnl == 6.10)
    #expect(snapshot.byRegime.first?.keyDisplay == "ranging")
}
