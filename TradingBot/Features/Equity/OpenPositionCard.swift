import SwiftUI
import BotDesignSystem

struct OpenPositionCard: View {
    let position: PositionPresentation

    var body: some View {
        BotCard(padding: 15) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 9) {
                    Text(position.pair)
                        .font(BotFont.symbol)
                        .foregroundStyle(BotColor.inkStrong)
                    BotBadge(
                        text: position.directionLabel,
                        tone: position.directionSign == .positive ? .positive : .negative
                    )
                    Text(position.leverageText)
                        .font(BotFont.metadataMono)
                        .foregroundStyle(BotColor.grey)
                    Spacer(minLength: 0)
                    Text(position.elapsedText)
                        .font(BotFont.metadataMono)
                        .foregroundStyle(BotColor.greyMuted)
                }
                .padding(.bottom, 14)

                HStack {
                    Text(position.takeProfitText)
                        .foregroundStyle(BotColor.positive)
                    Spacer()
                    Text(position.entryText)
                        .foregroundStyle(BotColor.grey)
                    Spacer()
                    Text(position.stopLossText)
                        .foregroundStyle(BotColor.negative)
                }
                .font(BotFont.badge)
                .tracking(1)
                .padding(.bottom, 6)

                TargetRail(progress: position.railProgress)
                    .padding(.bottom, 16)

                HStack(alignment: .top, spacing: 12) {
                    detail("Quantity", position.quantityText, color: BotColor.ink)
                    detail("Margin", position.marginText, color: BotColor.ink)
                    detail("Stops", position.stopsText, color: BotColor.positive)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("equity.openPosition")
    }

    private func detail(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(BotFont.label)
                .foregroundStyle(BotColor.grey)
            Text(value)
                .font(BotFont.figure)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
