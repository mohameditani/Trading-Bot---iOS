import Foundation
import BotDataKit

/// Where the app reads its dashboard settings from.
///
/// Settings live in `TradingBot/Resources/dashboard-config.json`, which is gitignored —
/// credentials never enter the repository. `dashboard-config.example.json` is the
/// committed template.
///
/// Everything is optional. With the file absent, or any required value blank, the app
/// falls back to the bundled snapshot and behaves exactly as it did before.
struct AppConfiguration: Sendable, Equatable {
    var baseURL: URL?
    var credentials: BasicCredentials?
    /// SHA-256 fingerprints of certificates the app will trust for `baseURL`.
    var pinnedFingerprints: [String]

    /// True when there is enough configuration to attempt a live fetch.
    var isLiveConfigured: Bool {
        baseURL != nil && !(credentials?.isEmpty ?? true)
    }

    static let bundledOnly = AppConfiguration(
        baseURL: nil, credentials: nil, pinnedFingerprints: []
    )

    static let resourceName = "dashboard-config"

    static func fromBundle(_ bundle: Bundle = .main) -> AppConfiguration {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return .bundledOnly }
        return decode(data)
    }

    /// Parsed leniently on purpose: a malformed or half-filled config must degrade to
    /// the bundled snapshot, never crash the app on launch or — worse — send a
    /// placeholder string to the dashboard and trip its per-IP lockout.
    static func decode(_ data: Data) -> AppConfiguration {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .bundledOnly
        }

        func string(_ key: String) -> String? {
            guard let raw = root[key] as? String else { return nil }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        let baseURL = string("baseURL").flatMap(URL.init(string:))
        let user = string("username")
        let password = string("password")
        let credentials = (user != nil && password != nil)
            ? BasicCredentials(username: user!, password: password!)
            : nil

        let fingerprints = ((root["certificateSHA256"] as? [String]) ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return AppConfiguration(
            baseURL: baseURL,
            credentials: credentials,
            pinnedFingerprints: fingerprints
        )
    }
}
