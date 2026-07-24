import SwiftUI

struct StatItemView: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTypography.statLabel)
                .foregroundStyle(AppColors.secondaryText)
            HStack(spacing: 6) {
                Text(value)
                    .font(AppTypography.statValue)
                    .foregroundStyle(valueColor)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
