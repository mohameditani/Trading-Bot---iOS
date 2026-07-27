import SwiftUI

/// Pill filter used on the Trades screen. Selected state is solid ink on paper text.
public struct FilterChipView: View {
    public let title: String
    public let isSelected: Bool

    public init(title: String, isSelected: Bool) {
        self.title = title
        self.isSelected = isSelected
    }

    public var body: some View {
        Text(title)
            .font(BotFont.figureSmall)
            .foregroundStyle(isSelected ? BotColor.paper : BotColor.grey)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(BotColor.ink)
                    } else {
                        Capsule().stroke(BotColor.hairline, lineWidth: 1)
                    }
                }
            )
            .contentShape(Capsule())
    }
}
