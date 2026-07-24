import SwiftUI

struct PositionCardView: View {
    let position: Position

    private var durationText: String {
        let interval = Date.now.timeIntervalSince(position.openedAt)
        let minutes = max(1, Int(interval / 60))
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h \(minutes % 60)m" }
        return "\(hours / 24)d \(hours % 24)h"
    }

    var body: some View {
        CardView {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(position.symbol)
                        .font(AppTypography.cardTitle)
                    BadgeView(
                        text: position.side.rawValue,
                        color: position.side == .long ? AppColors.pnlPositive : AppColors.pnlNegative
                    )
                    Spacer()
                    Label(durationText, systemImage: "clock")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItemView(label: "Entry Price", value: Formatters.price(position.entryPrice))
                    StatItemView(label: "Quantity", value: String(format: "%.4f", position.quantity))
                    StatItemView(label: "Leverage", value: "\(position.leverage)x")
                    StatItemView(label: "Margin", value: Formatters.currency(position.margin))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Take-Profit")
                            .font(AppTypography.statLabel)
                            .foregroundStyle(.secondary)
                        Text(Formatters.price(position.takeProfit))
                            .font(AppTypography.statValue)
                            .foregroundStyle(AppColors.pnlPositive)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stop-Loss")
                            .font(AppTypography.statLabel)
                            .foregroundStyle(.secondary)
                        Text(Formatters.price(position.stopLoss))
                            .font(AppTypography.statValue)
                            .foregroundStyle(AppColors.pnlNegative)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unrealized P/L")
                            .font(AppTypography.statLabel)
                            .foregroundStyle(.secondary)
                        Text(Formatters.currency(position.unrealizedPnL))
                            .font(AppTypography.statValue)
                            .foregroundStyle(AppColors.pnl(position.unrealizedPnL))
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("positionCard")
    }
}
