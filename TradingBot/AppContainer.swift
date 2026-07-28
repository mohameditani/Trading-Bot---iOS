import Foundation
import BotDataKit
import BotDomain

/// A provider that always fails, used only by the `error` UI-test fixture.
private struct FailingSnapshotProvider: SnapshotProvider {
    func fetchPayload() async throws -> Data {
        throw SnapshotError.offline
    }
}

/// The one place that decides where data comes from.
///
/// Pointing the app at the real dashboard is a change here and nowhere else:
/// swap `BundledSnapshotProvider` for `RemoteSnapshotProvider(baseURL:)`.
@MainActor
final class AppContainer {
    let store: SnapshotStore
    /// True when the app is talking to the real dashboard rather than bundled JSON.
    let isLive: Bool

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        configuration: AppConfiguration = .fromBundle()
    ) {
        let fixture = Self.fixtureName(from: arguments)

        // A fixture always wins: UI tests must never reach the network, whatever the
        // build happens to be configured with.
        let useLive = fixture == nil && configuration.isLiveConfigured
        self.isLive = useLive

        let provider: any SnapshotProvider
        if fixture == "error" {
            provider = FailingSnapshotProvider()
        } else if useLive, let baseURL = configuration.baseURL {
            provider = RemoteSnapshotProvider(
                baseURL: baseURL,
                client: HTTPClient(
                    session: Self.session(for: configuration),
                    credentials: configuration.credentials
                ),
                // The dashboard's endpoint is /api/data.
                path: "api/data"
            )
        } else {
            provider = BundledSnapshotProvider(
                resource: Self.resourceName(for: fixture),
                bundle: .main
            )
        }

        // A UI-test run must not inherit a cache from a previous fixture — otherwise the
        // error fixture would fall back to cached data and never reach its failed state.
        let cache: SnapshotCache
        if let fixture {
            cache = SnapshotCache(
                directory: FileManager.default.temporaryDirectory
                    .appendingPathComponent("uitest-\(fixture)")
            )
        } else {
            cache = SnapshotCache.makeDefault()
        }

        self.store = SnapshotStore(
            repository: SnapshotRepository(provider: provider, cache: cache)
        )
    }

    /// Reads `-fixture <name>` from launch arguments. Returns nil when absent.
    ///
    /// `nonisolated` because argument parsing is pure — it would otherwise inherit the
    /// class's `@MainActor` and be unusable from a synchronous test.
    nonisolated static func fixtureName(from arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: "-fixture"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        return arguments[arguments.index(after: index)]
    }

    nonisolated static func resourceName(for fixture: String?) -> String {
        switch fixture {
        case "aiNull": return "snapshot-ai-null"
        case "empty": return "snapshot-empty"
        default: return "snapshot"
        }
    }

    /// Pinned session when fingerprints are configured, default session otherwise.
    ///
    /// The dashboard's certificate is self-signed, so without a pin the connection
    /// simply fails — which is the correct outcome, not something to work around.
    nonisolated static func session(for configuration: AppConfiguration) -> URLSession {
        guard !configuration.pinnedFingerprints.isEmpty else { return .shared }
        return .pinned(to: CertificatePinner(fingerprints: configuration.pinnedFingerprints))
    }
}
