import SwiftUI

struct PortfolioView: View {
    let store: SnapshotStore

    private static let rangeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Portfolio")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Date range")
                    }
                }
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView { CardView { SkeletonView(height: 320) }.padding(16) }
        case .loaded(let snapshot), .refreshing(let snapshot):
            portfolioContent(snapshot.portfolio)
        case .empty:
            EmptyStateView(title: "No portfolio data", systemImage: "chart.pie")
        case .error(let message, let last):
            if let last {
                portfolioContent(last.portfolio)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func portfolioContent(_ portfolio: PortfolioSummary) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("\(Self.rangeFormatter.string(from: portfolio.rangeStart)) - \(Self.rangeFormatter.string(from: portfolio.rangeEnd))")
                        .font(AppTypography.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("dateRangeSelector")

                CardView {
                    EquityChartView(points: portfolio.equityCurve, showsAxes: true)
                        .frame(height: 300)
                }

                CardView {
                    HStack {
                        StatItemView(label: "High", value: Formatters.currency(portfolio.high, decimals: 0), valueColor: AppColors.pnlPositive)
                        StatItemView(label: "Low", value: Formatters.currency(portfolio.low, decimals: 0), valueColor: AppColors.pnlNegative)
                        StatItemView(label: "Current", value: Formatters.currency(portfolio.current))
                    }
                }
            }
            .padding(16)
        }
    }
}
