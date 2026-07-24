import Foundation
import Testing
@testable import TradingBot

@Suite("SnapshotMapper")
struct SnapshotMapperTests {
    private func loadFixture() throws -> Data {
        let url = try #require(Bundle.main.url(forResource: "snapshot", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test func decodesBundledSnapshot() throws {
        let dto = try JSONDecoder.snapshot.decode(SnapshotDTO.self, from: loadFixture())
        let snapshot = SnapshotMapper.map(dto)
        #expect(snapshot.dashboard.totalEquity == 179.79)
        #expect(snapshot.dashboard.balance == 81.67)
        #expect(snapshot.dashboard.winRate == 0.222)
        #expect(snapshot.dashboard.allTimePnL == -21.70)
        #expect(snapshot.dashboard.openPositionsCount == 1)
        #expect(snapshot.dashboard.totalTrades == 27)
    }

    @Test func mapsPosition() throws {
        let dto = try JSONDecoder.snapshot.decode(SnapshotDTO.self, from: loadFixture())
        let snapshot = SnapshotMapper.map(dto)
        let position = try #require(snapshot.positions.first)
        #expect(position.symbol == "BTCUSDT")
        #expect(position.side == .long)
        #expect(position.entryPrice == 65413.1)
        #expect(position.leverage == 2)
        #expect(position.takeProfit == 67375.5)
        #expect(position.stopLoss == 64431.9)
    }

    @Test func mapsTradesWithResults() throws {
        let dto = try JSONDecoder.snapshot.decode(SnapshotDTO.self, from: loadFixture())
        let snapshot = SnapshotMapper.map(dto)
        #expect(snapshot.trades.count == 3)
        #expect(snapshot.trades.contains { $0.pnl > 0 })
        #expect(snapshot.trades.contains { $0.pnl < 0 })
    }

    @Test func mapsInsightsAndBreakdown() throws {
        let dto = try JSONDecoder.snapshot.decode(SnapshotDTO.self, from: loadFixture())
        let snapshot = SnapshotMapper.map(dto)
        #expect(snapshot.insights.vetoLog.count == 3)
        #expect(snapshot.insights.vetoLog.contains { $0.status == .blocked })
        #expect(snapshot.insights.lessons.count == 2)
        #expect(snapshot.breakdown.bySymbol.count == 2)
        #expect(snapshot.breakdown.byRegime.count == 4)
    }
}
