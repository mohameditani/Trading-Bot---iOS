import SwiftUI

public enum BadgeTone: Equatable, Sendable {
    case positive, negative, accent, neutral
}

/// Small tinted pill: TP / SL, proceed / block, risk flags.
public struct BotBadge: View {
    public let text: String
    public let tone: BadgeTone

    public init(text: String, tone: BadgeTone) {
        self.text = text
        self.tone = tone
    }

    var foreground: Color {
        switch tone {
        case .positive: return BotColor.positive
        case .negative: return BotColor.negative
        case .accent: return BotColor.accent
        case .neutral: return BotColor.grey
        }
    }

    var background: Color {
        switch tone {
        case .positive: return BotColor.positiveFill
        case .negative: return BotColor.negativeFill
        case .accent: return BotColor.accentFill
        case .neutral: return BotColor.chipNeutral
        }
    }

    public var body: some View {
        Text(text)
            .font(BotFont.badge)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous))
    }
}

/// A `#tag` on a lesson card.
public struct TagChip: View {
    public let tag: String

    public init(tag: String) {
        self.tag = tag
    }

    var displayText: String { "#\(tag)" }

    public var body: some View {
        Text(displayText)
            .font(BotFont.badge)
            .foregroundStyle(BotColor.grey)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(BotColor.chipNeutral)
            .clipShape(RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous))
    }
}
