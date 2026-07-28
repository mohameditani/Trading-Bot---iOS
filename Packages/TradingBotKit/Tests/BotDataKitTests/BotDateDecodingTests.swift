import Foundation
import Testing
@testable import BotDataKit

// Every string below is a real format the bot emits, taken from trades_live.json
// and dashboard.py. The bot writes `datetime.now().isoformat()` — naive local time,
// no timezone designator — so a plain `.iso8601` strategy rejects the whole payload.

@Test func decodesNaiveTimestampWithFractionalSeconds() throws {
    // trades_live.json: closed_at / timestamp
    //
    // The bot writes microseconds but DateFormatter resolves only to milliseconds, so
    // the parse is accurate to ~1ms rather than exact. That is deliberate and harmless:
    // nothing in the UI renders finer than a minute.
    let date = try #require(BotDate.parse("2026-06-24T03:25:02.737831"))
    let expected = Date(timeIntervalSince1970: 1_782_271_502.737831)
    #expect(abs(date.timeIntervalSince(expected)) < 0.001)
}

@Test func decodesNaiveTimestampWithoutFractionalSeconds() throws {
    // dashboard.py: generated_at uses strftime('%Y-%m-%dT%H:%M:%S')
    let date = try #require(BotDate.parse("2026-07-27T14:31:00"))
    #expect(date == Date(timeIntervalSince1970: 1_785_162_660))
}

@Test func stillDecodesZuluTimestamps() throws {
    // Our bundled fixtures use a trailing Z — these must keep working.
    let date = try #require(BotDate.parse("2026-06-30T15:22:45Z"))
    #expect(date == Date(timeIntervalSince1970: 1_782_832_965))
}

@Test func decodesExplicitOffsetTimestamps() throws {
    // 12:22:45+03:00 is the same instant as 09:22:45Z
    let date = try #require(BotDate.parse("2026-06-30T12:22:45+03:00"))
    #expect(date == Date(timeIntervalSince1970: 1_782_811_365))
}

@Test func naiveAndZuluOfTheSameWallClockAgree() throws {
    // Naive stamps are interpreted as UTC, so these must be identical.
    let naive = try #require(BotDate.parse("2026-06-30T15:22:45"))
    let zulu = try #require(BotDate.parse("2026-06-30T15:22:45Z"))
    #expect(naive == zulu)
}

@Test func rejectsGarbage() {
    #expect(BotDate.parse("") == nil)
    #expect(BotDate.parse("not a date") == nil)
    #expect(BotDate.parse("2026-13-45T99:99:99") == nil)
}

// MARK: - Whole-payload decoding

@Test func decodesAPayloadUsingTheBotsNaiveTimestamps() throws {
    let payload = Data("""
    {
      "generated_at": "2026-07-27T14:31:00",
      "summary": { "balance": 87.26, "equity": 116.40, "open": 1, "total": 28,
        "wins": 11, "losses": 17, "win_rate": 39.3, "total_pnl": -12.74,
        "today_total": 3, "today_wins": 1, "today_losses": 2, "today_pnl": -2.22 },
      "curve": [ { "t": "2026-06-24", "ts": "2026-06-24T12:25", "equity": 100.0, "clean": false } ],
      "open_positions": [ { "pair": "BTCUSDT", "direction": "long", "entry_price": 64732.1,
        "quantity": 0.003, "leverage": 2, "margin": 97.09815, "take_profit": 66674.063,
        "stop_loss": 63761.1185, "timestamp": "2026-07-15T03:50:19.670972",
        "exchange_stops": true } ],
      "closed_trades": [ { "closed_at": "2026-06-24T12:25:21.152267", "pair": "SOLUSDT",
        "direction": "short", "entry_price": 69.22, "exit_price": 70.37, "quantity": 1.95,
        "pnl": -2.35, "status": "closed_sl", "regime": "trending_down", "confidence": 7,
        "timestamp": "2026-06-24T03:25:02.737831", "exit_reason": null, "note": null } ],
      "by_symbol": [], "by_regime": [],
      "ai_report": null, "veto": null, "lessons": null
    }
    """.utf8)

    let snapshot = try SnapshotDecoder.decode(payload)
    #expect(snapshot.summary.total == 28)
    #expect(snapshot.closedTrades.first?.pair == "SOLUSDT")
    // 03:25:02 -> 12:25:21 is 9h 0m 18s
    #expect(Int(snapshot.closedTrades.first?.holdDuration ?? 0) == 32_418)
    #expect(snapshot.openPositions.first?.pair == "BTCUSDT")
    #expect(snapshot.curve.first?.equity == 100.0)
}

// The live payload carries fields our contract does not model. They must be ignored,
// not rejected — otherwise every real fetch fails.
@Test func toleratesTheExtraFieldsTheLivePayloadCarries() throws {
    let payload = Data("""
    {
      "generated_at": "2026-07-27T14:31:00",
      "summary": { "balance": 1, "equity": 1, "open": 0, "total": 0, "wins": 0,
        "losses": 0, "win_rate": 0, "total_pnl": 0, "today_total": 0,
        "today_wins": 0, "today_losses": 0, "today_pnl": 0 },
      "scorecard": { "trades": 12, "win_rate": 41.7, "expectancy_r": 0.13 },
      "last_activity": "2026-07-27T09:12:03.221144",
      "max_hold_hours": 72.0,
      "curve": [], "open_positions": [], "closed_trades": [],
      "by_symbol": [], "by_regime": [],
      "ai_report": null, "veto": null, "lessons": null
    }
    """.utf8)

    let snapshot = try SnapshotDecoder.decode(payload)
    #expect(snapshot.summary.total == 0)
}
