import Foundation

enum LoadState<Value: Equatable>: Equatable {
    case loading
    case loaded(Value)
    case refreshing(Value)
    case empty
    case error(String, Value?)

    var value: Value? {
        switch self {
        case .loaded(let value), .refreshing(let value): value
        case .error(_, let last): last
        case .loading, .empty: nil
        }
    }
}
