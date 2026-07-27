import Testing
import SwiftUI
@testable import BotDesignSystem

@Test func paperTokenExists() {
    #expect(BotColor.paper != Color.clear)
}
