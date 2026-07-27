import Foundation
import Testing
import BotDomain
import BotDataKit

@Test func appTargetCanImportPackageModules() {
    let point = CurvePoint(date: Date(timeIntervalSince1970: 0), equity: 100)
    #expect(point.equity == 100)
    #expect(LoadState<Int>.loaded(1).value == 1)
    #expect(TradeDirection(wire: "short") == .short)
}
