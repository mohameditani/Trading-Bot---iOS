import SwiftUI

/// A section title with an optional mono counter beside it.
public struct SectionHeading: View {
    public let title: String
    public let trailing: String?

    public init(title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(title)
                .font(BotFont.sectionTitle)
                .foregroundStyle(BotColor.ink)
            if let trailing {
                Text(trailing)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.greyMuted)
            }
            Spacer(minLength: 0)
        }
    }
}

/// The uppercase overline above a card's contents. Gold by default.
public struct Overline: View {
    public let text: String
    public let color: Color

    public init(text: String, color: Color = BotColor.accent) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(BotFont.overline)
            .tracking(1.6)
            .foregroundStyle(color)
    }
}
