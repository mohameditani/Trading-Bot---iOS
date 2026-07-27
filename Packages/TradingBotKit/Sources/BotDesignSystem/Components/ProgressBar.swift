import SwiftUI

/// A thin proportional bar — breakdown magnitudes and trade confidence.
public struct ProgressBar: View {
    public let fraction: Double
    public let color: Color
    public let height: CGFloat

    public init(fraction: Double, color: Color, height: CGFloat = 4) {
        self.fraction = fraction
        self.color = color
        self.height = height
    }

    var clampedFraction: Double { min(max(fraction, 0), 1) }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(BotColor.track)
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * clampedFraction)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
