import SwiftUI
import BotDesignSystem

struct VetoLogCard: View {
    let summary: VetoSummaryPresentation
    let rows: [VetoRowPresentation]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Veto log")
                    .font(BotFont.sectionTitle)
                    .foregroundStyle(BotColor.ink)
                Spacer()
                Text(summary.scoredText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }
            .padding(.horizontal, BotSpacing.cardPadding)
            .padding(.top, 15)
            .padding(.bottom, 12)

            HStack(spacing: 16) {
                labelled("proceed", summary.proceedText, BotColor.positive)
                labelled("block", summary.blockText, BotColor.negative)
                labelled("win rate", summary.winRateText, BotColor.ink)
                Spacer(minLength: 0)
            }
            .font(BotFont.metadataMono)
            .foregroundStyle(BotColor.grey)
            .padding(.horizontal, BotSpacing.cardPadding)
            .padding(.vertical, 9)
            .background(BotColor.surface)
            .overlay(alignment: .top) { hairline }
            .overlay(alignment: .bottom) { hairline }

            ForEach(rows) { row in
                vetoRow(row)
            }
        }
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.vetoLog")
    }

    private var hairline: some View {
        Rectangle().fill(BotColor.hairline).frame(height: 1)
    }

    private func labelled(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Text(value).foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private func vetoRow(_ row: VetoRowPresentation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(row.symbol)
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.ink)
                Text(row.signalText)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(row.signalIsBuy ? BotColor.positive : BotColor.negative)
                BotBadge(text: row.decisionLabel, tone: row.didProceed ? .positive : .negative)
                Spacer(minLength: 0)
                Text(row.timeText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }

            Text(row.reason)
                .font(BotFont.caption)
                .foregroundStyle(BotColor.grey)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(row.flags, id: \.self) { flag in
                    Text(flag)
                        .font(BotFont.badge)
                        .foregroundStyle(BotColor.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(BotColor.accentFill)
                        .clipShape(RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous)
                                .stroke(BotColor.accentStroke, lineWidth: 1)
                        )
                }
                Spacer(minLength: 0)
                Text(row.outcomeText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.forSign(row.outcomeSign))
            }
        }
        .padding(.horizontal, BotSpacing.cardPadding)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { hairline }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(row.symbol) \(row.signalText), \(row.decisionLabel). \(row.reason). "
            + "Outcome \(row.outcomeText)"
        )
    }
}
