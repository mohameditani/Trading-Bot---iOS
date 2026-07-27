import Foundation
import BotDomain

/// Stores the last good snapshot so the app has something to show when a load fails.
///
/// An actor because reads and writes race between the polling store and a manual refresh.
public actor SnapshotCache {
    private let directory: URL
    private let fileName = "snapshot-cache.json"

    private var fileURL: URL { directory.appendingPathComponent(fileName) }

    public init(directory: URL) {
        self.directory = directory
    }

    /// Default location in Caches — disposable, and excluded from backup by the system.
    public static func makeDefault() -> SnapshotCache {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("TradingBot", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SnapshotCache(directory: directory)
    }

    /// Validates before storing so a corrupt payload can never become the offline fallback.
    public func write(_ data: Data) throws {
        _ = try SnapshotDecoder.decode(data)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    public func read() throws -> Snapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SnapshotError.noCachedSnapshot
        }
        let data = try Data(contentsOf: fileURL)
        return try SnapshotDecoder.decode(data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
