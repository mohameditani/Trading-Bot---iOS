import Foundation

/// The chip row on the Trades screen. Pure — no state, no side effects.
public enum TradeFilter: Equatable, Sendable, Hashable {
    case all
    case symbol(String)
    case losses

    public func apply(to trades: [ClosedTrade]) -> [ClosedTrade] {
        switch self {
        case .all:
            return trades
        case .symbol(let prefix):
            let needle = prefix.lowercased()
            return trades.filter { $0.pair.lowercased().hasPrefix(needle) }
        case .losses:
            return trades.filter { $0.pnl < 0 }
        }
    }

    /// The chip label. Only `.all` shows a count, matching the design's "All 28".
    public func title(totalCount: Int) -> String {
        switch self {
        case .all: return "All \(totalCount)"
        case .symbol(let symbol): return symbol
        case .losses: return "Losses"
        }
    }
}

extension Array where Element == ClosedTrade {
    /// Newest close first, as every trade list in the design is ordered.
    public func sortedByCloseDateDescending() -> [ClosedTrade] {
        sorted { $0.closedAt > $1.closedAt }
    }
}
