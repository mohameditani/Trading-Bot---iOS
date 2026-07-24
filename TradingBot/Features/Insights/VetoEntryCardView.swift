import SwiftUI

struct VetoEntryCardView: View {
    let entry: VetoEntry
    @State private var isExpanded = false

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(Self.timestampFormatter.string(from: entry.timestamp))
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.symbol)
                        .font(AppTypography.body.weight(.semibold))
                    Text(entry.side)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    BadgeView(
                        text: entry.status.rawValue,
                        color: entry.status == .proceed ? AppColors.pnlPositive : AppColors.pnlNegative
                    )
                }
                Text(entry.reason)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
                if !isExpanded {
                    Button("Show more") { withAnimation { isExpanded = true } }
                        .font(AppTypography.caption)
                }
            }
        }
        .onTapGesture { withAnimation { isExpanded.toggle() } }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to expand")
    }
}
