import Foundation

/// Minimal GET client with bounded retry.
///
/// Retries only what can plausibly succeed on a second attempt: transport errors and
/// 5xx responses. A 4xx is a permanent answer, so it fails immediately.
public struct HTTPClient: Sendable {
    private let session: URLSession
    private let maxRetries: Int
    private let retryDelay: Duration
    private let credentials: BasicCredentials?

    public init(
        session: URLSession = .shared,
        maxRetries: Int = 2,
        retryDelay: Duration = .milliseconds(400),
        credentials: BasicCredentials? = nil
    ) {
        self.session = session
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.credentials = credentials
    }

    /// Convenience for tests that want a delay expressed in whole milliseconds.
    public init(
        session: URLSession,
        maxRetries: Int,
        retryDelay: Int,
        credentials: BasicCredentials? = nil
    ) {
        self.init(
            session: session,
            maxRetries: maxRetries,
            retryDelay: .milliseconds(retryDelay),
            credentials: credentials
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
        var request = URLRequest(url: url)
        if let credentials, !credentials.isEmpty {
            request.setValue(
                credentials.authorizationHeaderValue,
                forHTTPHeaderField: "Authorization"
            )
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                throw SnapshotError.offline
            case .serverCertificateUntrusted,
                 .serverCertificateHasBadDate,
                 .serverCertificateHasUnknownRoot,
                 .serverCertificateNotYetValid,
                 .cancelled:
                // The pinning delegate cancels the challenge on a mismatch, which
                // surfaces here as .cancelled — report it as what it actually is
                // rather than as a generic transport failure.
                throw SnapshotError.certificateMismatch
            default:
                throw SnapshotError.transport(urlError.localizedDescription)
            }
        } catch {
            throw SnapshotError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SnapshotError.transport("Response was not HTTP.")
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401:
            throw SnapshotError.unauthorized
        case 429:
            throw SnapshotError.lockedOut
        case 503:
            throw SnapshotError.dashboardNotConfigured
        default:
            throw SnapshotError.server(status: http.statusCode)
        }
    }

    private func isRetryable(_ error: SnapshotError) -> Bool {
        switch error {
        case .transport, .offline:
            return true
        case .server(let status):
            return status >= 500
        // Never retry these: bad credentials stay bad, and retrying into the
        // dashboard's per-IP lockout is exactly how a 401 becomes a 429.
        case .unauthorized, .lockedOut, .dashboardNotConfigured, .certificateMismatch:
            return false
        default:
            return false
        }
    }
}
