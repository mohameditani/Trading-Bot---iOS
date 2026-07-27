import SwiftUI
import BotDesignSystem

struct LessonsCard: View {
    let lessons: [LessonPresentation]
    let countText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Lessons")
                    .font(BotFont.sectionTitle)
                    .foregroundStyle(BotColor.ink)
                Spacer()
                Text(countText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }

            ForEach(lessons) { lesson in
                lessonCard(lesson)
            }
        }
        .padding(.horizontal, BotSpacing.cardPadding)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.lessons")
    }

    private func lessonCard(_ lesson: LessonPresentation) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(lesson.pair)
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.inkStrong)
                BotBadge(text: lesson.outcomeLabel, tone: .negative)
                Spacer(minLength: 0)
                Text(lesson.timeText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }

            Text(lesson.text)
                .font(BotFont.body)
                .foregroundStyle(BotColor.inkBody)
                .fixedSize(horizontal: false, vertical: true)

            Text(lesson.metaText)
                .font(BotFont.metadata)
                .foregroundStyle(BotColor.greyMuted)

            HStack(spacing: 5) {
                ForEach(lesson.tags, id: \.self) { tag in
                    TagChip(tag: tag)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(13)
        .background(BotColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
    }
}
