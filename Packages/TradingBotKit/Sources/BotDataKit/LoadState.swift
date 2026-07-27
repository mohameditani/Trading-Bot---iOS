import Foundation

/// The state of an asynchronous load, shared by every screen.
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(any Error)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var error: (any Error)? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
