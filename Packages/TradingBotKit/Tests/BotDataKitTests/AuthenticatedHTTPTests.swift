import Foundation
import Testing
@testable import BotDataKit

// Pure credential tests — these touch no shared state, so they need no suite.
// Everything that drives MockURLProtocol lives in HTTPClientTests' single serialized
// suite: `.serialized` orders tests *within* a suite, so two separate serialized
// suites sharing the mock's global queue still race each other.

@Test func basicCredentialsEncodeTheStandardHeader() {
    // RFC 7617: base64("admin:secret")
    let credentials = BasicCredentials(username: "admin", password: "secret")
    #expect(credentials.authorizationHeaderValue == "Basic YWRtaW46c2VjcmV0")
}

@Test func basicCredentialsHandleColonsInThePassword() {
    // Only the first colon separates user from password.
    let credentials = BasicCredentials(username: "admin", password: "a:b:c")
    let decoded = Data(
        base64Encoded: String(credentials.authorizationHeaderValue.dropFirst("Basic ".count))
    )
    #expect(String(decoding: decoded ?? Data(), as: UTF8.self) == "admin:a:b:c")
}

@Test func emptyCredentialsAreDetected() {
    #expect(BasicCredentials(username: "", password: "x").isEmpty)
    #expect(BasicCredentials(username: "x", password: "").isEmpty)
    #expect(BasicCredentials(username: "x", password: "y").isEmpty == false)
}
