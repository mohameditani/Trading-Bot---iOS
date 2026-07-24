import Foundation
import Testing
@testable import TradingBot

@Suite("HistoryViewModel")
@MainActor
struct HistoryViewModelTests {
    private func makeTrades() -> [Trade] {
        let date = Date(timeIntervalSince1970: 1_752_192_000)
        return [
            Trade(id: "1", closedAt: date, symbol: "BTCUSDT", side: .long, entryPrice: 65071.3, exitPrice: 64857.0, pnl: -2.34),
            Trade(id: "2", closedAt: date, symbol: "SOLUSDT", side: .long, entryPrice: 78.3, exitPrice: 77.1, pnl: -1.72),
            Trade(id: "3", closedAt: date, symbol: "BTCUSDT", side: .long, entryPrice: 63977.9, exitPrice: 65898.5, pnl: 5.6)
        ]
    }

    @Test func showsAllTradesByDefault() {
        let vm = HistoryViewModel()
        vm.update(trades: makeTrades())
        #expect(vm.visibleTrades.count == 3)
    }

    @Test func searchFiltersBySymbol() {
        let vm = HistoryViewModel()
        vm.update(trades: makeTrades())
        vm.searchText = "sol"
        #expect(vm.visibleTrades.count == 1)
        #expect(vm.visibleTrades.first?.symbol == "SOLUSDT")
    }

    @Test func winsFilterKeepsOnlyPositivePnL() {
        let vm = HistoryViewModel()
        vm.update(trades: makeTrades())
        vm.filter = .wins
        #expect(vm.visibleTrades.allSatisfy { $0.pnl > 0 })
        #expect(vm.visibleTrades.count == 1)
    }

    @Test func lossesFilterKeepsOnlyNegativePnL() {
        let vm = HistoryViewModel()
        vm.update(trades: makeTrades())
        vm.filter = .losses
        #expect(vm.visibleTrades.count == 2)
    }

    @Test func searchAndFilterCompose() {
        let vm = HistoryViewModel()
        vm.update(trades: makeTrades())
        vm.searchText = "BTC"
        vm.filter = .losses
        #expect(vm.visibleTrades.count == 1)
        #expect(vm.visibleTrades.first?.id == "1")
    }
}
