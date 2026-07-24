import Foundation

enum HTTPError: Error, Equatable {
    case invalidURL
    case httpStatus(Int)
    case decoding
    case transport(String)

    var userMessage: String {
        switch self {
        case .invalidURL:
            "Invalid server address."
        case .httpStatus(401):
            "Session expired. Please sign in again."
        case .httpStatus(403):
            "You don't have access to this resource."
        case .httpStatus(404):
            "The requested data was not found."
        case .httpStatus(let code) where code >= 500:
            "The server is having trouble. Try again shortly."
        case .httpStatus(let code):
            "Request failed (HTTP \(code))."
        case .decoding:
            "Received unexpected data from the server."
        case .transport:
            "Network unavailable. Check your connection and retry."
        }
    }
}
