import SwiftUI

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppTypography.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityLabel(text)
    }
}
