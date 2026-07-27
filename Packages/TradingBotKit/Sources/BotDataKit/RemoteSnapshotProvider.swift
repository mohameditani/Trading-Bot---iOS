import Foundation
import BotDomain

/// Fetches the snapshot over HTTP. Implemented and tested now; wired live only when
/// the real dashboard's credentials exist.
public struct RemoteSnapshotProvider: SnapshotProvider {
    private let url: URL
    private let client: HTTPClient

    public init(baseURL: URL, client: HTTPClient = HTTPClient(), path: String = "api/snapshot") {
        self.url = baseURL.appendingPathComponent(path)
        self.client = client
    }

    public func fetchPayload() async throws -> Data {
        try await client.get(url)
    }
}
