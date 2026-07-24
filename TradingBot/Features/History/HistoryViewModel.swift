import Foundation
import Observation

enum TradeFilter: String, CaseIterable, Sendable {
    case all = "All"
    case wins = "Wins"
    case losses = "Losses"
}

@Observable
@MainActor
final class HistoryViewModel {
    var searchText = ""
    var filter: TradeFilter = .all

    private var trades: [Trade] = []

    func update(trades: [Trade]) {
        self.trades = trades.sorted { $0.closedAt > $1.closedAt }
    }

    var visibleTrades: [Trade] {
        trades.filter { trade in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .wins: matchesFilter = trade.pnl > 0
            case .losses: matchesFilter = trade.pnl < 0
            }
            let matchesSearch = searchText.isEmpty
                || trade.symbol.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }
}
