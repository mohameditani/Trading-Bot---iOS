import Foundation

/// Minimal GET client with bounded retry.
///
/// Retries only what can plausibly succeed on a second attempt: transport errors and
/// 5xx responses. A 4xx is a permanent answer, so it fails immediately.
public struct HTTPClient: Sendable {
    private let session: URLSession
    private let maxRetries: Int
    private let retryDelay: Duration

    public init(
        session: URLSession = .shared,
        maxRetries: Int = 2,
        retryDelay: Duration = .milliseconds(400)
    ) {
        self.session = session
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    /// Convenience for tests that want a delay expressed in whole milliseconds.
    public init(session: URLSession, maxRetries: Int, retryDelay: Int) {
        self.init(
            session: session,
            maxRetries: maxRetries,
            retryDelay: .milliseconds(retryDelay)
        )
    }

    public func get(_ url: URL) async throws -> Data {
        var attempt = 0
        while true {
            do {
                return try await perform(url)
            } catch let error as SnapshotError {
                guard attempt < maxRetries, isRetryable(error) else { throw error }
                attempt += 1
                if retryDelay > .zero {
                    try? await Task.sleep(for: retryDelay)
                }
            }
        }
    }

    private func perform(_ url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            throw urlError.code == .notConnectedToInternet
                ? SnapshotError.offline
                : SnapshotError.transport(urlError.localizedDescription)
        } catch {
            throw SnapshotError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SnapshotError.transport("Response was not HTTP.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SnapshotError.server(status: http.statusCode)
        }
        return data
    }

    private func isRetryable(_ error: SnapshotError) -> Bool {
        switch error {
        case .transport, .offline:
            return true
        case .server(let status):
            return status >= 500
        default:
            return false
        }
    }
}
