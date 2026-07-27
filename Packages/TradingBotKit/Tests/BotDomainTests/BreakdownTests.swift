import Testing
@testable import BotDomain

private func group(_ key: String, _ net: Double, winRate: Double = 50) -> BreakdownGroup {
    BreakdownGroup(key: key, trades: 10, winRate: winRate, netPnl: net)
}

@Test func barFractionNormalisesAgainstTheLargestAbsoluteNet() {
    // by_symbol from the design: BTC +6.10, SOL -18.84 -> max abs 18.84
    let groups = [group("BTCUSDT", 6.10), group("SOLUSDT", -18.84)]
    let max = groups.maxAbsoluteNet
    #expect(max == 18.84)
    #expect(abs(groups[0].barFraction(relativeTo: max) - 0.3237) < 0.001)
    #expect(groups[1].barFraction(relativeTo: max) == 1)
}

@Test func barFractionUsesMagnitudeSoLossesRenderFullWidth() {
    let groups = [group("a", -22.99), group("b", 8.20), group("c", 2.05)]
    #expect(groups.maxAbsoluteNet == 22.99)
    #expect(groups[0].barFraction(relativeTo: groups.maxAbsoluteNet) == 1)
}

@Test func barFractionIsZeroWhenEveryNetIsZero() {
    let groups = [group("a", 0), group("b", 0)]
    #expect(groups.maxAbsoluteNet == 0)
    #expect(groups[0].barFraction(relativeTo: 0) == 0)
}

@Test func maxAbsoluteNetOfAnEmptyListIsZero() {
    #expect([BreakdownGroup]().maxAbsoluteNet == 0)
}

@Test func singleGroupAlwaysFillsTheBar() {
    let groups = [group("only", -3.2)]
    #expect(groups[0].barFraction(relativeTo: groups.maxAbsoluteNet) == 1)
}

@Test func winRateTierBuckets() {
    #expect(group("a", 1, winRate: 66.7).winRateTier == .strong)
    #expect(group("a", 1, winRate: 50).winRateTier == .strong)
    #expect(group("a", 1, winRate: 44.4).winRateTier == .neutral)
    #expect(group("a", 1, winRate: 33).winRateTier == .neutral)
    #expect(group("a", 1, winRate: 28.6).winRateTier == .weak)
}

@Test func keyDisplayReplacesUnderscores() {
    #expect(group("trending_up", 1).keyDisplay == "trending up")
}
