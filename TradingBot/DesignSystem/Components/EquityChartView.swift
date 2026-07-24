import Charts
import SwiftUI

struct EquityChartView: View {
    let points: [EquityPoint]
    var showsAxes: Bool = false

    private var trendColor: Color {
        guard let first = points.first?.equity, let last = points.last?.equity else {
            return AppColors.pnlNegative
        }
        return last >= first ? AppColors.pnlPositive : AppColors.pnlNegative
    }

    var body: some View {
        Chart(points, id: \.date) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .foregroundStyle(trendColor)
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [trendColor.opacity(0.25), trendColor.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis(showsAxes ? .visible : .hidden)
        .chartYAxis(showsAxes ? .visible : .hidden)
        .accessibilityLabel("Equity curve")
    }
}
