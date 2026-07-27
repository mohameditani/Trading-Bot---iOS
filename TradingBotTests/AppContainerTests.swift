import Testing
import BotDataKit
@testable import TradingBot

@Test func defaultsToTheFullFixtureWhenNoArgumentIsGiven() {
    #expect(AppContainer.fixtureName(from: []) == nil)
}

@Test func readsTheFixtureNameFromLaunchArguments() {
    #expect(AppContainer.fixtureName(from: ["-fixture", "aiNull"]) == "aiNull")
    #expect(AppContainer.fixtureName(from: ["-fixture", "empty"]) == "empty")
    #expect(AppContainer.fixtureName(from: ["-fixture", "error"]) == "error")
}

@Test func ignoresATrailingFixtureFlagWithNoValue() {
    #expect(AppContainer.fixtureName(from: ["-fixture"]) == nil)
}

@Test func mapsFixtureNamesToBundledResources() {
    #expect(AppContainer.resourceName(for: nil) == "snapshot")
    #expect(AppContainer.resourceName(for: "full") == "snapshot")
    #expect(AppContainer.resourceName(for: "aiNull") == "snapshot-ai-null")
    #expect(AppContainer.resourceName(for: "empty") == "snapshot-empty")
}

@MainActor
@Test func containerBuildsAStoreThatLoadsTheDefaultSnapshot() async {
    let container = AppContainer(arguments: [])
    await container.store.refresh()
    #expect(container.store.state.value?.summary.total == 28)
}

@MainActor
@Test func errorFixtureProducesAFailedStore() async {
    let container = AppContainer(arguments: ["-fixture", "error"])
    await container.store.refresh()
    #expect(container.store.state.value == nil)
    #expect(container.store.state.error != nil)
}

@MainActor
@Test func aiNullFixtureLoadsASnapshotWithoutAReviewLayer() async {
    let container = AppContainer(arguments: ["-fixture", "aiNull"])
    await container.store.refresh()
    #expect(container.store.state.value?.hasReviewLayer == false)
}

@MainActor
@Test func emptyFixtureLoadsASnapshotWithNoHistory() async {
    let container = AppContainer(arguments: ["-fixture", "empty"])
    await container.store.refresh()
    #expect(container.store.state.value?.closedTrades.isEmpty == true)
    #expect(container.store.state.value?.openPositions.isEmpty == true)
}
