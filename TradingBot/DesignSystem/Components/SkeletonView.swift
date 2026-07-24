import SwiftUI

struct SkeletonView: View {
    var height: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: height)
            .accessibilityHidden(true)
    }
}
