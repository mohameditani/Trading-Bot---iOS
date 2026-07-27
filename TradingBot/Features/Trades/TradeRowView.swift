import SwiftUI
import BotDesignSystem

struct TradeRowView: View {
    let row: TradeRowPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(row.pair)
                    .font(BotFont.figure)
                    .fontWeight(.medium)
                    .foregroundStyle(BotColor.inkStrong)

                Text(row.directionLabel)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.forSign(row.directionSign))

                BotBadge(text: row.outcomeLabel, tone: row.outcomeIsWin ? .positive : .negative)

                Spacer(minLength: 0)

                Text(row.pnlText)
                    .font(BotFont.pnlFigure)
                    .foregroundStyle(BotColor.forSign(row.pnlSign))
            }

            HStack(spacing: 7) {
                Text(row.dateText)
                Text("·").opacity(0.4)
                Text(row.priceText)
                Text("·").opacity(0.4)
                Text(row.holdText)
                Spacer(minLength: 0)
                Text(row.regimeText).foregroundStyle(BotColor.grey)
                ProgressBar(fraction: row.confidenceFraction, color: BotColor.accent, height: 3)
                    .frame(width: 26)
            }
            .font(BotFont.metadataMono)
            .foregroundStyle(BotColor.greyMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, BotSpacing.rowVertical)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(row.pair) \(row.directionLabel), \(row.outcomeIsWin ? "take profit" : "stop loss"), "
            + "\(row.pnlText), held \(row.holdText), \(row.regimeText)"
        )
        // Lets UI tests count *trade rows* for a symbol without also matching the
        // breakdown tables, which list every symbol regardless of the active filter.
        .accessibilityIdentifier("trade.row")
    }
}
