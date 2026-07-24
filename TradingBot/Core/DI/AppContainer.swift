import Foundation
import Observation

@Observable
@MainActor
final class AppContainer {
    let repository: SnapshotRepository
    let store: SnapshotStore
    let session: SessionController

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
        self.session = SessionController()
    }

    /// Test seam: inject any repository.
    init(repository: SnapshotRepository, session: SessionController? = nil) {
        self.repository = repository
        self.store = SnapshotStore(repository: repository)
        self.session = session ?? SessionController()
    }
}
