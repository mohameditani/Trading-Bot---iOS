import Foundation

extension Position {
    /// Where the entry sits on the take-profit -> stop-loss rail, 0...1.
    ///
    /// The rail always runs take-profit (left, green) to stop-loss (right, red)
    /// regardless of direction, so one formula covers both long and short.
    /// The design hardcodes 64%; this computes it so every position renders truthfully.
    ///
    /// The ratio is signed, not absolute: for a short the span is positive and for a
    /// long it is negative, and dividing by it normalises both to the same 0...1 axis.
    /// Taking `abs` of the numerator instead would place an entry *beyond* take-profit —
    /// a deeply winning position — at the stop-loss end of the rail.
    public var railProgress: Double {
        let span = stopLoss - takeProfit
        guard span != 0 else { return 0.5 }
        return min(max((entryPrice - takeProfit) / span, 0), 1)
    }
}

extension ClosedTrade {
    /// How long the position was held.
    public var holdDuration: TimeInterval {
        closedAt.timeIntervalSince(openedAt)
    }

    /// Confidence expressed as a 0...1 bar width. The wire scale is 0...10.
    public var confidenceFraction: Double {
        min(max(Double(confidence) / 10, 0), 1)
    }
}
