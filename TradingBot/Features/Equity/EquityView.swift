import SwiftUI
import BotDataKit

struct EquityView: View {
    let store: SnapshotStore
    var body: some View {
        Text("Equity").accessibilityIdentifier("screen.equity")
    }
}
