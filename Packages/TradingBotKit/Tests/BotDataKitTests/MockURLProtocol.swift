import Foundation

/// Intercepts URLSession traffic so HTTP behaviour is testable without a network.
final class MockURLProtocol: URLProtocol {
    struct Response {
        let statusCode: Int
        let data: Data?
        let error: (any Error)?

        static func ok(_ data: Data) -> Response {
            Response(statusCode: 200, data: data, error: nil)
        }
        static func status(_ code: Int) -> Response {
            Response(statusCode: code, data: Data(), error: nil)
        }
        static func failure(_ error: any Error) -> Response {
            Response(statusCode: 0, data: nil, error: error)
        }
    }

    /// Responses are popped in order, so a test can script "fail, fail, succeed".
    /// The last entry repeats once the queue is down to one.
    nonisolated(unsafe) private static var queue: [Response] = []
    nonisolated(unsafe) private static var requestCount = 0
    private static let lock = NSLock()

    static func reset(with responses: [Response]) {
        lock.lock()
        queue = responses
        requestCount = 0
        lock.unlock()
    }

    static func next() -> Response {
        lock.lock()
        defer { lock.unlock() }
        requestCount += 1
        if queue.count > 1 { return queue.removeFirst() }
        return queue.first ?? .status(500)
    }

    static var totalRequests: Int {
        lock.lock()
        defer { lock.unlock() }
        return requestCount
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let response = MockURLProtocol.next()
        if let error = response.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        if let data = response.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
}
