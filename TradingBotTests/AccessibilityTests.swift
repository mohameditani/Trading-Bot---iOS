import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func loadedContainer(fixture: String? = nil) async -> AppContainer {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return container
}

@MainActor
@Test func everyTileExposesAReadableLabel() async {
    let model = EquityViewModel(store: await loadedContainer().store)
    for tile in model.tiles {
        #expect(tile.label.isEmpty == false)
        #expect(tile.value.isEmpty == false)
        #expect(tile.subtitle.isEmpty == false)
    }
}

// Colour must never be the only carrier of meaning: direction and outcome each pair
// their tint with a text label.
@MainActor
@Test func directionAndOutcomeAreConveyedByTextNotOnlyColour() async {
    let model = TradesViewModel(store: await loadedContainer().store)
    #expect(model.rows.isEmpty == false)
    for row in model.rows {
        #expect(row.directionLabel.contains("LONG") || row.directionLabel.contains("SHORT"))
        #expect(row.outcomeLabel == "TP" || row.outcomeLabel == "SL")
    }
}

@MainActor
@Test func vetoDecisionsCarryATextLabel() async {
    let model = ReviewViewModel(store: await loadedContainer().store)
    #expect(model.vetoRows.isEmpty == false)
    for row in model.vetoRows {
        #expect(row.decisionLabel == "proceed" || row.decisionLabel == "block")
        #expect(row.outcomeText.isEmpty == false)
        #expect(row.signalText.isEmpty == false)
    }
}

@MainActor
@Test func placeholderCopyIsNeverEmpty() async {
    let model = ReviewViewModel(store: await loadedContainer(fixture: "aiNull").store)
    for placeholder in model.placeholders {
        #expect(placeholder.title.isEmpty == false)
        #expect(placeholder.description.isEmpty == false)
    }
}

@MainActor
@Test func errorStatesProduceAHumanReadableMessage() async {
    let container = await loadedContainer(fixture: "error")
    let equity = EquityViewModel(store: container.store)
    let trades = TradesViewModel(store: container.store)
    let review = ReviewViewModel(store: container.store)
    // Every screen must explain itself rather than showing a bare empty view.
    #expect(equity.errorMessage?.isEmpty == false)
    #expect(trades.errorMessage?.isEmpty == false)
    #expect(review.errorMessage?.isEmpty == false)
}
