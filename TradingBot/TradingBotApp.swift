import SwiftUI
import BotDesignSystem

@main
struct TradingBotApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: container.store)
                // The palette is a fixed light editorial scheme — every colour is a
                // hardcoded hex with no dark variant. Without this, a device in dark
                // mode mixes those light colours with dark system-adaptive chrome and
                // the result is neither scheme.
                .preferredColorScheme(.light)
        }
    }
}
