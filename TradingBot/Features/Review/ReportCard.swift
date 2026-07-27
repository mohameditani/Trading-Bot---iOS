import SwiftUI
import BotDesignSystem

struct ReportCard: View {
    let report: ReportPresentation

    var body: some View {
        BotCard {
            VStack(alignment: .leading, spacing: 0) {
                Overline(text: "Latest report")
                    .padding(.bottom, 11)

                Text(report.narrative)
                    .font(BotFont.narrative)
                    .foregroundStyle(BotColor.inkBody)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)

                bulletList(title: "Working", items: report.working, color: BotColor.positive)
                    .padding(.bottom, 13)
                bulletList(title: "Losing", items: report.losing, color: BotColor.negative)

                if !report.suggestions.isEmpty {
                    Rectangle()
                        .fill(BotColor.hairline)
                        .frame(height: 1)
                        .padding(.vertical, 14)
                    Overline(text: "Config suggestions", color: BotColor.grey)
                        .padding(.bottom, 10)
                    ForEach(report.suggestions) { suggestion in
                        suggestionRow(suggestion)
                    }
                }
            }
        }
        .accessibilityIdentifier("review.report")
    }

    private func bulletList(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Overline(text: title, color: color)
                .padding(.bottom, 2)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 9) {
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .padding(.top, 7)
                    Text(item)
                        .font(BotFont.listItem)
                        .foregroundStyle(BotColor.grey)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(items.joined(separator: ", "))")
    }

    private func suggestionRow(_ suggestion: SuggestionPresentation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(suggestion.param)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(suggestion.current)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.grey)
                Text("→")
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.accent)
                Text(suggestion.suggested)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.positive)
            }
            Text(suggestion.rationale)
                .font(BotFont.metadata)
                .foregroundStyle(BotColor.greyMuted)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(suggestion.param), currently \(suggestion.current), "
            + "suggested \(suggestion.suggested). \(suggestion.rationale)"
        )
    }
}
