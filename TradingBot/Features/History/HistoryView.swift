import SwiftUI

struct HistoryView: View {
    let store: SnapshotStore
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Trade History")
                .searchable(text: $viewModel.searchText, prompt: "Search symbol")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Filter", selection: $viewModel.filter) {
                                ForEach(TradeFilter.allCases, id: \.self) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .accessibilityLabel("Filter trades")
                        }
                    }
                }
                .refreshable { await store.refresh() }
        }
        .onChange(of: store.state.value?.trades) { _, trades in
            viewModel.update(trades: trades ?? [])
        }
        .task { viewModel.update(trades: store.state.value?.trades ?? []) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            List(0..<5, id: \.self) { _ in SkeletonView(height: 56) }
        case .loaded, .refreshing:
            tradeList
        case .empty:
            EmptyStateView(title: "No trades yet", systemImage: "clock")
        case .error(let message, let last):
            if last != nil {
                tradeList
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    @ViewBuilder
    private var tradeList: some View {
        if viewModel.visibleTrades.isEmpty {
            EmptyStateView(title: "No matching trades", systemImage: "magnifyingglass")
        } else {
            List(viewModel.visibleTrades) { trade in
                TradeRowView(trade: trade)
            }
            .listStyle(.plain)
            .accessibilityIdentifier("tradeList")
        }
    }
}

struct TradeRowView: View {
    let trade: Trade

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dayFormatter.string(from: trade.closedAt))
                    .font(AppTypography.caption)
                Text(Self.timeFormatter.string(from: trade.closedAt))
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(trade.symbol)
                        .font(AppTypography.body.weight(.semibold))
                    Image(systemName: trade.side == .long ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(trade.side == .long ? AppColors.pnlPositive : AppColors.pnlNegative)
                    Text(trade.side.rawValue)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Text(Formatters.price(trade.entryPrice))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(Formatters.price(trade.exitPrice))
                }
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(Formatters.currency(trade.pnl))
                    .font(AppTypography.statValue)
                    .foregroundStyle(AppColors.pnl(trade.pnl))
                Image(systemName: trade.pnl >= 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(AppColors.pnl(trade.pnl))
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
