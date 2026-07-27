import Testing
import SwiftUI
@testable import BotDesignSystem

@Test func tabItemsKeepTheirIdentity() {
    let item = BotTabItem(id: "equity", title: "EQUITY", systemImage: "chart.line.uptrend.xyaxis")
    #expect(item.id == "equity")
    #expect(item.title == "EQUITY")
}

@Test func tabBarTintsOnlyTheSelectedItem() {
    let items = [
        BotTabItem(id: "equity", title: "EQUITY", systemImage: "chart.line.uptrend.xyaxis"),
        BotTabItem(id: "trades", title: "TRADES", systemImage: "line.3.horizontal"),
    ]
    let bar = BotTabBar(items: items, selection: .constant("equity"))
    #expect(bar.color(for: items[0]) == BotColor.accent)
    #expect(bar.color(for: items[1]) == BotColor.greyMuted)
}
