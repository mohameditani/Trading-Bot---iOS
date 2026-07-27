import SwiftUI
import BotDomain
import BotFormatting

/// One line of the "By symbol" / "By regime" tables.
public struct BreakdownRowView: View {
    public let group: BreakdownGroup
    public let maxAbsolute: Double

    public init(group: BreakdownGroup, maxAbsolute: Double) {
        self.group = group
        self.maxAbsolute = maxAbsolute
    }

    var barFraction: Double { group.barFraction(relativeTo: maxAbsolute) }
    var barColor: Color { group.netPnl >= 0 ? BotColor.positive : BotColor.negative }
    var winRateColor: Color { BotColor.forWinRateTier(group.winRateTier) }

    public var body: some View {
        HStack(spacing: 12) {
            Text(group.keyDisplay)
                .font(BotFont.figureSmall)
                .foregroundStyle(BotColor.ink)
                .frame(width: 88, alignment: .leading)
                .lineLimit(1)

            Text("\(group.trades)t")
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.grey)
                .frame(width: 40, alignment: .leading)

            Text(BotFormat.percent(group.winRate))
                .font(BotFont.metadataMono)
                .foregroundStyle(winRateColor)
                .frame(width: 48, alignment: .leading)

            ProgressBar(fraction: barFraction, color: barColor)

            Text(BotFormat.signedCurrency(group.netPnl))
                .font(BotFont.figureSmall)
                .foregroundStyle(barColor)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(group.keyDisplay), \(group.trades) trades, "
            + "win rate \(BotFormat.percent(group.winRate)), "
            + "net \(BotFormat.signedCurrency(group.netPnl))"
        )
    }
}
