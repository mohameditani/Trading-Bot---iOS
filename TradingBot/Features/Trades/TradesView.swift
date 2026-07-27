import SwiftUI
import BotDataKit
import BotDesignSystem
import BotDomain

struct TradesView: View {
    @State private var viewModel: TradesViewModel

    init(store: SnapshotStore) {
        _viewModel = State(initialValue: TradesViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            // Data is on screen but the last load did not fully succeed — either it
            // came from cache, or a background refresh failed. Never blocks the UI.
            if viewModel.snapshot != nil, let message = viewModel.errorMessage {
                OfflineBanner(message: message)
            }

            content
        }
        .background(BotColor.paper)
        // `children: .contain` scopes the identifier to this container. Without it the
        // identifier propagates onto every descendant and overrides theirs.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.trades")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                Text("Closed trades")
                    .font(BotFont.screenTitle)
                    .foregroundStyle(BotColor.inkStrong)
                Spacer()
                HStack(spacing: 0) {
                    Text(viewModel.winsText).foregroundStyle(BotColor.positive)
                    Text(" / ").foregroundStyle(BotColor.grey)
                    Text(viewModel.lossesText).foregroundStyle(BotColor.negative)
                }
                .font(BotFont.metadataMono)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(viewModel.winsText) wins, \(viewModel.lossesText) losses")
            }

            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    ForEach(Array(viewModel.filters.enumerated()), id: \.offset) { _, filter in
                        Button {
                            viewModel.select(filter)
                        } label: {
                            FilterChipView(
                                title: viewModel.chipTitle(for: filter),
                                isSelected: viewModel.selectedFilter == filter
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("filter.\(identifier(for: filter))")
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
    }

    private func identifier(for filter: TradeFilter) -> String {
        switch filter {
        case .all: return "all"
        case .symbol(let symbol): return symbol.lowercased()
        case .losses: return "losses"
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingSkeleton()
            Spacer()
        } else if viewModel.snapshot == nil, let message = viewModel.errorMessage {
            ErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.rows.isEmpty {
                        EmptyStateView(
                            message: viewModel.isFilteredEmpty
                                ? "No trades match this filter."
                                : "No closed trades yet."
                        )
                    } else {
                        ForEach(viewModel.rows) { row in
                            TradeRowView(row: row)
                        }
                    }

                    if !viewModel.bySymbol.isEmpty {
                        breakdown(
                            title: "By symbol",
                            identifier: "bysymbol",
                            groups: viewModel.bySymbol,
                            maxAbsolute: viewModel.symbolMaxAbsolute
                        )
                    }

                    if !viewModel.byRegime.isEmpty {
                        breakdown(
                            title: "By regime",
                            identifier: "byregime",
                            groups: viewModel.byRegime,
                            maxAbsolute: viewModel.regimeMaxAbsolute
                        )
                    }

                    Color.clear.frame(height: 24)
                }
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }

    private func breakdown(
        title: String,
        identifier: String,
        groups: [BreakdownGroup],
        maxAbsolute: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(BotFont.cardTitle)
                .foregroundStyle(BotColor.ink)
                .padding(.horizontal, BotSpacing.screenHorizontal)
                .padding(.top, 22)
                .padding(.bottom, 8)

            ForEach(groups) { group in
                BreakdownRowView(group: group, maxAbsolute: maxAbsolute)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("breakdown.\(identifier)")
    }
}
