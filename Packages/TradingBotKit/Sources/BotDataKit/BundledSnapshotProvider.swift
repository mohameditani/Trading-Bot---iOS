import Foundation
import BotDomain

/// Reads a snapshot from a JSON resource shipped inside the app.
///
/// The loader closure is injectable so tests exercise it without a real bundle.
public struct BundledSnapshotProvider: SnapshotProvider {
    private let resource: String
    private let loader: @Sendable () -> Data?

    public init(resource: String = "snapshot", loader: @escaping @Sendable () -> Data?) {
        self.resource = resource
        self.loader = loader
    }

    /// Production initialiser — reads `<resource>.json` from the given bundle.
    public init(resource: String = "snapshot", bundle: Bundle = .main) {
        self.resource = resource
        self.loader = { [resource] in
            guard let url = bundle.url(forResource: resource, withExtension: "json") else {
                return nil
            }
            return try? Data(contentsOf: url)
        }
    }

    public func fetchPayload() async throws -> Data {
        guard let data = loader() else {
            throw SnapshotError.resourceMissing(resource)
        }
        return data
    }
}
