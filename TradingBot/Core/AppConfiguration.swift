import Foundation

struct AppConfiguration: Sendable {
    /// Base URL of the bot dashboard, e.g. https://165.227.151.108:8443
    /// `nil` = bundled snapshot only (Phase 1 default until API credentials exist).
    var baseURL: URL? = nil
}
