import Foundation
import Observation
import BotDataKit
import BotDomain
import BotFormatting

struct TileData: Identifiable, Equatable {
    let label: String
    let value: String
    let sign: PnLSign
    let isAccent: Bool
    let subtitle: String

    var id: String { label }
}

struct PositionPresentation: Equatable {
    let pair: String
    let directionLabel: String
    let directionSign: PnLSign
    let leverageText: String
    let elapsedText: String
    let takeProfitText: String
    let entryText: String
    let stopLossText: String
    let railProgress: Double
    let quantityText: String
    let marginText: String
    let stopsText: String
}

/// Everything the Equity screen renders, pre-formatted. The View does no maths.
@MainActor
@Observable
final class EquityViewModel {
    private let store: SnapshotStore

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

    var freshnessText: String { BotFormat.freshness(seconds: store.secondsSinceUpdate) }

    // MARK: - Hero

    var equityFigure: String { BotFormat.currency(snapshot?.summary.equity ?? 0) }
    var totalPnlText: String { BotFormat.signedCurrency(snapshot?.summary.totalPnl) }
    var totalPnlSign: PnLSign { PnLSign.of(snapshot?.summary.totalPnl ?? 0) }
    var subtitleText: String { "all-time · \(snapshot?.summary.total ?? 0) trades" }

    // MARK: - Curve

    var curvePoints: [CurvePoint] { snapshot?.curve ?? [] }

    var curveFromLabel: String {
        guard let first = curvePoints.first else { return "" }
        return "\(BotFormat.day(first.date))  \(BotFormat.currency(first.equity))"
    }

    var curveToLabel: String {
        guard let last = curvePoints.last else { return "" }
        return "\(BotFormat.day(last.date))  \(BotFormat.currency(last.equity))"
    }

    // MARK: - Tiles

    /// Reserved is derived — the sum of margin across open positions, not a wire field.
    private var reservedMargin: Double {
        (snapshot?.openPositions ?? []).reduce(0) { $0 + $1.margin }
    }

    var tiles: [TileData] {
        guard let summary = snapshot?.summary else { return [] }
        return [
            TileData(
                label: "Balance",
                value: BotFormat.currency(summary.balance),
                sign: .flat, isAccent: false,
                subtitle: "realized cash"
            ),
            TileData(
                label: "Today P/L",
                value: BotFormat.signedCurrency(summary.todayPnl),
                sign: PnLSign.of(summary.todayPnl), isAccent: false,
                subtitle: "\(summary.todayWins)W / \(summary.todayLosses)L · \(summary.todayTotal) trades"
            ),
            TileData(
                label: "Win rate",
                value: BotFormat.percent(summary.winRate),
                sign: .flat, isAccent: false,
                subtitle: "\(summary.wins) of \(summary.total) closed"
            ),
            TileData(
                label: "Reserved",
                value: BotFormat.currency(reservedMargin),
                sign: .flat, isAccent: true,
                subtitle: "\(summary.open) position margin"
            ),
        ]
    }

    // MARK: - Open position

    var openCountText: String { "\(snapshot?.summary.open ?? 0) live" }

    var openPosition: PositionPresentation? {
        guard let position = snapshot?.openPositions.first else { return nil }
        let isLong = position.direction == .long
        return PositionPresentation(
            pair: position.pair,
            directionLabel: isLong ? "▲ LONG" : "▼ SHORT",
            directionSign: isLong ? .positive : .negative,
            leverageText: BotFormat.leverage(position.leverage),
            elapsedText: BotFormat.duration(
                (snapshot?.generatedAt ?? position.openedAt)
                    .timeIntervalSince(position.openedAt)
            ),
            takeProfitText: "TP \(BotFormat.price(position.takeProfit))",
            entryText: "entry \(BotFormat.price(position.entryPrice))",
            stopLossText: "SL \(BotFormat.price(position.stopLoss))",
            railProgress: position.railProgress,
            quantityText: BotFormat.quantity(position.quantity),
            marginText: BotFormat.currency(position.margin),
            stopsText: position.exchangeStops ? "on exchange" : "local"
        )
    }

    func refresh() async {
        await store.refresh()
    }
}
