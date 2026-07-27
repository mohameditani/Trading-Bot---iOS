import Testing
import SwiftUI
import BotDomain
@testable import BotDesignSystem

@Test func cardWrapsItsContent() {
    let card = BotCard { Text("hello") }
    #expect(String(describing: type(of: card.body)).isEmpty == false)
}

@Test func badgeCarriesItsLabelAndTone() {
    let badge = BotBadge(text: "TP", tone: .positive)
    #expect(badge.text == "TP")
    #expect(badge.tone == .positive)
}

@Test func filterChipTracksSelection() {
    let selected = FilterChipView(title: "All 28", isSelected: true)
    let plain = FilterChipView(title: "BTC", isSelected: false)
    #expect(selected.isSelected)
    #expect(plain.isSelected == false)
}

@Test func statTileHoldsEveryFieldTheDesignShows() {
    let tile = StatTile(
        label: "Today P/L", value: "-$2.22",
        valueColor: BotColor.negative, subtitle: "1W / 2L · 3 trades"
    )
    #expect(tile.label == "Today P/L")
    #expect(tile.value == "-$2.22")
    #expect(tile.subtitle == "1W / 2L · 3 trades")
}

@Test func targetRailClampsTheMarkerToItsTrack() {
    #expect(TargetRail(progress: 1.4).clampedProgress == 1)
    #expect(TargetRail(progress: -0.2).clampedProgress == 0)
    #expect(abs(TargetRail(progress: 0.6657).clampedProgress - 0.6657) < 0.0001)
}

@Test func progressBarClampsItsFill() {
    #expect(ProgressBar(fraction: 2, color: BotColor.positive).clampedFraction == 1)
    #expect(ProgressBar(fraction: -1, color: BotColor.positive).clampedFraction == 0)
}

@Test func tagChipPrefixesAHash() {
    #expect(TagChip(tag: "ranging").displayText == "#ranging")
}

@Test func badgeTonesCoverEveryOutcome() {
    #expect(BotBadge(text: "TP", tone: .positive).foreground == BotColor.positive)
    #expect(BotBadge(text: "SL", tone: .negative).foreground == BotColor.negative)
    #expect(BotBadge(text: "flag", tone: .accent).foreground == BotColor.accent)
    #expect(BotBadge(text: "x", tone: .neutral).foreground == BotColor.grey)
}
