import SwiftUI

struct InsightsView: View {
    let store: SnapshotStore

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("AI Insights")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            BreakdownView(store: store)
                        } label: {
                            Image(systemName: "info.circle")
                                .accessibilityLabel("Breakdown analytics")
                        }
                    }
                }
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView {
                VStack(spacing: 16) {
                    CardView { SkeletonView(height: 90) }
                    CardView { SkeletonView(height: 90) }
                }
                .padding(16)
            }
        case .loaded(let snapshot), .refreshing(let snapshot):
            insightsContent(snapshot.insights)
        case .empty:
            EmptyStateView(title: "No insights yet", systemImage: "lightbulb")
        case .error(let message, let last):
            if let last {
                insightsContent(last.insights)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func insightsContent(_ feed: InsightFeed) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Veto Log (Recent)")
                ForEach(feed.vetoLog) { entry in
                    VetoEntryCardView(entry: entry)
                }

                sectionHeader("Lessons (Pattern Analysis)")
                ForEach(feed.lessons) { lesson in
                    LessonCardView(lesson: lesson)
                }
            }
            .padding(16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.cardTitle)
            Spacer()
            Text("View All")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
