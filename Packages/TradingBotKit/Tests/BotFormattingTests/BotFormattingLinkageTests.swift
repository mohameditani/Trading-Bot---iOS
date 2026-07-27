import Testing
@testable import BotFormatting

@Test func formattingModuleIsLinkable() {
    #expect(String(describing: BotFormat.self) == "BotFormat")
}
