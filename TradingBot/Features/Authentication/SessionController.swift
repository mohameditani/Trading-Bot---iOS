import Foundation
import Observation

@Observable
@MainActor
final class SessionController {
    private(set) var isAuthenticated = false
    var errorMessage: String?

    private let keychain: KeychainStore

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
        self.isAuthenticated = keychain.load() != nil
    }

    func login(username: String, password: String) async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Enter both username and password."
            return
        }
        // Phase 1: acceptance only. Server-side Basic auth validation is Phase 2.
        do {
            try keychain.save(username: trimmedUsername, password: password)
            isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = "Could not store credentials securely."
        }
    }

    func logout() {
        keychain.clear()
        isAuthenticated = false
    }
}
