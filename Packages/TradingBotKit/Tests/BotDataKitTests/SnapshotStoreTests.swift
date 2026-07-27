import Foundation
import Testing
@testable import BotDataKit

private func makeCache() -> SnapshotCache {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("store-test-\(UUID().uuidString)")
    return SnapshotCache(directory: url)
}

@MainActor
@Test func storeStartsIdle() {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
            cache: makeCache()
        )
    )
    #expect(store.state.value == nil)
    #expect(store.isRefreshing == false)
}

@MainActor
@Test func refreshLoadsASnapshot() async {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
            cache: makeCache()
        )
    )
    await store.refresh()
    #expect(store.state.value?.summary.balance == 87.26)
    #expect(store.isStale == false)
    #expect(store.isRefreshing == false)
}

@MainActor
@Test func refreshFromCacheMarksTheStoreStale() async throws {
    let cache = makeCache()
    try await cache.write(Fixtures.full)
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
            cache: cache
        )
    )
    await store.refresh()
    #expect(store.state.value != nil)
    #expect(store.isStale)
}

@MainActor
@Test func refreshWithNoCacheEntersTheFailedState() async {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
            cache: makeCache()
        )
    )
    await store.refresh()
    #expect(store.state.value == nil)
    #expect(store.state.error != nil)
}

@MainActor
@Test func aFailedRefreshKeepsDataAlreadyOnScreen() async {
    let provider = StubSnapshotProvider([
        .success(Fixtures.full),
        .failure(SnapshotError.server(status: 500)),
    ])
    let store = SnapshotStore(
        repository: SnapshotRepository(provider: provider, cache: makeCache())
    )
    await store.refresh()
    #expect(store.state.value != nil)

    await store.refresh()
    // The screen must not blank out just because a background refresh failed.
    #expect(store.state.value != nil)
    #expect(store.lastErrorMessage != nil)
}

@MainActor
@Test func secondsSinceUpdateResetsOnASuccessfulLoad() async {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
            cache: makeCache()
        )
    )
    await store.refresh()
    #expect(store.secondsSinceUpdate == 0)
}

@MainActor
@Test func stopPollingPreventsFurtherFetches() async {
    let provider = StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full)
    let store = SnapshotStore(
        repository: SnapshotRepository(provider: provider, cache: makeCache())
    )
    store.startPolling(interval: .milliseconds(20))
    try? await Task.sleep(for: .milliseconds(120))
    store.stopPolling()
    let countAfterStop = provider.callCount
    try? await Task.sleep(for: .milliseconds(120))
    #expect(provider.callCount == countAfterStop)
}
