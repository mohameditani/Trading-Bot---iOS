import Foundation

struct BundledBotDataProvider: BotDataProvider {
    enum BundledError: Error {
        case missingResource
    }

    func fetchSnapshot() async throws -> BotSnapshot {
        guard let url = Bundle.main.url(forResource: "snapshot", withExtension: "json") else {
            throw BundledError.missingResource
        }
        let data = try Data(contentsOf: url)
        let dto = try JSONDecoder.snapshot.decode(SnapshotDTO.self, from: data)
        return SnapshotMapper.map(dto)
    }
}
