import SwiftUI
import BotDesignSystem

@main
struct TradingBotApp: App {
    @State private var container = AppContainer()

    init() {
        // Custom faces ship in the package bundle, so they need runtime registration.
        BotFont.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(store: container.store)
        }
    }
}
