import Foundation

struct RemoteBotDataProvider: BotDataProvider {
    let baseURL: URL
    let client: HTTPClient

    func fetchSnapshot() async throws -> BotSnapshot {
        let url = baseURL.appending(path: "snapshot.json")
        let data = try await client.get(url)
        guard let dto = try? JSONDecoder.snapshot.decode(SnapshotDTO.self, from: data) else {
            throw HTTPError.decoding
        }
        return SnapshotMapper.map(dto)
    }
}
