import Foundation
import Observation

@Observable
@MainActor
final class AppContainer {
    let repository: SnapshotRepository
    let store: SnapshotStore

    init(configuration: AppConfiguration = AppConfiguration()) {
        let provider: any BotDataProvider
        if let baseURL = configuration.baseURL {
            provider = RemoteBotDataProvider(baseURL: baseURL, client: HTTPClient())
        } else {
            provider = BundledBotDataProvider()
        }
        let repository = SnapshotRepository(provider: provider, cache: JSONCacheStore())
        self.repository = repository
        self.store = SnapshotStore(repository: repository)
    }

    /// Test seam: inject any repository.
    init(repository: SnapshotRepository) {
        self.repository = repository
        self.store = SnapshotStore(repository: repository)
    }
}
