import Foundation
import Testing
@testable import BotDataKit

private func makeTemporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("cache-test-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Test func cacheRoundTripsASnapshot() async throws {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    try await cache.write(Fixtures.full)
    let snapshot = try await cache.read()
    #expect(snapshot.summary.balance == 87.26)
}

@Test func readingAnEmptyCacheThrowsNoCachedSnapshot() async {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    await #expect(throws: SnapshotError.noCachedSnapshot) {
        try await cache.read()
    }
}

@Test func writingReplacesThePreviousEntry() async throws {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    try await cache.write(Fixtures.full)
    try await cache.write(Fixtures.aiNull)
    let snapshot = try await cache.read()
    #expect(snapshot.aiReport == nil)
    #expect(snapshot.summary.open == 0)
}

@Test func clearRemovesTheCachedEntry() async throws {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    try await cache.write(Fixtures.full)
    await cache.clear()
    await #expect(throws: SnapshotError.noCachedSnapshot) {
        try await cache.read()
    }
}

// The cache validates before storing, so a corrupt response can never poison the
// offline fallback.
@Test func cacheRefusesToStoreMalformedData() async {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    await #expect(throws: (any Error).self) {
        try await cache.write(Fixtures.malformed)
    }
}
