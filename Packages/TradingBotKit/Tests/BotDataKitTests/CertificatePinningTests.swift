import Foundation
import Testing
@testable import BotDataKit

// The real dashboard certificate, captured with:
//   openssl s_client -connect 165.227.151.108:8443 | openssl x509 -fingerprint -sha256
private let dashboardFingerprint =
    "A2:AA:A9:47:11:BD:3B:2A:9A:B7:49:63:96:7D:0F:A8:4C:5C:BB:9B:DD:65:D4:DA:8D:1E:BF:31:19:DC:F1:A9"

@Test func normalisesTheFormOpensslPrints() {
    #expect(
        CertificatePinner.normalise(dashboardFingerprint)
        == "a2aaa94711bd3b2a9ab74963967d0fa84c5cbb9bdd65d4da8d1ebf3119dcf1a9"
    )
}

@Test func normalisesAPastedOpensslLine() {
    let pasted = "sha256 Fingerprint=A2:AA:A9:47"
    #expect(CertificatePinner.normalise(pasted) == "a2aaa947")
}

@Test func normalisationIsIdempotent() {
    let once = CertificatePinner.normalise(dashboardFingerprint)
    #expect(CertificatePinner.normalise(once) == once)
}

@Test func acceptsCertificateMatchingThePin() {
    let der = Data("pretend-certificate".utf8)
    let pinner = CertificatePinner(fingerprints: [CertificatePinner.fingerprint(ofDER: der)])
    #expect(pinner.accepts(certificateDER: der))
}

@Test func rejectsAnyOtherCertificate() {
    let der = Data("pretend-certificate".utf8)
    let other = Data("a different certificate".utf8)
    let pinner = CertificatePinner(fingerprints: [CertificatePinner.fingerprint(ofDER: der)])
    #expect(pinner.accepts(certificateDER: other) == false)
}

@Test func rejectsEverythingWhenNoFingerprintIsPinned() {
    let pinner = CertificatePinner(fingerprints: [])
    #expect(pinner.accepts(certificateDER: Data("anything".utf8)) == false)
}

@Test func acceptsAnyOfSeveralPins() {
    // Two pins let the server rotate its certificate without breaking installed apps.
    let current = Data("current-cert".utf8)
    let next = Data("next-cert".utf8)
    let pinner = CertificatePinner(fingerprints: [
        CertificatePinner.fingerprint(ofDER: current),
        CertificatePinner.fingerprint(ofDER: next),
    ])
    #expect(pinner.accepts(certificateDER: current))
    #expect(pinner.accepts(certificateDER: next))
    #expect(pinner.accepts(certificateDER: Data("rogue".utf8)) == false)
}

@Test func fingerprintIsStableAndSHA256Sized() {
    let der = Data("abc".utf8)
    let once = CertificatePinner.fingerprint(ofDER: der)
    #expect(once == CertificatePinner.fingerprint(ofDER: der))
    #expect(once.count == 64)
    // Known SHA-256 of "abc".
    #expect(once == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
}
