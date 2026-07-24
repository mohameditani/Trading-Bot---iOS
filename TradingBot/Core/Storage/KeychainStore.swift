import Foundation
import Security

final class KeychainStore: Sendable {
    enum KeychainError: Error {
        case encodingFailed
        case unexpectedStatus(OSStatus)
    }

    private let service: String

    init(service: String = "com.tradingbot.ios") {
        self.service = service
    }

    func save(username: String, password: String) throws {
        let payload = "\(username)\n\(password)"
        guard let data = payload.data(using: .utf8) else { throw KeychainError.encodingFailed }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "dashboard-credentials"
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    func load() -> (username: String, password: String)? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "dashboard-credentials",
            kSecReturnData as String: true
        ]
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let payload = String(data: data, encoding: .utf8)
        else { return nil }
        let parts = payload.split(separator: "\n", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "dashboard-credentials"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
