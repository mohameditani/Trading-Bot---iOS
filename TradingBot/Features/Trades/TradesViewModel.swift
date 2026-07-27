import Foundation
import Observation
import BotDataKit
import BotDomain
import BotFormatting

struct TradeRowPresentation: Identifiable, Equatable {
    let id: String
    let pair: String
    let directionLabel: String
    let directionSign: PnLSign
    let outcomeLabel: String
    let outcomeIsWin: Bool
    let pnlText: String
    let pnlSign: PnLSign
    let dateText: String
    let priceText: String
    let holdText: String
    let regimeText: String
    let confidenceFraction: Double
}

@MainActor
@Observable
final class TradesViewModel {
    private let store: SnapshotStore
    private(set) var selectedFilter: TradeFilter = .all

    init(store: SnapshotStore) {
        self.store = store
    }

    var snapshot: Snapshot? { store.state.value }
    var isLoading: Bool { store.state.isLoading && snapshot == nil }
    var isStale: Bool { store.isStale }
    var errorMessage: String? {
        guard snapshot == nil else { return store.lastErrorMessage }
        guard let error = store.state.error else { return nil }
        return (error as? SnapshotError)?.userMessage ?? error.localizedDescription
    }

    let filters: [TradeFilter] = [.all, .symbol("BTC"), .symbol("SOL"), .losses]

    private var allTrades: [ClosedTrade] { snapshot?.closedTrades ?? [] }

    /// The chip count is derived from the payload, never the design's literal 28.
    func chipTitle(for filter: TradeFilter) -> String {
        filter.title(totalCount: allTrades.count)
    }

    func select(_ filter: TradeFilter) {
        selectedFilter = filter
    }

    var winsText: String { "\(snapshot?.summary.wins ?? 0)W" }
    var lossesText: String { "\(snapshot?.summary.losses ?? 0)L" }

    var isFilteredEmpty: Bool { rows.isEmpty && !allTrades.isEmpty }

    var rows: [TradeRowPresentation] {
        selectedFilter
            .apply(to: allTrades)
            .sortedByCloseDateDescending()
            .map { trade in
                let isLong = trade.direction == .long
                let isWin = trade.status == .takeProfit
                return TradeRowPresentation(
                    id: trade.id,
                    pair: trade.pair,
                    directionLabel: isLong ? "▲ LONG" : "▼ SHORT",
                    directionSign: isLong ? .positive : .negative,
                    outcomeLabel: isWin ? "TP" : "SL",
                    outcomeIsWin: isWin,
                    pnlText: BotFormat.signedCurrency(trade.pnl),
                    pnlSign: PnLSign.of(trade.pnl),
                    dateText: BotFormat.stamp(trade.closedAt),
                    priceText: "\(BotFormat.price(trade.entryPrice)) → \(BotFormat.price(trade.exitPrice))",
                    holdText: BotFormat.duration(trade.holdDuration),
                    regimeText: trade.regimeDisplay,
                    confidenceFraction: trade.confidenceFraction
                )
            }
    }

    var bySymbol: [BreakdownGroup] { snapshot?.bySymbol ?? [] }
    var byRegime: [BreakdownGroup] { snapshot?.byRegime ?? [] }
    var symbolMaxAbsolute: Double { bySymbol.maxAbsoluteNet }
    var regimeMaxAbsolute: Double { byRegime.maxAbsoluteNet }

    func refresh() async {
        await store.refresh()
    }
}
