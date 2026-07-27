import Foundation
import BotDomain
@testable import BotDataKit

/// Scriptable provider: each fetch pops the next outcome. The last entry repeats.
final class StubSnapshotProvider: SnapshotProvider, @unchecked Sendable {
    enum Outcome {
        case success(Data)
        case failure(any Error)
    }

    private let lock = NSLock()
    private var outcomes: [Outcome]
    private var fetchCount = 0

    init(_ outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    convenience init(alwaysSucceedsWith data: Data) {
        self.init([.success(data)])
    }

    /// Scoped `withLock` rather than lock()/unlock(): the bare calls are unavailable
    /// from an async context because a suspension could strand the lock held.
    func fetchPayload() async throws -> Data {
        let outcome = lock.withLock { () -> Outcome in
            fetchCount += 1
            return outcomes.count > 1
                ? outcomes.removeFirst()
                : (outcomes.first ?? .failure(SnapshotError.offline))
        }

        switch outcome {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }

    var callCount: Int {
        lock.withLock { fetchCount }
    }
}
