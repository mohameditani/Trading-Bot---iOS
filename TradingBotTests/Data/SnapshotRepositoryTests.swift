import Foundation
import Testing
@testable import TradingBot

@Suite("SnapshotRepository")
struct SnapshotRepositoryTests {
    private func makeSnapshot(equity: Double = 179.79) -> BotSnapshot {
        let point = EquityPoint(date: Date(timeIntervalSince1970: 1_752_192_000), equity: equity)
        let curve = [point]
        return BotSnapshot(
            dashboard: DashboardSummary(totalEquity: equity, balance: 81.67, winRate: 0.222, todayPnL: 0, allTimePnL: -21.7, openPositionsCount: 1, totalTrades: 27, equityCurve: curve),
            portfolio: PortfolioSummary(equityCurve: curve, high: 185, low: 75, current: 79.8, rangeStart: point.date, rangeEnd: point.date),
            positions: [],
            trades: [],
            insights: InsightFeed(vetoLog: [], lessons: []),
            breakdown: Breakdown(bySymbol: [], byRegime: [])
        )
    }

    private func makeCache() -> JSONCacheStore {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        return JSONCacheStore(directory: dir)
    }

    @Test func returnsLoadedOnSuccess() async {
        let repo = SnapshotRepository(provider: MockBotDataProvider(result: .success(makeSnapshot())), cache: makeCache())
        let state = await repo.snapshot()
        #expect(state.value?.dashboard.totalEquity == 179.79)
        guard case .loaded = state else { Issue.record("expected .loaded, got \(state)"); return }
    }

    @Test func fallsBackToCacheOnFailure() async {
        let cache = makeCache()
        await cache.save(makeSnapshot(equity: 100))
        let repo = SnapshotRepository(provider: MockBotDataProvider(result: .failure(URLError(.notConnectedToInternet))), cache: cache)
        let state = await repo.snapshot()
        #expect(state.value?.dashboard.totalEquity == 100)
        guard case .error = state else { Issue.record("expected .error with cached value, got \(state)"); return }
    }

    @Test func cacheRoundTrip() async {
        let cache = makeCache()
        await cache.save(makeSnapshot(equity: 42))
        let loaded = await cache.load()
        #expect(loaded?.dashboard.totalEquity == 42)
    }
}
