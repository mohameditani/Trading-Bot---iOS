import SwiftUI
import BotDesignSystem

/// Live dot, bot identity, exchange, freshness, refresh affordance.
struct StatusHeaderBar: View {
    let freshnessText: String
    let botActivityText: String
    let isBotActivityOverdue: Bool
    let refresh: () async -> Void

    /// The dot reflects the *bot's* health, not the fetch's. A green dot beside a
    /// stale ledger would be a lie.
    private var statusColor: Color {
        isBotActivityOverdue ? BotColor.negative : BotColor.positive
    }

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .overlay(
                    Circle().stroke(statusColor.opacity(0.15), lineWidth: 3)
                )
                .accessibilityHidden(true)

            Text("bot")
                .font(BotFont.figureSmall)
                .foregroundStyle(BotColor.ink)

            Text("· binance futures")
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.greyMuted)

            Spacer(minLength: 0)

            Text(botActivityText)
                .font(BotFont.badge)
                .foregroundStyle(isBotActivityOverdue ? BotColor.negative : BotColor.greyMuted)
                .lineLimit(1)
                .accessibilityLabel(
                    isBotActivityOverdue
                        ? "Bot may have stopped — \(botActivityText)"
                        : botActivityText
                )
                .accessibilityIdentifier("header.botActivity")

            Text(freshnessText)
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.greyMuted)
                .accessibilityLabel("Updated \(freshnessText)")

            Button {
                Task { await refresh() }
            } label: {
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BotColor.grey)
            }
            .accessibilityLabel("Refresh")
            .accessibilityIdentifier("header.refresh")
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, 12)
    }
}
