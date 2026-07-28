import Foundation
import Testing
@testable import BotDataKit

private let testURL = URL(string: "https://example.test/api/snapshot")!

/// Serialized: `MockURLProtocol` scripts responses through shared static state, and
/// Swift Testing runs tests in parallel by default. Without this the queue and the
/// request counter are clobbered across concurrent tests.
///
/// **Every test that drives the mock belongs in this one suite.** `.serialized` orders
/// tests within a suite but does nothing across suites, so splitting them into a second
/// serialized suite reintroduces the race between the two suites.
@Suite(.serialized)
struct HTTPClientTests {

    // MARK: - Authentication

    @Test func sendsTheAuthorizationHeader() async throws {
        MockURLProtocol.reset(with: [.ok(Fixtures.full)])
        let client = HTTPClient(
            session: MockURLProtocol.makeSession(),
            maxRetries: 0,
            retryDelay: 0,
            credentials: BasicCredentials(username: "admin", password: "secret")
        )
        _ = try await client.get(testURL)
        #expect(MockURLProtocol.lastAuthorizationHeader == "Basic YWRtaW46c2VjcmV0")
    }

    @Test func sendsNoAuthorizationHeaderWhenUnconfigured() async throws {
        MockURLProtocol.reset(with: [.ok(Fixtures.full)])
        let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        _ = try await client.get(testURL)
        #expect(MockURLProtocol.lastAuthorizationHeader == nil)
    }

    // The dashboard's real failure modes, mapped to messages a person can act on.
    @Test func mapsUnauthorized() async {
        MockURLProtocol.reset(with: [.status(401)])
        let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        await #expect(throws: SnapshotError.unauthorized) {
            _ = try await client.get(testURL)
        }
    }

    @Test func mapsTheDashboardsPerIPLockout() async {
        MockURLProtocol.reset(with: [.status(429)])
        let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        await #expect(throws: SnapshotError.lockedOut) {
            _ = try await client.get(testURL)
        }
    }

    @Test func mapsTheFailClosedUnconfiguredDashboard() async {
        MockURLProtocol.reset(with: [.status(503)])
        let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        await #expect(throws: SnapshotError.dashboardNotConfigured) {
            _ = try await client.get(testURL)
        }
    }

    // Retrying a 401 is how a wrong password becomes a 5-minute IP lockout.
    @Test func doesNotRetryAuthenticationFailures() async {
        MockURLProtocol.reset(with: [.status(401)])
        let client = HTTPClient(
            session: MockURLProtocol.makeSession(), maxRetries: 3, retryDelay: 0
        )
        await #expect(throws: SnapshotError.unauthorized) {
            _ = try await client.get(testURL)
        }
        #expect(MockURLProtocol.totalRequests == 1)
    }

    @Test func doesNotRetryALockout() async {
        MockURLProtocol.reset(with: [.status(429)])
        let client = HTTPClient(
            session: MockURLProtocol.makeSession(), maxRetries: 3, retryDelay: 0
        )
        await #expect(throws: SnapshotError.lockedOut) {
            _ = try await client.get(testURL)
        }
        #expect(MockURLProtocol.totalRequests == 1)
    }

    // MARK: - Transport

    @Test func getReturnsBodyOnSuccess() async throws {
        MockURLProtocol.reset(with: [.ok(Fixtures.full)])
        let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        let data = try await client.get(testURL)
        #expect(data == Fixtures.full)
    }

    @Test func serverErrorIsMappedToAServerFailure() async {
        MockURLProtocol.reset(with: [.status(500)])
        let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        await #expect(throws: SnapshotError.server(status: 500)) {
            _ = try await client.get(testURL)
        }
    }

    @Test func clientErrorIsMappedAndNotRetried() async {
        MockURLProtocol.reset(with: [.status(404)])
        let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 3)
        await #expect(throws: SnapshotError.server(status: 404)) {
            _ = try await client.get(testURL)
        }
        // A 404 will not fix itself — retrying it wastes time and battery.
        #expect(MockURLProtocol.totalRequests == 1)
    }

    @Test func transientFailureIsRetriedUntilItSucceeds() async throws {
        let transient = URLError(.timedOut)
        MockURLProtocol.reset(with: [
            .failure(transient),
            .failure(transient),
            .ok(Fixtures.full),
        ])
        let client = HTTPClient(
            session: MockURLProtocol.makeSession(), maxRetries: 3, retryDelay: 0
        )
        let data = try await client.get(testURL)
        #expect(data == Fixtures.full)
        #expect(MockURLProtocol.totalRequests == 3)
    }

    // 502, not 503: the dashboard uses 503 specifically to mean "no password
    // configured", which is permanent and must not be retried.
    @Test func serverErrorsAreRetriedThenGiveUp() async {
        MockURLProtocol.reset(with: [.status(502)])
        let client = HTTPClient(
            session: MockURLProtocol.makeSession(), maxRetries: 2, retryDelay: 0
        )
        await #expect(throws: SnapshotError.server(status: 502)) {
            _ = try await client.get(testURL)
        }
        #expect(MockURLProtocol.totalRequests == 3)   // initial + 2 retries
    }

    @Test func offlineIsReportedDistinctlyFromOtherTransportFailures() async {
        MockURLProtocol.reset(with: [.failure(URLError(.notConnectedToInternet))])
        let client = HTTPClient(
            session: MockURLProtocol.makeSession(), maxRetries: 0, retryDelay: 0
        )
        await #expect(throws: SnapshotError.offline) {
            _ = try await client.get(testURL)
        }
    }

    @Test func remoteProviderFetchesADecodablePayload() async throws {
        MockURLProtocol.reset(with: [.ok(Fixtures.full)])
        let provider = RemoteSnapshotProvider(
            baseURL: URL(string: "https://example.test")!,
            client: HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        )
        let snapshot = try SnapshotDecoder.decode(try await provider.fetchPayload())
        #expect(snapshot.summary.equity == 116.40)
    }

    @Test func remoteProviderPropagatesAuthenticationFailures() async {
        MockURLProtocol.reset(with: [.status(401)])
        let provider = RemoteSnapshotProvider(
            baseURL: URL(string: "https://example.test")!,
            client: HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        )
        await #expect(throws: SnapshotError.unauthorized) {
            _ = try await provider.fetchPayload()
        }
    }

    @Test func remoteProviderPropagatesGenericServerErrors() async {
        MockURLProtocol.reset(with: [.status(500)])
        let provider = RemoteSnapshotProvider(
            baseURL: URL(string: "https://example.test")!,
            client: HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        )
        await #expect(throws: SnapshotError.server(status: 500)) {
            _ = try await provider.fetchPayload()
        }
    }
}
