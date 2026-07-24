import SwiftUI

@main
struct TradingBotApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            if container.session.isAuthenticated {
                MainTabView()
                    .environment(container)
            } else {
                LoginView(session: container.session)
            }
        }
    }
}
