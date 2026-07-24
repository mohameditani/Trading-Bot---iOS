import Foundation

struct HTTPClient: Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"
        return try await perform(request, allowRetry: true)
    }

    private func perform(_ request: URLRequest, allowRetry: Bool) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw HTTPError.transport("invalid response")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw HTTPError.httpStatus(http.statusCode)
            }
            return data
        } catch let error as HTTPError {
            throw error
        } catch let error as URLError where allowRetry && (error.code == .timedOut || error.code == .networkConnectionLost) {
            return try await perform(request, allowRetry: false)
        } catch {
            throw HTTPError.transport(error.localizedDescription)
        }
    }
}
