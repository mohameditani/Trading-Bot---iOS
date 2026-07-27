import SwiftUI

public struct BotTabItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String

    public init(id: String, title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

/// The app's own tab bar — the design's 9pt uppercase mono labels and gold active tint
/// are not expressible with the system bar.
public struct BotTabBar: View {
    public let items: [BotTabItem]
    @Binding public var selection: String

    public init(items: [BotTabItem], selection: Binding<String>) {
        self.items = items
        self._selection = selection
    }

    func color(for item: BotTabItem) -> Color {
        item.id == selection ? BotColor.accent : BotColor.greyMuted
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    selection = item.id
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 19, weight: .regular))
                        Text(item.title)
                            .font(BotFont.tabLabel)
                            .tracking(0.6)
                    }
                    .foregroundStyle(color(for: item))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(item.id)")
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(item.id == selection ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.top, 9)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
    }
}
