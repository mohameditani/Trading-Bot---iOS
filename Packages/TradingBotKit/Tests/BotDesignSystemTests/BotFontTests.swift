import Testing
import SwiftUI
@testable import BotDesignSystem

// The app uses the system font (SF Pro / SF Mono), matching RentRoll. There are no
// bundled faces to register and no family names to resolve, so the old registration
// tests are gone with them — what matters now is that the semantic scale stays
// distinct and that figures stay monospaced.

@Test func semanticStylesAreDistinct() {
    #expect(BotFont.heroFigure != BotFont.tabLabel)
    #expect(BotFont.screenTitle != BotFont.body)
    #expect(BotFont.tileValue != BotFont.figure)
    #expect(BotFont.sectionTitle != BotFont.caption)
}

@Test func headingsAreHeavierThanBodyAtTheSameSize() {
    // Hierarchy now comes from weight rather than from a contrasting typeface, so a
    // heading and body text at one size must still differ.
    #expect(BotFont.heading(13) != BotFont.ui(13))
}

@Test func figureStylesAreMonospaced() {
    // Column alignment across trade rows depends on this.
    #expect(BotFont.figure == BotFont.mono(13))
    #expect(BotFont.tileValue == BotFont.mono(21))
    #expect(BotFont.heroFigure == BotFont.mono(46, weight: .light))
    #expect(BotFont.pnlFigure == BotFont.mono(14.5))
}

@Test func interfaceStylesAreNotMonospaced() {
    #expect(BotFont.body == BotFont.ui(13))
    #expect(BotFont.body != BotFont.mono(13))
}

@Test func designSizesAreUnchangedByTheTypefaceSwitch() {
    // Point sizes come from the mockup; only the typeface changed, so layout must not.
    #expect(BotFont.screenTitle == BotFont.heading(27, weight: .semibold))
    #expect(BotFont.caption == BotFont.ui(11.5))
    #expect(BotFont.badge == BotFont.mono(9.5))
}
