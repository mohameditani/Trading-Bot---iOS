import Foundation

enum Formatters {
    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_US")
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.negativeFormat = "-$#,##0.00"
        return f
    }()

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()

    static func currency(_ value: Double, decimals: Int = 2) -> String {
        currencyFormatter.minimumFractionDigits = decimals
        currencyFormatter.maximumFractionDigits = decimals
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    static func price(_ value: Double) -> String {
        priceFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
