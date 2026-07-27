import SwiftUI
import CoreText
#if canImport(UIKit)
import UIKit
#endif

/// Typography for the app.
///
/// Faces are registered from the package bundle at runtime — SwiftPM resources cannot
/// use `UIAppFonts`. PostScript names are resolved by family so the exact file naming
/// of a Google Fonts release does not matter.
///
/// Bodoni Moda and Plus Jakarta Sans ship as variable fonts; IBM Plex Mono as static
/// faces. Both work through the same family lookup.
public enum BotFont {
    public enum Family {
        public static let serif = "Bodoni Moda"
        public static let ui = "Plus Jakarta Sans"
        public static let mono = "IBM Plex Mono"
    }

    private static let registrationLock = NSLock()
    nonisolated(unsafe) private static var hasRegistered = false

    /// Registers every bundled `.ttf`. Safe to call repeatedly.
    public static func registerAll() {
        registrationLock.lock()
        defer { registrationLock.unlock() }
        guard !hasRegistered else { return }
        hasRegistered = true

        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            // Already-registered fonts return false with an "already registered" error,
            // which is harmless — the goal is availability, not a clean first run.
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }

    /// Resolution goes through CoreText rather than `UIFont` so there is a single code
    /// path: the package's own tests build for macOS, the app runs on iOS.
    private static func faceNames(in family: String) -> [String] {
        registerAll()
        let attributes: [CFString: Any] = [kCTFontFamilyNameAttribute: family]
        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let matches = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, nil)
            as? [CTFontDescriptor] ?? []
        return matches.compactMap {
            CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String
        }
    }

    public static func isAvailable(_ family: String) -> Bool {
        !faceNames(in: family).isEmpty
    }

    /// Finds a concrete face within a family, preferring an upright regular unless
    /// italic is requested.
    public static func postScriptName(family: String, italic: Bool) -> String? {
        let names = faceNames(in: family)
        guard !names.isEmpty else { return nil }
        if italic {
            return names.first { $0.localizedCaseInsensitiveContains("italic") } ?? names.first
        }
        let upright = names.filter { !$0.localizedCaseInsensitiveContains("italic") }
        return upright.first { $0.localizedCaseInsensitiveContains("regular") }
            ?? upright.first
            ?? names.first
    }

    // MARK: - Builders

    /// Editorial serif. `relativeTo` keeps Dynamic Type working on custom faces.
    public static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        guard let name = postScriptName(family: Family.serif, italic: italic) else {
            return .system(size: size, design: .serif)
        }
        return .custom(name, size: size, relativeTo: .title3)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let name = postScriptName(family: Family.mono, italic: false) else {
            return .system(size: size, weight: weight, design: .monospaced)
        }
        return .custom(name, size: size, relativeTo: .body).weight(weight)
    }

    public static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let name = postScriptName(family: Family.ui, italic: false) else {
            return .system(size: size, weight: weight)
        }
        return .custom(name, size: size, relativeTo: .body).weight(weight)
    }

    // MARK: - Semantic styles
    //
    // Call sites use these, never a raw family name or point size.

    public static var heroFigure: Font { mono(46, weight: .light) }
    public static var screenTitle: Font { serif(27) }
    public static var sectionTitle: Font { serif(19) }
    public static var cardTitle: Font { serif(20) }
    public static var canvasTitle: Font { serif(22) }
    public static var placeholderTitle: Font { serif(18) }
    public static var narrative: Font { serif(17, italic: true) }

    public static var tileValue: Font { mono(21) }
    public static var pnlFigure: Font { mono(14.5) }
    public static var symbol: Font { mono(14, weight: .medium) }
    public static var figure: Font { mono(13) }
    public static var figureSmall: Font { mono(12) }
    public static var metadataMono: Font { mono(10.5) }
    public static var badge: Font { mono(9.5) }
    public static var overline: Font { mono(9.5) }
    public static var tabLabel: Font { mono(9) }

    public static var body: Font { ui(13) }
    public static var listItem: Font { ui(12.5) }
    public static var caption: Font { ui(11.5) }
    public static var metadata: Font { ui(10.5) }
    public static var label: Font { ui(10) }
}
