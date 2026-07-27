import SwiftUI
import BotDataKit
import BotDesignSystem

struct ReviewView: View {
    @State private var viewModel: ReviewViewModel

    init(store: SnapshotStore) {
        _viewModel = State(initialValue: ReviewViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            // Data is on screen but the last load did not fully succeed — either it
            // came from cache, or a background refresh failed. Never blocks the UI.
            if viewModel.snapshot != nil, let message = viewModel.errorMessage {
                OfflineBanner(message: message)
            }

            content
        }
        .background(BotColor.paper)
        .accessibilityIdentifier("screen.review")
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Review")
                .font(BotFont.screenTitle)
                .foregroundStyle(BotColor.inkStrong)
            Spacer()
            Text(viewModel.dateText)
                .font(BotFont.metadataMono)
                .foregroundStyle(viewModel.hasReviewLayer ? BotColor.grey : BotColor.greyMuted)
                .accessibilityIdentifier("review.date")
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingSkeleton()
            Spacer()
        } else if viewModel.snapshot == nil, let message = viewModel.errorMessage {
            ErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let report = viewModel.report {
                        ReportCard(report: report)
                    }

                    if let summary = viewModel.vetoSummary {
                        VetoLogCard(summary: summary, rows: viewModel.vetoRows)
                    }

                    if !viewModel.lessons.isEmpty {
                        LessonsCard(
                            lessons: viewModel.lessons,
                            countText: viewModel.lessonCountText
                        )
                    }

                    // The design's fourth screen: one branch, not a separate view.
                    ForEach(viewModel.placeholders) { placeholder in
                        PlaceholderCard(
                            title: placeholder.title,
                            description: placeholder.description
                        )
                        .accessibilityIdentifier("review.placeholder")
                    }
                }
                .padding(.horizontal, BotSpacing.screenHorizontal)
                .padding(.vertical, 18)
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }
}
