import SwiftUI
import BotDataKit

struct TradesView: View {
    let store: SnapshotStore
    var body: some View {
        Text("Trades").accessibilityIdentifier("screen.trades")
    }
}
