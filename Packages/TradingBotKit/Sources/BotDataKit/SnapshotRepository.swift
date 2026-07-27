import Foundation
import BotDomain

public struct RepositoryResult: Sendable {
    public let snapshot: Snapshot
    /// True when the snapshot came from cache because the live load failed.
    public let isStale: Bool

    public init(snapshot: Snapshot, isStale: Bool) {
        self.snapshot = snapshot
        self.isStale = isStale
    }
}

/// Orchestrates provider and cache: fetch, cache on success, fall back on failure.
///
/// Decoding happens here rather than in the provider so the cache stores exactly the
/// bytes that arrived, byte-identical to the server's payload.
public struct SnapshotRepository: Sendable {
    private let provider: any SnapshotProvider
    private let cache: SnapshotCache

    public init(provider: any SnapshotProvider, cache: SnapshotCache) {
        self.provider = provider
        self.cache = cache
    }

    public func load() async throws -> RepositoryResult {
        do {
            let payload = try await provider.fetchPayload()
            let snapshot = try SnapshotDecoder.decode(payload)
            // Best-effort: a cache write failure must not fail an otherwise good load.
            try? await cache.write(payload)
            return RepositoryResult(snapshot: snapshot, isStale: false)
        } catch {
            // A live failure is survivable if we have something on disk.
            if let cached = try? await cache.read() {
                return RepositoryResult(snapshot: cached, isStale: true)
            }
            throw error
        }
    }
}
