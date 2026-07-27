import Foundation
import Testing
@testable import BotDomain

private func trade(
    _ pair: String,
    pnl: Double,
    closedAtOffset: TimeInterval
) -> ClosedTrade {
    ClosedTrade(
        closedAt: Date(timeIntervalSince1970: closedAtOffset),
        openedAt: Date(timeIntervalSince1970: 0),
        pair: pair,
        direction: .short,
        entryPrice: 1, exitPrice: 2, quantity: 1,
        pnl: pnl,
        status: pnl >= 0 ? .takeProfit : .stopLoss,
        regime: "ranging",
        confidence: 5
    )
}

private let sample = [
    trade("SOLUSDT", pnl: -1.99, closedAtOffset: 300),
    trade("BTCUSDT", pnl: 1.76, closedAtOffset: 200),
    trade("SOLUSDT", pnl: -1.28, closedAtOffset: 100),
]

@Test func allFilterKeepsEveryTrade() {
    #expect(TradeFilter.all.apply(to: sample).count == 3)
}

@Test func symbolFilterMatchesOnPrefix() {
    #expect(TradeFilter.symbol("SOL").apply(to: sample).count == 2)
    #expect(TradeFilter.symbol("BTC").apply(to: sample).count == 1)
}

@Test func symbolFilterIsCaseInsensitive() {
    #expect(TradeFilter.symbol("sol").apply(to: sample).count == 2)
}

@Test func lossesFilterKeepsOnlyNegativePnl() {
    let losses = TradeFilter.losses.apply(to: sample)
    #expect(losses.count == 2)
    #expect(losses.allSatisfy { $0.pnl < 0 })
}

@Test func lossesFilterExcludesBreakEven() {
    let trades = [trade("SOLUSDT", pnl: 0, closedAtOffset: 10)]
    #expect(TradeFilter.losses.apply(to: trades).isEmpty)
}

@Test func filterPreservesInputOrder() {
    let result = TradeFilter.symbol("SOL").apply(to: sample)
    #expect(result.map(\.closedAt) == [
        Date(timeIntervalSince1970: 300),
        Date(timeIntervalSince1970: 100),
    ])
}

@Test func sortedByCloseDateDescendingPutsNewestFirst() {
    let sorted = sample.sortedByCloseDateDescending()
    #expect(sorted.map(\.closedAt) == [
        Date(timeIntervalSince1970: 300),
        Date(timeIntervalSince1970: 200),
        Date(timeIntervalSince1970: 100),
    ])
}

@Test func filterTitlesMatchTheDesign() {
    #expect(TradeFilter.all.title(totalCount: 28) == "All 28")
    #expect(TradeFilter.symbol("BTC").title(totalCount: 28) == "BTC")
    #expect(TradeFilter.losses.title(totalCount: 28) == "Losses")
}
