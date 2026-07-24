import Foundation
import Observation

@Observable
@MainActor
final class AppContainer {
    let repository: SnapshotRepository

    init(configuration: AppConfiguration = AppConfiguration()) {
        let provider: any BotDataProvider
        if let baseURL = configuration.baseURL {
            provider = RemoteBotDataProvider(baseURL: baseURL, client: HTTPClient())
        } else {
            provider = BundledBotDataProvider()
        }
        self.repository = SnapshotRepository(provider: provider, cache: JSONCacheStore())
    }

    /// Test seam: inject any repository.
    init(repository: SnapshotRepository) {
        self.repository = repository
    }
}
