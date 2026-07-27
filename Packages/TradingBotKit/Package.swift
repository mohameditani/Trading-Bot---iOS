// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TradingBotKit",
    // iOS 18 is the app's deployment target. macOS 14 is declared only so `swift test`
    // can build these modules natively for the fast inner loop — SwiftUI, Observation
    // and Charts are all unavailable below it, and the app itself never ships on macOS.
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "BotDomain", targets: ["BotDomain"]),
        .library(name: "BotFormatting", targets: ["BotFormatting"]),
        .library(name: "BotDataKit", targets: ["BotDataKit"]),
        .library(name: "BotDesignSystem", targets: ["BotDesignSystem"]),
    ],
    targets: [
        .target(name: "BotDomain"),
        .target(name: "BotFormatting", dependencies: ["BotDomain"]),
        .target(name: "BotDataKit", dependencies: ["BotDomain"]),
        // No `resources:` yet — an empty resource bundle fails codesign with
        // "bundle format unrecognized". Task 8 adds it alongside the real font files.
        .target(
            name: "BotDesignSystem",
            dependencies: ["BotDomain", "BotFormatting"]
        ),
        .testTarget(name: "BotDomainTests", dependencies: ["BotDomain"]),
        .testTarget(name: "BotFormattingTests", dependencies: ["BotFormatting"]),
        .testTarget(name: "BotDataKitTests", dependencies: ["BotDataKit"]),
        .testTarget(name: "BotDesignSystemTests", dependencies: ["BotDesignSystem"]),
    ]
)
