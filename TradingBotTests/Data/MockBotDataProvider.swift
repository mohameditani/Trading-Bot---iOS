import Foundation
@testable import TradingBot

final class MockBotDataProvider: BotDataProvider, @unchecked Sendable {
    var result: Result<BotSnapshot, Error>
    var callCount = 0

    init(result: Result<BotSnapshot, Error>) {
        self.result = result
    }

    func fetchSnapshot() async throws -> BotSnapshot {
        callCount += 1
        return try result.get()
    }
}
