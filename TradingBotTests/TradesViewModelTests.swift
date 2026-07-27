import Foundation
import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func loadedViewModel(fixture: String? = nil) async -> TradesViewModel {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return TradesViewModel(store: container.store)
}

@MainActor
@Test func showsEveryTradeByDefault() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.selectedFilter == .all)
    #expect(viewModel.rows.count == 9)
}

@MainActor
@Test func tallyCountsWinsAndLossesFromTheSummary() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.winsText == "11W")
    #expect(viewModel.lossesText == "17L")
}

@MainActor
@Test func theAllChipCarriesTheDerivedCount() async {
    let viewModel = await loadedViewModel()
    // 9 trades in the payload — the chip must not hardcode the design's "28".
    #expect(viewModel.chipTitle(for: .all) == "All 9")
    #expect(viewModel.chipTitle(for: .symbol("BTC")) == "BTC")
    #expect(viewModel.chipTitle(for: .losses) == "Losses")
}

@MainActor
@Test func filteringBySymbolNarrowsTheRows() async {
    let viewModel = await loadedViewModel()
    viewModel.select(.symbol("SOL"))
    #expect(viewModel.rows.count == 5)
    #expect(viewModel.rows.allSatisfy { $0.pair == "SOLUSDT" })

    viewModel.select(.symbol("BTC"))
    #expect(viewModel.rows.count == 4)
}

@MainActor
@Test func filteringByLossesKeepsOnlyNegatives() async {
    let viewModel = await loadedViewModel()
    viewModel.select(.losses)
    #expect(viewModel.rows.count == 5)
    #expect(viewModel.rows.allSatisfy { $0.pnlSign == .negative })
}

@MainActor
@Test func rowsAreSortedNewestFirst() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.rows.first?.dateText == "Jun 30 14:31")
    #expect(viewModel.rows.last?.dateText == "Jun 27 08:35")
}

@MainActor
@Test func rowPresentationMatchesTheDesign() async throws {
    let viewModel = await loadedViewModel()
    let row = try #require(viewModel.rows.first)
    #expect(row.pair == "SOLUSDT")
    #expect(row.directionLabel == "▼ SHORT")
    #expect(row.outcomeLabel == "SL")
    #expect(row.pnlText == "-$1.99")
    #expect(row.priceText == "72.95 → 71.85")
    #expect(row.holdText == "2h 26m")
    #expect(row.regimeText == "ranging")
    #expect(abs(row.confidenceFraction - 0.7) < 0.0001)
}

@MainActor
@Test func widePricesDropTheirDecimals() async throws {
    let viewModel = await loadedViewModel()
    let btc = try #require(viewModel.rows.first { $0.pair == "BTCUSDT" })
    #expect(btc.priceText == "58,800 → 58,289")
}

@MainActor
@Test func breakdownsCarryTheirNormalisationBase() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.bySymbol.count == 2)
    #expect(viewModel.symbolMaxAbsolute == 18.84)
    #expect(viewModel.byRegime.count == 3)
    #expect(viewModel.regimeMaxAbsolute == 22.99)
}

@MainActor
@Test func emptyHistoryProducesNoRowsAndNoBreakdowns() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    #expect(viewModel.rows.isEmpty)
    #expect(viewModel.bySymbol.isEmpty)
    #expect(viewModel.chipTitle(for: .all) == "All 0")
}

@MainActor
@Test func aFilterMatchingNothingYieldsAnEmptyRowSet() async {
    let viewModel = await loadedViewModel()
    viewModel.select(.symbol("DOGE"))
    #expect(viewModel.rows.isEmpty)
    #expect(viewModel.isFilteredEmpty)
}

@MainActor
@Test func anEmptyPayloadIsNotAFilteredEmptyState() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    // Nothing to show because there is no history, not because a filter hid it.
    #expect(viewModel.isFilteredEmpty == false)
}
