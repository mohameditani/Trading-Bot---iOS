import SwiftUI
import BotDataKit
import BotDesignSystem

struct EquityView: View {
    @State private var viewModel: EquityViewModel

    init(store: SnapshotStore) {
        _viewModel = State(initialValue: EquityViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            StatusHeaderBar(freshnessText: viewModel.freshnessText) {
                await viewModel.refresh()
            }

            // Data is on screen but the last load did not fully succeed — either it
            // came from cache, or a background refresh failed. Never blocks the UI.
            if viewModel.snapshot != nil, let message = viewModel.errorMessage {
                OfflineBanner(message: message)
            }

            content
        }
        .background(BotColor.paper)
        .accessibilityIdentifier("screen.equity")
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
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    chart
                    tiles
                    openPositionSection
                }
                .padding(.horizontal, BotSpacing.screenHorizontal)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Overline(text: "Equity", color: BotColor.grey)
                .padding(.top, 18)
                .padding(.bottom, 10)

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(viewModel.equityFigure)
                    .font(BotFont.heroFigure)
                    .tracking(-2)
                    .foregroundStyle(BotColor.inkStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityIdentifier("equity.figure")
                Text("USDT")
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.grey)
            }

            HStack(spacing: 8) {
                Text(viewModel.totalPnlText)
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.forSign(viewModel.totalPnlSign))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BotColor.fillForSign(viewModel.totalPnlSign))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(viewModel.subtitleText)
                    .font(BotFont.caption)
                    .foregroundStyle(BotColor.grey)
            }
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var chart: some View {
        if viewModel.curvePoints.isEmpty {
            EmptyStateView(message: "No equity history yet.")
        } else {
            EquityCurveChart(points: viewModel.curvePoints)
                .padding(.top, 18)

            HStack {
                Text(viewModel.curveFromLabel)
                Spacer()
                Text(viewModel.curveToLabel)
            }
            .font(BotFont.badge)
            .foregroundStyle(BotColor.greyMuted)
            .padding(.bottom, 20)
            .overlay(alignment: .bottom) {
                Rectangle().fill(BotColor.hairline).frame(height: 1)
            }
        }
    }

    private var tiles: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: BotSpacing.tileGap),
                GridItem(.flexible(), spacing: BotSpacing.tileGap),
            ],
            spacing: BotSpacing.tileGap
        ) {
            ForEach(viewModel.tiles) { tile in
                StatTile(
                    label: tile.label,
                    value: tile.value,
                    valueColor: color(for: tile),
                    subtitle: tile.subtitle
                )
            }
        }
        .padding(.top, 20)
    }

    /// Balance and Win rate carry no sign tint — the design renders them in ink.
    /// Only Today P/L is sign-tinted, and only Reserved is gold.
    private func color(for tile: TileData) -> Color {
        if tile.isAccent { return BotColor.accent }
        return tile.sign == .flat ? BotColor.ink : BotColor.forSign(tile.sign)
    }

    @ViewBuilder
    private var openPositionSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text("Open position")
                .font(BotFont.sectionTitle)
                .foregroundStyle(BotColor.ink)
            Text(viewModel.openCountText)
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.greyMuted)
            Spacer(minLength: 0)
        }
        .padding(.top, BotSpacing.sectionGap)
        .padding(.bottom, 11)

        if let position = viewModel.openPosition {
            OpenPositionCard(position: position)
        } else {
            EmptyStateView(message: "No position open.")
        }
    }
}
