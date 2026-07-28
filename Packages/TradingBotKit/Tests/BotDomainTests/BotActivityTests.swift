import Foundation
import Testing
@testable import BotDomain

private let now = Date(timeIntervalSince1970: 1_785_162_660)   // 2026-07-27T14:31:00Z

@Test func noActivityTimestampIsUnknown() {
    #expect(BotActivity.status(lastActivity: nil, now: now, maxHoldHours: 72) == .unknown)
}

@Test func recentActivityIsReported() {
    let status = BotActivity.status(
        lastActivity: now.addingTimeInterval(-3_600), now: now, maxHoldHours: 72
    )
    #expect(status == .recent(3_600))
    #expect(status.isOverdue == false)
}

@Test func activityOlderThanTheMaxHoldWindowIsOverdue() {
    // 72h window, last write 100h ago — the bot should have force-closed by now.
    let status = BotActivity.status(
        lastActivity: now.addingTimeInterval(-100 * 3_600), now: now, maxHoldHours: 72
    )
    #expect(status.isOverdue)
    #expect(abs((status.interval ?? 0) - 360_000) < 0.001)
}

@Test func exactlyAtTheWindowIsNotYetOverdue() {
    let status = BotActivity.status(
        lastActivity: now.addingTimeInterval(-72 * 3_600), now: now, maxHoldHours: 72
    )
    #expect(status.isOverdue == false)
}

@Test func justPastTheWindowIsOverdue() {
    let status = BotActivity.status(
        lastActivity: now.addingTimeInterval(-72 * 3_600 - 1), now: now, maxHoldHours: 72
    )
    #expect(status.isOverdue)
}

@Test func clockSkewDoesNotProduceANegativeInterval() {
    // Server clock ahead of the phone: treat as zero rather than a negative age.
    let status = BotActivity.status(
        lastActivity: now.addingTimeInterval(600), now: now, maxHoldHours: 72
    )
    #expect(status == .recent(0))
}

@Test func aZeroWindowNeverMarksTheBotOverdue() {
    // Guard against a missing or zero MAX_HOLD_HOURS making every bot look dead.
    let status = BotActivity.status(
        lastActivity: now.addingTimeInterval(-1_000_000), now: now, maxHoldHours: 0
    )
    #expect(status.isOverdue == false)
}

@Test func unknownStatusHasNoInterval() {
    #expect(BotActivityStatus.unknown.interval == nil)
}
