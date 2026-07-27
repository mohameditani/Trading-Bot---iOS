import Foundation
import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func loadedViewModel(fixture: String? = nil) async -> ReviewViewModel {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return ReviewViewModel(store: container.store)
}

// MARK: - AI enabled

@MainActor
@Test func showsTheReviewLayerWhenPresent() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.hasReviewLayer)
    #expect(viewModel.dateText == "2026-06-30")
}

@MainActor
@Test func presentsTheNarrativeInTypographicQuotes() async throws {
    let viewModel = await loadedViewModel()
    let report = try #require(viewModel.report)
    #expect(report.narrative.hasPrefix("\u{201C}"))
    #expect(report.narrative.hasSuffix("\u{201D}"))
    #expect(report.narrative.contains("Choppy fortnight"))
}

@MainActor
@Test func splitsWorkingAndLosingLists() async throws {
    let viewModel = await loadedViewModel()
    let report = try #require(viewModel.report)
    #expect(report.working == ["BTC entries in clear trends", "Stops kept losses small"])
    #expect(report.losing.count == 2)
    #expect(report.losing[0] == "SOL trades in ranging regime")
}

@MainActor
@Test func presentsConfigSuggestionsAsCurrentToSuggested() async throws {
    let viewModel = await loadedViewModel()
    let report = try #require(viewModel.report)
    #expect(report.suggestions.count == 2)
    #expect(report.suggestions[0].param == "ADX_TREND_MIN_SOLUSDT")
    #expect(report.suggestions[0].current == "25")
    #expect(report.suggestions[0].suggested == "30")
    #expect(report.suggestions[0].rationale == "filter more SOL chop")
}

@MainActor
@Test func summarisesTheVetoLog() async throws {
    let viewModel = await loadedViewModel()
    let summary = try #require(viewModel.vetoSummary)
    #expect(summary.proceedText == "26")
    #expect(summary.blockText == "2")
    #expect(summary.winRateText == "41.7%")
    #expect(summary.scoredText == "24 scored")
}

@MainActor
@Test func presentsVetoRowsWithFlagsAndOutcome() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.vetoRows.count == 2)

    let proceeded = viewModel.vetoRows[0]
    #expect(proceeded.symbol == "SOLUSDT")
    #expect(proceeded.signalText == "SELL")
    #expect(proceeded.signalIsBuy == false)
    #expect(proceeded.decisionLabel == "proceed")
    #expect(proceeded.didProceed)
    #expect(proceeded.flags == ["low_adx_chop"])
    #expect(proceeded.outcomeText == "loss")
    #expect(proceeded.timeText == "Jun 30 12:05")
}

@MainActor
@Test func aBlockedSignalWithNoResultReadsNoOutcome() async {
    let viewModel = await loadedViewModel()
    let blocked = viewModel.vetoRows[1]
    #expect(blocked.decisionLabel == "block")
    #expect(blocked.didProceed == false)
    #expect(blocked.signalIsBuy)
    #expect(blocked.outcomeText == "no outcome")
    #expect(blocked.outcomeSign == .flat)
}

@MainActor
@Test func presentsLessons() async throws {
    let viewModel = await loadedViewModel()
    #expect(viewModel.lessonCountText == "1 recent")
    let lesson = try #require(viewModel.lessons.first)
    #expect(lesson.pair == "SOLUSDT")
    #expect(lesson.outcomeLabel == "SL")
    #expect(lesson.text == "Avoid shorting into established support in a ranging market.")
    #expect(lesson.metaText == "pattern: shorted into support · conf: high")
    #expect(lesson.tags == ["support", "ranging", "short"])
}

// MARK: - AI null — the design's fourth screen

@MainActor
@Test func fallsBackToPlaceholdersWhenTheLayerIsOff() async {
    let viewModel = await loadedViewModel(fixture: "aiNull")
    #expect(viewModel.hasReviewLayer == false)
    #expect(viewModel.report == nil)
    #expect(viewModel.vetoSummary == nil)
    #expect(viewModel.vetoRows.isEmpty)
    #expect(viewModel.lessons.isEmpty)
}

@MainActor
@Test func theHeaderReadsOffWhenTheLayerIsDisabled() async {
    let viewModel = await loadedViewModel(fixture: "aiNull")
    #expect(viewModel.dateText == "off")
}

@MainActor
@Test func providesExactlyThreePlaceholdersWithTheDesignCopy() async {
    let viewModel = await loadedViewModel(fixture: "aiNull")
    #expect(viewModel.placeholders.count == 3)
    #expect(viewModel.placeholders[0].title == "Latest AI report")
    #expect(viewModel.placeholders[1].title == "Veto log")
    #expect(viewModel.placeholders[2].title == "Lessons")
    #expect(viewModel.placeholders[2].description
        == "Captures a post-mortem after each loss with failure patterns and tags.")
}

@MainActor
@Test func placeholdersAreAbsentWhenTheLayerIsOn() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.placeholders.isEmpty)
}

@MainActor
@Test func placeholdersAreAbsentBeforeAnythingHasLoaded() async {
    // No snapshot at all is a loading/error state, not "the layer is off".
    let container = AppContainer(arguments: ["-fixture", "error"])
    await container.store.refresh()
    let viewModel = ReviewViewModel(store: container.store)
    #expect(viewModel.placeholders.isEmpty)
}
