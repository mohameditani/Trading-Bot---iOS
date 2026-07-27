import Foundation
import Testing
@testable import BotDataKit

private func makeCache() -> SnapshotCache {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("repo-test-\(UUID().uuidString)")
    return SnapshotCache(directory: url)
}

@Test func loadReturnsFreshDataAndCachesIt() async throws {
    let cache = makeCache()
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
        cache: cache
    )
    let result = try await repository.load()
    #expect(result.isStale == false)
    #expect(result.snapshot.summary.balance == 87.26)

    // The successful load must have populated the cache.
    let cached = try await cache.read()
    #expect(cached.summary.balance == 87.26)
}

@Test func loadFallsBackToCacheAndMarksTheResultStale() async throws {
    let cache = makeCache()
    try await cache.write(Fixtures.full)
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
        cache: cache
    )
    let result = try await repository.load()
    #expect(result.isStale)
    #expect(result.snapshot.summary.balance == 87.26)
}

@Test func loadRethrowsTheOriginalErrorWhenThereIsNoCache() async {
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
        cache: makeCache()
    )
    await #expect(throws: SnapshotError.offline) {
        _ = try await repository.load()
    }
}

@Test func aFailedLoadDoesNotOverwriteAGoodCache() async throws {
    let cache = makeCache()
    try await cache.write(Fixtures.full)
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider([.failure(SnapshotError.server(status: 500))]),
        cache: cache
    )
    _ = try? await repository.load()
    let cached = try await cache.read()
    #expect(cached.summary.total == 28)
}
