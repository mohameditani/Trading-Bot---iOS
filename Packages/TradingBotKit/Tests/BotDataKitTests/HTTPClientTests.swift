import Foundation
import Testing
@testable import BotDataKit

private let testURL = URL(string: "https://example.test/api/snapshot")!

/// Serialized: `MockURLProtocol` scripts responses through shared static state, and
/// Swift Testing runs tests in parallel by default. Without this the queue and the
/// request counter are clobbered across concurrent tests.
@Suite(.serialized)
struct HTTPClientTests {

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

    @Test func serverErrorsAreRetriedThenGiveUp() async {
        MockURLProtocol.reset(with: [.status(503)])
        let client = HTTPClient(
            session: MockURLProtocol.makeSession(), maxRetries: 2, retryDelay: 0
        )
        await #expect(throws: SnapshotError.server(status: 503)) {
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

    @Test func remoteProviderPropagatesServerErrors() async {
        MockURLProtocol.reset(with: [.status(401)])
        let provider = RemoteSnapshotProvider(
            baseURL: URL(string: "https://example.test")!,
            client: HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
        )
        await #expect(throws: SnapshotError.server(status: 401)) {
            _ = try await provider.fetchPayload()
        }
    }
}
