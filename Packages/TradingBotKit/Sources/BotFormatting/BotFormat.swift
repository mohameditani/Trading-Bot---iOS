import Foundation

/// All display formatting for the app.
///
/// Locale and time zone are pinned deliberately: the design's figures are exact
/// (`$87.26`, `58,800`, `Jun 30 14:31` in UTC) and must not drift with the host
/// machine's region or time zone.
public enum BotFormat {
    static let locale = Locale(identifier: "en_US_POSIX")
    static let timeZone = TimeZone(identifier: "UTC") ?? .gmt

    private static func decimal(minimum: Int, maximum: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = minimum
        formatter.maximumFractionDigits = maximum
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private static func string(_ value: Double, minimum: Int, maximum: Int) -> String {
        let formatter = decimal(minimum: minimum, maximum: maximum)
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Money

    /// `$87.26`, negatives as `-$5.50`.
    public static func currency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        return sign + "$" + string(abs(value), minimum: 2, maximum: 2)
    }

    /// `+$1.76` / `-$12.74` / `$0.00`, and `—` when there is no value.
    public static func signedCurrency(_ value: Double?) -> String {
        guard let value else { return "—" }
        let sign = value > 0 ? "+" : (value < 0 ? "-" : "")
        return sign + "$" + string(abs(value), minimum: 2, maximum: 2)
    }

    /// Prices lose their decimals at or above 1,000 so wide pairs stay readable.
    public static func price(_ value: Double?) -> String {
        guard let value else { return "—" }
        return abs(value) >= 1_000
            ? string(value, minimum: 0, maximum: 0)
            : string(value, minimum: 2, maximum: 2)
    }

    public static func quantity(_ value: Double) -> String {
        string(value, minimum: 2, maximum: 2)
    }

    public static func leverage(_ value: Int) -> String { "\(value)×" }

    /// `39.3%`
    public static func percent(_ value: Double) -> String {
        string(value, minimum: 1, maximum: 1) + "%"
    }

    // MARK: - Dates

    private static func dateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }

    /// `Jun 20`
    public static func day(_ date: Date) -> String {
        dateFormatter("MMM d").string(from: date)
    }

    /// `Jun 30 14:31`, always UTC.
    public static func stamp(_ date: Date) -> String {
        dateFormatter("MMM d HH:mm").string(from: date)
    }

    // MARK: - Durations

    /// `45m`, `1h`, `1h 22m`.
    public static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int((interval / 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    /// `just now` for the first three seconds, then `12s ago`.
    public static func freshness(seconds: Int) -> String {
        seconds < 3 ? "just now" : "\(seconds)s ago"
    }
}
