import Foundation
import Testing
@testable import TradingBot

@Suite("SessionController")
@MainActor
struct SessionControllerTests {
    private func makeSession() -> SessionController {
        let keychain = KeychainStore(service: "com.tradingbot.ios.tests.\(UUID().uuidString)")
        return SessionController(keychain: keychain)
    }

    @Test func startsLoggedOutWithoutStoredCredentials() {
        #expect(makeSession().isAuthenticated == false)
    }

    @Test func loginWithNonEmptyCredentialsAuthenticates() async {
        let session = makeSession()
        await session.login(username: "demo", password: "secret")
        #expect(session.isAuthenticated == true)
        #expect(session.errorMessage == nil)
    }

    @Test func loginWithEmptyUsernameFails() async {
        let session = makeSession()
        await session.login(username: "", password: "secret")
        #expect(session.isAuthenticated == false)
        #expect(session.errorMessage != nil)
    }

    @Test func loginWithEmptyPasswordFails() async {
        let session = makeSession()
        await session.login(username: "demo", password: "  ")
        #expect(session.isAuthenticated == false)
    }

    @Test func credentialsSurviveNewController() async {
        let service = "com.tradingbot.ios.tests.\(UUID().uuidString)"
        let keychain = KeychainStore(service: service)
        let first = SessionController(keychain: keychain)
        await first.login(username: "demo", password: "secret")
        let second = SessionController(keychain: KeychainStore(service: service))
        #expect(second.isAuthenticated == true)
    }

    @Test func logoutClearsSessionAndKeychain() async {
        let service = "com.tradingbot.ios.tests.\(UUID().uuidString)"
        let keychain = KeychainStore(service: service)
        let session = SessionController(keychain: keychain)
        await session.login(username: "demo", password: "secret")
        session.logout()
        #expect(session.isAuthenticated == false)
        #expect(KeychainStore(service: service).load() == nil)
    }
}
