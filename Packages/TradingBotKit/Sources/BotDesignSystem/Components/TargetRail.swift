import SwiftUI

/// The take-profit -> stop-loss track with an entry marker.
///
/// Always runs green (take-profit) on the left to red (stop-loss) on the right,
/// whichever side of the entry those prices sit on.
public struct TargetRail: View {
    public let progress: Double

    public init(progress: Double) {
        self.progress = progress
    }

    var clampedProgress: Double { min(max(progress, 0), 1) }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                LinearGradient(
                    stops: [
                        .init(color: BotColor.positive, location: 0),
                        .init(color: BotColor.track, location: 0.62),
                        .init(color: BotColor.track, location: 0.66),
                        .init(color: BotColor.negative, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 4)
                .clipShape(Capsule())
                .frame(maxHeight: .infinity, alignment: .center)

                Rectangle()
                    .fill(BotColor.inkStrong)
                    .frame(width: 2, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    .offset(x: geometry.size.width * clampedProgress - 1)
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}
