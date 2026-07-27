import Testing
import SwiftUI
@testable import BotDesignSystem

@Test func registrationMakesEveryFamilyAvailable() {
    BotFont.registerAll()
    #expect(BotFont.isAvailable(BotFont.Family.serif))
    #expect(BotFont.isAvailable(BotFont.Family.ui))
    #expect(BotFont.isAvailable(BotFont.Family.mono))
}

@Test func registrationIsIdempotent() {
    BotFont.registerAll()
    BotFont.registerAll()
    #expect(BotFont.isAvailable(BotFont.Family.mono))
}

@Test func resolvesARegularFaceForEachFamily() {
    #expect(BotFont.postScriptName(family: BotFont.Family.mono, italic: false) != nil)
    #expect(BotFont.postScriptName(family: BotFont.Family.serif, italic: false) != nil)
    #expect(BotFont.postScriptName(family: BotFont.Family.ui, italic: false) != nil)
}

@Test func resolvesAnItalicSerifForTheNarrative() {
    let italic = BotFont.postScriptName(family: BotFont.Family.serif, italic: true)
    #expect(italic?.localizedCaseInsensitiveContains("italic") == true)
}

@Test func upRightSerifIsNotAnItalicFace() {
    let upright = BotFont.postScriptName(family: BotFont.Family.serif, italic: false)
    #expect(upright?.localizedCaseInsensitiveContains("italic") == false)
}

@Test func unknownFamilyResolvesToNil() {
    #expect(BotFont.postScriptName(family: "No Such Family", italic: false) == nil)
    #expect(BotFont.isAvailable("No Such Family") == false)
}

@Test func semanticStylesAreDistinct() {
    #expect(BotFont.heroFigure != BotFont.tabLabel)
    #expect(BotFont.screenTitle != BotFont.body)
}
