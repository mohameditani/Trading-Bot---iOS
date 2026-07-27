import Foundation
import BotDomain

/// Anything that can produce a raw snapshot payload. The app depends on this, never on
/// a concrete source. Decoding is the repository's job, which keeps providers trivial
/// and lets the cache store exactly the bytes that arrived.
public protocol SnapshotProvider: Sendable {
    func fetchPayload() async throws -> Data
}

public enum SnapshotError: Error, Equatable {
    case resourceMissing(String)
    case noCachedSnapshot
    case decoding(String)
    case transport(String)
    case server(status: Int)
    case offline

    public var userMessage: String {
        switch self {
        case .resourceMissing(let name):
            return "Bundled snapshot \"\(name)\" is missing."
        case .noCachedSnapshot:
            return "No saved snapshot yet."
        case .decoding:
            return "The snapshot could not be read."
        case .transport:
            return "Could not reach the bot."
        case .server(let status):
            return "The bot responded with an error (\(status))."
        case .offline:
            return "You appear to be offline."
        }
    }
}
