import SwiftUI

/// The "Not enabled yet" card shown on Review when the AI layer is off.
public struct PlaceholderCard: View {
    public let title: String
    public let description: String

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    var notEnabledText: String { "NOT ENABLED YET" }

    public var body: some View {
        VStack(spacing: 9) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(BotColor.placeholderIcon)

            Text(title)
                .font(BotFont.placeholderTitle)
                .foregroundStyle(BotColor.grey)

            Text(notEnabledText)
                .font(BotFont.badge)
                .tracking(1.4)
                .foregroundStyle(BotColor.greyMuted)

            Text(description)
                .font(BotFont.caption)
                .foregroundStyle(BotColor.greyMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 22)
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). Not enabled yet. \(description)")
    }
}
