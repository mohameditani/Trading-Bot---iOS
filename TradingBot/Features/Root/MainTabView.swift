import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                PlaceholderScreen(title: "Dashboard")
            }
            Tab("Portfolio", systemImage: "chart.pie.fill") {
                PlaceholderScreen(title: "Portfolio")
            }
            Tab("Positions", systemImage: "square.stack.3d.up.fill") {
                PlaceholderScreen(title: "Positions")
            }
            Tab("History", systemImage: "clock.fill") {
                PlaceholderScreen(title: "History")
            }
            Tab("Insights", systemImage: "lightbulb.fill") {
                PlaceholderScreen(title: "Insights")
            }
        }
    }
}

struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        NavigationStack {
            Text(title)
                .navigationTitle(title)
        }
    }
}
