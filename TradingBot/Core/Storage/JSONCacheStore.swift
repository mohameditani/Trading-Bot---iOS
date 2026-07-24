import Foundation

actor JSONCacheStore {
    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.fileURL = dir.appending(path: "snapshot-cache.json")
    }

    func load() -> BotSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let dto = try? JSONDecoder.snapshot.decode(SnapshotDTO.self, from: data)
        return dto.map(SnapshotMapper.map)
    }

    func save(_ snapshot: BotSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(SnapshotMapper.dto(from: snapshot)) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}
