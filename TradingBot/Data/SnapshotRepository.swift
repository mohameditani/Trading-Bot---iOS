import Foundation

enum SnapshotRepositoryError: Error {
    case noData
}

struct SnapshotRepository: Sendable {
    let provider: any BotDataProvider
    let cache: JSONCacheStore

    func snapshot() async -> LoadState<BotSnapshot> {
        do {
            let snapshot = try await provider.fetchSnapshot()
            await cache.save(snapshot)
            return .loaded(snapshot)
        } catch {
            if let cached = await cache.load() {
                return .error(error.localizedDescription, cached)
            }
            return .error(error.localizedDescription, nil)
        }
    }
}
