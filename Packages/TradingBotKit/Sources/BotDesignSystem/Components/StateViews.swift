import SwiftUI

/// Skeleton block used while the first load is in flight.
public struct SkeletonBlock: View {
    public let height: CGFloat
    public let width: CGFloat?

    public init(height: CGFloat, width: CGFloat? = nil) {
        self.height = height
        self.width = width
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(BotColor.track)
            .frame(width: width, height: height)
            .opacity(0.6)
    }
}

/// First-load placeholder shaped like the real screen so nothing jumps on arrival.
public struct LoadingSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SkeletonBlock(height: 46, width: 200)
            SkeletonBlock(height: BotSpacing.chartHeight)
            HStack(spacing: BotSpacing.tileGap) {
                SkeletonBlock(height: 84)
                SkeletonBlock(height: 84)
            }
            HStack(spacing: BotSpacing.tileGap) {
                SkeletonBlock(height: 84)
                SkeletonBlock(height: 84)
            }
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
        .accessibilityIdentifier("state.loading")
    }
}

public struct ErrorStateView: View {
    public let message: String
    public let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(BotColor.negative)
            Text("Could not load")
                .font(BotFont.placeholderTitle)
                .foregroundStyle(BotColor.ink)
            Text(message)
                .font(BotFont.caption)
                .foregroundStyle(BotColor.greyMuted)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .font(BotFont.figureSmall)
                .foregroundStyle(BotColor.paper)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(BotColor.ink))
                .accessibilityIdentifier("state.retry")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(BotSpacing.screenHorizontal)
        .accessibilityIdentifier("state.error")
    }
}

public struct EmptyStateView: View {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        Text(message)
            .font(BotFont.caption)
            .foregroundStyle(BotColor.greyMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .accessibilityIdentifier("state.empty")
    }
}

/// Non-blocking strip shown when the data on screen is not fully current.
public struct OfflineBanner: View {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 10))
            Text(message)
                .font(BotFont.metadata)
            Spacer(minLength: 0)
        }
        .foregroundStyle(BotColor.accent)
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, 7)
        .background(BotColor.accentFill)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityIdentifier("state.offline")
    }
}
