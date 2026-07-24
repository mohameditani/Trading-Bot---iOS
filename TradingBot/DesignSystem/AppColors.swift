import SwiftUI

enum AppColors {
    static let pnlPositive = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let pnlNegative = Color(red: 0.94, green: 0.27, blue: 0.23)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let secondaryText = Color.secondary
    static let blockedAmber = Color(red: 0.95, green: 0.61, blue: 0.07)

    static func pnl(_ value: Double) -> Color {
        value >= 0 ? pnlPositive : pnlNegative
    }
}
