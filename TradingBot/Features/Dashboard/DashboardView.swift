import SwiftUI

struct DashboardView: View {
    let store: SnapshotStore

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Trading Bot")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "bell")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Notifications")
                    }
                }
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            loadingView
        case .loaded(let snapshot), .refreshing(let snapshot):
            dashboardContent(snapshot.dashboard)
        case .empty:
            EmptyStateView(title: "No data yet", systemImage: "tray")
        case .error(let message, let last):
            if let last {
                dashboardContent(last.dashboard)
                    .overlay(alignment: .top) { offlineBanner(message) }
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func dashboardContent(_ summary: DashboardSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Equity")
                        .font(AppTypography.statLabel)
                        .foregroundStyle(AppColors.secondaryText)
                    Text(Formatters.currency(summary.totalEquity))
                        .font(AppTypography.largeEquity)
                        .contentTransition(.numericText())
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("totalEquity")

                CardView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StatItemView(label: "Balance", value: Formatters.currency(summary.balance))
                        StatItemView(label: "All-Time P/L", value: Formatters.currency(summary.allTimePnL), valueColor: AppColors.pnl(summary.allTimePnL))
                        StatItemView(label: "Win Rate", value: Formatters.percent(summary.winRate))
                        StatItemView(label: "Open Positions", value: "\(summary.openPositionsCount)", systemImage: "person.crop.circle")
                        StatItemView(label: "Today P/L", value: Formatters.currency(summary.todayPnL), valueColor: AppColors.pnl(summary.todayPnL))
                        StatItemView(label: "Total Trades", value: "\(summary.totalTrades)", systemImage: "chart.bar.fill")
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Equity Curve (All-Time)")
                            .font(AppTypography.cardTitle)
                        EquityChartView(points: summary.equityCurve)
                            .frame(height: 140)
                    }
                }
            }
            .padding(16)
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                SkeletonView(height: 44)
                CardView { SkeletonView(height: 160) }
                CardView { SkeletonView(height: 180) }
            }
            .padding(16)
        }
    }

    private func offlineBanner(_ message: String) -> some View {
        Text("Offline — showing last known data")
            .font(AppTypography.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 4)
            .accessibilityLabel(message)
    }
}
