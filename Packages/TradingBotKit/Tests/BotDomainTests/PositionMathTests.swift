import Foundation
import Testing
@testable import BotDomain

private func makePosition(
    entry: Double,
    takeProfit: Double,
    stopLoss: Double,
    direction: TradeDirection = .short
) -> Position {
    Position(
        pair: "SOLUSDT",
        direction: direction,
        entryPrice: entry,
        quantity: 0.8,
        leverage: 2,
        margin: 29.24,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
        openedAt: Date(timeIntervalSince1970: 0),
        exchangeStops: true
    )
}

@Test func railProgressMatchesTheDesignSamplePosition() {
    // TP 70.91, entry 73.10, SL 74.20 -> |73.10-70.91| / |74.20-70.91| = 0.6657
    let position = makePosition(entry: 73.10, takeProfit: 70.91, stopLoss: 74.20)
    #expect(abs(position.railProgress - 0.6657) < 0.001)
}

@Test func railProgressWorksForALongPosition() {
    // TP 80, entry 75, SL 73 -> |75-80| / |73-80| = 0.7142
    let position = makePosition(entry: 75, takeProfit: 80, stopLoss: 73, direction: .long)
    #expect(abs(position.railProgress - 0.7142) < 0.001)
}

@Test func railProgressIsZeroAtTakeProfit() {
    let position = makePosition(entry: 70.91, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 0)
}

@Test func railProgressIsOneAtStopLoss() {
    let position = makePosition(entry: 74.20, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 1)
}

@Test func railProgressClampsBeyondTheStopLoss() {
    let position = makePosition(entry: 99, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 1)
}

@Test func railProgressClampsBelowTheTakeProfit() {
    let position = makePosition(entry: 10, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 0)
}

// Regression: an absolute-value formula puts a deeply winning entry at the stop-loss
// end of the rail. The marker must sit at the take-profit end for both directions.
@Test func railProgressIsZeroWhenAWinningEntrySitsBeyondTakeProfit() {
    let short = makePosition(entry: 10, takeProfit: 70.91, stopLoss: 74.20)
    #expect(short.railProgress == 0)

    let long = makePosition(entry: 85, takeProfit: 80, stopLoss: 73, direction: .long)
    #expect(long.railProgress == 0)
}

@Test func railProgressIsOneWhenALosingEntrySitsBeyondStopLoss() {
    let long = makePosition(entry: 70, takeProfit: 80, stopLoss: 73, direction: .long)
    #expect(long.railProgress == 1)
}

@Test func railProgressCentresWhenStopEqualsTarget() {
    let position = makePosition(entry: 73.10, takeProfit: 72, stopLoss: 72)
    #expect(position.railProgress == 0.5)
}

@Test func holdDurationIsTheClosedMinusOpenedInterval() {
    let trade = ClosedTrade(
        closedAt: Date(timeIntervalSince1970: 4_920),
        openedAt: Date(timeIntervalSince1970: 0),
        pair: "SOLUSDT",
        direction: .short,
        entryPrice: 72.95,
        exitPrice: 71.85,
        quantity: 1.2,
        pnl: -1.99,
        status: .stopLoss,
        regime: "ranging",
        confidence: 7
    )
    #expect(trade.holdDuration == 4_920)          // 1h 22m
    #expect(abs(trade.confidenceFraction - 0.7) < 0.0001)
}

@Test func confidenceFractionClampsToUnitRange() {
    func trade(confidence: Int) -> ClosedTrade {
        ClosedTrade(
            closedAt: Date(timeIntervalSince1970: 60),
            openedAt: Date(timeIntervalSince1970: 0),
            pair: "BTCUSDT", direction: .long, entryPrice: 1, exitPrice: 2,
            quantity: 1, pnl: 1, status: .takeProfit, regime: "trending_up",
            confidence: confidence
        )
    }
    #expect(trade(confidence: 0).confidenceFraction == 0)
    #expect(trade(confidence: 10).confidenceFraction == 1)
    #expect(trade(confidence: 15).confidenceFraction == 1)
    #expect(trade(confidence: -3).confidenceFraction == 0)
}

@Test func pnlSignBuckets() {
    #expect(PnLSign.of(1.5) == .positive)
    #expect(PnLSign.of(-1.5) == .negative)
    #expect(PnLSign.of(0) == .flat)
}
