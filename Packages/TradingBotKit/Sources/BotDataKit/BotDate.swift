import Foundation

/// Parses every timestamp shape the bot actually emits.
///
/// The bot writes `datetime.now().isoformat()` and `strftime('%Y-%m-%dT%H:%M:%S')`,
/// both of which are **naive** — no timezone designator. Foundation's `.iso8601`
/// strategy requires one, so a plain ISO8601 decoder rejects the entire live payload.
/// Our own bundled fixtures use a trailing `Z`, so both must work.
public enum BotDate {
    /// Naive stamps carry no offset, so they need an assumed zone.
    ///
    /// The bot runs on a DigitalOcean droplet, which defaults to UTC, and it trades
    /// crypto — a 24/7 UTC-centric market. If the host is ever moved to a local zone,
    /// this one constant is the only thing that needs to change.
    static let assumedZoneForNaiveTimestamps = TimeZone(identifier: "UTC") ?? .gmt

    private static let naiveFormats = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm",
    ]

    /// Resolves to milliseconds; the bot writes microseconds, so parsing is accurate to
    /// ~1ms. Nothing in the UI renders finer than a minute.
    private static let naiveParsers: [DateFormatter] = naiveFormats.map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = assumedZoneForNaiveTimestamps
        formatter.dateFormat = format
        formatter.isLenient = false
        return formatter
    }

    nonisolated(unsafe) private static let offsetParsers: [ISO8601DateFormatter] = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [withFraction, plain]
    }()

    /// Returns nil rather than throwing so callers can decide what a bad stamp means.
    public static func parse(_ string: String) -> Date? {
        guard !string.isEmpty else { return nil }

        // Try offset-bearing forms first: they are unambiguous.
        if string.hasSuffix("Z") || string.contains("+")
            || string.dropFirst(10).contains("-") {
            for parser in offsetParsers {
                if let date = parser.date(from: string) { return date }
            }
        }

        for parser in naiveParsers {
            if let date = parser.date(from: string) { return date }
        }
        return nil
    }
}

extension JSONDecoder.DateDecodingStrategy {
    /// The strategy every snapshot decode uses.
    static var botTimestamp: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = BotDate.parse(raw) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unrecognised timestamp \"\(raw)\"."
                )
            }
            return date
        }
    }
}
