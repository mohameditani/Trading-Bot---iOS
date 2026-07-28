import Foundation
import Testing
@testable import BotDataKit

/// `live-payload.json` was produced by running the bot's own
/// `dashboard_data.build_payload()` over its real ledger, then replacing the monetary
/// figures with synthetic ones — balances belong in the bot's repository, not this one.
///
/// Everything that governs decoding is untouched: all 13 top-level keys, the naive
/// timestamp formats, the extra per-trade fields, and the sections our contract does
/// not model (`scorecard`, `max_hold_hours`).
private func liveFixture() throws -> Data {
    let url = try #require(
        Bundle.module.url(forResource: "live-payload", withExtension: "json"),
        "live-payload.json missing from BotDataKitTests resources"
    )
    return try Data(contentsOf: url)
}

@Test func decodesAPayloadShapedLikeTheRealDashboards() throws {
    let snapshot = try SnapshotDecoder.decode(try liveFixture())

    #expect(snapshot.closedTrades.count == 21)
    #expect(snapshot.openPositions.count == 1)
    #expect(snapshot.curve.count == 22)
    #expect(snapshot.maxHoldHours == 72)
}

@Test func decodesTheBotsNaiveTimestampsThroughout() throws {
    let snapshot = try SnapshotDecoder.decode(try liveFixture())

    // generated_at: "2026-07-28T12:13:09" — no timezone, no fractional seconds.
    #expect(snapshot.generatedAt == Date(timeIntervalSince1970: 1_785_240_789))
    // last_activity: "2026-07-15T03:50:19.670972" — no timezone, microseconds.
    let lastActivity = try #require(snapshot.lastActivity)
    #expect(abs(lastActivity.timeIntervalSince1970 - 1_784_087_419.670972) < 0.001)

    // Every trade timestamp parsed, so no hold duration is nonsensical.
    #expect(snapshot.closedTrades.allSatisfy { $0.holdDuration >= 0 })
}

@Test func decodesTheReviewLayerFromTheLiveShape() throws {
    let snapshot = try SnapshotDecoder.decode(try liveFixture())

    #expect(snapshot.hasReviewLayer)
    let veto = try #require(snapshot.veto)
    #expect(veto.proceed == 26)
    #expect(veto.rows.count == 2)
    #expect(veto.rows.first?.signal == .buy)
    // A blocked signal never opened, so it has no outcome — the bot's own blind spot.
    #expect(veto.rows.last?.outcome == nil)
    #expect(veto.rows.last?.outcomeLabel == "no outcome")

    #expect(snapshot.lessons.count == 1)
    #expect(snapshot.lessons.first?.tags == ["support", "ranging", "short"])
}

@Test func ignoresTheSectionsOurContractDoesNotModel() throws {
    // scorecard and max_hold_hours are present in the live payload; the first is not
    // in our contract at all and must not cause a decode failure.
    let raw = try #require(
        try JSONSerialization.jsonObject(with: try liveFixture()) as? [String: Any]
    )
    #expect(raw["scorecard"] != nil)
    #expect(try SnapshotDecoder.decode(try liveFixture()).summary.total >= 0)
}

@Test func theHeartbeatRuleWorksOnRealGaps() throws {
    let snapshot = try SnapshotDecoder.decode(try liveFixture())
    let lastActivity = try #require(snapshot.lastActivity)

    // One hour after the last write: well inside the 72h window.
    let soon = snapshot.activityStatus(now: lastActivity.addingTimeInterval(3_600))
    #expect(soon.isOverdue == false)

    // Eight days later: the bot force-closes at 72h, so silence this long is a signal.
    let later = snapshot.activityStatus(now: lastActivity.addingTimeInterval(8 * 86_400))
    #expect(later.isOverdue)
}
