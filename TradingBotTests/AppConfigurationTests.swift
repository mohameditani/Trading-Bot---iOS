import Foundation
import Testing
import BotDataKit
@testable import TradingBot

@Test func decodesACompleteConfiguration() {
    let config = AppConfiguration.decode(Data("""
    { "baseURL": "https://165.227.151.108:8443", "username": "admin",
      "password": "hunter2",
      "certificateSHA256": ["a2aaa94711bd3b2a9ab74963967d0fa84c5cbb9bdd65d4da8d1ebf3119dcf1a9"] }
    """.utf8))

    #expect(config.baseURL?.absoluteString == "https://165.227.151.108:8443")
    #expect(config.credentials?.username == "admin")
    #expect(config.pinnedFingerprints.count == 1)
    #expect(config.isLiveConfigured)
}

// The template ships with a blank password. Shipping that as-is must not go live —
// it would send an empty credential and count against the dashboard's IP lockout.
@Test func aBlankPasswordIsNotLiveConfigured() {
    let config = AppConfiguration.decode(Data("""
    { "baseURL": "https://example.test", "username": "admin", "password": "" }
    """.utf8))
    #expect(config.credentials == nil)
    #expect(config.isLiveConfigured == false)
}

@Test func whitespaceOnlyValuesCountAsBlank() {
    let config = AppConfiguration.decode(Data("""
    { "baseURL": "https://example.test", "username": "  ", "password": "\\n" }
    """.utf8))
    #expect(config.isLiveConfigured == false)
}

@Test func aMissingBaseURLIsNotLiveConfigured() {
    let config = AppConfiguration.decode(Data("""
    { "username": "admin", "password": "hunter2" }
    """.utf8))
    #expect(config.isLiveConfigured == false)
}

@Test func malformedJSONFallsBackToBundled() {
    #expect(AppConfiguration.decode(Data("{ not json".utf8)) == .bundledOnly)
}

@Test func anAbsentConfigFileFallsBackToBundled() {
    // Bundle.main during tests has no dashboard-config.json.
    let config = AppConfiguration.fromBundle(Bundle(for: ConfigProbe.self))
    #expect(config.isLiveConfigured == false)
}

@Test func ignoresTheTemplatesCommentBlock() {
    let config = AppConfiguration.decode(Data("""
    { "_comment": ["copy me"], "baseURL": "https://example.test",
      "username": "admin", "password": "hunter2", "certificateSHA256": [] }
    """.utf8))
    #expect(config.isLiveConfigured)
    #expect(config.pinnedFingerprints.isEmpty)
}

@Test func acceptsTwoFingerprintsForRotation() {
    let config = AppConfiguration.decode(Data("""
    { "baseURL": "https://example.test", "username": "u", "password": "p",
      "certificateSHA256": ["aaaa", " bbbb ", ""] }
    """.utf8))
    #expect(config.pinnedFingerprints == ["aaaa", "bbbb"])
}

// MARK: - The unit-test network guard
//
// A developer machine with a filled-in dashboard-config.json would otherwise point the
// whole suite at the production bot: every ViewModel test would assert against live
// trades and fail, and each run would spend attempts against the dashboard's 10-strike
// per-IP lockout. This test exists so the guard cannot be quietly removed.

@Test func aUnitTestHostIsDetected() {
    #expect(AppContainer.isRunningUnitTests)
}

@MainActor
@Test func aUnitTestHostNeverGoesLiveEvenWhenFullyConfigured() async {
    let container = AppContainer(
        arguments: [],
        configuration: AppConfiguration(
            baseURL: URL(string: "https://165.227.151.108:8443"),
            credentials: BasicCredentials(username: "admin", password: "real"),
            pinnedFingerprints: ["deadbeef"]
        )
    )
    #expect(container.isLive == false)

    // And it still serves the bundled snapshot rather than failing.
    await container.store.refresh()
    #expect(container.store.state.value?.summary.total == 28)
}

private final class ConfigProbe {}
