import SwiftUI

/// The raised card used throughout the app: a subtle vertical gradient with a hairline.
public struct BotCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat

    public init(padding: CGFloat = BotSpacing.cardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [BotColor.cardTop, BotColor.cardBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                    .stroke(BotColor.hairline, lineWidth: 1)
            )
    }
}
