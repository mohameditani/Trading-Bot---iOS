import SwiftUI

struct PositionsView: View {
    let store: SnapshotStore

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Open Positions")
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView { CardView { SkeletonView(height: 200) }.padding(16) }
        case .loaded(let snapshot), .refreshing(let snapshot):
            positionsContent(snapshot.positions)
        case .empty:
            EmptyStateView(title: "No open positions", systemImage: "square.stack.3d.up")
        case .error(let message, let last):
            if let last {
                positionsContent(last.positions)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    @ViewBuilder
    private func positionsContent(_ positions: [Position]) -> some View {
        if positions.isEmpty {
            EmptyStateView(title: "No open positions", systemImage: "square.stack.3d.up")
        } else {
            List(positions) { position in
                PositionCardView(position: position)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top) {
                Text("\(positions.count) Open Position\(positions.count == 1 ? "" : "s")")
                    .font(AppTypography.statLabel)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(AppColors.screenBackground)
            }
        }
    }
}
