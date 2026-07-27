import SwiftUI
import BotDomain

/// The design's palette, lifted from the mockup's hex values.
public enum BotColor {
    // Surfaces
    public static let paper = Color(hex: 0xFAF9F6)
    public static let cardTop = Color(hex: 0xFFFFFF)
    public static let cardBottom = Color(hex: 0xFBF9F5)
    public static let surface = Color(hex: 0xF7F5F1)
    public static let chipNeutral = Color(hex: 0xEDEAE4)
    public static let track = Color(hex: 0xE7E4DE)

    // Ink
    public static let inkStrong = Color(hex: 0x15171B)
    public static let ink = Color(hex: 0x23262C)
    public static let inkBody = Color(hex: 0x33373E)
    public static let grey = Color(hex: 0x5C616A)
    public static let greyMuted = Color(hex: 0x63686F)
    public static let placeholderIcon = Color(hex: 0xC3C7CD)

    // Semantic
    public static let positive = Color(hex: 0x1A7C54)
    public static let negative = Color(hex: 0xBF362C)
    public static let accent = Color(hex: 0x8C6E2A)

    /// Hairline dividers and card borders.
    public static let hairline = Color(hex: 0x16181C, opacity: 0.10)

    // Tinted chip fills, derived rather than hardcoded as separate constants.
    public static let positiveFill = positive.opacity(0.13)
    public static let negativeFill = negative.opacity(0.11)
    public static let accentFill = accent.opacity(0.09)
    public static let accentStroke = accent.opacity(0.32)

    public static func forSign(_ sign: PnLSign) -> Color {
        switch sign {
        case .positive: return positive
        case .negative: return negative
        case .flat: return grey
        }
    }

    public static func fillForSign(_ sign: PnLSign) -> Color {
        switch sign {
        case .positive: return positiveFill
        case .negative: return negativeFill
        case .flat: return chipNeutral
        }
    }

    public static func forWinRateTier(_ tier: WinRateTier) -> Color {
        switch tier {
        case .strong: return positive
        case .neutral: return grey
        case .weak: return negative
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
