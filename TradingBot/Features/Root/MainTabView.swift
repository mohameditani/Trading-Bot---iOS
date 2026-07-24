import SwiftUI

struct MainTabView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView(store: container.store)
            }
            Tab("Portfolio", systemImage: "chart.pie.fill") {
                PortfolioView(store: container.store)
            }
            Tab("Positions", systemImage: "square.stack.3d.up.fill") {
                PositionsView(store: container.store)
            }
            Tab("History", systemImage: "clock.fill") {
                HistoryView(store: container.store)
            }
            Tab("Insights", systemImage: "lightbulb.fill") {
                InsightsView(store: container.store)
            }
        }
        .task { container.store.startPolling() }
    }
}
