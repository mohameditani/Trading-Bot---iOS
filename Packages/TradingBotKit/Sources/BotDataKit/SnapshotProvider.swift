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
    /// 401 — wrong or missing dashboard credentials.
    case unauthorized
    /// 429 — the dashboard locks an IP out for 5 minutes after 10 failed attempts.
    case lockedOut
    /// 503 — the dashboard is running but `DASHBOARD_PASSWORD` is unset, so it
    /// fail-closes every data route.
    case dashboardNotConfigured
    /// The TLS certificate did not match the pinned fingerprint.
    case certificateMismatch

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
        case .unauthorized:
            return "Dashboard credentials were rejected."
        case .lockedOut:
            return "Too many failed attempts — try again in a few minutes."
        case .dashboardNotConfigured:
            return "The dashboard has no password set."
        case .certificateMismatch:
            return "The bot's certificate did not match the expected one."
        }
    }
}

/// HTTP Basic credentials for the dashboard.
///
/// Deliberately not `CustomStringConvertible` — nothing should be able to print these
/// into a log by accident.
public struct BasicCredentials: Sendable, Equatable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    public var isEmpty: Bool { username.isEmpty || password.isEmpty }

    public var authorizationHeaderValue: String {
        "Basic " + Data("\(username):\(password)".utf8).base64EncodedString()
    }
}
