import SwiftUI
import Charts
import BotDomain

/// The equity curve: a smoothed red line under a fading fill, no axes, no interaction.
public struct EquityCurveChart: View {
    public let points: [CurvePoint]

    public init(points: [CurvePoint]) {
        self.points = points
    }

    var hasData: Bool { !points.isEmpty }

    /// Padded vertical domain so the stroke never clips against the frame.
    var yDomain: ClosedRange<Double> {
        let values = points.map(\.equity)
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        if low == high {
            let padding = max(abs(low) * 0.1, 1)
            return (low - padding)...(high + padding)
        }
        let padding = (high - low) * 0.14
        return (low - padding)...(high + padding)
    }

    public var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [BotColor.negative.opacity(0.20), BotColor.negative.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(BotColor.negative)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain)
        .chartLegend(.hidden)
        .frame(height: BotSpacing.chartHeight)
        .accessibilityLabel("Equity curve")
    }
}
