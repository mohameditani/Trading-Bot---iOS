import SwiftUI
import BotDesignSystem

/// Live dot, bot identity, exchange, freshness, refresh affordance.
struct StatusHeaderBar: View {
    let freshnessText: String
    let refresh: () async -> Void

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(BotColor.positive)
                .frame(width: 7, height: 7)
                .overlay(
                    Circle().stroke(BotColor.positive.opacity(0.15), lineWidth: 3)
                )
                .accessibilityHidden(true)

            Text("bot")
                .font(BotFont.figureSmall)
                .foregroundStyle(BotColor.ink)

            Text("· binance futures")
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.greyMuted)

            Spacer(minLength: 0)

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
