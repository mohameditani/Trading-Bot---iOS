import Foundation

protocol BotDataProvider: Sendable {
    func fetchSnapshot() async throws -> BotSnapshot
}
