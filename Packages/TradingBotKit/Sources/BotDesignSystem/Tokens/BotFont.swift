import SwiftUI

/// Typography for the app — the system font, matching RentRoll.
///
/// Earlier this bundled Bodoni Moda, Plus Jakarta Sans and IBM Plex Mono to reproduce
/// the mockup's editorial look. Those are gone: the app now uses SF Pro for interface
/// text and SF Mono (`design: .monospaced`) for every figure, which is exactly what
/// RentRoll does. Point sizes are unchanged, so layout and column alignment are
/// identical — only the typeface differs.
///
/// Dropping the bundled faces also removes ~1.1 MB from the app and the runtime font
/// registration step entirely.
public enum BotFont {
    /// Interface text.
    public static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Every figure. Monospaced so columns of numbers line up.
    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Headings. The design's editorial serif is replaced by a heavier system weight —
    /// the hierarchy now comes from weight rather than from a contrasting typeface.
    public static func heading(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    // MARK: - Semantic styles
    //
    // Call sites use these, never a raw size. Names and sizes are unchanged from the
    // bundled-font version, so no view needed editing when the typeface changed.

    public static var heroFigure: Font { mono(46, weight: .light) }
    public static var screenTitle: Font { heading(27, weight: .semibold) }
    public static var sectionTitle: Font { heading(19, weight: .semibold) }
    public static var cardTitle: Font { heading(20, weight: .semibold) }
    public static var canvasTitle: Font { heading(22, weight: .semibold) }
    public static var placeholderTitle: Font { heading(18, weight: .medium) }
    public static var narrative: Font { .system(size: 17, weight: .regular).italic() }

    public static var tileValue: Font { mono(21) }
    public static var pnlFigure: Font { mono(14.5) }
    public static var symbol: Font { mono(14, weight: .medium) }
    public static var figure: Font { mono(13) }
    public static var figureSmall: Font { mono(12) }
    public static var metadataMono: Font { mono(10.5) }
    public static var badge: Font { mono(9.5) }
    public static var overline: Font { mono(9.5, weight: .medium) }
    public static var tabLabel: Font { ui(10, weight: .medium) }

    public static var body: Font { ui(13) }
    public static var listItem: Font { ui(12.5) }
    public static var caption: Font { ui(11.5) }
    public static var metadata: Font { ui(10.5) }
    public static var label: Font { ui(10) }
}
