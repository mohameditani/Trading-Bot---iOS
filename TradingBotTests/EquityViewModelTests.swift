import Foundation
import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func loadedViewModel(fixture: String? = nil) async -> EquityViewModel {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return EquityViewModel(store: container.store)
}

@MainActor
@Test func rendersTheHeroEquityFigure() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.equityFigure == "$116.40")
    #expect(viewModel.totalPnlText == "-$12.74")
    #expect(viewModel.totalPnlSign == .negative)
    #expect(viewModel.subtitleText == "all-time · 28 trades")
}

@MainActor
@Test func buildsTheFourStatTilesInDesignOrder() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.tiles.count == 4)

    #expect(viewModel.tiles[0].label == "Balance")
    #expect(viewModel.tiles[0].value == "$87.26")
    #expect(viewModel.tiles[0].subtitle == "realized cash")

    #expect(viewModel.tiles[1].label == "Today P/L")
    #expect(viewModel.tiles[1].value == "-$2.22")
    #expect(viewModel.tiles[1].subtitle == "1W / 2L · 3 trades")

    #expect(viewModel.tiles[2].label == "Win rate")
    #expect(viewModel.tiles[2].value == "39.3%")
    #expect(viewModel.tiles[2].subtitle == "11 of 28 closed")

    // Reserved is the sum of open-position margin, not a wire field.
    #expect(viewModel.tiles[3].label == "Reserved")
    #expect(viewModel.tiles[3].value == "$29.24")
    #expect(viewModel.tiles[3].subtitle == "1 position margin")
}

@MainActor
@Test func labelsTheCurveEndpoints() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.curvePoints.count == 5)
    #expect(viewModel.curveFromLabel == "Jun 20  $100.00")
    #expect(viewModel.curveToLabel == "Jun 30  $87.26")
}

@MainActor
@Test func presentsTheOpenPosition() async throws {
    let viewModel = await loadedViewModel()
    let position = try #require(viewModel.openPosition)
    #expect(position.pair == "SOLUSDT")
    #expect(position.directionLabel == "▼ SHORT")
    #expect(position.leverageText == "2×")
    #expect(position.takeProfitText == "TP 70.91")
    #expect(position.entryText == "entry 73.10")
    #expect(position.stopLossText == "SL 74.20")
    #expect(position.quantityText == "0.80")
    #expect(position.marginText == "$29.24")
    #expect(position.stopsText == "on exchange")
    #expect(abs(position.railProgress - 0.6657) < 0.001)
    #expect(viewModel.openCountText == "1 live")
}

@MainActor
@Test func hasNoOpenPositionWhenTheBotIsFlat() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    #expect(viewModel.openPosition == nil)
    #expect(viewModel.openCountText == "0 live")
    #expect(viewModel.curvePoints.isEmpty)
}

@MainActor
@Test func reservedIsZeroWithNoOpenPositions() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    #expect(viewModel.tiles[3].value == "$0.00")
    #expect(viewModel.tiles[3].subtitle == "0 position margin")
}

@MainActor
@Test func curveLabelsAreBlankWithNoHistory() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    #expect(viewModel.curveFromLabel.isEmpty)
    #expect(viewModel.curveToLabel.isEmpty)
}

@MainActor
@Test func exposesTheStoresLoadState() async {
    let container = AppContainer(arguments: ["-fixture", "error"])
    await container.store.refresh()
    let viewModel = EquityViewModel(store: container.store)
    #expect(viewModel.snapshot == nil)
    #expect(viewModel.errorMessage != nil)
}
