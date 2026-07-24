import SwiftUI

struct BreakdownView: View {
    let store: SnapshotStore
    @State private var mode: Mode = .bySymbol

    enum Mode: String, CaseIterable {
        case bySymbol = "By Symbol"
        case byRegime = "By Regime"
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Breakdown mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            content
        }
        .background(AppColors.screenBackground)
        .navigationTitle("Breakdown")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView { CardView { SkeletonView(height: 200) }.padding(16) }
        case .loaded(let snapshot), .refreshing(let snapshot):
            breakdownContent(snapshot.breakdown)
        case .empty:
            EmptyStateView(title: "No breakdown data", systemImage: "chart.bar")
        case .error(let message, let last):
            if let last {
                breakdownContent(last.breakdown)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func breakdownContent(_ breakdown: Breakdown) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                switch mode {
                case .bySymbol:
                    CardView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("By Symbol")
                                .font(AppTypography.cardTitle)
                            ForEach(breakdown.bySymbol) { item in
                                SymbolBreakdownRow(item: item)
                            }
                        }
                    }
                case .byRegime:
                    CardView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("By Regime")
                                .font(AppTypography.cardTitle)
                            ForEach(breakdown.byRegime) { item in
                                RegimeBreakdownRow(item: item)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct SymbolBreakdownRow: View {
    let item: SymbolBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.symbol)
                    .font(AppTypography.body.weight(.semibold))
                Spacer()
                Text(Formatters.percent(item.winRate))
                    .font(AppTypography.statValue)
                Text(Formatters.currency(item.netPnL))
                    .font(AppTypography.statValue)
                    .foregroundStyle(AppColors.pnl(item.netPnL))
            }
            HStack {
                Text("\(item.trades) Trades")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Win Rate")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Text("Net P/L")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: item.winRate)
                .tint(AppColors.pnl(item.netPnL))
        }
        .accessibilityElement(children: .combine)
    }
}

struct RegimeBreakdownRow: View {
    let item: RegimeBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.regime)
                    .font(AppTypography.body.weight(.semibold))
                Spacer()
                Text(Formatters.percent(item.winRate))
                    .font(AppTypography.statValue)
            }
            Text("\(item.trades) Trades")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: item.winRate)
                .tint(item.winRate >= 0.2 ? AppColors.pnlPositive : AppColors.pnlNegative)
        }
        .accessibilityElement(children: .combine)
    }
}
