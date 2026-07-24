import SwiftUI

enum AppTypography {
    static let largeEquity = Font.system(size: 34, weight: .bold, design: .default).monospacedDigit()
    static let statValue = Font.system(size: 17, weight: .semibold).monospacedDigit()
    static let statLabel = Font.system(size: 13, weight: .regular)
    static let cardTitle = Font.system(size: 15, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
}
