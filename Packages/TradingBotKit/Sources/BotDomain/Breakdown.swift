import Foundation

/// Win-rate colour tiers from the design: >=50% green, >=33% grey, below that red.
public enum WinRateTier: Equatable, Sendable {
    case strong, neutral, weak
}

public struct BreakdownGroup: Equatable, Sendable, Identifiable {
    public let key: String
    public let trades: Int
    public let winRate: Double
    public let netPnl: Double

    public var id: String { key }

    public init(key: String, trades: Int, winRate: Double, netPnl: Double) {
        self.key = key
        self.trades = trades
        self.winRate = winRate
        self.netPnl = netPnl
    }

    public var keyDisplay: String { key.replacingOccurrences(of: "_", with: " ") }

    public var winRateTier: WinRateTier {
        if winRate >= 50 { return .strong }
        if winRate >= 33 { return .neutral }
        return .weak
    }

    /// Bar width 0...1, normalised against the largest magnitude in the group set so
    /// a heavy loss reads as full-width just as a heavy gain does.
    public func barFraction(relativeTo maxAbsolute: Double) -> Double {
        guard maxAbsolute > 0 else { return 0 }
        return min(max(abs(netPnl) / maxAbsolute, 0), 1)
    }
}

extension Array where Element == BreakdownGroup {
    public var maxAbsoluteNet: Double {
        reduce(0) { Swift.max($0, Swift.abs($1.netPnl)) }
    }
}
