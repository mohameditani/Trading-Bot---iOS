import SwiftUI
import BotDataKit

struct ReviewView: View {
    let store: SnapshotStore
    var body: some View {
        Text("Review").accessibilityIdentifier("screen.review")
    }
}
