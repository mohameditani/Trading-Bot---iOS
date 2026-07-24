import Foundation
import Testing
@testable import TradingBot

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else { return }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data { client?.urlProtocol(self, didLoad: data) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("HTTPClient", .serialized)
struct HTTPClientTests {
    private func makeClient() -> HTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return HTTPClient(session: URLSession(configuration: config))
    }

    private func url() -> URL {
        URL(string: "https://example.com/snapshot.json")! // swiftlint:disable:this force_unwrapping
    }

    @Test func returnsDataOn200() async throws {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)! // test-only
            return (response, Data("{\"ok\":true}".utf8))
        }
        let data = try await makeClient().get(url())
        #expect(String(data: data, encoding: .utf8) == "{\"ok\":true}")
    }

    @Test func throwsHTTPStatusOn404() async {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)! // test-only
            return (response, nil)
        }
        do {
            _ = try await makeClient().get(url())
            Issue.record("expected throw")
        } catch let error as HTTPError {
            #expect(error == .httpStatus(404))
        } catch {
            Issue.record("wrong error type: \(error)")
        }
    }

    @Test func userMessagesAreReadable() {
        #expect(!HTTPError.httpStatus(401).userMessage.isEmpty)
        #expect(!HTTPError.transport("offline").userMessage.isEmpty)
    }
}
