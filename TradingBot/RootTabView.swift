import SwiftUI
import BotDataKit
import BotDesignSystem
import BotDomain
import BotFormatting

/// Placeholder shell. Replaced with the real tab bar in Task 11.
struct RootTabView: View {
    var body: some View {
        ZStack {
            BotColor.paper.ignoresSafeArea()
            Text("Trading Bot")
                .accessibilityIdentifier("root.placeholder")
        }
    }
}

#Preview {
    RootTabView()
}
