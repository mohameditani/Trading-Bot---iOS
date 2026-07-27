import Testing
import SwiftUI
import BotDomain
@testable import BotDesignSystem

@Test func paletteExposesEveryTokenTheDesignUses() {
    // Colours are opaque values; assert distinctness so a copy-paste slip is caught.
    let tokens: [Color] = [
        BotColor.paper, BotColor.cardTop, BotColor.cardBottom, BotColor.surface,
        BotColor.chipNeutral, BotColor.track, BotColor.inkStrong, BotColor.ink,
        BotColor.inkBody, BotColor.grey, BotColor.greyMuted, BotColor.positive,
        BotColor.negative, BotColor.accent,
    ]
    #expect(Set(tokens.map { String(describing: $0) }).count == tokens.count)
}

@Test func signColoursMapToTheDesignPalette() {
    #expect(BotColor.forSign(.positive) == BotColor.positive)
    #expect(BotColor.forSign(.negative) == BotColor.negative)
    #expect(BotColor.forSign(.flat) == BotColor.grey)
}

@Test func winRateTierColoursMatchTheDesignThresholds() {
    #expect(BotColor.forWinRateTier(.strong) == BotColor.positive)
    #expect(BotColor.forWinRateTier(.neutral) == BotColor.grey)
    #expect(BotColor.forWinRateTier(.weak) == BotColor.negative)
}
