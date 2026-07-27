import Foundation
import Observation
import BotDomain

/// The single source of snapshot state for the whole app.
///
/// One instance is shared by all three tabs, so a refresh updates every screen at once
/// and the app issues one request rather than three.
@MainActor
@Observable
public final class SnapshotStore {
    public private(set) var state: LoadState<Snapshot> = .idle
    /// True when the data on screen came from cache after a failed load.
    public private(set) var isStale = false
    public private(set) var isRefreshing = false
    /// Drives the header's "just now / 12s ago" indicator.
    public private(set) var secondsSinceUpdate = 0
    /// Set when a refresh fails while data is already on screen.
    public private(set) var lastErrorMessage: String?

    private let repository: SnapshotRepository
    private var pollingTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?

    public init(repository: SnapshotRepository) {
        self.repository = repository
    }

    // No `deinit` cancelling the tasks: under Swift 6 a deinit is nonisolated and
    // cannot touch main-actor state. Both tasks instead re-acquire `self` weakly on
    // every iteration, so they end on their own once the store is released.

    public func refresh() async {
        if state.value == nil { state = .loading }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let result = try await repository.load()
            state = .loaded(result.snapshot)
            isStale = result.isStale
            secondsSinceUpdate = 0
            lastErrorMessage = result.isStale
                ? SnapshotError.offline.userMessage
                : nil
        } catch {
            let message = (error as? SnapshotError)?.userMessage ?? error.localizedDescription
            if state.value == nil {
                state = .failed(error)
            } else {
                // Keep what is on screen; surface the problem without blanking the UI.
                lastErrorMessage = message
            }
        }
    }

    public func startPolling(interval: Duration = .seconds(30)) {
        stopPolling()

        // `self` is re-bound weakly inside the loop, never hoisted above it: a single
        // `guard let self` before the loop would hold a strong reference for the task's
        // whole life and keep the store alive forever.
        pollingTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                if Task.isCancelled { return }
                guard let self else { return }
                await self.refresh()
            }
        }

        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                guard let self else { return }
                self.secondsSinceUpdate = min(self.secondsSinceUpdate + 1, 3_600)
            }
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        tickTask?.cancel()
        tickTask = nil
    }
}
