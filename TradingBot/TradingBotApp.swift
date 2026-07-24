import SwiftUI

@main
struct TradingBotApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(container)
        }
    }
}
