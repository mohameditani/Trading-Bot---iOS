import Foundation
import Observation

@Observable
@MainActor
final class SnapshotStore {
    private(set) var state: LoadState<BotSnapshot> = .loading

    private let repository: SnapshotRepository
    private let pollInterval: Duration
    private var pollingTask: Task<Void, Never>?

    init(repository: SnapshotRepository, pollInterval: Duration = .seconds(5)) {
        self.repository = repository
        self.pollInterval = pollInterval
    }

    func refresh() async {
        if let current = state.value {
            state = .refreshing(current)
        }
        state = await repository.snapshot()
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: self?.pollInterval ?? .seconds(5))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
