import Foundation
import CryptoKit
import Security

/// Validates a server's certificate against a fingerprint bundled with the app.
///
/// The dashboard uses a self-signed certificate (`CN=trading-dashboard`), which iOS
/// rejects by default and rightly so. Pinning is the correct answer here rather than
/// an ATS exception: an exception would accept *any* certificate for that host, while
/// pinning accepts exactly one — including refusing a genuine CA-signed certificate
/// presented by an attacker who has taken over the address.
public struct CertificatePinner: Sendable {
    /// Lowercase hex SHA-256 of the DER certificate, colons and spaces optional.
    public let pinnedFingerprints: Set<String>

    public init(fingerprints: [String]) {
        self.pinnedFingerprints = Set(fingerprints.map(Self.normalise))
    }

    /// Accepts the forms `openssl x509 -fingerprint -sha256` prints as well as plain hex.
    public static func normalise(_ fingerprint: String) -> String {
        fingerprint
            .replacingOccurrences(of: "sha256 Fingerprint=", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }

    public static func fingerprint(ofDER der: Data) -> String {
        SHA256.hash(data: der).map { String(format: "%02x", $0) }.joined()
    }

    public func accepts(certificateDER der: Data) -> Bool {
        pinnedFingerprints.contains(Self.fingerprint(ofDER: der))
    }

    /// True when the trust's leaf certificate matches a pinned fingerprint.
    public func accepts(_ trust: SecTrust) -> Bool {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first
        else { return false }
        return accepts(certificateDER: SecCertificateCopyData(leaf) as Data)
    }
}

/// Applies a `CertificatePinner` to a URLSession's TLS challenges.
public final class PinningSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    private let pinner: CertificatePinner

    public init(pinner: CertificatePinner) {
        self.pinner = pinner
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if pinner.accepts(trust) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            // Cancel rather than fall through to default handling: default handling
            // would reject a self-signed cert anyway, but being explicit means a
            // fingerprint mismatch can never be silently downgraded.
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

extension URLSession {
    /// A session that trusts only the pinned certificate.
    public static func pinned(to pinner: CertificatePinner) -> URLSession {
        URLSession(
            configuration: .ephemeral,
            delegate: PinningSessionDelegate(pinner: pinner),
            delegateQueue: nil
        )
    }
}
