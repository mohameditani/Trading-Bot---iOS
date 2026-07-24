import Foundation
import Testing
@testable import TradingBot

@Suite("SnapshotStore")
@MainActor
struct SnapshotStoreTests {
    private func makeSnapshot(equity: Double = 179.79) -> BotSnapshot {
        let point = EquityPoint(date: Date(timeIntervalSince1970: 1_752_192_000), equity: equity)
        return BotSnapshot(
            dashboard: DashboardSummary(totalEquity: equity, balance: 81.67, winRate: 0.222, todayPnL: 0, allTimePnL: -21.7, openPositionsCount: 1, totalTrades: 27, equityCurve: [point]),
            portfolio: PortfolioSummary(equityCurve: [point], high: 185, low: 75, current: 79.8, rangeStart: point.date, rangeEnd: point.date),
            positions: [],
            trades: [],
            insights: InsightFeed(vetoLog: [], lessons: []),
            breakdown: Breakdown(bySymbol: [], byRegime: [])
        )
    }

    private func makeStore(result: Result<BotSnapshot, Error>) -> (SnapshotStore, MockBotDataProvider) {
        let provider = MockBotDataProvider(result: result)
        let repo = SnapshotRepository(provider: provider, cache: JSONCacheStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        return (SnapshotStore(repository: repo, pollInterval: .seconds(3600)), provider)
    }

    @Test func refreshLoadsSnapshot() async {
        let (store, _) = makeStore(result: .success(makeSnapshot()))
        await store.refresh()
        #expect(store.state.value?.dashboard.totalEquity == 179.79)
        guard case .loaded = store.state else { Issue.record("expected .loaded, got \(store.state)"); return }
    }

    @Test func refreshFailureKeepsPreviousValueAsError() async {
        let (store, provider) = makeStore(result: .success(makeSnapshot()))
        await store.refresh()
        provider.result = .failure(URLError(.notConnectedToInternet))
        await store.refresh()
        guard case .error(_, let last) = store.state else { Issue.record("expected .error, got \(store.state)"); return }
        #expect(last?.dashboard.totalEquity == 179.79)
    }

    @Test func startPollingFetchesRepeatedly() async throws {
        let (store, provider) = makeStore(result: .success(makeSnapshot()))
        let repo = SnapshotRepository(provider: provider, cache: JSONCacheStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        let pollingStore = SnapshotStore(repository: repo, pollInterval: .milliseconds(50))
        pollingStore.startPolling()
        try await Task.sleep(for: .milliseconds(200))
        pollingStore.stopPolling()
        #expect(provider.callCount >= 2)
        _ = store
    }

    @Test func stopPollingCancelsLoop() async throws {
        let (store, provider) = makeStore(result: .success(makeSnapshot()))
        let repo = SnapshotRepository(provider: provider, cache: JSONCacheStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        let pollingStore = SnapshotStore(repository: repo, pollInterval: .milliseconds(50))
        pollingStore.startPolling()
        try await Task.sleep(for: .milliseconds(120))
        pollingStore.stopPolling()
        let countAfterStop = provider.callCount
        try await Task.sleep(for: .milliseconds(150))
        #expect(provider.callCount == countAfterStop)
        _ = store
    }
}
