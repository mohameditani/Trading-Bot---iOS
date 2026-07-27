import SwiftUI
import BotDataKit
import BotDesignSystem

enum AppTab: String, CaseIterable {
    case equity, trades, review

    var item: BotTabItem {
        switch self {
        case .equity:
            return BotTabItem(id: rawValue, title: "EQUITY", systemImage: "chart.line.uptrend.xyaxis")
        case .trades:
            return BotTabItem(id: rawValue, title: "TRADES", systemImage: "line.3.horizontal")
        case .review:
            return BotTabItem(id: rawValue, title: "REVIEW", systemImage: "star")
        }
    }
}

struct RootTabView: View {
    let store: SnapshotStore
    @State private var selection = AppTab.equity.rawValue

    var body: some View {
        ZStack {
            BotColor.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch AppTab(rawValue: selection) ?? .equity {
                    case .equity: EquityView(store: store)
                    case .trades: TradesView(store: store)
                    case .review: ReviewView(store: store)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                BotTabBar(items: AppTab.allCases.map(\.item), selection: $selection)
            }
        }
        .task {
            store.startPolling(interval: .seconds(30))
        }
        .onDisappear {
            store.stopPolling()
        }
    }
}
