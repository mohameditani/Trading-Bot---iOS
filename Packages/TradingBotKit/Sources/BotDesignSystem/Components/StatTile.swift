import SwiftUI

/// One cell of the Equity screen's 2x2 grid.
public struct StatTile: View {
    public let label: String
    public let value: String
    public let valueColor: Color
    public let subtitle: String

    public init(label: String, value: String, valueColor: Color, subtitle: String) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(BotFont.badge)
                .tracking(1.4)
                .foregroundStyle(BotColor.grey)
            Text(value)
                .font(BotFont.tileValue)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(subtitle)
                .font(BotFont.metadata)
                .foregroundStyle(BotColor.greyMuted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BotSpacing.tilePadding)
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.tile, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value), \(subtitle)")
    }
}
