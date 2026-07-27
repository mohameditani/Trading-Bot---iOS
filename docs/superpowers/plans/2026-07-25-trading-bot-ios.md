# Trading Bot for iPhone — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a read-only SwiftUI iPhone companion for a crypto trading bot that renders one JSON snapshot across three tabs (Equity, Trades, Review), matching the editorial design in `docs/superpowers/specs/2026-07-25-trading-bot-ios-design.md`.

**Architecture:** A thin app target holds only `@Observable` MVVM ViewModels and Views. All reusable code lives in a local Swift package `TradingBotKit` with four modules: `BotDomain` (models + pure logic, no dependencies), `BotFormatting`, `BotDataKit` (provider, DTOs, HTTP, cache, polling store), and `BotDesignSystem` (tokens, fonts, components). Views contain no formatting and no business logic — ViewModels expose view-ready values, which is what makes them testable without a UI.

**Tech Stack:** Swift 6.0 (strict concurrency `complete`), SwiftUI, Swift Charts, Observation (`@Observable`), Swift Testing (`@Test`) for units, XCUITest for UI, SwiftPM for the package, Xcode 26.6.

## Global Constraints

Every task's requirements implicitly include this section.

- **Minimum iOS:** 18.0. `IPHONEOS_DEPLOYMENT_TARGET = 18.0` in all targets and `platforms: [.iOS(.v18)]` in `Package.swift`.
- **Swift:** `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`. Build must be warning-free.
- **Read-only app:** never place, modify, or close trades; never write bot configuration. Config suggestions are displayed only.
- **No authentication.** There is no login screen. Do not port one from the archive branch.
- **iPhone portrait only.** No iPad or macOS layouts.
- **All numeric output is `IBM Plex Mono`.** Every figure in every screen.
- **Formatters are pinned** to `Locale(identifier: "en_US_POSIX")` and `TimeZone(identifier: "UTC")`. Never use `.current` for either.
- **No formatting or business logic in a View.** If a View converts a number to a string or picks a colour from a condition, it belongs in a ViewModel or `BotDesignSystem`.
- **Unknown enum values decode to `.unknown`**, never throw. Malformed JSON *does* throw. This distinction is tested.
- **Primary simulator:** `iPhone 17 Pro` (iOS 26.5, UDID `952DA1C4-6173-4398-B7AB-7DA0E4767DFE`). An iOS 18.6 device is created in Task 16 to verify the deployment floor.
- **Reference material:** branch `archive/prior-5tab-build` holds a prior build against an *older 5-tab, login-gated spec*. Read it for reference (`git show archive/prior-5tab-build:<path>`). Do not copy its UI, its login, or its 5-tab structure.

### Canonical build & test commands

```bash
# Package unit tests (fast — prefer this during package work)
cd Packages/TradingBotKit && swift test

# Full app scheme (unit + UI tests)
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' | xcbeautify || true
```

If `xcbeautify` is unavailable, drop the pipe and read raw output.

---

## File Structure

```
Packages/TradingBotKit/
  Package.swift                              4 library products, 4 test targets
  Sources/BotDomain/
    Snapshot.swift                           Snapshot, Summary, CurvePoint
    Trade.swift                              Position, ClosedTrade, TradeDirection, TradeStatus
    Breakdown.swift                          BreakdownGroup + bar normalisation
    Review.swift                             AIReport, VetoLog, VetoRow, Lesson, enums
    TradeFilter.swift                        filter cases + pure `apply(to:)`
    PositionMath.swift                       rail marker, hold duration, confidence
  Sources/BotFormatting/
    BotFormat.swift                          all display formatting, pinned locale/TZ
  Sources/BotDataKit/
    DTO/SnapshotDTO.swift                    wire types (snake_case CodingKeys)
    DTO/SnapshotMapper.swift                 DTO -> BotDomain
    SnapshotProvider.swift                   protocol + errors
    BundledSnapshotProvider.swift            reads a bundled JSON resource
    RemoteSnapshotProvider.swift             HTTP-backed provider
    HTTPClient.swift                         request + retry + error mapping
    SnapshotCache.swift                      disk cache
    SnapshotRepository.swift                 provider + cache orchestration
    SnapshotStore.swift                      @Observable polling state
    LoadState.swift                          idle/loading/loaded/failed
  Sources/BotDesignSystem/
    Tokens/BotColor.swift                    palette
    Tokens/BotFont.swift                     semantic styles + registration
    Tokens/BotSpacing.swift                  spacing/radius scale
    Components/*.swift                       one file per component
    Resources/Fonts/*.ttf                    bundled font files
TradingBot/
  TradingBotApp.swift                        @main, font registration
  AppContainer.swift                         composition root
  RootTabView.swift                          3-tab shell
  Features/Equity/EquityView.swift
  Features/Equity/EquityViewModel.swift
  Features/Trades/TradesView.swift
  Features/Trades/TradesViewModel.swift
  Features/Review/ReviewView.swift
  Features/Review/ReviewViewModel.swift
  Resources/snapshot.json                    design's sample payload
TradingBotTests/                             ViewModel tests
TradingBotUITests/                           XCUITest
```

---

## Task 1: Project scaffold, package skeleton, app shell

**Files:**
- Create: `TradingBot.xcodeproj/project.pbxproj` (restored from archive, then modified)
- Create: `TradingBot.xcodeproj/xcshareddata/xcschemes/TradingBot.xcscheme` (restored from archive)
- Create: `Packages/TradingBotKit/Package.swift`
- Create: `Packages/TradingBotKit/Sources/BotDomain/Snapshot.swift` (placeholder type only)
- Create: `Packages/TradingBotKit/Sources/BotFormatting/BotFormat.swift` (empty enum)
- Create: `Packages/TradingBotKit/Sources/BotDataKit/LoadState.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotColor.swift` (stub)
- Create: `Packages/TradingBotKit/Tests/BotDomainTests/PackageLinkageTests.swift`
- Create: `TradingBot/TradingBotApp.swift`
- Create: `TradingBot/RootTabView.swift`
- Create: `TradingBotTests/AppLinkageTests.swift`
- Create: `TradingBotUITests/LaunchUITests.swift`

**Interfaces:**
- Produces: `TradingBotApp` (`@main`), `RootTabView`, and the four package modules `BotDomain`, `BotFormatting`, `BotDataKit`, `BotDesignSystem`, all importable from the app target. `LoadState<Value>` with cases `idle`, `loading`, `loaded(Value)`, `failed(Error)`.
- The three synchronized folder groups mean **every later task adds `.swift` files under `TradingBot/`, `TradingBotTests/`, or `TradingBotUITests/` with no pbxproj edits.** Package sources need no project edits either.

- [ ] **Step 1: Restore the project files from the archive branch**

```bash
mkdir -p TradingBot.xcodeproj/xcshareddata/xcschemes
git show archive/prior-5tab-build:TradingBot.xcodeproj/project.pbxproj > TradingBot.xcodeproj/project.pbxproj
git show archive/prior-5tab-build:TradingBot.xcodeproj/xcshareddata/xcschemes/TradingBot.xcscheme > TradingBot.xcodeproj/xcshareddata/xcschemes/TradingBot.xcscheme
```

This base already sets `IPHONEOS_DEPLOYMENT_TARGET = 18.0`, `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`, `objectVersion = 77`, and three synchronized folder groups for the app, unit-test, and UI-test targets. Only the package wiring is missing.

- [ ] **Step 2: Register the local package in the project object**

In `TradingBot.xcodeproj/project.pbxproj`, find the `PBXProject` block and the line `mainGroup = AA1000000000000000000001;`. Insert immediately **after** that line:

```
			packageReferences = (
				AA1000000000000000000500 /* XCLocalSwiftPackageReference "Packages/TradingBotKit" */,
			);
```

- [ ] **Step 3: Add the package reference and product dependency sections**

Find the line `/* End PBXNativeTarget section */`. Insert immediately **after** it:

```
/* Begin XCLocalSwiftPackageReference section */
		AA1000000000000000000500 /* XCLocalSwiftPackageReference "Packages/TradingBotKit" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = Packages/TradingBotKit;
		};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		AA1000000000000000000600 /* BotDomain */ = {
			isa = XCSwiftPackageProductDependency;
			productName = BotDomain;
		};
		AA1000000000000000000601 /* BotFormatting */ = {
			isa = XCSwiftPackageProductDependency;
			productName = BotFormatting;
		};
		AA1000000000000000000602 /* BotDataKit */ = {
			isa = XCSwiftPackageProductDependency;
			productName = BotDataKit;
		};
		AA1000000000000000000603 /* BotDesignSystem */ = {
			isa = XCSwiftPackageProductDependency;
			productName = BotDesignSystem;
		};
/* End XCSwiftPackageProductDependency section */
```

- [ ] **Step 4: Attach the products to the app and unit-test targets**

In the `AA1000000000000000000100 /* TradingBot */` native target block, replace:

```
			packageProductDependencies = (
			);
			productName = TradingBot;
```

with:

```
			packageProductDependencies = (
				AA1000000000000000000600 /* BotDomain */,
				AA1000000000000000000601 /* BotFormatting */,
				AA1000000000000000000602 /* BotDataKit */,
				AA1000000000000000000603 /* BotDesignSystem */,
			);
			productName = TradingBot;
```

In the `AA1000000000000000000101 /* TradingBotTests */` block, replace:

```
			packageProductDependencies = (
			);
			productName = TradingBotTests;
```

with:

```
			packageProductDependencies = (
				AA1000000000000000000600 /* BotDomain */,
				AA1000000000000000000601 /* BotFormatting */,
				AA1000000000000000000602 /* BotDataKit */,
				AA1000000000000000000603 /* BotDesignSystem */,
			);
			productName = TradingBotTests;
```

Leave the UI-test target's `packageProductDependencies` empty — UI tests drive the app through XCUIElement queries and must not import app or package code.

- [ ] **Step 5: Link the products into the app's Frameworks phase**

Find `/* Begin PBXBuildFile section */`. Insert immediately after it:

```
		AA1000000000000000000700 /* BotDomain in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000600 /* BotDomain */; };
		AA1000000000000000000701 /* BotFormatting in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000601 /* BotFormatting */; };
		AA1000000000000000000702 /* BotDataKit in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000602 /* BotDataKit */; };
		AA1000000000000000000703 /* BotDesignSystem in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000603 /* BotDesignSystem */; };
```

If there is no `PBXBuildFile` section in the file, create one immediately after the line `objects = {`:

```
/* Begin PBXBuildFile section */
		AA1000000000000000000700 /* BotDomain in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000600 /* BotDomain */; };
		AA1000000000000000000701 /* BotFormatting in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000601 /* BotFormatting */; };
		AA1000000000000000000702 /* BotDataKit in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000602 /* BotDataKit */; };
		AA1000000000000000000703 /* BotDesignSystem in Frameworks */ = {isa = PBXBuildFile; productRef = AA1000000000000000000603 /* BotDesignSystem */; };
/* End PBXBuildFile section */
```

Then in the app's Frameworks phase `AA1000000000000000000020`, replace:

```
		AA1000000000000000000020 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
```

with:

```
		AA1000000000000000000020 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA1000000000000000000700 /* BotDomain in Frameworks */,
				AA1000000000000000000701 /* BotFormatting in Frameworks */,
				AA1000000000000000000702 /* BotDataKit in Frameworks */,
				AA1000000000000000000703 /* BotDesignSystem in Frameworks */,
			);
```

- [ ] **Step 6: Write `Package.swift`**

Create `Packages/TradingBotKit/Package.swift`:

```swift
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
```

`BotDomain` deliberately declares no dependencies — that is what keeps its logic tests instant.

- [ ] **Step 7: Create the placeholder sources so every target compiles**

`Packages/TradingBotKit/Sources/BotDomain/Snapshot.swift`:

```swift
import Foundation

/// Marker for package linkage; replaced with the real model in Task 2.
public enum BotDomainInfo {
    public static let moduleName = "BotDomain"
}
```

`Packages/TradingBotKit/Sources/BotFormatting/BotFormat.swift`:

```swift
import Foundation

/// Namespace for all display formatting. Populated in Task 3.
public enum BotFormat {}
```

`Packages/TradingBotKit/Sources/BotDataKit/LoadState.swift`:

```swift
import Foundation

/// The state of an asynchronous load, shared by every screen.
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(any Error)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var error: (any Error)? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
```

`Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotColor.swift`:

```swift
import SwiftUI

/// Design palette. Populated in Task 8.
public enum BotColor {
    public static let paper = Color(red: 0.980, green: 0.976, blue: 0.965)
}
```

Do **not** create a `Resources` directory yet. SwiftPM builds a resource bundle for any target declaring `resources:`, and an empty one fails codesign with `bundle format unrecognized, invalid, or unsuitable`. Task 8 creates the directory, adds the fonts, and declares the resources together.

- [ ] **Step 8: Write the package linkage test**

`Packages/TradingBotKit/Tests/BotDomainTests/PackageLinkageTests.swift`:

```swift
import Testing
@testable import BotDomain

@Test func moduleIsLinkable() {
    #expect(BotDomainInfo.moduleName == "BotDomain")
}
```

Create the three other test directories with a trivial test each so all four test targets resolve:

`Packages/TradingBotKit/Tests/BotFormattingTests/BotFormattingLinkageTests.swift`:

```swift
import Testing
@testable import BotFormatting

@Test func formattingModuleIsLinkable() {
    #expect(String(describing: BotFormat.self) == "BotFormat")
}
```

`Packages/TradingBotKit/Tests/BotDataKitTests/LoadStateTests.swift`:

```swift
import Testing
@testable import BotDataKit

@Test func loadedStateExposesItsValue() {
    let state = LoadState<Int>.loaded(7)
    #expect(state.value == 7)
    #expect(state.isLoading == false)
}

@Test func loadingStateHasNoValue() {
    let state = LoadState<Int>.loading
    #expect(state.value == nil)
    #expect(state.isLoading)
}
```

`Packages/TradingBotKit/Tests/BotDesignSystemTests/BotColorTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BotDesignSystem

@Test func paperTokenExists() {
    #expect(BotColor.paper != Color.clear)
}
```

- [ ] **Step 9: Run the package tests**

```bash
cd Packages/TradingBotKit && swift test
```

Expected: all four test targets build and pass (6 tests).

- [ ] **Step 10: Write the app shell**

`TradingBot/TradingBotApp.swift`:

```swift
import SwiftUI

@main
struct TradingBotApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
```

`TradingBot/RootTabView.swift`:

```swift
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
            Text(BotDomainInfo.moduleName)
                .accessibilityIdentifier("root.placeholder")
        }
    }
}

#Preview {
    RootTabView()
}
```

- [ ] **Step 11: Write the app-target linkage test**

`TradingBotTests/AppLinkageTests.swift`:

```swift
import Testing
import BotDomain
import BotDataKit

@Test func appTargetCanImportPackageModules() {
    #expect(BotDomainInfo.moduleName == "BotDomain")
    #expect(LoadState<Int>.loaded(1).value == 1)
}
```

- [ ] **Step 12: Write the launch UI test**

`TradingBotUITests/LaunchUITests.swift`:

```swift
import XCTest

final class LaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(
            app.otherElements["root.placeholder"].waitForExistence(timeout: 10)
                || app.staticTexts["root.placeholder"].waitForExistence(timeout: 10)
        )
    }
}
```

- [ ] **Step 13: Build and test the full scheme**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: **BUILD SUCCEEDED** and **TEST SUCCEEDED**. If the package fails to resolve, run `xcodebuild -resolvePackageDependencies -project TradingBot.xcodeproj -scheme TradingBot` and retry.

- [ ] **Step 14: Commit**

```bash
git add Packages TradingBot TradingBot.xcodeproj TradingBotTests TradingBotUITests
git commit -m "feat: Xcode project, TradingBotKit package with four modules, app shell"
```

---

## Task 2: BotDomain — models and pure logic

**Files:**
- Modify: `Packages/TradingBotKit/Sources/BotDomain/Snapshot.swift`
- Create: `Packages/TradingBotKit/Sources/BotDomain/Trade.swift`
- Create: `Packages/TradingBotKit/Sources/BotDomain/Breakdown.swift`
- Create: `Packages/TradingBotKit/Sources/BotDomain/Review.swift`
- Create: `Packages/TradingBotKit/Sources/BotDomain/TradeFilter.swift`
- Create: `Packages/TradingBotKit/Sources/BotDomain/PositionMath.swift`
- Test: `Packages/TradingBotKit/Tests/BotDomainTests/PositionMathTests.swift`
- Test: `Packages/TradingBotKit/Tests/BotDomainTests/BreakdownTests.swift`
- Test: `Packages/TradingBotKit/Tests/BotDomainTests/TradeFilterTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `Snapshot`, `Summary`, `CurvePoint`, `Position`, `ClosedTrade`, `TradeDirection`, `TradeStatus`, `BreakdownGroup`, `AIReport`, `ConfigSuggestion`, `VetoLog`, `VetoRow`, `VetoSignal`, `VetoOutcome`, `Lesson`, `TradeFilter`, `PnLSign`. Key computed members later tasks rely on: `Position.railProgress -> Double`, `ClosedTrade.holdDuration -> TimeInterval`, `ClosedTrade.confidenceFraction -> Double`, `BreakdownGroup.barFraction(relativeTo:) -> Double`, `[BreakdownGroup].maxAbsoluteNet -> Double`, `TradeFilter.apply(to:) -> [ClosedTrade]`, `PnLSign.of(_:) -> PnLSign`.

- [ ] **Step 1: Write the failing tests for position maths**

`Packages/TradingBotKit/Tests/BotDomainTests/PositionMathTests.swift`:

```swift
import Foundation
import Testing
@testable import BotDomain

private func makePosition(
    entry: Double,
    takeProfit: Double,
    stopLoss: Double,
    direction: TradeDirection = .short
) -> Position {
    Position(
        pair: "SOLUSDT",
        direction: direction,
        entryPrice: entry,
        quantity: 0.8,
        leverage: 2,
        margin: 29.24,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
        openedAt: Date(timeIntervalSince1970: 0),
        exchangeStops: true
    )
}

@Test func railProgressMatchesTheDesignSamplePosition() {
    // TP 70.91, entry 73.10, SL 74.20 -> |73.10-70.91| / |74.20-70.91| = 0.6657
    let position = makePosition(entry: 73.10, takeProfit: 70.91, stopLoss: 74.20)
    #expect(abs(position.railProgress - 0.6657) < 0.001)
}

@Test func railProgressWorksForALongPosition() {
    // TP 80, entry 75, SL 73 -> |75-80| / |73-80| = 0.7142
    let position = makePosition(entry: 75, takeProfit: 80, stopLoss: 73, direction: .long)
    #expect(abs(position.railProgress - 0.7142) < 0.001)
}

@Test func railProgressIsZeroAtTakeProfit() {
    let position = makePosition(entry: 70.91, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 0)
}

@Test func railProgressIsOneAtStopLoss() {
    let position = makePosition(entry: 74.20, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 1)
}

@Test func railProgressClampsBeyondTheStopLoss() {
    let position = makePosition(entry: 99, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 1)
}

@Test func railProgressClampsBelowTheTakeProfit() {
    let position = makePosition(entry: 10, takeProfit: 70.91, stopLoss: 74.20)
    #expect(position.railProgress == 0)
}

@Test func railProgressCentresWhenStopEqualsTarget() {
    let position = makePosition(entry: 73.10, takeProfit: 72, stopLoss: 72)
    #expect(position.railProgress == 0.5)
}

@Test func holdDurationIsTheClosedMinusOpenedInterval() {
    let trade = ClosedTrade(
        closedAt: Date(timeIntervalSince1970: 4_920),
        openedAt: Date(timeIntervalSince1970: 0),
        pair: "SOLUSDT",
        direction: .short,
        entryPrice: 72.95,
        exitPrice: 71.85,
        quantity: 1.2,
        pnl: -1.99,
        status: .stopLoss,
        regime: "ranging",
        confidence: 7
    )
    #expect(trade.holdDuration == 4_920)          // 1h 22m
    #expect(abs(trade.confidenceFraction - 0.7) < 0.0001)
}

@Test func confidenceFractionClampsToUnitRange() {
    func trade(confidence: Int) -> ClosedTrade {
        ClosedTrade(
            closedAt: Date(timeIntervalSince1970: 60),
            openedAt: Date(timeIntervalSince1970: 0),
            pair: "BTCUSDT", direction: .long, entryPrice: 1, exitPrice: 2,
            quantity: 1, pnl: 1, status: .takeProfit, regime: "trending_up",
            confidence: confidence
        )
    }
    #expect(trade(confidence: 0).confidenceFraction == 0)
    #expect(trade(confidence: 10).confidenceFraction == 1)
    #expect(trade(confidence: 15).confidenceFraction == 1)
    #expect(trade(confidence: -3).confidenceFraction == 0)
}

@Test func pnlSignBuckets() {
    #expect(PnLSign.of(1.5) == .positive)
    #expect(PnLSign.of(-1.5) == .negative)
    #expect(PnLSign.of(0) == .flat)
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd Packages/TradingBotKit && swift test --filter BotDomainTests
```

Expected: FAIL — `cannot find 'Position' in scope`, `cannot find 'ClosedTrade' in scope`, `cannot find 'PnLSign' in scope`.

- [ ] **Step 3: Write the trade models**

Replace `Packages/TradingBotKit/Sources/BotDomain/Snapshot.swift` entirely:

```swift
import Foundation

/// One complete read of bot state. The app renders exactly this and nothing else.
public struct Snapshot: Equatable, Sendable {
    public let generatedAt: Date
    public let summary: Summary
    public let curve: [CurvePoint]
    public let openPositions: [Position]
    public let closedTrades: [ClosedTrade]
    public let bySymbol: [BreakdownGroup]
    public let byRegime: [BreakdownGroup]
    /// Nil when the AI review layer is disabled — this is what drives the "AI null" screen.
    public let aiReport: AIReport?
    public let veto: VetoLog?
    public let lessons: [Lesson]

    public init(
        generatedAt: Date,
        summary: Summary,
        curve: [CurvePoint],
        openPositions: [Position],
        closedTrades: [ClosedTrade],
        bySymbol: [BreakdownGroup],
        byRegime: [BreakdownGroup],
        aiReport: AIReport?,
        veto: VetoLog?,
        lessons: [Lesson]
    ) {
        self.generatedAt = generatedAt
        self.summary = summary
        self.curve = curve
        self.openPositions = openPositions
        self.closedTrades = closedTrades
        self.bySymbol = bySymbol
        self.byRegime = byRegime
        self.aiReport = aiReport
        self.veto = veto
        self.lessons = lessons
    }

    /// True when the review layer has nothing to show.
    public var hasReviewLayer: Bool { aiReport != nil }
}

public struct Summary: Equatable, Sendable {
    public let balance: Double
    public let equity: Double
    public let open: Int
    public let total: Int
    public let wins: Int
    public let losses: Int
    public let winRate: Double
    public let totalPnl: Double
    public let todayTotal: Int
    public let todayWins: Int
    public let todayLosses: Int
    public let todayPnl: Double

    public init(
        balance: Double, equity: Double, open: Int, total: Int, wins: Int, losses: Int,
        winRate: Double, totalPnl: Double, todayTotal: Int, todayWins: Int,
        todayLosses: Int, todayPnl: Double
    ) {
        self.balance = balance
        self.equity = equity
        self.open = open
        self.total = total
        self.wins = wins
        self.losses = losses
        self.winRate = winRate
        self.totalPnl = totalPnl
        self.todayTotal = todayTotal
        self.todayWins = todayWins
        self.todayLosses = todayLosses
        self.todayPnl = todayPnl
    }
}

public struct CurvePoint: Equatable, Sendable, Identifiable {
    public let date: Date
    public let equity: Double
    public var id: Date { date }

    public init(date: Date, equity: Double) {
        self.date = date
        self.equity = equity
    }
}
```

`Packages/TradingBotKit/Sources/BotDomain/Trade.swift`:

```swift
import Foundation

public enum TradeDirection: String, Equatable, Sendable, CaseIterable {
    case long
    case short
    case unknown

    /// Decodes tolerantly — an unrecognised direction must not break the whole snapshot.
    public init(wire: String) {
        self = TradeDirection(rawValue: wire.lowercased()) ?? .unknown
    }
}

public enum TradeStatus: String, Equatable, Sendable {
    case takeProfit
    case stopLoss
    case unknown

    public init(wire: String) {
        switch wire.lowercased() {
        case "closed_tp": self = .takeProfit
        case "closed_sl": self = .stopLoss
        default: self = .unknown
        }
    }
}

public enum PnLSign: Equatable, Sendable {
    case positive, negative, flat

    public static func of(_ value: Double) -> PnLSign {
        if value > 0 { return .positive }
        if value < 0 { return .negative }
        return .flat
    }
}

public struct Position: Equatable, Sendable, Identifiable {
    public let pair: String
    public let direction: TradeDirection
    public let entryPrice: Double
    public let quantity: Double
    public let leverage: Int
    public let margin: Double
    public let takeProfit: Double
    public let stopLoss: Double
    public let openedAt: Date
    public let exchangeStops: Bool

    public var id: String { "\(pair)-\(openedAt.timeIntervalSince1970)" }

    public init(
        pair: String, direction: TradeDirection, entryPrice: Double, quantity: Double,
        leverage: Int, margin: Double, takeProfit: Double, stopLoss: Double,
        openedAt: Date, exchangeStops: Bool
    ) {
        self.pair = pair
        self.direction = direction
        self.entryPrice = entryPrice
        self.quantity = quantity
        self.leverage = leverage
        self.margin = margin
        self.takeProfit = takeProfit
        self.stopLoss = stopLoss
        self.openedAt = openedAt
        self.exchangeStops = exchangeStops
    }
}

public struct ClosedTrade: Equatable, Sendable, Identifiable {
    public let closedAt: Date
    public let openedAt: Date
    public let pair: String
    public let direction: TradeDirection
    public let entryPrice: Double
    public let exitPrice: Double
    public let quantity: Double
    public let pnl: Double
    public let status: TradeStatus
    public let regime: String
    public let confidence: Int

    public var id: String { "\(pair)-\(closedAt.timeIntervalSince1970)" }

    public init(
        closedAt: Date, openedAt: Date, pair: String, direction: TradeDirection,
        entryPrice: Double, exitPrice: Double, quantity: Double, pnl: Double,
        status: TradeStatus, regime: String, confidence: Int
    ) {
        self.closedAt = closedAt
        self.openedAt = openedAt
        self.pair = pair
        self.direction = direction
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.quantity = quantity
        self.pnl = pnl
        self.status = status
        self.regime = regime
        self.confidence = confidence
    }

    /// The regime with underscores replaced by spaces, as the design renders it.
    public var regimeDisplay: String { regime.replacingOccurrences(of: "_", with: " ") }
}
```

- [ ] **Step 4: Write the position maths**

`Packages/TradingBotKit/Sources/BotDomain/PositionMath.swift`:

```swift
import Foundation

extension Position {
    /// Where the entry sits on the take-profit -> stop-loss rail, 0...1.
    ///
    /// The rail always runs take-profit (left, green) to stop-loss (right, red)
    /// regardless of direction, so one formula covers both long and short.
    /// The design hardcodes 64%; this computes it so every position renders truthfully.
    ///
    /// The ratio is signed, not absolute: for a short the span is positive and for a
    /// long it is negative, and dividing by it normalises both to the same 0...1 axis.
    /// Taking `abs` of the numerator instead would place an entry *beyond* take-profit —
    /// a deeply winning position — at the stop-loss end of the rail.
    public var railProgress: Double {
        let span = stopLoss - takeProfit
        guard span != 0 else { return 0.5 }
        return min(max((entryPrice - takeProfit) / span, 0), 1)
    }
}

extension ClosedTrade {
    /// How long the position was held.
    public var holdDuration: TimeInterval {
        closedAt.timeIntervalSince(openedAt)
    }

    /// Confidence expressed as a 0...1 bar width. The wire scale is 0...10.
    public var confidenceFraction: Double {
        min(max(Double(confidence) / 10, 0), 1)
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
cd Packages/TradingBotKit && swift test --filter BotDomainTests
```

Expected: PASS (the linkage test plus 10 new tests).

- [ ] **Step 6: Write the failing breakdown tests**

`Packages/TradingBotKit/Tests/BotDomainTests/BreakdownTests.swift`:

```swift
import Testing
@testable import BotDomain

private func group(_ key: String, _ net: Double, winRate: Double = 50) -> BreakdownGroup {
    BreakdownGroup(key: key, trades: 10, winRate: winRate, netPnl: net)
}

@Test func barFractionNormalisesAgainstTheLargestAbsoluteNet() {
    // by_symbol from the design: BTC +6.10, SOL -18.84 -> max abs 18.84
    let groups = [group("BTCUSDT", 6.10), group("SOLUSDT", -18.84)]
    let max = groups.maxAbsoluteNet
    #expect(max == 18.84)
    #expect(abs(groups[0].barFraction(relativeTo: max) - 0.3237) < 0.001)
    #expect(groups[1].barFraction(relativeTo: max) == 1)
}

@Test func barFractionUsesMagnitudeSoLossesRenderFullWidth() {
    let groups = [group("a", -22.99), group("b", 8.20), group("c", 2.05)]
    #expect(groups.maxAbsoluteNet == 22.99)
    #expect(groups[0].barFraction(relativeTo: groups.maxAbsoluteNet) == 1)
}

@Test func barFractionIsZeroWhenEveryNetIsZero() {
    let groups = [group("a", 0), group("b", 0)]
    #expect(groups.maxAbsoluteNet == 0)
    #expect(groups[0].barFraction(relativeTo: 0) == 0)
}

@Test func maxAbsoluteNetOfAnEmptyListIsZero() {
    #expect([BreakdownGroup]().maxAbsoluteNet == 0)
}

@Test func singleGroupAlwaysFillsTheBar() {
    let groups = [group("only", -3.2)]
    #expect(groups[0].barFraction(relativeTo: groups.maxAbsoluteNet) == 1)
}

@Test func winRateTierBuckets() {
    #expect(group("a", 1, winRate: 66.7).winRateTier == .strong)
    #expect(group("a", 1, winRate: 50).winRateTier == .strong)
    #expect(group("a", 1, winRate: 44.4).winRateTier == .neutral)
    #expect(group("a", 1, winRate: 33).winRateTier == .neutral)
    #expect(group("a", 1, winRate: 28.6).winRateTier == .weak)
}

@Test func keyDisplayReplacesUnderscores() {
    #expect(group("trending_up", 1).keyDisplay == "trending up")
}
```

- [ ] **Step 7: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter BreakdownTests
```

Expected: FAIL — `cannot find 'BreakdownGroup' in scope`.

- [ ] **Step 8: Write the breakdown model**

`Packages/TradingBotKit/Sources/BotDomain/Breakdown.swift`:

```swift
import Foundation

/// Win-rate colour tiers from the design: >=50% green, >=33% grey, below that red.
public enum WinRateTier: Equatable, Sendable {
    case strong, neutral, weak
}

public struct BreakdownGroup: Equatable, Sendable, Identifiable {
    public let key: String
    public let trades: Int
    public let winRate: Double
    public let netPnl: Double

    public var id: String { key }

    public init(key: String, trades: Int, winRate: Double, netPnl: Double) {
        self.key = key
        self.trades = trades
        self.winRate = winRate
        self.netPnl = netPnl
    }

    public var keyDisplay: String { key.replacingOccurrences(of: "_", with: " ") }

    public var winRateTier: WinRateTier {
        if winRate >= 50 { return .strong }
        if winRate >= 33 { return .neutral }
        return .weak
    }

    /// Bar width 0...1, normalised against the largest magnitude in the group set so
    /// a heavy loss reads as full-width just as a heavy gain does.
    public func barFraction(relativeTo maxAbsolute: Double) -> Double {
        guard maxAbsolute > 0 else { return 0 }
        return min(max(abs(netPnl) / maxAbsolute, 0), 1)
    }
}

extension Array where Element == BreakdownGroup {
    public var maxAbsoluteNet: Double {
        reduce(0) { Swift.max($0, Swift.abs($1.netPnl)) }
    }
}
```

- [ ] **Step 9: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter BreakdownTests
```

Expected: PASS (7 tests).

- [ ] **Step 10: Write the failing filter tests**

`Packages/TradingBotKit/Tests/BotDomainTests/TradeFilterTests.swift`:

```swift
import Foundation
import Testing
@testable import BotDomain

private func trade(
    _ pair: String,
    pnl: Double,
    closedAtOffset: TimeInterval
) -> ClosedTrade {
    ClosedTrade(
        closedAt: Date(timeIntervalSince1970: closedAtOffset),
        openedAt: Date(timeIntervalSince1970: 0),
        pair: pair,
        direction: .short,
        entryPrice: 1, exitPrice: 2, quantity: 1,
        pnl: pnl,
        status: pnl >= 0 ? .takeProfit : .stopLoss,
        regime: "ranging",
        confidence: 5
    )
}

private let sample = [
    trade("SOLUSDT", pnl: -1.99, closedAtOffset: 300),
    trade("BTCUSDT", pnl: 1.76, closedAtOffset: 200),
    trade("SOLUSDT", pnl: -1.28, closedAtOffset: 100),
]

@Test func allFilterKeepsEveryTrade() {
    #expect(TradeFilter.all.apply(to: sample).count == 3)
}

@Test func symbolFilterMatchesOnPrefix() {
    #expect(TradeFilter.symbol("SOL").apply(to: sample).count == 2)
    #expect(TradeFilter.symbol("BTC").apply(to: sample).count == 1)
}

@Test func symbolFilterIsCaseInsensitive() {
    #expect(TradeFilter.symbol("sol").apply(to: sample).count == 2)
}

@Test func lossesFilterKeepsOnlyNegativePnl() {
    let losses = TradeFilter.losses.apply(to: sample)
    #expect(losses.count == 2)
    #expect(losses.allSatisfy { $0.pnl < 0 })
}

@Test func lossesFilterExcludesBreakEven() {
    let trades = [trade("SOLUSDT", pnl: 0, closedAtOffset: 10)]
    #expect(TradeFilter.losses.apply(to: trades).isEmpty)
}

@Test func filterPreservesInputOrder() {
    let result = TradeFilter.symbol("SOL").apply(to: sample)
    #expect(result.map(\.closedAt) == [
        Date(timeIntervalSince1970: 300),
        Date(timeIntervalSince1970: 100),
    ])
}

@Test func sortedByCloseDateDescendingPutsNewestFirst() {
    let sorted = sample.sortedByCloseDateDescending()
    #expect(sorted.map(\.closedAt) == [
        Date(timeIntervalSince1970: 300),
        Date(timeIntervalSince1970: 200),
        Date(timeIntervalSince1970: 100),
    ])
}

@Test func filterTitlesMatchTheDesign() {
    #expect(TradeFilter.all.title(totalCount: 28) == "All 28")
    #expect(TradeFilter.symbol("BTC").title(totalCount: 28) == "BTC")
    #expect(TradeFilter.losses.title(totalCount: 28) == "Losses")
}
```

- [ ] **Step 11: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter TradeFilterTests
```

Expected: FAIL — `cannot find 'TradeFilter' in scope`.

- [ ] **Step 12: Write the filter**

`Packages/TradingBotKit/Sources/BotDomain/TradeFilter.swift`:

```swift
import Foundation

/// The chip row on the Trades screen. Pure — no state, no side effects.
public enum TradeFilter: Equatable, Sendable, Hashable {
    case all
    case symbol(String)
    case losses

    public func apply(to trades: [ClosedTrade]) -> [ClosedTrade] {
        switch self {
        case .all:
            return trades
        case .symbol(let prefix):
            let needle = prefix.lowercased()
            return trades.filter { $0.pair.lowercased().hasPrefix(needle) }
        case .losses:
            return trades.filter { $0.pnl < 0 }
        }
    }

    /// The chip label. Only `.all` shows a count, matching the design's "All 28".
    public func title(totalCount: Int) -> String {
        switch self {
        case .all: return "All \(totalCount)"
        case .symbol(let symbol): return symbol
        case .losses: return "Losses"
        }
    }
}

extension Array where Element == ClosedTrade {
    /// Newest close first, as every trade list in the design is ordered.
    public func sortedByCloseDateDescending() -> [ClosedTrade] {
        sorted { $0.closedAt > $1.closedAt }
    }
}
```

- [ ] **Step 13: Write the review models**

`Packages/TradingBotKit/Sources/BotDomain/Review.swift`:

```swift
import Foundation

public struct ConfigSuggestion: Equatable, Sendable, Identifiable {
    public let param: String
    public let current: String
    public let suggested: String
    public let rationale: String

    public var id: String { param }

    public init(param: String, current: String, suggested: String, rationale: String) {
        self.param = param
        self.current = current
        self.suggested = suggested
        self.rationale = rationale
    }
}

public struct AIReport: Equatable, Sendable {
    public let date: String
    public let narrative: String
    public let whatsWorking: [String]
    public let whatsLosing: [String]
    public let configSuggestions: [ConfigSuggestion]

    public init(
        date: String, narrative: String, whatsWorking: [String],
        whatsLosing: [String], configSuggestions: [ConfigSuggestion]
    ) {
        self.date = date
        self.narrative = narrative
        self.whatsWorking = whatsWorking
        self.whatsLosing = whatsLosing
        self.configSuggestions = configSuggestions
    }
}

public enum VetoSignal: String, Equatable, Sendable {
    case buy = "BUY"
    case sell = "SELL"
    case unknown

    public init(wire: String) {
        self = VetoSignal(rawValue: wire.uppercased()) ?? .unknown
    }
}

public enum VetoOutcome: String, Equatable, Sendable {
    case win
    case loss

    public init?(wire: String?) {
        guard let wire, let value = VetoOutcome(rawValue: wire.lowercased()) else { return nil }
        self = value
    }
}

public struct VetoRow: Equatable, Sendable, Identifiable {
    public let timestamp: Date
    public let symbol: String
    public let signal: VetoSignal
    public let proceed: Bool
    public let reason: String
    public let riskFlags: [String]
    public let newsFlag: Bool
    public let outcome: VetoOutcome?

    public var id: String { "\(symbol)-\(timestamp.timeIntervalSince1970)" }

    public init(
        timestamp: Date, symbol: String, signal: VetoSignal, proceed: Bool,
        reason: String, riskFlags: [String], newsFlag: Bool, outcome: VetoOutcome?
    ) {
        self.timestamp = timestamp
        self.symbol = symbol
        self.signal = signal
        self.proceed = proceed
        self.reason = reason
        self.riskFlags = riskFlags
        self.newsFlag = newsFlag
        self.outcome = outcome
    }

    /// Risk flags plus a synthetic "news" chip, exactly as the design composes them.
    public var displayFlags: [String] {
        riskFlags + (newsFlag ? ["news"] : [])
    }

    public var outcomeLabel: String { outcome?.rawValue ?? "no outcome" }
    public var decisionLabel: String { proceed ? "proceed" : "block" }
}

public struct VetoLog: Equatable, Sendable {
    public let proceed: Int
    public let block: Int
    public let scored: Int
    public let proceedWinRate: Double
    public let rows: [VetoRow]

    public init(proceed: Int, block: Int, scored: Int, proceedWinRate: Double, rows: [VetoRow]) {
        self.proceed = proceed
        self.block = block
        self.scored = scored
        self.proceedWinRate = proceedWinRate
        self.rows = rows
    }
}

public struct Lesson: Equatable, Sendable, Identifiable {
    public let timestamp: Date
    public let pair: String
    public let outcome: TradeStatus
    public let lesson: String
    public let failurePattern: String
    public let confidence: String
    public let tags: [String]

    public var id: String { "\(pair)-\(timestamp.timeIntervalSince1970)" }

    public init(
        timestamp: Date, pair: String, outcome: TradeStatus, lesson: String,
        failurePattern: String, confidence: String, tags: [String]
    ) {
        self.timestamp = timestamp
        self.pair = pair
        self.outcome = outcome
        self.lesson = lesson
        self.failurePattern = failurePattern
        self.confidence = confidence
        self.tags = tags
    }
}
```

- [ ] **Step 14: Run the whole domain suite**

```bash
cd Packages/TradingBotKit && swift test --filter BotDomainTests
```

Expected: PASS (26 tests).

- [ ] **Step 15: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: BotDomain models, rail maths, breakdown normalisation, trade filters"
```

---

## Task 3: BotFormatting — pinned display formatting

**Files:**
- Modify: `Packages/TradingBotKit/Sources/BotFormatting/BotFormat.swift`
- Test: `Packages/TradingBotKit/Tests/BotFormattingTests/BotFormatTests.swift`
- Delete: `Packages/TradingBotKit/Tests/BotFormattingTests/BotFormattingLinkageTests.swift`

**Interfaces:**
- Consumes: `BotDomain` (`ClosedTrade`, `Position`).
- Produces: `BotFormat.currency(_:) -> String`, `.signedCurrency(_:) -> String`, `.price(_:) -> String`, `.percent(_:) -> String`, `.day(_:) -> String`, `.stamp(_:) -> String`, `.duration(_:) -> String`, `.freshness(seconds:) -> String`, `.quantity(_:) -> String`, `.leverage(_:) -> String`.

- [ ] **Step 1: Write the failing tests**

`Packages/TradingBotKit/Tests/BotFormattingTests/BotFormatTests.swift`:

```swift
import Foundation
import Testing
@testable import BotFormatting

// Every expectation below is a literal from the design mockup.

@Test func currencyMatchesTheDesign() {
    #expect(BotFormat.currency(87.26) == "$87.26")
    #expect(BotFormat.currency(116.40) == "$116.40")
    #expect(BotFormat.currency(29.24) == "$29.24")
    #expect(BotFormat.currency(0) == "$0.00")
}

@Test func currencyRendersNegativesWithALeadingMinus() {
    #expect(BotFormat.currency(-5.5) == "-$5.50")
}

@Test func signedCurrencyAlwaysCarriesItsSign() {
    #expect(BotFormat.signedCurrency(1.76) == "+$1.76")
    #expect(BotFormat.signedCurrency(-12.74) == "-$12.74")
    #expect(BotFormat.signedCurrency(-2.22) == "-$2.22")
}

@Test func signedCurrencyOfZeroHasNoSign() {
    #expect(BotFormat.signedCurrency(0) == "$0.00")
}

@Test func signedCurrencyOfNilIsAnEmDash() {
    #expect(BotFormat.signedCurrency(nil) == "—")
}

@Test func priceDropsDecimalsAtOrAboveOneThousand() {
    #expect(BotFormat.price(58800.0) == "58,800")
    #expect(BotFormat.price(58288.8) == "58,289")
    #expect(BotFormat.price(1000) == "1,000")
}

@Test func priceKeepsTwoDecimalsBelowOneThousand() {
    #expect(BotFormat.price(73.10) == "73.10")
    #expect(BotFormat.price(999.99) == "999.99")
    #expect(BotFormat.price(70.91) == "70.91")
}

@Test func priceOfNilIsAnEmDash() {
    #expect(BotFormat.price(nil) == "—")
}

@Test func percentKeepsOneDecimal() {
    #expect(BotFormat.percent(39.3) == "39.3%")
    #expect(BotFormat.percent(41.7) == "41.7%")
    #expect(BotFormat.percent(50) == "50.0%")
    #expect(BotFormat.percent(28.6) == "28.6%")
}

@Test func dayIsMonthAndDayInUTC() {
    // 2026-06-20T00:00:00Z
    #expect(BotFormat.day(Date(timeIntervalSince1970: 1_781_913_600)) == "Jun 20")
}

@Test func stampIsMonthDayAndUTCClockTime() {
    // 2026-06-30T14:31:00Z
    #expect(BotFormat.stamp(Date(timeIntervalSince1970: 1_782_829_860)) == "Jun 30 14:31")
}

@Test func stampDoesNotShiftWithTheHostTimeZone() {
    // Same instant must render identically no matter where the machine is.
    let instant = Date(timeIntervalSince1970: 1_782_829_860)
    #expect(BotFormat.stamp(instant) == "Jun 30 14:31")
    #expect(BotFormat.stamp(instant).hasPrefix("Jun 30"))
}

@Test func durationUnderAnHourIsMinutesOnly() {
    #expect(BotFormat.duration(45 * 60) == "45m")
    #expect(BotFormat.duration(59 * 60) == "59m")
    #expect(BotFormat.duration(0) == "0m")
}

@Test func durationOverAnHourCombinesHoursAndMinutes() {
    #expect(BotFormat.duration(4_920) == "1h 22m")
    #expect(BotFormat.duration(2 * 3_600 + 5 * 60) == "2h 5m")
}

@Test func durationOnAnExactHourOmitsMinutes() {
    #expect(BotFormat.duration(3_600) == "1h")
    #expect(BotFormat.duration(2 * 3_600) == "2h")
}

@Test func durationClampsNegativeIntervals() {
    #expect(BotFormat.duration(-120) == "0m")
}

@Test func freshnessReadsJustNowForTheFirstThreeSeconds() {
    #expect(BotFormat.freshness(seconds: 0) == "just now")
    #expect(BotFormat.freshness(seconds: 2) == "just now")
}

@Test func freshnessCountsSecondsAfterThree() {
    #expect(BotFormat.freshness(seconds: 3) == "3s ago")
    #expect(BotFormat.freshness(seconds: 12) == "12s ago")
    #expect(BotFormat.freshness(seconds: 30) == "30s ago")
}

@Test func quantityKeepsTwoDecimals() {
    #expect(BotFormat.quantity(0.8) == "0.80")
    #expect(BotFormat.quantity(1.2) == "1.20")
}

@Test func leverageIsSuffixedWithACross() {
    #expect(BotFormat.leverage(2) == "2×")
}
```

Delete the placeholder linkage test:

```bash
rm Packages/TradingBotKit/Tests/BotFormattingTests/BotFormattingLinkageTests.swift
```

- [ ] **Step 2: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter BotFormattingTests
```

Expected: FAIL — `type 'BotFormat' has no member 'currency'`.

- [ ] **Step 3: Implement the formatters**

Replace `Packages/TradingBotKit/Sources/BotFormatting/BotFormat.swift` entirely:

```swift
import Foundation

/// All display formatting for the app.
///
/// Locale and time zone are pinned deliberately: the design's figures are exact
/// (`$87.26`, `58,800`, `Jun 30 14:31` in UTC) and must not drift with the host
/// machine's region or time zone.
public enum BotFormat {
    static let locale = Locale(identifier: "en_US_POSIX")
    static let timeZone = TimeZone(identifier: "UTC") ?? .gmt

    private static func decimal(minimum: Int, maximum: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = minimum
        formatter.maximumFractionDigits = maximum
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private static func string(_ value: Double, minimum: Int, maximum: Int) -> String {
        let formatter = decimal(minimum: minimum, maximum: maximum)
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Money

    /// `$87.26`, negatives as `-$5.50`.
    public static func currency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        return sign + "$" + string(abs(value), minimum: 2, maximum: 2)
    }

    /// `+$1.76` / `-$12.74` / `$0.00`, and `—` when there is no value.
    public static func signedCurrency(_ value: Double?) -> String {
        guard let value else { return "—" }
        let sign = value > 0 ? "+" : (value < 0 ? "-" : "")
        return sign + "$" + string(abs(value), minimum: 2, maximum: 2)
    }

    /// Prices lose their decimals at or above 1,000 so wide pairs stay readable.
    public static func price(_ value: Double?) -> String {
        guard let value else { return "—" }
        return abs(value) >= 1_000
            ? string(value, minimum: 0, maximum: 0)
            : string(value, minimum: 2, maximum: 2)
    }

    public static func quantity(_ value: Double) -> String {
        string(value, minimum: 2, maximum: 2)
    }

    public static func leverage(_ value: Int) -> String { "\(value)×" }

    /// `39.3%`
    public static func percent(_ value: Double) -> String {
        string(value, minimum: 1, maximum: 1) + "%"
    }

    // MARK: - Dates

    private static func dateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }

    /// `Jun 20`
    public static func day(_ date: Date) -> String {
        dateFormatter("MMM d").string(from: date)
    }

    /// `Jun 30 14:31`, always UTC.
    public static func stamp(_ date: Date) -> String {
        dateFormatter("MMM d HH:mm").string(from: date)
    }

    // MARK: - Durations

    /// `45m`, `1h`, `1h 22m`.
    public static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int((interval / 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    /// `just now` for the first three seconds, then `12s ago`.
    public static func freshness(seconds: Int) -> String {
        seconds < 3 ? "just now" : "\(seconds)s ago"
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter BotFormattingTests
```

Expected: PASS (21 tests).

- [ ] **Step 5: Verify the timezone pin actually holds**

Run the suite under a deliberately hostile time zone. It must produce identical results:

```bash
cd Packages/TradingBotKit && TZ=Asia/Tokyo swift test --filter BotFormattingTests
```

Expected: PASS. If `stampIsMonthDayAndUTCClockTime` fails here, the `timeZone` pin is not being applied — fix it before continuing, because every timestamp in the app depends on it.

- [ ] **Step 6: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: BotFormatting with locale- and timezone-pinned display formatting"
```

---

## Task 4: BotDataKit — wire DTOs, mapper, and the sample snapshot

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDataKit/DTO/SnapshotDTO.swift`
- Create: `Packages/TradingBotKit/Sources/BotDataKit/DTO/SnapshotMapper.swift`
- Create: `TradingBot/Resources/snapshot.json`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotMapperTests.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/Fixtures.swift`

**Interfaces:**
- Consumes: `BotDomain` (all models), `LoadState`.
- Produces: `SnapshotDTO: Decodable`, `SnapshotMapper.map(_ dto: SnapshotDTO) -> Snapshot`, `SnapshotDecoder.decode(_ data: Data) throws -> Snapshot`.

- [ ] **Step 1: Write the sample snapshot resource**

This is the design's own payload verbatim. Create `TradingBot/Resources/snapshot.json`:

```json
{
  "generated_at": "2026-06-30T15:22:45Z",
  "summary": {
    "balance": 87.26, "equity": 116.40, "open": 1, "total": 28,
    "wins": 11, "losses": 17, "win_rate": 39.3, "total_pnl": -12.74,
    "today_total": 3, "today_wins": 1, "today_losses": 2, "today_pnl": -2.22
  },
  "curve": [
    { "t": "2026-06-20", "equity": 100.00 },
    { "t": "2026-06-23", "equity": 96.94 },
    { "t": "2026-06-26", "equity": 101.50 },
    { "t": "2026-06-28", "equity": 89.25 },
    { "t": "2026-06-30", "equity": 87.26 }
  ],
  "open_positions": [
    {
      "pair": "SOLUSDT", "direction": "short", "entry_price": 73.10, "quantity": 0.8,
      "leverage": 2, "margin": 29.24, "take_profit": 70.91, "stop_loss": 74.20,
      "timestamp": "2026-06-30T14:00:00Z", "exchange_stops": true
    }
  ],
  "closed_trades": [
    { "closed_at": "2026-06-30T14:31:00Z", "pair": "SOLUSDT", "direction": "short", "entry_price": 72.95, "exit_price": 71.85, "quantity": 1.2, "pnl": -1.99, "status": "closed_sl", "regime": "ranging", "confidence": 7, "timestamp": "2026-06-30T12:05:00Z" },
    { "closed_at": "2026-06-30T13:10:00Z", "pair": "BTCUSDT", "direction": "short", "entry_price": 58800.0, "exit_price": 58288.8, "quantity": 0.001, "pnl": 1.76, "status": "closed_tp", "regime": "trending_down", "confidence": 8, "timestamp": "2026-06-30T10:40:00Z" },
    { "closed_at": "2026-06-30T09:52:00Z", "pair": "SOLUSDT", "direction": "long", "entry_price": 71.40, "exit_price": 70.62, "quantity": 1.0, "pnl": -1.28, "status": "closed_sl", "regime": "ranging", "confidence": 5, "timestamp": "2026-06-30T08:15:00Z" },
    { "closed_at": "2026-06-29T22:04:00Z", "pair": "BTCUSDT", "direction": "long", "entry_price": 57920.0, "exit_price": 58410.5, "quantity": 0.001, "pnl": 1.42, "status": "closed_tp", "regime": "trending_up", "confidence": 9, "timestamp": "2026-06-29T19:30:00Z" },
    { "closed_at": "2026-06-29T15:18:00Z", "pair": "SOLUSDT", "direction": "short", "entry_price": 74.85, "exit_price": 75.60, "quantity": 0.9, "pnl": -1.11, "status": "closed_sl", "regime": "ranging", "confidence": 6, "timestamp": "2026-06-29T13:02:00Z" },
    { "closed_at": "2026-06-28T18:47:00Z", "pair": "BTCUSDT", "direction": "short", "entry_price": 59310.0, "exit_price": 58790.0, "quantity": 0.001, "pnl": 1.63, "status": "closed_tp", "regime": "trending_down", "confidence": 8, "timestamp": "2026-06-28T16:20:00Z" },
    { "closed_at": "2026-06-28T11:29:00Z", "pair": "SOLUSDT", "direction": "long", "entry_price": 69.90, "exit_price": 68.95, "quantity": 1.1, "pnl": -1.72, "status": "closed_sl", "regime": "ranging", "confidence": 4, "timestamp": "2026-06-28T09:05:00Z" },
    { "closed_at": "2026-06-27T20:12:00Z", "pair": "BTCUSDT", "direction": "long", "entry_price": 58150.0, "exit_price": 57640.0, "quantity": 0.001, "pnl": -1.54, "status": "closed_sl", "regime": "ranging", "confidence": 6, "timestamp": "2026-06-27T17:48:00Z" },
    { "closed_at": "2026-06-27T08:35:00Z", "pair": "SOLUSDT", "direction": "short", "entry_price": 76.20, "exit_price": 74.10, "quantity": 0.8, "pnl": 1.94, "status": "closed_tp", "regime": "trending_down", "confidence": 8, "timestamp": "2026-06-27T05:10:00Z" }
  ],
  "by_symbol": [
    { "key": "BTCUSDT", "trades": 14, "win_rate": 50.0, "net_pnl": 6.10 },
    { "key": "SOLUSDT", "trades": 14, "win_rate": 28.6, "net_pnl": -18.84 }
  ],
  "by_regime": [
    { "key": "trending_up", "trades": 6, "win_rate": 66.7, "net_pnl": 8.20 },
    { "key": "trending_down", "trades": 9, "win_rate": 44.4, "net_pnl": 2.05 },
    { "key": "ranging", "trades": 13, "win_rate": 23.1, "net_pnl": -22.99 }
  ],
  "ai_report": {
    "date": "2026-06-30",
    "narrative": "Choppy fortnight; SOL shorts in ranging conditions are the main drag while BTC trend entries held up.",
    "whats_working": ["BTC entries in clear trends", "Stops kept losses small"],
    "whats_losing": ["SOL trades in ranging regime", "Second concurrent position sized too small to matter"],
    "config_suggestions": [
      { "param": "ADX_TREND_MIN_SOLUSDT", "current": "25", "suggested": "30", "rationale": "filter more SOL chop" },
      { "param": "MAX_CONCURRENT_POSITIONS", "current": "2", "suggested": "1", "rationale": "full-size, comparable trades" }
    ]
  },
  "veto": {
    "proceed": 26, "block": 2, "scored": 24, "proceed_win_rate": 41.7,
    "rows": [
      { "ts": "2026-06-30T12:05:00Z", "symbol": "SOLUSDT", "signal": "SELL", "proceed": true, "reason": "trend intact, no red flag", "risk_flags": ["low_adx_chop"], "news_flag": false, "outcome": "loss" },
      { "ts": "2026-06-29T09:00:00Z", "symbol": "BTCUSDT", "signal": "BUY", "proceed": false, "reason": "blow-off top risk", "risk_flags": ["rsi_overbought"], "news_flag": false, "outcome": null }
    ]
  },
  "lessons": [
    {
      "ts": "2026-06-30T14:31:00Z", "pair": "SOLUSDT", "outcome": "closed_sl",
      "lesson": "Avoid shorting into established support in a ranging market.",
      "failure_pattern": "shorted into support", "confidence": "high",
      "tags": ["support", "ranging", "short"]
    }
  ]
}
```

- [ ] **Step 2: Write the test fixtures helper**

`Packages/TradingBotKit/Tests/BotDataKitTests/Fixtures.swift`:

```swift
import Foundation

enum Fixtures {
    /// A minimal but complete payload with the review layer present.
    static let full = """
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 87.26, "equity": 116.40, "open": 1, "total": 28,
        "wins": 11, "losses": 17, "win_rate": 39.3, "total_pnl": -12.74,
        "today_total": 3, "today_wins": 1, "today_losses": 2, "today_pnl": -2.22 },
      "curve": [ { "t": "2026-06-20", "equity": 100.0 }, { "t": "2026-06-30", "equity": 87.26 } ],
      "open_positions": [ { "pair": "SOLUSDT", "direction": "short", "entry_price": 73.10,
        "quantity": 0.8, "leverage": 2, "margin": 29.24, "take_profit": 70.91,
        "stop_loss": 74.20, "timestamp": "2026-06-30T14:00:00Z", "exchange_stops": true } ],
      "closed_trades": [ { "closed_at": "2026-06-30T14:31:00Z", "pair": "SOLUSDT",
        "direction": "short", "entry_price": 72.95, "exit_price": 71.85, "quantity": 1.2,
        "pnl": -1.99, "status": "closed_sl", "regime": "ranging", "confidence": 7,
        "timestamp": "2026-06-30T12:05:00Z" } ],
      "by_symbol": [ { "key": "BTCUSDT", "trades": 14, "win_rate": 50.0, "net_pnl": 6.10 } ],
      "by_regime": [ { "key": "ranging", "trades": 13, "win_rate": 23.1, "net_pnl": -22.99 } ],
      "ai_report": { "date": "2026-06-30", "narrative": "Choppy fortnight.",
        "whats_working": ["BTC entries in clear trends"],
        "whats_losing": ["SOL trades in ranging regime"],
        "config_suggestions": [ { "param": "ADX_TREND_MIN_SOLUSDT", "current": "25",
          "suggested": "30", "rationale": "filter more SOL chop" } ] },
      "veto": { "proceed": 26, "block": 2, "scored": 24, "proceed_win_rate": 41.7,
        "rows": [ { "ts": "2026-06-30T12:05:00Z", "symbol": "SOLUSDT", "signal": "SELL",
          "proceed": true, "reason": "trend intact, no red flag",
          "risk_flags": ["low_adx_chop"], "news_flag": false, "outcome": "loss" } ] },
      "lessons": [ { "ts": "2026-06-30T14:31:00Z", "pair": "SOLUSDT", "outcome": "closed_sl",
        "lesson": "Avoid shorting into established support in a ranging market.",
        "failure_pattern": "shorted into support", "confidence": "high",
        "tags": ["support", "ranging", "short"] } ]
    }
    """.data(using: .utf8)!

    /// The same payload with the entire review layer absent — drives the AI-null screen.
    static let aiNull = """
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 87.26, "equity": 116.40, "open": 0, "total": 28,
        "wins": 11, "losses": 17, "win_rate": 39.3, "total_pnl": -12.74,
        "today_total": 3, "today_wins": 1, "today_losses": 2, "today_pnl": -2.22 },
      "curve": [ { "t": "2026-06-20", "equity": 100.0 } ],
      "open_positions": [],
      "closed_trades": [],
      "by_symbol": [],
      "by_regime": [],
      "ai_report": null,
      "veto": null,
      "lessons": null
    }
    """.data(using: .utf8)!

    /// Unrecognised direction, status, and signal values.
    static let unknownEnums = """
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 1, "equity": 1, "open": 0, "total": 1,
        "wins": 0, "losses": 1, "win_rate": 0, "total_pnl": -1,
        "today_total": 0, "today_wins": 0, "today_losses": 0, "today_pnl": 0 },
      "curve": [],
      "open_positions": [],
      "closed_trades": [ { "closed_at": "2026-06-30T14:31:00Z", "pair": "XRPUSDT",
        "direction": "sideways", "entry_price": 1, "exit_price": 1, "quantity": 1,
        "pnl": -1, "status": "closed_manual", "regime": "chop", "confidence": 3,
        "timestamp": "2026-06-30T12:05:00Z" } ],
      "by_symbol": [], "by_regime": [],
      "ai_report": null, "veto": null, "lessons": null
    }
    """.data(using: .utf8)!

    static let malformed = Data("{ this is not json".utf8)
}
```

- [ ] **Step 3: Write the failing mapper tests**

`Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotMapperTests.swift`:

```swift
import Foundation
import Testing
import BotDomain
@testable import BotDataKit

@Test func decodesTheSummary() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.summary.balance == 87.26)
    #expect(snapshot.summary.equity == 116.40)
    #expect(snapshot.summary.total == 28)
    #expect(snapshot.summary.wins == 11)
    #expect(snapshot.summary.winRate == 39.3)
    #expect(snapshot.summary.totalPnl == -12.74)
    #expect(snapshot.summary.todayPnl == -2.22)
}

@Test func decodesGeneratedAtAsAnISO8601Instant() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.generatedAt == Date(timeIntervalSince1970: 1_782_832_965))
}

@Test func decodesCurveDatesFromYearMonthDay() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.curve.count == 2)
    #expect(snapshot.curve[0].equity == 100.0)
    #expect(snapshot.curve[0].date == Date(timeIntervalSince1970: 1_781_913_600))
}

@Test func decodesTheOpenPosition() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    let position = try #require(snapshot.openPositions.first)
    #expect(position.pair == "SOLUSDT")
    #expect(position.direction == .short)
    #expect(position.entryPrice == 73.10)
    #expect(position.leverage == 2)
    #expect(position.takeProfit == 70.91)
    #expect(position.stopLoss == 74.20)
    #expect(position.exchangeStops)
}

@Test func decodesAClosedTradeIncludingItsOpenTimestamp() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    let trade = try #require(snapshot.closedTrades.first)
    #expect(trade.pair == "SOLUSDT")
    #expect(trade.direction == .short)
    #expect(trade.status == .stopLoss)
    #expect(trade.confidence == 7)
    // closed 14:31, opened 12:05 -> 2h 26m
    #expect(trade.holdDuration == 8_760)
}

@Test func decodesTheReviewLayerWhenPresent() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    let report = try #require(snapshot.aiReport)
    #expect(report.date == "2026-06-30")
    #expect(report.narrative == "Choppy fortnight.")
    #expect(report.whatsWorking == ["BTC entries in clear trends"])
    #expect(report.configSuggestions.first?.param == "ADX_TREND_MIN_SOLUSDT")
    #expect(report.configSuggestions.first?.suggested == "30")

    let veto = try #require(snapshot.veto)
    #expect(veto.proceed == 26)
    #expect(veto.proceedWinRate == 41.7)
    #expect(veto.rows.first?.signal == .sell)
    #expect(veto.rows.first?.outcome == .loss)
    #expect(veto.rows.first?.displayFlags == ["low_adx_chop"])

    #expect(snapshot.lessons.first?.failurePattern == "shorted into support")
    #expect(snapshot.lessons.first?.tags == ["support", "ranging", "short"])
    #expect(snapshot.hasReviewLayer)
}

// The design's fourth screen exists purely because these three fields are nullable.
@Test func decodesAnAbsentReviewLayerAsNil() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.aiNull)
    #expect(snapshot.aiReport == nil)
    #expect(snapshot.veto == nil)
    #expect(snapshot.lessons.isEmpty)
    #expect(snapshot.hasReviewLayer == false)
    // The rest of the snapshot still decodes normally.
    #expect(snapshot.summary.total == 28)
}

@Test func decodesMissingReviewKeysEntirelyAsNil() throws {
    let withoutKeys = Data("""
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 1, "equity": 1, "open": 0, "total": 0, "wins": 0,
        "losses": 0, "win_rate": 0, "total_pnl": 0, "today_total": 0,
        "today_wins": 0, "today_losses": 0, "today_pnl": 0 },
      "curve": [], "open_positions": [], "closed_trades": [],
      "by_symbol": [], "by_regime": []
    }
    """.utf8)
    let snapshot = try SnapshotDecoder.decode(withoutKeys)
    #expect(snapshot.aiReport == nil)
    #expect(snapshot.veto == nil)
    #expect(snapshot.lessons.isEmpty)
}

// Tolerating unknown enum values keeps one odd row from blanking the whole screen.
@Test func unknownEnumValuesFallBackInsteadOfThrowing() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.unknownEnums)
    let trade = try #require(snapshot.closedTrades.first)
    #expect(trade.direction == .unknown)
    #expect(trade.status == .unknown)
    #expect(trade.regime == "chop")
    #expect(trade.pair == "XRPUSDT")
}

// Malformed JSON is a real failure and must surface.
@Test func malformedJSONThrows() {
    #expect(throws: (any Error).self) {
        try SnapshotDecoder.decode(Fixtures.malformed)
    }
}

@Test func missingRequiredFieldThrows() {
    let missingSummary = Data("""
    { "generated_at": "2026-06-30T15:22:45Z", "curve": [], "open_positions": [],
      "closed_trades": [], "by_symbol": [], "by_regime": [] }
    """.utf8)
    #expect(throws: (any Error).self) {
        try SnapshotDecoder.decode(missingSummary)
    }
}

@Test func decodesBreakdownGroups() throws {
    let snapshot = try SnapshotDecoder.decode(Fixtures.full)
    #expect(snapshot.bySymbol.first?.key == "BTCUSDT")
    #expect(snapshot.bySymbol.first?.netPnl == 6.10)
    #expect(snapshot.byRegime.first?.keyDisplay == "ranging")
}
```

- [ ] **Step 5: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter SnapshotMapperTests
```

Expected: FAIL — `cannot find 'SnapshotDecoder' in scope`.

- [ ] **Step 5: Write the DTOs**

`Packages/TradingBotKit/Sources/BotDataKit/DTO/SnapshotDTO.swift`:

```swift
import Foundation

/// Wire types. These mirror the JSON exactly and never leak past `SnapshotMapper`,
/// so a change to the real API is contained to this file and the mapper.
struct SnapshotDTO: Decodable {
    let generatedAt: Date
    let summary: SummaryDTO
    let curve: [CurvePointDTO]
    let openPositions: [PositionDTO]
    let closedTrades: [ClosedTradeDTO]
    let bySymbol: [BreakdownDTO]
    let byRegime: [BreakdownDTO]
    let aiReport: AIReportDTO?
    let veto: VetoDTO?
    let lessons: [LessonDTO]?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case summary, curve, veto, lessons
        case openPositions = "open_positions"
        case closedTrades = "closed_trades"
        case bySymbol = "by_symbol"
        case byRegime = "by_regime"
        case aiReport = "ai_report"
    }
}

struct SummaryDTO: Decodable {
    let balance: Double
    let equity: Double
    let open: Int
    let total: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let totalPnl: Double
    let todayTotal: Int
    let todayWins: Int
    let todayLosses: Int
    let todayPnl: Double

    enum CodingKeys: String, CodingKey {
        case balance, equity, open, total, wins, losses
        case winRate = "win_rate"
        case totalPnl = "total_pnl"
        case todayTotal = "today_total"
        case todayWins = "today_wins"
        case todayLosses = "today_losses"
        case todayPnl = "today_pnl"
    }
}

struct CurvePointDTO: Decodable {
    let t: String
    let equity: Double
}

struct PositionDTO: Decodable {
    let pair: String
    let direction: String
    let entryPrice: Double
    let quantity: Double
    let leverage: Int
    let margin: Double
    let takeProfit: Double
    let stopLoss: Double
    let timestamp: Date
    let exchangeStops: Bool

    enum CodingKeys: String, CodingKey {
        case pair, direction, quantity, leverage, margin, timestamp
        case entryPrice = "entry_price"
        case takeProfit = "take_profit"
        case stopLoss = "stop_loss"
        case exchangeStops = "exchange_stops"
    }
}

struct ClosedTradeDTO: Decodable {
    let closedAt: Date
    let pair: String
    let direction: String
    let entryPrice: Double
    let exitPrice: Double
    let quantity: Double
    let pnl: Double
    let status: String
    let regime: String
    let confidence: Int
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case pair, direction, quantity, pnl, status, regime, confidence, timestamp
        case closedAt = "closed_at"
        case entryPrice = "entry_price"
        case exitPrice = "exit_price"
    }
}

struct BreakdownDTO: Decodable {
    let key: String
    let trades: Int
    let winRate: Double
    let netPnl: Double

    enum CodingKeys: String, CodingKey {
        case key, trades
        case winRate = "win_rate"
        case netPnl = "net_pnl"
    }
}

struct ConfigSuggestionDTO: Decodable {
    let param: String
    let current: String
    let suggested: String
    let rationale: String
}

struct AIReportDTO: Decodable {
    let date: String
    let narrative: String
    let whatsWorking: [String]
    let whatsLosing: [String]
    let configSuggestions: [ConfigSuggestionDTO]

    enum CodingKeys: String, CodingKey {
        case date, narrative
        case whatsWorking = "whats_working"
        case whatsLosing = "whats_losing"
        case configSuggestions = "config_suggestions"
    }
}

struct VetoRowDTO: Decodable {
    let ts: Date
    let symbol: String
    let signal: String
    let proceed: Bool
    let reason: String
    let riskFlags: [String]?
    let newsFlag: Bool?
    let outcome: String?

    enum CodingKeys: String, CodingKey {
        case ts, symbol, signal, proceed, reason, outcome
        case riskFlags = "risk_flags"
        case newsFlag = "news_flag"
    }
}

struct VetoDTO: Decodable {
    let proceed: Int
    let block: Int
    let scored: Int
    let proceedWinRate: Double
    let rows: [VetoRowDTO]

    enum CodingKeys: String, CodingKey {
        case proceed, block, scored, rows
        case proceedWinRate = "proceed_win_rate"
    }
}

struct LessonDTO: Decodable {
    let ts: Date
    let pair: String
    let outcome: String
    let lesson: String
    let failurePattern: String
    let confidence: String
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case ts, pair, outcome, lesson, confidence, tags
        case failurePattern = "failure_pattern"
    }
}
```

- [ ] **Step 6: Write the mapper and decoder**

`Packages/TradingBotKit/Sources/BotDataKit/DTO/SnapshotMapper.swift`:

```swift
import Foundation
import BotDomain

/// Turns wire DTOs into domain models. The only place snake_case meets the app.
enum SnapshotMapper {
    /// Curve points arrive as bare `YYYY-MM-DD` strings, not full timestamps.
    private static let dayParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func map(_ dto: SnapshotDTO) -> Snapshot {
        Snapshot(
            generatedAt: dto.generatedAt,
            summary: map(dto.summary),
            curve: dto.curve.compactMap(map),
            openPositions: dto.openPositions.map(map),
            closedTrades: dto.closedTrades.map(map),
            bySymbol: dto.bySymbol.map(map),
            byRegime: dto.byRegime.map(map),
            aiReport: dto.aiReport.map(map),
            veto: dto.veto.map(map),
            lessons: (dto.lessons ?? []).map(map)
        )
    }

    private static func map(_ dto: SummaryDTO) -> Summary {
        Summary(
            balance: dto.balance, equity: dto.equity, open: dto.open, total: dto.total,
            wins: dto.wins, losses: dto.losses, winRate: dto.winRate,
            totalPnl: dto.totalPnl, todayTotal: dto.todayTotal, todayWins: dto.todayWins,
            todayLosses: dto.todayLosses, todayPnl: dto.todayPnl
        )
    }

    /// Returns nil for an unparseable day so one bad point cannot break the chart.
    private static func map(_ dto: CurvePointDTO) -> CurvePoint? {
        guard let date = dayParser.date(from: dto.t) else { return nil }
        return CurvePoint(date: date, equity: dto.equity)
    }

    private static func map(_ dto: PositionDTO) -> Position {
        Position(
            pair: dto.pair,
            direction: TradeDirection(wire: dto.direction),
            entryPrice: dto.entryPrice,
            quantity: dto.quantity,
            leverage: dto.leverage,
            margin: dto.margin,
            takeProfit: dto.takeProfit,
            stopLoss: dto.stopLoss,
            openedAt: dto.timestamp,
            exchangeStops: dto.exchangeStops
        )
    }

    private static func map(_ dto: ClosedTradeDTO) -> ClosedTrade {
        ClosedTrade(
            closedAt: dto.closedAt,
            openedAt: dto.timestamp,
            pair: dto.pair,
            direction: TradeDirection(wire: dto.direction),
            entryPrice: dto.entryPrice,
            exitPrice: dto.exitPrice,
            quantity: dto.quantity,
            pnl: dto.pnl,
            status: TradeStatus(wire: dto.status),
            regime: dto.regime,
            confidence: dto.confidence
        )
    }

    private static func map(_ dto: BreakdownDTO) -> BreakdownGroup {
        BreakdownGroup(
            key: dto.key, trades: dto.trades,
            winRate: dto.winRate, netPnl: dto.netPnl
        )
    }

    private static func map(_ dto: AIReportDTO) -> AIReport {
        AIReport(
            date: dto.date,
            narrative: dto.narrative,
            whatsWorking: dto.whatsWorking,
            whatsLosing: dto.whatsLosing,
            configSuggestions: dto.configSuggestions.map {
                ConfigSuggestion(
                    param: $0.param, current: $0.current,
                    suggested: $0.suggested, rationale: $0.rationale
                )
            }
        )
    }

    private static func map(_ dto: VetoDTO) -> VetoLog {
        VetoLog(
            proceed: dto.proceed,
            block: dto.block,
            scored: dto.scored,
            proceedWinRate: dto.proceedWinRate,
            rows: dto.rows.map { row in
                VetoRow(
                    timestamp: row.ts,
                    symbol: row.symbol,
                    signal: VetoSignal(wire: row.signal),
                    proceed: row.proceed,
                    reason: row.reason,
                    riskFlags: row.riskFlags ?? [],
                    newsFlag: row.newsFlag ?? false,
                    outcome: VetoOutcome(wire: row.outcome)
                )
            }
        )
    }

    private static func map(_ dto: LessonDTO) -> Lesson {
        Lesson(
            timestamp: dto.ts,
            pair: dto.pair,
            outcome: TradeStatus(wire: dto.outcome),
            lesson: dto.lesson,
            failurePattern: dto.failurePattern,
            confidence: dto.confidence,
            tags: dto.tags ?? []
        )
    }
}

/// The single entry point for turning raw bytes into a `Snapshot`.
public enum SnapshotDecoder {
    public static func decode(_ data: Data) throws -> Snapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(SnapshotDTO.self, from: data)
        return SnapshotMapper.map(dto)
    }
}
```

- [ ] **Step 7: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter SnapshotMapperTests
```

Expected: PASS (12 tests).

- [ ] **Step 8: Commit**

```bash
git add Packages/TradingBotKit TradingBot/Resources
git commit -m "feat: snapshot DTOs, mapper, decoder, and the sample payload"
```

---

## Task 5: BotDataKit — provider protocol, bundled provider, disk cache

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDataKit/SnapshotProvider.swift`
- Create: `Packages/TradingBotKit/Sources/BotDataKit/BundledSnapshotProvider.swift`
- Create: `Packages/TradingBotKit/Sources/BotDataKit/SnapshotCache.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotCacheTests.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/BundledSnapshotProviderTests.swift`

**Interfaces:**
- Consumes: `SnapshotDecoder`, `Snapshot`.
- Produces: `protocol SnapshotProvider: Sendable { func fetchPayload() async throws -> Data }`, `SnapshotError`, `BundledSnapshotProvider(bundle:resource:)`, `actor SnapshotCache` with `func write(_ data: Data) async throws`, `func read() async throws -> Snapshot`, `func clear() async`.

**Why providers return `Data`, not `Snapshot`:** decoding lives in the repository (Task 7) so the cache can store the exact bytes that arrived rather than a re-encoded approximation. This keeps providers trivial and makes the cached payload byte-identical to the server's.

- [ ] **Step 1: Write the failing cache tests**

`Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotCacheTests.swift`:

```swift
import Foundation
import Testing
@testable import BotDataKit

private func makeTemporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("cache-test-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Test func cacheRoundTripsASnapshot() async throws {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    try await cache.write(Fixtures.full)
    let snapshot = try await cache.read()
    #expect(snapshot.summary.balance == 87.26)
}

@Test func readingAnEmptyCacheThrowsNoCachedSnapshot() async {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    await #expect(throws: SnapshotError.noCachedSnapshot) {
        try await cache.read()
    }
}

@Test func writingReplacesThePreviousEntry() async throws {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    try await cache.write(Fixtures.full)
    try await cache.write(Fixtures.aiNull)
    let snapshot = try await cache.read()
    #expect(snapshot.aiReport == nil)
    #expect(snapshot.summary.open == 0)
}

@Test func clearRemovesTheCachedEntry() async throws {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    try await cache.write(Fixtures.full)
    await cache.clear()
    await #expect(throws: SnapshotError.noCachedSnapshot) {
        try await cache.read()
    }
}

@Test func cacheRefusesToStoreMalformedData() async {
    let cache = SnapshotCache(directory: makeTemporaryDirectory())
    await #expect(throws: (any Error).self) {
        try await cache.write(Fixtures.malformed)
    }
}
```

The last test encodes a deliberate rule: the cache validates before storing, so a corrupt response can never poison the offline fallback.

- [ ] **Step 2: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter SnapshotCacheTests
```

Expected: FAIL — `cannot find 'SnapshotCache' in scope`.

- [ ] **Step 3: Write the provider protocol and errors**

`Packages/TradingBotKit/Sources/BotDataKit/SnapshotProvider.swift`:

```swift
import Foundation
import BotDomain

/// Anything that can produce a raw snapshot payload. The app depends on this, never on
/// a concrete source. Decoding is the repository's job, which keeps providers trivial
/// and lets the cache store exactly the bytes that arrived.
public protocol SnapshotProvider: Sendable {
    func fetchPayload() async throws -> Data
}

public enum SnapshotError: Error, Equatable {
    case resourceMissing(String)
    case noCachedSnapshot
    case decoding(String)
    case transport(String)
    case server(status: Int)
    case offline

    public var userMessage: String {
        switch self {
        case .resourceMissing(let name):
            return "Bundled snapshot \"\(name)\" is missing."
        case .noCachedSnapshot:
            return "No saved snapshot yet."
        case .decoding:
            return "The snapshot could not be read."
        case .transport:
            return "Could not reach the bot."
        case .server(let status):
            return "The bot responded with an error (\(status))."
        case .offline:
            return "You appear to be offline."
        }
    }
}
```

- [ ] **Step 4: Write the cache**

`Packages/TradingBotKit/Sources/BotDataKit/SnapshotCache.swift`:

```swift
import Foundation
import BotDomain

/// Stores the last good snapshot so the app has something to show when a load fails.
///
/// An actor because reads and writes race between the polling store and a manual refresh.
public actor SnapshotCache {
    private let directory: URL
    private let fileName = "snapshot-cache.json"

    private var fileURL: URL { directory.appendingPathComponent(fileName) }

    public init(directory: URL) {
        self.directory = directory
    }

    /// Default location in Caches — disposable, and excluded from backup by the system.
    public static func makeDefault() -> SnapshotCache {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("TradingBot", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SnapshotCache(directory: directory)
    }

    /// Validates before storing so a corrupt payload can never become the offline fallback.
    public func write(_ data: Data) throws {
        _ = try SnapshotDecoder.decode(data)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    public func read() throws -> Snapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SnapshotError.noCachedSnapshot
        }
        let data = try Data(contentsOf: fileURL)
        return try SnapshotDecoder.decode(data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
```

- [ ] **Step 5: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter SnapshotCacheTests
```

Expected: PASS (5 tests).

- [ ] **Step 6: Write the failing bundled-provider tests**

`Packages/TradingBotKit/Tests/BotDataKitTests/BundledSnapshotProviderTests.swift`:

```swift
import Foundation
import Testing
@testable import BotDataKit

@Test func bundledProviderReturnsThePayloadItIsGiven() async throws {
    let provider = BundledSnapshotProvider(loader: { Fixtures.full })
    let payload = try await provider.fetchPayload()
    let snapshot = try SnapshotDecoder.decode(payload)
    #expect(snapshot.summary.total == 28)
    #expect(snapshot.hasReviewLayer)
}

@Test func bundledProviderSurfacesAMissingResource() async {
    let provider = BundledSnapshotProvider(resource: "does-not-exist", loader: { nil })
    await #expect(throws: SnapshotError.resourceMissing("does-not-exist")) {
        _ = try await provider.fetchPayload()
    }
}

@Test func bundledProviderIsIndifferentToPayloadValidity() async throws {
    // The provider only transports bytes; decoding failures surface in the repository.
    let provider = BundledSnapshotProvider(loader: { Fixtures.malformed })
    let payload = try await provider.fetchPayload()
    #expect(payload == Fixtures.malformed)
}

@Test func bundledProviderCanServeTheAINullFixture() async throws {
    let provider = BundledSnapshotProvider(loader: { Fixtures.aiNull })
    let snapshot = try SnapshotDecoder.decode(try await provider.fetchPayload())
    #expect(snapshot.hasReviewLayer == false)
}
```

- [ ] **Step 7: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter BundledSnapshotProviderTests
```

Expected: FAIL — `cannot find 'BundledSnapshotProvider' in scope`.

- [ ] **Step 8: Write the bundled provider**

`Packages/TradingBotKit/Sources/BotDataKit/BundledSnapshotProvider.swift`:

```swift
import Foundation
import BotDomain

/// Reads a snapshot from a JSON resource shipped inside the app.
///
/// The loader closure is injectable so tests exercise it without a real bundle.
public struct BundledSnapshotProvider: SnapshotProvider {
    private let resource: String
    private let loader: @Sendable () -> Data?

    public init(resource: String = "snapshot", loader: @escaping @Sendable () -> Data?) {
        self.resource = resource
        self.loader = loader
    }

    /// Production initialiser — reads `<resource>.json` from the given bundle.
    public init(resource: String = "snapshot", bundle: Bundle = .main) {
        self.resource = resource
        self.loader = { [resource] in
            guard let url = bundle.url(forResource: resource, withExtension: "json") else {
                return nil
            }
            return try? Data(contentsOf: url)
        }
    }

    public func fetchPayload() async throws -> Data {
        guard let data = loader() else {
            throw SnapshotError.resourceMissing(resource)
        }
        return data
    }
}
```

- [ ] **Step 9: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter BotDataKitTests
```

Expected: PASS (all data-kit tests so far: 2 LoadState + 12 mapper + 5 cache + 4 bundled = 23).

- [ ] **Step 10: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: SnapshotProvider protocol, bundled provider, validating disk cache"
```

---

## Task 6: BotDataKit — HTTP client and remote provider

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDataKit/HTTPClient.swift`
- Create: `Packages/TradingBotKit/Sources/BotDataKit/RemoteSnapshotProvider.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/HTTPClientTests.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/MockURLProtocol.swift`

**Interfaces:**
- Consumes: `SnapshotProvider`, `SnapshotError`, `SnapshotDecoder`.
- Produces: `HTTPClient(session:maxRetries:)` with `func get(_ url: URL) async throws -> Data`, and `RemoteSnapshotProvider(baseURL:client:path:)` conforming to `SnapshotProvider`.

- [ ] **Step 1: Write the mock URL protocol**

`Packages/TradingBotKit/Tests/BotDataKitTests/MockURLProtocol.swift`:

```swift
import Foundation

/// Intercepts URLSession traffic so HTTP behaviour is testable without a network.
final class MockURLProtocol: URLProtocol {
    struct Response {
        let statusCode: Int
        let data: Data?
        let error: (any Error)?

        static func ok(_ data: Data) -> Response {
            Response(statusCode: 200, data: data, error: nil)
        }
        static func status(_ code: Int) -> Response {
            Response(statusCode: code, data: Data(), error: nil)
        }
        static func failure(_ error: any Error) -> Response {
            Response(statusCode: 0, data: nil, error: error)
        }
    }

    /// Responses are popped in order, so a test can script "fail, fail, succeed".
    nonisolated(unsafe) static var queue: [Response] = []
    nonisolated(unsafe) static var requestCount = 0
    private static let lock = NSLock()

    static func reset(with responses: [Response]) {
        lock.lock()
        queue = responses
        requestCount = 0
        lock.unlock()
    }

    static func next() -> Response {
        lock.lock()
        defer { lock.unlock() }
        requestCount += 1
        if queue.count > 1 { return queue.removeFirst() }
        return queue.first ?? .status(500)
    }

    static var totalRequests: Int {
        lock.lock()
        defer { lock.unlock() }
        return requestCount
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let response = MockURLProtocol.next()
        if let error = response.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        if let data = response.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
}
```

- [ ] **Step 2: Write the failing HTTP tests**

`Packages/TradingBotKit/Tests/BotDataKitTests/HTTPClientTests.swift`:

```swift
import Foundation
import Testing
@testable import BotDataKit

private let testURL = URL(string: "https://example.test/api/snapshot")!

/// Serialized: `MockURLProtocol` scripts responses through shared static state, and
/// Swift Testing runs tests in parallel by default. Without this the queue and the
/// request counter are clobbered across concurrent tests — the retry-count assertions
/// see every test's requests summed together.
@Suite(.serialized)
struct HTTPClientTests {

@Test func getReturnsBodyOnSuccess() async throws {
    MockURLProtocol.reset(with: [.ok(Fixtures.full)])
    let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
    let data = try await client.get(testURL)
    #expect(data == Fixtures.full)
}

@Test func serverErrorIsMappedToAServerFailure() async {
    MockURLProtocol.reset(with: [.status(500)])
    let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
    await #expect(throws: SnapshotError.server(status: 500)) {
        _ = try await client.get(testURL)
    }
}

@Test func clientErrorIsMappedAndNotRetried() async {
    MockURLProtocol.reset(with: [.status(404)])
    let client = HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 3)
    await #expect(throws: SnapshotError.server(status: 404)) {
        _ = try await client.get(testURL)
    }
    // A 404 will not fix itself — retrying it wastes time and battery.
    #expect(MockURLProtocol.totalRequests == 1)
}

@Test func transientFailureIsRetriedUntilItSucceeds() async throws {
    let transient = URLError(.timedOut)
    MockURLProtocol.reset(with: [
        .failure(transient),
        .failure(transient),
        .ok(Fixtures.full),
    ])
    let client = HTTPClient(
        session: MockURLProtocol.makeSession(), maxRetries: 3, retryDelay: 0
    )
    let data = try await client.get(testURL)
    #expect(data == Fixtures.full)
    #expect(MockURLProtocol.totalRequests == 3)
}

@Test func serverErrorsAreRetriedThenGiveUp() async {
    MockURLProtocol.reset(with: [.status(503)])
    let client = HTTPClient(
        session: MockURLProtocol.makeSession(), maxRetries: 2, retryDelay: 0
    )
    await #expect(throws: SnapshotError.server(status: 503)) {
        _ = try await client.get(testURL)
    }
    #expect(MockURLProtocol.totalRequests == 3)   // initial + 2 retries
}

@Test func offlineIsReportedDistinctlyFromOtherTransportFailures() async {
    MockURLProtocol.reset(with: [.failure(URLError(.notConnectedToInternet))])
    let client = HTTPClient(
        session: MockURLProtocol.makeSession(), maxRetries: 0, retryDelay: 0
    )
    await #expect(throws: SnapshotError.offline) {
        _ = try await client.get(testURL)
    }
}

@Test func remoteProviderFetchesADecodablePayload() async throws {
    MockURLProtocol.reset(with: [.ok(Fixtures.full)])
    let provider = RemoteSnapshotProvider(
        baseURL: URL(string: "https://example.test")!,
        client: HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
    )
    let snapshot = try SnapshotDecoder.decode(try await provider.fetchPayload())
    #expect(snapshot.summary.equity == 116.40)
}

@Test func remoteProviderPropagatesServerErrors() async {
    MockURLProtocol.reset(with: [.status(401)])
    let provider = RemoteSnapshotProvider(
        baseURL: URL(string: "https://example.test")!,
        client: HTTPClient(session: MockURLProtocol.makeSession(), maxRetries: 0)
    )
    await #expect(throws: SnapshotError.server(status: 401)) {
        _ = try await provider.fetchPayload()
    }
}

}   // end @Suite(.serialized) struct HTTPClientTests
```

Indent the eight `@Test` functions one level to sit inside the suite. Every test above must be a method of `HTTPClientTests`, not a free function.

- [ ] **Step 3: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter HTTPClientTests
```

Expected: FAIL — `cannot find 'HTTPClient' in scope`.

- [ ] **Step 4: Write the HTTP client**

`Packages/TradingBotKit/Sources/BotDataKit/HTTPClient.swift`:

```swift
import Foundation

/// Minimal GET client with bounded retry.
///
/// Retries only what can plausibly succeed on a second attempt: transport errors and
/// 5xx responses. A 4xx is a permanent answer, so it fails immediately.
public struct HTTPClient: Sendable {
    private let session: URLSession
    private let maxRetries: Int
    private let retryDelay: Duration

    public init(
        session: URLSession = .shared,
        maxRetries: Int = 2,
        retryDelay: Duration = .milliseconds(400)
    ) {
        self.session = session
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    public init(session: URLSession, maxRetries: Int, retryDelay: Int) {
        self.init(
            session: session,
            maxRetries: maxRetries,
            retryDelay: .milliseconds(retryDelay)
        )
    }

    public func get(_ url: URL) async throws -> Data {
        var attempt = 0
        while true {
            do {
                return try await perform(url)
            } catch let error as SnapshotError {
                guard attempt < maxRetries, isRetryable(error) else { throw error }
                attempt += 1
                if retryDelay > .zero {
                    try? await Task.sleep(for: retryDelay)
                }
            }
        }
    }

    private func perform(_ url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            throw urlError.code == .notConnectedToInternet
                ? SnapshotError.offline
                : SnapshotError.transport(urlError.localizedDescription)
        } catch {
            throw SnapshotError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SnapshotError.transport("Response was not HTTP.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SnapshotError.server(status: http.statusCode)
        }
        return data
    }

    private func isRetryable(_ error: SnapshotError) -> Bool {
        switch error {
        case .transport, .offline:
            return true
        case .server(let status):
            return status >= 500
        default:
            return false
        }
    }
}
```

- [ ] **Step 5: Write the remote provider**

`Packages/TradingBotKit/Sources/BotDataKit/RemoteSnapshotProvider.swift`:

```swift
import Foundation
import BotDomain

/// Fetches the snapshot over HTTP. Implemented and tested now; wired live only when
/// the real dashboard's credentials exist.
public struct RemoteSnapshotProvider: SnapshotProvider {
    private let url: URL
    private let client: HTTPClient

    public init(baseURL: URL, client: HTTPClient = HTTPClient(), path: String = "api/snapshot") {
        self.url = baseURL.appendingPathComponent(path)
        self.client = client
    }

    public func fetchPayload() async throws -> Data {
        try await client.get(url)
    }
}
```

- [ ] **Step 6: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter HTTPClientTests
```

Expected: PASS (8 tests).

- [ ] **Step 7: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: HTTP client with bounded retry and the remote snapshot provider"
```

---

## Task 7: BotDataKit — repository and observable polling store

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDataKit/SnapshotRepository.swift`
- Create: `Packages/TradingBotKit/Sources/BotDataKit/SnapshotStore.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotRepositoryTests.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotStoreTests.swift`
- Test: `Packages/TradingBotKit/Tests/BotDataKitTests/StubSnapshotProvider.swift`

**Interfaces:**
- Consumes: `SnapshotProvider`, `SnapshotCache`, `LoadState`, `SnapshotError`.
- Produces: `SnapshotRepository(provider:cache:)` with `func load() async throws -> RepositoryResult`; `RepositoryResult` (`snapshot: Snapshot`, `isStale: Bool`); `@MainActor @Observable final class SnapshotStore` with `state: LoadState<Snapshot>`, `isStale: Bool`, `isRefreshing: Bool`, `secondsSinceUpdate: Int`, `func refresh() async`, `func startPolling(interval:)`, `func stopPolling()`.

- [ ] **Step 1: Write the stub provider**

`Packages/TradingBotKit/Tests/BotDataKitTests/StubSnapshotProvider.swift`:

```swift
import Foundation
import BotDomain
@testable import BotDataKit

/// Scriptable provider: each fetch pops the next outcome.
final class StubSnapshotProvider: SnapshotProvider, @unchecked Sendable {
    enum Outcome {
        case success(Data)
        case failure(any Error)
    }

    private let lock = NSLock()
    private var outcomes: [Outcome]
    private(set) var fetchCount = 0

    init(_ outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    convenience init(alwaysSucceedsWith data: Data) {
        self.init([.success(data)])
    }

    func fetchPayload() async throws -> Data {
        lock.lock()
        fetchCount += 1
        let outcome = outcomes.count > 1 ? outcomes.removeFirst() : (outcomes.first ?? .failure(SnapshotError.offline))
        lock.unlock()

        switch outcome {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return fetchCount
    }
}
```

- [ ] **Step 2: Write the failing repository tests**

`Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotRepositoryTests.swift`:

```swift
import Foundation
import Testing
@testable import BotDataKit

private func makeCache() -> SnapshotCache {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("repo-test-\(UUID().uuidString)")
    return SnapshotCache(directory: url)
}

@Test func loadReturnsFreshDataAndCachesIt() async throws {
    let cache = makeCache()
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
        cache: cache
    )
    let result = try await repository.load()
    #expect(result.isStale == false)
    #expect(result.snapshot.summary.balance == 87.26)

    // The successful load must have populated the cache.
    let cached = try await cache.read()
    #expect(cached.summary.balance == 87.26)
}

@Test func loadFallsBackToCacheAndMarksTheResultStale() async throws {
    let cache = makeCache()
    try await cache.write(Fixtures.full)
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
        cache: cache
    )
    let result = try await repository.load()
    #expect(result.isStale)
    #expect(result.snapshot.summary.balance == 87.26)
}

@Test func loadRethrowsTheOriginalErrorWhenThereIsNoCache() async {
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
        cache: makeCache()
    )
    await #expect(throws: SnapshotError.offline) {
        _ = try await repository.load()
    }
}

@Test func aFailedLoadDoesNotOverwriteAGoodCache() async throws {
    let cache = makeCache()
    try await cache.write(Fixtures.full)
    let repository = SnapshotRepository(
        provider: StubSnapshotProvider([.failure(SnapshotError.server(status: 500))]),
        cache: cache
    )
    _ = try? await repository.load()
    let cached = try await cache.read()
    #expect(cached.summary.total == 28)
}
```

- [ ] **Step 3: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter SnapshotRepositoryTests
```

Expected: FAIL — `cannot find 'SnapshotRepository' in scope`.

- [ ] **Step 4: Write the repository**

`Packages/TradingBotKit/Sources/BotDataKit/SnapshotRepository.swift`:

```swift
import Foundation
import BotDomain

public struct RepositoryResult: Sendable {
    public let snapshot: Snapshot
    /// True when the snapshot came from cache because the live load failed.
    public let isStale: Bool

    public init(snapshot: Snapshot, isStale: Bool) {
        self.snapshot = snapshot
        self.isStale = isStale
    }
}

/// Orchestrates provider and cache: fetch, cache on success, fall back on failure.
///
/// Decoding happens here rather than in the provider so the cache stores exactly the
/// bytes that arrived, byte-identical to the server's payload.
public struct SnapshotRepository: Sendable {
    private let provider: any SnapshotProvider
    private let cache: SnapshotCache

    public init(provider: any SnapshotProvider, cache: SnapshotCache) {
        self.provider = provider
        self.cache = cache
    }

    public func load() async throws -> RepositoryResult {
        do {
            let payload = try await provider.fetchPayload()
            let snapshot = try SnapshotDecoder.decode(payload)
            // Best-effort: a cache write failure must not fail an otherwise good load.
            try? await cache.write(payload)
            return RepositoryResult(snapshot: snapshot, isStale: false)
        } catch {
            // A live failure is survivable if we have something on disk.
            if let cached = try? await cache.read() {
                return RepositoryResult(snapshot: cached, isStale: true)
            }
            throw error
        }
    }
}
```

- [ ] **Step 5: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter BotDataKitTests
```

Expected: PASS — all data-kit tests including the four repository tests.

- [ ] **Step 6: Write the failing store tests**

`Packages/TradingBotKit/Tests/BotDataKitTests/SnapshotStoreTests.swift`:

```swift
import Foundation
import Testing
@testable import BotDataKit

private func makeCache() -> SnapshotCache {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("store-test-\(UUID().uuidString)")
    return SnapshotCache(directory: url)
}

@MainActor
@Test func storeStartsIdle() {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
            cache: makeCache()
        )
    )
    #expect(store.state.value == nil)
    #expect(store.isRefreshing == false)
}

@MainActor
@Test func refreshLoadsASnapshot() async {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
            cache: makeCache()
        )
    )
    await store.refresh()
    #expect(store.state.value?.summary.balance == 87.26)
    #expect(store.isStale == false)
    #expect(store.isRefreshing == false)
}

@MainActor
@Test func refreshFromCacheMarksTheStoreStale() async throws {
    let cache = makeCache()
    try await cache.write(Fixtures.full)
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
            cache: cache
        )
    )
    await store.refresh()
    #expect(store.state.value != nil)
    #expect(store.isStale)
}

@MainActor
@Test func refreshWithNoCacheEntersTheFailedState() async {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider([.failure(SnapshotError.offline)]),
            cache: makeCache()
        )
    )
    await store.refresh()
    #expect(store.state.value == nil)
    #expect(store.state.error != nil)
}

@MainActor
@Test func aFailedRefreshKeepsDataAlreadyOnScreen() async {
    let provider = StubSnapshotProvider([
        .success(Fixtures.full),
        .failure(SnapshotError.server(status: 500)),
    ])
    let store = SnapshotStore(
        repository: SnapshotRepository(provider: provider, cache: makeCache())
    )
    await store.refresh()
    #expect(store.state.value != nil)

    await store.refresh()
    // The screen must not blank out just because a background refresh failed.
    #expect(store.state.value != nil)
    #expect(store.lastErrorMessage != nil)
}

@MainActor
@Test func secondsSinceUpdateResetsOnASuccessfulLoad() async {
    let store = SnapshotStore(
        repository: SnapshotRepository(
            provider: StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full),
            cache: makeCache()
        )
    )
    await store.refresh()
    #expect(store.secondsSinceUpdate == 0)
}

@MainActor
@Test func stopPollingPreventsFurtherFetches() async {
    let provider = StubSnapshotProvider(alwaysSucceedsWith: Fixtures.full)
    let store = SnapshotStore(
        repository: SnapshotRepository(provider: provider, cache: makeCache())
    )
    store.startPolling(interval: .milliseconds(20))
    try? await Task.sleep(for: .milliseconds(120))
    store.stopPolling()
    let countAfterStop = provider.callCount
    try? await Task.sleep(for: .milliseconds(120))
    #expect(provider.callCount == countAfterStop)
}
```

- [ ] **Step 7: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter SnapshotStoreTests
```

Expected: FAIL — `cannot find 'SnapshotStore' in scope`.

- [ ] **Step 8: Write the store**

`Packages/TradingBotKit/Sources/BotDataKit/SnapshotStore.swift`:

```swift
import Foundation
import Observation
import BotDomain

/// The single source of snapshot state for the whole app.
///
/// One instance is shared by all three tabs, so a refresh updates every screen at once
/// and the app issues one request rather than three.
@MainActor
@Observable
public final class SnapshotStore {
    public private(set) var state: LoadState<Snapshot> = .idle
    /// True when the data on screen came from cache after a failed load.
    public private(set) var isStale = false
    public private(set) var isRefreshing = false
    /// Drives the header's "just now / 12s ago" indicator.
    public private(set) var secondsSinceUpdate = 0
    /// Set when a refresh fails while data is already on screen.
    public private(set) var lastErrorMessage: String?

    private let repository: SnapshotRepository
    private var pollingTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?

    public init(repository: SnapshotRepository) {
        self.repository = repository
    }

    deinit {
        pollingTask?.cancel()
        tickTask?.cancel()
    }

    public func refresh() async {
        if state.value == nil { state = .loading }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let result = try await repository.load()
            state = .loaded(result.snapshot)
            isStale = result.isStale
            secondsSinceUpdate = 0
            lastErrorMessage = result.isStale
                ? SnapshotError.offline.userMessage
                : nil
        } catch {
            let message = (error as? SnapshotError)?.userMessage ?? error.localizedDescription
            if state.value == nil {
                state = .failed(error)
            } else {
                // Keep what is on screen; surface the problem without blanking the UI.
                lastErrorMessage = message
            }
        }
    }

    public func startPolling(interval: Duration = .seconds(30)) {
        stopPolling()

        pollingTask = Task { [weak self] in
            guard let self else { return }
            await self.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                if Task.isCancelled { return }
                await self.refresh()
            }
        }

        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                guard let self else { return }
                self.secondsSinceUpdate = min(self.secondsSinceUpdate + 1, 3_600)
            }
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        tickTask?.cancel()
        tickTask = nil
    }
}
```

- [ ] **Step 9: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test
```

Expected: PASS — every package test target green.

- [ ] **Step 10: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: snapshot repository with cache fallback and observable polling store"
```

---

## Task 8: BotDesignSystem — fonts and tokens

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Resources/Fonts/*.ttf`
- Modify: `Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotColor.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotFont.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotSpacing.swift`
- Test: `Packages/TradingBotKit/Tests/BotDesignSystemTests/BotFontTests.swift`
- Modify: `Packages/TradingBotKit/Tests/BotDesignSystemTests/BotColorTests.swift`

**Interfaces:**
- Produces: `BotColor` (all palette tokens), `BotFont.registerAll()`, `BotFont.serif(_:italic:)`, `.mono(_:weight:)`, `.ui(_:weight:)` plus semantic constants, `BotSpacing`, `BotRadius`.

> **PERMISSION GATE — read before starting.** This task downloads font files. Do **not** download anything before asking the user and receiving a clear yes. State exactly this: three families from Google Fonts — **Bodoni Moda**, **Plus Jakarta Sans**, **IBM Plex Mono** — all under the SIL Open Font License, roughly 1–2 MB of `.ttf` total, fetched from `fonts.google.com`. If the user declines, stop and ask how they want to proceed rather than substituting fonts silently.

- [ ] **Step 1: Ask permission, then download the three families**

After approval:

```bash
cd /tmp
curl -L -o bodoni.zip "https://fonts.google.com/download?family=Bodoni%20Moda"
curl -L -o jakarta.zip "https://fonts.google.com/download?family=Plus%20Jakarta%20Sans"
curl -L -o plexmono.zip "https://fonts.google.com/download?family=IBM%20Plex%20Mono"
mkdir -p fontwork && cd fontwork
unzip -o ../bodoni.zip -d bodoni >/dev/null
unzip -o ../jakarta.zip -d jakarta >/dev/null
unzip -o ../plexmono.zip -d plexmono >/dev/null
find . -name "*.ttf" | sort
```

Expected: a list of `.ttf` paths. Families that ship variable fonts also include a `static/` directory — prefer those static files, they behave predictably with SwiftUI weight selection.

- [ ] **Step 2: Create the resources directory and declare it in the manifest**

```bash
mkdir -p Packages/TradingBotKit/Sources/BotDesignSystem/Resources/Fonts
```

In `Packages/TradingBotKit/Package.swift`, replace:

```swift
        // No `resources:` yet — an empty resource bundle fails codesign with
        // "bundle format unrecognized". Task 8 adds it alongside the real font files.
        .target(
            name: "BotDesignSystem",
            dependencies: ["BotDomain", "BotFormatting"]
        ),
```

with:

```swift
        .target(
            name: "BotDesignSystem",
            dependencies: ["BotDomain", "BotFormatting"],
            resources: [.process("Resources")]
        ),
```

Declaring resources is what generates `Bundle.module`, which `BotFont.registerAll()` needs. Do this only once real `.ttf` files are in place — the directory must not be empty when you next build.

- [ ] **Step 3: Copy the needed faces into the package**

Copy only the weights the design uses — Bodoni Moda regular and italic, Plus Jakarta Sans light/regular/medium/semibold, IBM Plex Mono light/regular/medium/semibold:

```bash
DEST="$OLDPWD/Packages/TradingBotKit/Sources/BotDesignSystem/Resources/Fonts"
cd /tmp/fontwork
find . -path "*static*" -name "BodoniModa*-Regular.ttf" -exec cp {} "$DEST/" \;
find . -path "*static*" -name "BodoniModa*-Italic.ttf" -exec cp {} "$DEST/" \;
find . -path "*static*" -name "PlusJakartaSans-Light.ttf" -exec cp {} "$DEST/" \;
find . -path "*static*" -name "PlusJakartaSans-Regular.ttf" -exec cp {} "$DEST/" \;
find . -path "*static*" -name "PlusJakartaSans-Medium.ttf" -exec cp {} "$DEST/" \;
find . -path "*static*" -name "PlusJakartaSans-SemiBold.ttf" -exec cp {} "$DEST/" \;
find . -name "IBMPlexMono-Light.ttf" -exec cp {} "$DEST/" \;
find . -name "IBMPlexMono-Regular.ttf" -exec cp {} "$DEST/" \;
find . -name "IBMPlexMono-Medium.ttf" -exec cp {} "$DEST/" \;
find . -name "IBMPlexMono-SemiBold.ttf" -exec cp {} "$DEST/" \;
ls -la "$DEST"
```

If a `find` matches nothing (naming varies between family releases), fall back to copying every `.ttf` from that family's `static/` directory, then delete the faces you do not need. Verify at least one file per family landed in `$DEST` before continuing.

Also copy the licence files, which the OFL requires you to ship:

```bash
find /tmp/fontwork -iname "OFL.txt" -exec sh -c 'cp "$1" "$0/OFL-$(basename $(dirname $1)).txt"' "$DEST" {} \;
ls "$DEST"
```

Remove the placeholder:

```bash
rm -f "$DEST/.gitkeep"
```

- [ ] **Step 4: Write the failing font tests**

`Packages/TradingBotKit/Tests/BotDesignSystemTests/BotFontTests.swift`:

```swift
import Testing
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import BotDesignSystem

@Test func registrationMakesEveryFamilyAvailable() {
    BotFont.registerAll()
    #expect(BotFont.isAvailable(BotFont.Family.serif))
    #expect(BotFont.isAvailable(BotFont.Family.ui))
    #expect(BotFont.isAvailable(BotFont.Family.mono))
}

@Test func registrationIsIdempotent() {
    BotFont.registerAll()
    BotFont.registerAll()
    #expect(BotFont.isAvailable(BotFont.Family.mono))
}

@Test func resolvesARegularFaceForEachFamily() {
    BotFont.registerAll()
    #expect(BotFont.postScriptName(family: BotFont.Family.mono, italic: false) != nil)
    #expect(BotFont.postScriptName(family: BotFont.Family.serif, italic: false) != nil)
    #expect(BotFont.postScriptName(family: BotFont.Family.ui, italic: false) != nil)
}

@Test func resolvesAnItalicSerifForTheNarrative() {
    BotFont.registerAll()
    let italic = BotFont.postScriptName(family: BotFont.Family.serif, italic: true)
    #expect(italic?.localizedCaseInsensitiveContains("italic") == true)
}

@Test func semanticStylesAreDistinct() {
    BotFont.registerAll()
    #expect(BotFont.heroFigure != BotFont.tabLabel)
    #expect(BotFont.screenTitle != BotFont.body)
}
```

Rewrite `Packages/TradingBotKit/Tests/BotDesignSystemTests/BotColorTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BotDesignSystem

@Test func paletteExposesEveryTokenTheDesignUses() {
    // Colours are opaque values; assert distinctness so a copy-paste slip is caught.
    let tokens: [Color] = [
        BotColor.paper, BotColor.cardTop, BotColor.cardBottom, BotColor.surface,
        BotColor.chipNeutral, BotColor.track, BotColor.inkStrong, BotColor.ink,
        BotColor.inkBody, BotColor.grey, BotColor.greyMuted, BotColor.positive,
        BotColor.negative, BotColor.accent,
    ]
    #expect(Set(tokens.map { String(describing: $0) }).count == tokens.count)
}

@Test func signColoursMapToTheDesignPalette() {
    #expect(BotColor.forSign(.positive) == BotColor.positive)
    #expect(BotColor.forSign(.negative) == BotColor.negative)
    #expect(BotColor.forSign(.flat) == BotColor.grey)
}

@Test func winRateTierColoursMatchTheDesignThresholds() {
    #expect(BotColor.forWinRateTier(.strong) == BotColor.positive)
    #expect(BotColor.forWinRateTier(.neutral) == BotColor.grey)
    #expect(BotColor.forWinRateTier(.weak) == BotColor.negative)
}
```

- [ ] **Step 5: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter BotDesignSystemTests
```

Expected: FAIL — `cannot find 'BotFont' in scope`.

- [ ] **Step 6: Write the colour tokens**

Replace `Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotColor.swift`:

```swift
import SwiftUI
import BotDomain

/// The design's palette, lifted from the mockup's hex values.
public enum BotColor {
    // Surfaces
    public static let paper = Color(hex: 0xFAF9F6)
    public static let cardTop = Color(hex: 0xFFFFFF)
    public static let cardBottom = Color(hex: 0xFBF9F5)
    public static let surface = Color(hex: 0xF7F5F1)
    public static let chipNeutral = Color(hex: 0xEDEAE4)
    public static let track = Color(hex: 0xE7E4DE)

    // Ink
    public static let inkStrong = Color(hex: 0x15171B)
    public static let ink = Color(hex: 0x23262C)
    public static let inkBody = Color(hex: 0x33373E)
    public static let grey = Color(hex: 0x5C616A)
    public static let greyMuted = Color(hex: 0x63686F)
    public static let placeholderIcon = Color(hex: 0xC3C7CD)

    // Semantic
    public static let positive = Color(hex: 0x1A7C54)
    public static let negative = Color(hex: 0xBF362C)
    public static let accent = Color(hex: 0x8C6E2A)

    /// Hairline dividers and card borders.
    public static let hairline = Color(hex: 0x16181C, opacity: 0.10)

    // Tinted chip fills, derived rather than hardcoded as separate constants.
    public static let positiveFill = positive.opacity(0.13)
    public static let negativeFill = negative.opacity(0.11)
    public static let accentFill = accent.opacity(0.09)
    public static let accentStroke = accent.opacity(0.32)

    public static func forSign(_ sign: PnLSign) -> Color {
        switch sign {
        case .positive: return positive
        case .negative: return negative
        case .flat: return grey
        }
    }

    public static func fillForSign(_ sign: PnLSign) -> Color {
        switch sign {
        case .positive: return positiveFill
        case .negative: return negativeFill
        case .flat: return chipNeutral
        }
    }

    public static func forWinRateTier(_ tier: WinRateTier) -> Color {
        switch tier {
        case .strong: return positive
        case .neutral: return grey
        case .weak: return negative
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
```

- [ ] **Step 7: Write the font tokens**

`Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotFont.swift`:

```swift
import SwiftUI
import CoreText
#if canImport(UIKit)
import UIKit
#endif

/// Typography for the app.
///
/// Faces are registered from the package bundle at runtime — SwiftPM resources cannot
/// use `UIAppFonts`. PostScript names are resolved by family so the exact file naming
/// of a Google Fonts release does not matter.
public enum BotFont {
    public enum Family {
        public static let serif = "Bodoni Moda"
        public static let ui = "Plus Jakarta Sans"
        public static let mono = "IBM Plex Mono"
    }

    private static let registrationLock = NSLock()
    nonisolated(unsafe) private static var hasRegistered = false

    /// Registers every bundled `.ttf`. Safe to call repeatedly.
    public static func registerAll() {
        registrationLock.lock()
        defer { registrationLock.unlock() }
        guard !hasRegistered else { return }
        hasRegistered = true

        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            // Already-registered fonts return false with an "already registered" error,
            // which is harmless — the goal is availability, not a clean first run.
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }

    #if canImport(UIKit)
    public static func isAvailable(_ family: String) -> Bool {
        !UIFont.fontNames(forFamilyName: family).isEmpty
    }

    /// Finds a concrete face within a family, preferring an upright regular unless
    /// italic is requested.
    public static func postScriptName(family: String, italic: Bool) -> String? {
        let names = UIFont.fontNames(forFamilyName: family)
        guard !names.isEmpty else { return nil }
        if italic {
            return names.first { $0.localizedCaseInsensitiveContains("italic") } ?? names.first
        }
        let upright = names.filter { !$0.localizedCaseInsensitiveContains("italic") }
        return upright.first { $0.localizedCaseInsensitiveContains("regular") } ?? upright.first ?? names.first
    }
    #else
    public static func isAvailable(_ family: String) -> Bool { true }
    public static func postScriptName(family: String, italic: Bool) -> String? { family }
    #endif

    // MARK: - Builders

    /// Editorial serif. `relativeTo` keeps Dynamic Type working on custom faces.
    public static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        guard let name = postScriptName(family: Family.serif, italic: italic) else {
            return .system(size: size, design: .serif)
        }
        return .custom(name, size: size, relativeTo: .title3)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let name = postScriptName(family: Family.mono, italic: false) else {
            return .system(size: size, weight: weight, design: .monospaced)
        }
        return .custom(name, size: size, relativeTo: .body).weight(weight)
    }

    public static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let name = postScriptName(family: Family.ui, italic: false) else {
            return .system(size: size, weight: weight)
        }
        return .custom(name, size: size, relativeTo: .body).weight(weight)
    }

    // MARK: - Semantic styles
    //
    // Call sites use these, never a raw family name or point size.

    public static var heroFigure: Font { mono(46, weight: .light) }
    public static var screenTitle: Font { serif(27) }
    public static var sectionTitle: Font { serif(19) }
    public static var cardTitle: Font { serif(20) }
    public static var canvasTitle: Font { serif(22) }
    public static var placeholderTitle: Font { serif(18) }
    public static var narrative: Font { serif(17, italic: true) }

    public static var tileValue: Font { mono(21) }
    public static var pnlFigure: Font { mono(14.5) }
    public static var symbol: Font { mono(14, weight: .medium) }
    public static var figure: Font { mono(13) }
    public static var figureSmall: Font { mono(12) }
    public static var metadataMono: Font { mono(10.5) }
    public static var badge: Font { mono(9.5) }
    public static var overline: Font { mono(9.5) }
    public static var tabLabel: Font { mono(9) }

    public static var body: Font { ui(13) }
    public static var listItem: Font { ui(12.5) }
    public static var caption: Font { ui(11.5) }
    public static var metadata: Font { ui(10.5) }
    public static var label: Font { ui(10) }
}
```

- [ ] **Step 8: Write the spacing tokens**

`Packages/TradingBotKit/Sources/BotDesignSystem/Tokens/BotSpacing.swift`:

```swift
import CoreGraphics

/// Spacing and radius scale taken from the mockup's measurements.
public enum BotSpacing {
    public static let screenHorizontal: CGFloat = 20
    public static let cardPadding: CGFloat = 16
    public static let tilePadding: CGFloat = 13
    public static let tileGap: CGFloat = 9
    public static let rowVertical: CGFloat = 13
    public static let sectionGap: CGFloat = 26
    public static let chartHeight: CGFloat = 148
}

public enum BotRadius {
    public static let card: CGFloat = 16
    public static let tile: CGFloat = 14
    public static let badge: CGFloat = 4
    public static let chip: CGFloat = 20
    public static let bar: CGFloat = 3
}
```

- [ ] **Step 9: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter BotDesignSystemTests
```

Expected: PASS (8 tests). If `registrationMakesEveryFamilyAvailable` fails, the family-name constants do not match what the downloaded files declare. Print the real names and correct `BotFont.Family`:

```bash
cd Packages/TradingBotKit && swift test --filter registrationMakesEveryFamilyAvailable 2>&1 | head -30
```

- [ ] **Step 10: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: design system tokens — palette, bundled editorial fonts, spacing"
```

---

## Task 9: BotDesignSystem — primitive components

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/BotCard.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/BotBadge.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/FilterChip.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/StatTile.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/SectionHeading.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/TargetRail.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/ProgressBar.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/TagChip.swift`
- Test: `Packages/TradingBotKit/Tests/BotDesignSystemTests/ComponentRenderTests.swift`

**Interfaces:**
- Produces: `BotCard<Content>`, `BotBadge`, `FilterChipView`, `StatTile`, `SectionHeading`, `TargetRail`, `ProgressBar`, `TagChip`. Every one is initialised from plain values — no ViewModel or networking type may cross into this module.

- [ ] **Step 1: Write the failing render tests**

SwiftUI views are hard to assert on directly; these tests confirm each component constructs and produces a non-empty body, which catches the common failures (missing initialiser, bad generic constraint, crash in layout maths).

`Packages/TradingBotKit/Tests/BotDesignSystemTests/ComponentRenderTests.swift`:

```swift
import Testing
import SwiftUI
import BotDomain
@testable import BotDesignSystem

@Test func cardWrapsItsContent() {
    let card = BotCard { Text("hello") }
    #expect(String(describing: type(of: card.body)).isEmpty == false)
}

@Test func badgeCarriesItsLabelAndTone() {
    let badge = BotBadge(text: "TP", tone: .positive)
    #expect(badge.text == "TP")
    #expect(badge.tone == .positive)
}

@Test func filterChipTracksSelection() {
    let selected = FilterChipView(title: "All 28", isSelected: true)
    let plain = FilterChipView(title: "BTC", isSelected: false)
    #expect(selected.isSelected)
    #expect(plain.isSelected == false)
}

@Test func statTileHoldsEveryFieldTheDesignShows() {
    let tile = StatTile(
        label: "Today P/L", value: "-$2.22",
        valueColor: BotColor.negative, subtitle: "1W / 2L · 3 trades"
    )
    #expect(tile.label == "Today P/L")
    #expect(tile.value == "-$2.22")
    #expect(tile.subtitle == "1W / 2L · 3 trades")
}

@Test func targetRailClampsTheMarkerToItsTrack() {
    #expect(TargetRail(progress: 1.4).clampedProgress == 1)
    #expect(TargetRail(progress: -0.2).clampedProgress == 0)
    #expect(abs(TargetRail(progress: 0.6657).clampedProgress - 0.6657) < 0.0001)
}

@Test func progressBarClampsItsFill() {
    #expect(ProgressBar(fraction: 2, color: BotColor.positive).clampedFraction == 1)
    #expect(ProgressBar(fraction: -1, color: BotColor.positive).clampedFraction == 0)
}

@Test func tagChipPrefixesAHash() {
    #expect(TagChip(tag: "ranging").displayText == "#ranging")
}

@Test func badgeTonesCoverEveryOutcome() {
    #expect(BotBadge(text: "TP", tone: .positive).foreground == BotColor.positive)
    #expect(BotBadge(text: "SL", tone: .negative).foreground == BotColor.negative)
    #expect(BotBadge(text: "flag", tone: .accent).foreground == BotColor.accent)
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter ComponentRenderTests
```

Expected: FAIL — `cannot find 'BotCard' in scope`.

- [ ] **Step 3: Write the card**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/BotCard.swift`:

```swift
import SwiftUI

/// The raised card used throughout the app: a subtle vertical gradient with a hairline.
public struct BotCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat

    public init(padding: CGFloat = BotSpacing.cardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [BotColor.cardTop, BotColor.cardBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                    .stroke(BotColor.hairline, lineWidth: 1)
            )
    }
}
```

- [ ] **Step 4: Write the badge and tag chip**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/BotBadge.swift`:

```swift
import SwiftUI

public enum BadgeTone: Equatable, Sendable {
    case positive, negative, accent, neutral
}

/// Small tinted pill: TP / SL, proceed / block, risk flags.
public struct BotBadge: View {
    public let text: String
    public let tone: BadgeTone

    public init(text: String, tone: BadgeTone) {
        self.text = text
        self.tone = tone
    }

    var foreground: Color {
        switch tone {
        case .positive: return BotColor.positive
        case .negative: return BotColor.negative
        case .accent: return BotColor.accent
        case .neutral: return BotColor.grey
        }
    }

    var background: Color {
        switch tone {
        case .positive: return BotColor.positiveFill
        case .negative: return BotColor.negativeFill
        case .accent: return BotColor.accentFill
        case .neutral: return BotColor.chipNeutral
        }
    }

    public var body: some View {
        Text(text)
            .font(BotFont.badge)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous))
    }
}
```

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/TagChip.swift`:

```swift
import SwiftUI

/// A `#tag` on a lesson card.
public struct TagChip: View {
    public let tag: String

    public init(tag: String) {
        self.tag = tag
    }

    var displayText: String { "#\(tag)" }

    public var body: some View {
        Text(displayText)
            .font(BotFont.badge)
            .foregroundStyle(BotColor.grey)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(BotColor.chipNeutral)
            .clipShape(RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous))
    }
}
```

- [ ] **Step 5: Write the filter chip and section heading**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/FilterChip.swift`:

```swift
import SwiftUI

/// Pill filter used on the Trades screen. Selected state is solid ink on paper text.
public struct FilterChipView: View {
    public let title: String
    public let isSelected: Bool

    public init(title: String, isSelected: Bool) {
        self.title = title
        self.isSelected = isSelected
    }

    public var body: some View {
        Text(title)
            .font(BotFont.figureSmall)
            .foregroundStyle(isSelected ? BotColor.paper : BotColor.grey)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(BotColor.ink)
                    } else {
                        Capsule().stroke(BotColor.hairline, lineWidth: 1)
                    }
                }
            )
            .contentShape(Capsule())
    }
}
```

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/SectionHeading.swift`:

```swift
import SwiftUI

/// A Bodoni section title with an optional mono counter beside it.
public struct SectionHeading: View {
    public let title: String
    public let trailing: String?

    public init(title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(title)
                .font(BotFont.sectionTitle)
                .foregroundStyle(BotColor.ink)
            if let trailing {
                Text(trailing)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.greyMuted)
            }
            Spacer(minLength: 0)
        }
    }
}

/// The uppercase gold overline above a card's contents.
public struct Overline: View {
    public let text: String
    public let color: Color

    public init(text: String, color: Color = BotColor.accent) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(BotFont.overline)
            .tracking(1.6)
            .foregroundStyle(color)
    }
}
```

- [ ] **Step 6: Write the stat tile**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/StatTile.swift`:

```swift
import SwiftUI

/// One cell of the Equity screen's 2x2 grid.
public struct StatTile: View {
    public let label: String
    public let value: String
    public let valueColor: Color
    public let subtitle: String

    public init(label: String, value: String, valueColor: Color, subtitle: String) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(BotFont.badge)
                .tracking(1.4)
                .foregroundStyle(BotColor.grey)
            Text(value)
                .font(BotFont.tileValue)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(subtitle)
                .font(BotFont.metadata)
                .foregroundStyle(BotColor.greyMuted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BotSpacing.tilePadding)
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.tile, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value), \(subtitle)")
    }
}
```

- [ ] **Step 7: Write the rail and progress bar**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/TargetRail.swift`:

```swift
import SwiftUI

/// The take-profit -> stop-loss track with an entry marker.
///
/// Always runs green (take-profit) on the left to red (stop-loss) on the right,
/// whichever side of the entry those prices sit on.
public struct TargetRail: View {
    public let progress: Double

    public init(progress: Double) {
        self.progress = progress
    }

    var clampedProgress: Double { min(max(progress, 0), 1) }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                LinearGradient(
                    stops: [
                        .init(color: BotColor.positive, location: 0),
                        .init(color: BotColor.track, location: 0.62),
                        .init(color: BotColor.track, location: 0.66),
                        .init(color: BotColor.negative, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(Capsule())

                Rectangle()
                    .fill(BotColor.inkStrong)
                    .frame(width: 2, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    .offset(x: geometry.size.width * clampedProgress - 1, y: 0)
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}
```

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/ProgressBar.swift`:

```swift
import SwiftUI

/// A thin proportional bar — breakdown magnitudes and trade confidence.
public struct ProgressBar: View {
    public let fraction: Double
    public let color: Color
    public let height: CGFloat

    public init(fraction: Double, color: Color, height: CGFloat = 4) {
        self.fraction = fraction
        self.color = color
        self.height = height
    }

    var clampedFraction: Double { min(max(fraction, 0), 1) }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(BotColor.track)
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * clampedFraction)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
```

- [ ] **Step 9: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test --filter BotDesignSystemTests
```

Expected: PASS (16 tests).

- [ ] **Step 10: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: design system primitives — card, badge, chip, tile, rail, bars"
```

---

## Task 10: BotDesignSystem — chart, state views, placeholder card

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/EquityCurveChart.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/PlaceholderCard.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/StateViews.swift`
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/BreakdownRowView.swift`
- Test: `Packages/TradingBotKit/Tests/BotDesignSystemTests/ChartAndStateTests.swift`

**Interfaces:**
- Consumes: `CurvePoint`, `BreakdownGroup` from `BotDomain`.
- Produces: `EquityCurveChart(points:)`, `PlaceholderCard(title:description:)`, `LoadingSkeleton`, `ErrorStateView(message:retry:)`, `EmptyStateView(message:)`, `OfflineBanner(message:)`, `BreakdownRowView(group:maxAbsolute:)`.

- [ ] **Step 1: Write the failing tests**

`Packages/TradingBotKit/Tests/BotDesignSystemTests/ChartAndStateTests.swift`:

```swift
import Foundation
import Testing
import BotDomain
@testable import BotDesignSystem

@Test func chartReportsWhenItHasNothingToDraw() {
    #expect(EquityCurveChart(points: []).hasData == false)
    #expect(EquityCurveChart(points: [CurvePoint(date: .init(timeIntervalSince1970: 0), equity: 1)]).hasData)
}

@Test func chartDomainSpansTheDataWithHeadroom() {
    let points = [
        CurvePoint(date: Date(timeIntervalSince1970: 0), equity: 100),
        CurvePoint(date: Date(timeIntervalSince1970: 86_400), equity: 87.26),
    ]
    let chart = EquityCurveChart(points: points)
    // Padded so the line never touches the frame edge.
    #expect(chart.yDomain.lowerBound < 87.26)
    #expect(chart.yDomain.upperBound > 100)
}

@Test func chartDomainIsStableForAFlatCurve() {
    let points = [
        CurvePoint(date: Date(timeIntervalSince1970: 0), equity: 50),
        CurvePoint(date: Date(timeIntervalSince1970: 10), equity: 50),
    ]
    let chart = EquityCurveChart(points: points)
    // A zero-range curve must still produce a valid, non-empty domain.
    #expect(chart.yDomain.lowerBound < chart.yDomain.upperBound)
}

@Test func placeholderCardCarriesTheDesignCopy() {
    let card = PlaceholderCard(
        title: "Veto log",
        description: "Logs every proceed / block decision and tracks the win rate of trades it let through."
    )
    #expect(card.title == "Veto log")
    #expect(card.notEnabledText == "NOT ENABLED YET")
}

@Test func breakdownRowComputesItsBarFromTheGroupSet() {
    let group = BreakdownGroup(key: "SOLUSDT", trades: 14, winRate: 28.6, netPnl: -18.84)
    let row = BreakdownRowView(group: group, maxAbsolute: 18.84)
    #expect(row.barFraction == 1)
    #expect(row.barColor == BotColor.negative)
    #expect(row.winRateColor == BotColor.negative)
}

@Test func breakdownRowUsesPositiveColouringForGains() {
    let group = BreakdownGroup(key: "BTCUSDT", trades: 14, winRate: 50, netPnl: 6.10)
    let row = BreakdownRowView(group: group, maxAbsolute: 18.84)
    #expect(row.barColor == BotColor.positive)
    #expect(row.winRateColor == BotColor.positive)
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter ChartAndStateTests
```

Expected: FAIL — `cannot find 'EquityCurveChart' in scope`.

- [ ] **Step 3: Write the chart**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/EquityCurveChart.swift`:

```swift
import SwiftUI
import Charts
import BotDomain

/// The equity curve: a smoothed red line under a fading fill, no axes, no interaction.
public struct EquityCurveChart: View {
    public let points: [CurvePoint]

    public init(points: [CurvePoint]) {
        self.points = points
    }

    var hasData: Bool { !points.isEmpty }

    /// Padded vertical domain so the stroke never clips against the frame.
    var yDomain: ClosedRange<Double> {
        let values = points.map(\.equity)
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        if low == high {
            let padding = max(abs(low) * 0.1, 1)
            return (low - padding)...(high + padding)
        }
        let padding = (high - low) * 0.14
        return (low - padding)...(high + padding)
    }

    public var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [BotColor.negative.opacity(0.20), BotColor.negative.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(BotColor.negative)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain)
        .chartLegend(.hidden)
        .frame(height: BotSpacing.chartHeight)
        .accessibilityLabel("Equity curve")
    }
}
```

- [ ] **Step 4: Write the breakdown row**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/BreakdownRowView.swift`:

```swift
import SwiftUI
import BotDomain
import BotFormatting

/// One line of the "By symbol" / "By regime" tables.
public struct BreakdownRowView: View {
    public let group: BreakdownGroup
    public let maxAbsolute: Double

    public init(group: BreakdownGroup, maxAbsolute: Double) {
        self.group = group
        self.maxAbsolute = maxAbsolute
    }

    var barFraction: Double { group.barFraction(relativeTo: maxAbsolute) }
    var barColor: Color { group.netPnl >= 0 ? BotColor.positive : BotColor.negative }
    var winRateColor: Color { BotColor.forWinRateTier(group.winRateTier) }

    public var body: some View {
        HStack(spacing: 12) {
            Text(group.keyDisplay)
                .font(BotFont.figureSmall)
                .foregroundStyle(BotColor.ink)
                .frame(width: 88, alignment: .leading)
                .lineLimit(1)

            Text("\(group.trades)t")
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.grey)
                .frame(width: 40, alignment: .leading)

            Text(BotFormat.percent(group.winRate))
                .font(BotFont.metadataMono)
                .foregroundStyle(winRateColor)
                .frame(width: 48, alignment: .leading)

            ProgressBar(fraction: barFraction, color: barColor)

            Text(BotFormat.signedCurrency(group.netPnl))
                .font(BotFont.figureSmall)
                .foregroundStyle(barColor)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(group.keyDisplay), \(group.trades) trades, "
            + "win rate \(BotFormat.percent(group.winRate)), "
            + "net \(BotFormat.signedCurrency(group.netPnl))"
        )
    }
}
```

- [ ] **Step 5: Write the placeholder card**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/PlaceholderCard.swift`:

```swift
import SwiftUI

/// The "Not enabled yet" card shown on Review when the AI layer is off.
public struct PlaceholderCard: View {
    public let title: String
    public let description: String

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    var notEnabledText: String { "NOT ENABLED YET" }

    public var body: some View {
        VStack(spacing: 9) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(BotColor.placeholderIcon)

            Text(title)
                .font(BotFont.placeholderTitle)
                .foregroundStyle(BotColor.grey)

            Text(notEnabledText)
                .font(BotFont.badge)
                .tracking(1.4)
                .foregroundStyle(BotColor.greyMuted)

            Text(description)
                .font(BotFont.caption)
                .foregroundStyle(BotColor.greyMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 22)
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). Not enabled yet. \(description)")
    }
}
```

- [ ] **Step 6: Write the state views**

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/StateViews.swift`:

```swift
import SwiftUI

/// Shimmer-free skeleton block used while the first load is in flight.
public struct SkeletonBlock: View {
    public let height: CGFloat
    public let width: CGFloat?

    public init(height: CGFloat, width: CGFloat? = nil) {
        self.height = height
        self.width = width
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(BotColor.track)
            .frame(width: width, height: height)
            .opacity(0.6)
    }
}

/// First-load placeholder shaped like the real screen so nothing jumps on arrival.
public struct LoadingSkeleton: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SkeletonBlock(height: 46, width: 200)
            SkeletonBlock(height: BotSpacing.chartHeight)
            HStack(spacing: BotSpacing.tileGap) {
                SkeletonBlock(height: 84)
                SkeletonBlock(height: 84)
            }
            HStack(spacing: BotSpacing.tileGap) {
                SkeletonBlock(height: 84)
                SkeletonBlock(height: 84)
            }
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .accessibilityLabel("Loading")
        .accessibilityIdentifier("state.loading")
    }
}

public struct ErrorStateView: View {
    public let message: String
    public let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(BotColor.negative)
            Text("Could not load")
                .font(BotFont.placeholderTitle)
                .foregroundStyle(BotColor.ink)
            Text(message)
                .font(BotFont.caption)
                .foregroundStyle(BotColor.greyMuted)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .font(BotFont.figureSmall)
                .foregroundStyle(BotColor.paper)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(BotColor.ink))
                .accessibilityIdentifier("state.retry")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(BotSpacing.screenHorizontal)
        .accessibilityIdentifier("state.error")
    }
}

public struct EmptyStateView: View {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        Text(message)
            .font(BotFont.caption)
            .foregroundStyle(BotColor.greyMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .accessibilityIdentifier("state.empty")
    }
}

/// Non-blocking strip shown when the data on screen came from cache.
public struct OfflineBanner: View {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 10))
            Text(message)
                .font(BotFont.metadata)
            Spacer(minLength: 0)
        }
        .foregroundStyle(BotColor.accent)
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, 7)
        .background(BotColor.accentFill)
        .accessibilityIdentifier("state.offline")
    }
}
```

- [ ] **Step 7: Run to verify pass**

```bash
cd Packages/TradingBotKit && swift test
```

Expected: PASS — every package test target green (22 design-system tests plus all earlier ones).

- [ ] **Step 8: Commit**

```bash
git add Packages/TradingBotKit
git commit -m "feat: equity chart, breakdown row, placeholder and state views"
```

---

## Task 11: App shell — tab bar, composition root, fixture injection

**Files:**
- Create: `Packages/TradingBotKit/Sources/BotDesignSystem/Components/BotTabBar.swift`
- Create: `TradingBot/AppContainer.swift`
- Modify: `TradingBot/RootTabView.swift`
- Modify: `TradingBot/TradingBotApp.swift`
- Create: `TradingBot/Resources/snapshot-ai-null.json`
- Create: `TradingBot/Resources/snapshot-empty.json`
- Test: `Packages/TradingBotKit/Tests/BotDesignSystemTests/BotTabBarTests.swift`
- Test: `TradingBotTests/AppContainerTests.swift`
- Delete: `TradingBotTests/AppLinkageTests.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `SnapshotRepository`, `BundledSnapshotProvider`, `SnapshotCache`, design system components.
- Produces: `BotTabItem`, `BotTabBar(items:selection:)`, `AppTab` enum (`equity`, `trades`, `review`), `AppContainer` with `store: SnapshotStore` and `static func fixtureName(from arguments: [String]) -> String?`.

**Fixture injection:** UI tests must be deterministic, so the app selects its data source from a launch argument. `-fixture full` (default), `-fixture aiNull`, `-fixture empty`, `-fixture error`. Nothing else in the app branches on this.

- [ ] **Step 1: Write the failing tab bar tests**

`Packages/TradingBotKit/Tests/BotDesignSystemTests/BotTabBarTests.swift`:

```swift
import Testing
import SwiftUI
@testable import BotDesignSystem

@Test func tabItemsKeepTheirIdentity() {
    let item = BotTabItem(id: "equity", title: "EQUITY", systemImage: "chart.line.uptrend.xyaxis")
    #expect(item.id == "equity")
    #expect(item.title == "EQUITY")
}

@Test func tabBarTintsOnlyTheSelectedItem() {
    let items = [
        BotTabItem(id: "equity", title: "EQUITY", systemImage: "chart.line.uptrend.xyaxis"),
        BotTabItem(id: "trades", title: "TRADES", systemImage: "line.3.horizontal"),
    ]
    let bar = BotTabBar(items: items, selection: .constant("equity"))
    #expect(bar.color(for: items[0]) == BotColor.accent)
    #expect(bar.color(for: items[1]) == BotColor.greyMuted)
}
```

- [ ] **Step 2: Run to verify failure**

```bash
cd Packages/TradingBotKit && swift test --filter BotTabBarTests
```

Expected: FAIL — `cannot find 'BotTabItem' in scope`.

- [ ] **Step 3: Write the tab bar**

The stock `TabView` bar cannot render 9pt uppercase mono labels, so the app draws its own.

`Packages/TradingBotKit/Sources/BotDesignSystem/Components/BotTabBar.swift`:

```swift
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
```

- [ ] **Step 4: Write the extra fixture resources**

`TradingBot/Resources/snapshot-ai-null.json` — same shape, review layer off:

```json
{
  "generated_at": "2026-06-30T15:22:45Z",
  "summary": {
    "balance": 87.26, "equity": 116.40, "open": 1, "total": 28,
    "wins": 11, "losses": 17, "win_rate": 39.3, "total_pnl": -12.74,
    "today_total": 3, "today_wins": 1, "today_losses": 2, "today_pnl": -2.22
  },
  "curve": [
    { "t": "2026-06-20", "equity": 100.00 },
    { "t": "2026-06-23", "equity": 96.94 },
    { "t": "2026-06-26", "equity": 101.50 },
    { "t": "2026-06-28", "equity": 89.25 },
    { "t": "2026-06-30", "equity": 87.26 }
  ],
  "open_positions": [
    {
      "pair": "SOLUSDT", "direction": "short", "entry_price": 73.10, "quantity": 0.8,
      "leverage": 2, "margin": 29.24, "take_profit": 70.91, "stop_loss": 74.20,
      "timestamp": "2026-06-30T14:00:00Z", "exchange_stops": true
    }
  ],
  "closed_trades": [
    { "closed_at": "2026-06-30T14:31:00Z", "pair": "SOLUSDT", "direction": "short", "entry_price": 72.95, "exit_price": 71.85, "quantity": 1.2, "pnl": -1.99, "status": "closed_sl", "regime": "ranging", "confidence": 7, "timestamp": "2026-06-30T12:05:00Z" },
    { "closed_at": "2026-06-30T13:10:00Z", "pair": "BTCUSDT", "direction": "short", "entry_price": 58800.0, "exit_price": 58288.8, "quantity": 0.001, "pnl": 1.76, "status": "closed_tp", "regime": "trending_down", "confidence": 8, "timestamp": "2026-06-30T10:40:00Z" }
  ],
  "by_symbol": [
    { "key": "BTCUSDT", "trades": 14, "win_rate": 50.0, "net_pnl": 6.10 },
    { "key": "SOLUSDT", "trades": 14, "win_rate": 28.6, "net_pnl": -18.84 }
  ],
  "by_regime": [
    { "key": "trending_up", "trades": 6, "win_rate": 66.7, "net_pnl": 8.20 },
    { "key": "ranging", "trades": 13, "win_rate": 23.1, "net_pnl": -22.99 }
  ],
  "ai_report": null,
  "veto": null,
  "lessons": null
}
```

`TradingBot/Resources/snapshot-empty.json` — a live bot with no history yet:

```json
{
  "generated_at": "2026-06-30T15:22:45Z",
  "summary": {
    "balance": 100.00, "equity": 100.00, "open": 0, "total": 0,
    "wins": 0, "losses": 0, "win_rate": 0.0, "total_pnl": 0.0,
    "today_total": 0, "today_wins": 0, "today_losses": 0, "today_pnl": 0.0
  },
  "curve": [],
  "open_positions": [],
  "closed_trades": [],
  "by_symbol": [],
  "by_regime": [],
  "ai_report": null,
  "veto": null,
  "lessons": null
}
```

- [ ] **Step 5: Write the failing container tests**

Delete the placeholder linkage test and replace it:

```bash
rm TradingBotTests/AppLinkageTests.swift
```

`TradingBotTests/AppContainerTests.swift`:

```swift
import Testing
import BotDataKit
@testable import TradingBot

@Test func defaultsToTheFullFixtureWhenNoArgumentIsGiven() {
    #expect(AppContainer.fixtureName(from: []) == nil)
}

@Test func readsTheFixtureNameFromLaunchArguments() {
    #expect(AppContainer.fixtureName(from: ["-fixture", "aiNull"]) == "aiNull")
    #expect(AppContainer.fixtureName(from: ["-fixture", "empty"]) == "empty")
    #expect(AppContainer.fixtureName(from: ["-fixture", "error"]) == "error")
}

@Test func ignoresATrailingFixtureFlagWithNoValue() {
    #expect(AppContainer.fixtureName(from: ["-fixture"]) == nil)
}

@Test func mapsFixtureNamesToBundledResources() {
    #expect(AppContainer.resourceName(for: nil) == "snapshot")
    #expect(AppContainer.resourceName(for: "full") == "snapshot")
    #expect(AppContainer.resourceName(for: "aiNull") == "snapshot-ai-null")
    #expect(AppContainer.resourceName(for: "empty") == "snapshot-empty")
}

@MainActor
@Test func containerBuildsAStoreThatLoadsTheDefaultSnapshot() async {
    let container = AppContainer(arguments: [])
    await container.store.refresh()
    #expect(container.store.state.value?.summary.total == 28)
}

@MainActor
@Test func errorFixtureProducesAFailedStore() async {
    let container = AppContainer(arguments: ["-fixture", "error"])
    await container.store.refresh()
    #expect(container.store.state.value == nil)
    #expect(container.store.state.error != nil)
}

@MainActor
@Test func aiNullFixtureLoadsASnapshotWithoutAReviewLayer() async {
    let container = AppContainer(arguments: ["-fixture", "aiNull"])
    await container.store.refresh()
    #expect(container.store.state.value?.hasReviewLayer == false)
}
```

- [ ] **Step 6: Write the composition root**

`TradingBot/AppContainer.swift`:

```swift
import Foundation
import BotDataKit
import BotDomain

/// A provider that always fails, used only by the `error` UI-test fixture.
private struct FailingSnapshotProvider: SnapshotProvider {
    func fetchPayload() async throws -> Data {
        throw SnapshotError.offline
    }
}

/// The one place that decides where data comes from.
///
/// Pointing the app at the real dashboard is a change here and nowhere else:
/// swap `BundledSnapshotProvider` for `RemoteSnapshotProvider(baseURL:)`.
@MainActor
final class AppContainer {
    let store: SnapshotStore

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let fixture = Self.fixtureName(from: arguments)
        let provider: any SnapshotProvider = fixture == "error"
            ? FailingSnapshotProvider()
            : BundledSnapshotProvider(
                resource: Self.resourceName(for: fixture),
                bundle: .main
              )

        // UI-test runs must not reuse a cache from a previous fixture.
        let cache = fixture == nil
            ? SnapshotCache.makeDefault()
            : SnapshotCache(
                directory: FileManager.default.temporaryDirectory
                    .appendingPathComponent("uitest-\(fixture!)")
              )

        self.store = SnapshotStore(
            repository: SnapshotRepository(provider: provider, cache: cache)
        )
    }

    /// Reads `-fixture <name>` from launch arguments. Returns nil when absent.
    static func fixtureName(from arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: "-fixture"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        return arguments[arguments.index(after: index)]
    }

    static func resourceName(for fixture: String?) -> String {
        switch fixture {
        case "aiNull": return "snapshot-ai-null"
        case "empty": return "snapshot-empty"
        default: return "snapshot"
        }
    }
}
```

For the `error` fixture the cache must also start empty — the temporary directory above guarantees that, since the repository would otherwise fall back to a cached snapshot and the failed state would never be reachable.

- [ ] **Step 7: Wire the root view**

Replace `TradingBot/RootTabView.swift`:

```swift
import SwiftUI
import BotDataKit
import BotDesignSystem

enum AppTab: String, CaseIterable {
    case equity, trades, review

    var item: BotTabItem {
        switch self {
        case .equity:
            return BotTabItem(id: rawValue, title: "EQUITY", systemImage: "chart.line.uptrend.xyaxis")
        case .trades:
            return BotTabItem(id: rawValue, title: "TRADES", systemImage: "line.3.horizontal")
        case .review:
            return BotTabItem(id: rawValue, title: "REVIEW", systemImage: "star")
        }
    }
}

struct RootTabView: View {
    let store: SnapshotStore
    @State private var selection = AppTab.equity.rawValue

    var body: some View {
        ZStack {
            BotColor.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch AppTab(rawValue: selection) ?? .equity {
                    case .equity: EquityView(store: store)
                    case .trades: TradesView(store: store)
                    case .review: ReviewView(store: store)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                BotTabBar(items: AppTab.allCases.map(\.item), selection: $selection)
            }
        }
        .task {
            store.startPolling(interval: .seconds(30))
        }
        .onDisappear {
            store.stopPolling()
        }
    }
}
```

Replace `TradingBot/TradingBotApp.swift`:

```swift
import SwiftUI
import BotDesignSystem

@main
struct TradingBotApp: App {
    @State private var container = AppContainer()

    init() {
        // Custom faces ship in the package bundle, so they need runtime registration.
        BotFont.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(store: container.store)
        }
    }
}
```

- [ ] **Step 8: Create the three feature views as stubs so the shell compiles**

These are replaced with real screens in Tasks 12–14. Create each file now with just enough to build:

`TradingBot/Features/Equity/EquityView.swift`:

```swift
import SwiftUI
import BotDataKit

struct EquityView: View {
    let store: SnapshotStore
    var body: some View {
        Text("Equity").accessibilityIdentifier("screen.equity")
    }
}
```

`TradingBot/Features/Trades/TradesView.swift`:

```swift
import SwiftUI
import BotDataKit

struct TradesView: View {
    let store: SnapshotStore
    var body: some View {
        Text("Trades").accessibilityIdentifier("screen.trades")
    }
}
```

`TradingBot/Features/Review/ReviewView.swift`:

```swift
import SwiftUI
import BotDataKit

struct ReviewView: View {
    let store: SnapshotStore
    var body: some View {
        Text("Review").accessibilityIdentifier("screen.review")
    }
}
```

- [ ] **Step 9: Update the launch UI test for the new shell**

Replace `TradingBotUITests/LaunchUITests.swift`:

```swift
import XCTest

final class LaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testLaunchesOnTheEquityTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", "full"]
        app.launch()
        XCTAssertTrue(app.buttons["tab.equity"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tab.trades"].exists)
        XCTAssertTrue(app.buttons["tab.review"].exists)
    }

    func testSwitchesBetweenAllThreeTabs() {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", "full"]
        app.launch()
        XCTAssertTrue(app.buttons["tab.trades"].waitForExistence(timeout: 10))

        app.buttons["tab.trades"].tap()
        XCTAssertTrue(app.staticTexts["screen.trades"].waitForExistence(timeout: 5))

        app.buttons["tab.review"].tap()
        XCTAssertTrue(app.staticTexts["screen.review"].waitForExistence(timeout: 5))

        app.buttons["tab.equity"].tap()
        XCTAssertTrue(app.staticTexts["screen.equity"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 10: Run the full scheme**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: **TEST SUCCEEDED** — package tests, 7 container tests, 2 UI tests.

- [ ] **Step 11: Commit**

```bash
git add Packages TradingBot TradingBotTests TradingBotUITests
git commit -m "feat: custom tab bar, composition root, fixture injection, app shell"
```

---

## Task 12: Equity screen

**Files:**
- Create: `TradingBot/Features/Equity/EquityViewModel.swift`
- Modify: `TradingBot/Features/Equity/EquityView.swift`
- Create: `TradingBot/Features/Equity/OpenPositionCard.swift`
- Create: `TradingBot/Features/Equity/StatusHeaderBar.swift`
- Test: `TradingBotTests/EquityViewModelTests.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `BotFormat`, design system components, `Position.railProgress`.
- Produces: `EquityViewModel(store:)` exposing `equityFigure`, `totalPnlText`, `totalPnlSign`, `subtitleText`, `tiles: [TileData]`, `curvePoints`, `curveFromLabel`, `curveToLabel`, `openPosition: PositionPresentation?`, `openCountText`.

- [ ] **Step 1: Write the failing ViewModel tests**

`TradingBotTests/EquityViewModelTests.swift`:

```swift
import Foundation
import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func loadedViewModel(fixture: String? = nil) async -> EquityViewModel {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return EquityViewModel(store: container.store)
}

@MainActor
@Test func rendersTheHeroEquityFigure() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.equityFigure == "$116.40")
    #expect(viewModel.totalPnlText == "-$12.74")
    #expect(viewModel.totalPnlSign == .negative)
    #expect(viewModel.subtitleText == "all-time · 28 trades")
}

@MainActor
@Test func buildsTheFourStatTilesInDesignOrder() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.tiles.count == 4)

    #expect(viewModel.tiles[0].label == "Balance")
    #expect(viewModel.tiles[0].value == "$87.26")
    #expect(viewModel.tiles[0].subtitle == "realized cash")

    #expect(viewModel.tiles[1].label == "Today P/L")
    #expect(viewModel.tiles[1].value == "-$2.22")
    #expect(viewModel.tiles[1].subtitle == "1W / 2L · 3 trades")

    #expect(viewModel.tiles[2].label == "Win rate")
    #expect(viewModel.tiles[2].value == "39.3%")
    #expect(viewModel.tiles[2].subtitle == "11 of 28 closed")

    // Reserved is the sum of open-position margin, not a wire field.
    #expect(viewModel.tiles[3].label == "Reserved")
    #expect(viewModel.tiles[3].value == "$29.24")
    #expect(viewModel.tiles[3].subtitle == "1 position margin")
}

@MainActor
@Test func labelsTheCurveEndpoints() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.curvePoints.count == 5)
    #expect(viewModel.curveFromLabel == "Jun 20  $100.00")
    #expect(viewModel.curveToLabel == "Jun 30  $87.26")
}

@MainActor
@Test func presentsTheOpenPosition() async {
    let viewModel = await loadedViewModel()
    let position = try! #require(viewModel.openPosition)
    #expect(position.pair == "SOLUSDT")
    #expect(position.directionLabel == "▼ SHORT")
    #expect(position.leverageText == "2×")
    #expect(position.takeProfitText == "TP 70.91")
    #expect(position.entryText == "entry 73.10")
    #expect(position.stopLossText == "SL 74.20")
    #expect(position.quantityText == "0.80")
    #expect(position.marginText == "$29.24")
    #expect(position.stopsText == "on exchange")
    #expect(abs(position.railProgress - 0.6657) < 0.001)
    #expect(viewModel.openCountText == "1 live")
}

@MainActor
@Test func hasNoOpenPositionWhenTheBotIsFlat() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    #expect(viewModel.openPosition == nil)
    #expect(viewModel.openCountText == "0 live")
    #expect(viewModel.curvePoints.isEmpty)
}

@MainActor
@Test func reservedIsZeroWithNoOpenPositions() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    #expect(viewModel.tiles[3].value == "$0.00")
    #expect(viewModel.tiles[3].subtitle == "0 position margin")
}

@MainActor
@Test func exposesTheStoresLoadState() async {
    let container = AppContainer(arguments: ["-fixture", "error"])
    await container.store.refresh()
    let viewModel = EquityViewModel(store: container.store)
    #expect(viewModel.snapshot == nil)
    #expect(viewModel.errorMessage != nil)
}
```

- [ ] **Step 2: Run to verify failure**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotTests/EquityViewModelTests
```

Expected: FAIL — `cannot find 'EquityViewModel' in scope`.

- [ ] **Step 3: Write the ViewModel**

`TradingBot/Features/Equity/EquityViewModel.swift`:

```swift
import Foundation
import Observation
import BotDataKit
import BotDomain
import BotFormatting

struct TileData: Identifiable, Equatable {
    let label: String
    let value: String
    let sign: PnLSign
    let isAccent: Bool
    let subtitle: String

    var id: String { label }
}

struct PositionPresentation: Equatable {
    let pair: String
    let directionLabel: String
    let directionSign: PnLSign
    let leverageText: String
    let elapsedText: String
    let takeProfitText: String
    let entryText: String
    let stopLossText: String
    let railProgress: Double
    let quantityText: String
    let marginText: String
    let stopsText: String
}

/// Everything the Equity screen renders, pre-formatted. The View does no maths.
@MainActor
@Observable
final class EquityViewModel {
    private let store: SnapshotStore

    init(store: SnapshotStore) {
        self.store = store
    }

    var snapshot: Snapshot? { store.state.value }
    var isLoading: Bool { store.state.isLoading && snapshot == nil }
    var isStale: Bool { store.isStale }
    var errorMessage: String? {
        guard snapshot == nil else { return store.lastErrorMessage }
        guard let error = store.state.error else { return nil }
        return (error as? SnapshotError)?.userMessage ?? error.localizedDescription
    }

    var freshnessText: String { BotFormat.freshness(seconds: store.secondsSinceUpdate) }

    // MARK: - Hero

    var equityFigure: String { BotFormat.currency(snapshot?.summary.equity ?? 0) }
    var totalPnlText: String { BotFormat.signedCurrency(snapshot?.summary.totalPnl) }
    var totalPnlSign: PnLSign { PnLSign.of(snapshot?.summary.totalPnl ?? 0) }
    var subtitleText: String { "all-time · \(snapshot?.summary.total ?? 0) trades" }

    // MARK: - Curve

    var curvePoints: [CurvePoint] { snapshot?.curve ?? [] }

    var curveFromLabel: String {
        guard let first = curvePoints.first else { return "" }
        return "\(BotFormat.day(first.date))  \(BotFormat.currency(first.equity))"
    }

    var curveToLabel: String {
        guard let last = curvePoints.last else { return "" }
        return "\(BotFormat.day(last.date))  \(BotFormat.currency(last.equity))"
    }

    // MARK: - Tiles

    /// Reserved is derived — the sum of margin across open positions, not a wire field.
    private var reservedMargin: Double {
        (snapshot?.openPositions ?? []).reduce(0) { $0 + $1.margin }
    }

    var tiles: [TileData] {
        guard let summary = snapshot?.summary else { return [] }
        return [
            TileData(
                label: "Balance",
                value: BotFormat.currency(summary.balance),
                sign: .flat, isAccent: false,
                subtitle: "realized cash"
            ),
            TileData(
                label: "Today P/L",
                value: BotFormat.signedCurrency(summary.todayPnl),
                sign: PnLSign.of(summary.todayPnl), isAccent: false,
                subtitle: "\(summary.todayWins)W / \(summary.todayLosses)L · \(summary.todayTotal) trades"
            ),
            TileData(
                label: "Win rate",
                value: BotFormat.percent(summary.winRate),
                sign: .flat, isAccent: false,
                subtitle: "\(summary.wins) of \(summary.total) closed"
            ),
            TileData(
                label: "Reserved",
                value: BotFormat.currency(reservedMargin),
                sign: .flat, isAccent: true,
                subtitle: "\(summary.open) position margin"
            ),
        ]
    }

    // MARK: - Open position

    var openCountText: String { "\(snapshot?.summary.open ?? 0) live" }

    var openPosition: PositionPresentation? {
        guard let position = snapshot?.openPositions.first else { return nil }
        let isLong = position.direction == .long
        return PositionPresentation(
            pair: position.pair,
            directionLabel: isLong ? "▲ LONG" : "▼ SHORT",
            directionSign: isLong ? .positive : .negative,
            leverageText: BotFormat.leverage(position.leverage),
            elapsedText: BotFormat.duration(
                (snapshot?.generatedAt ?? position.openedAt)
                    .timeIntervalSince(position.openedAt)
            ),
            takeProfitText: "TP \(BotFormat.price(position.takeProfit))",
            entryText: "entry \(BotFormat.price(position.entryPrice))",
            stopLossText: "SL \(BotFormat.price(position.stopLoss))",
            railProgress: position.railProgress,
            quantityText: BotFormat.quantity(position.quantity),
            marginText: BotFormat.currency(position.margin),
            stopsText: position.exchangeStops ? "on exchange" : "local"
        )
    }

    func refresh() async {
        await store.refresh()
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotTests/EquityViewModelTests
```

Expected: PASS (8 tests).

- [ ] **Step 5: Write the status header**

`TradingBot/Features/Equity/StatusHeaderBar.swift`:

```swift
import SwiftUI
import BotDesignSystem

/// Live dot, bot identity, exchange, freshness, refresh affordance.
struct StatusHeaderBar: View {
    let freshnessText: String
    let refresh: () async -> Void

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(BotColor.positive)
                .frame(width: 7, height: 7)
                .overlay(
                    Circle().stroke(BotColor.positive.opacity(0.15), lineWidth: 3)
                )
                .accessibilityHidden(true)

            Text("bot")
                .font(BotFont.figureSmall)
                .foregroundStyle(BotColor.ink)

            Text("· binance futures")
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.greyMuted)

            Spacer(minLength: 0)

            Text(freshnessText)
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.greyMuted)
                .accessibilityLabel("Updated \(freshnessText)")

            Button {
                Task { await refresh() }
            } label: {
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BotColor.grey)
            }
            .accessibilityLabel("Refresh")
            .accessibilityIdentifier("header.refresh")
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, 12)
    }
}
```

- [ ] **Step 6: Write the open position card**

`TradingBot/Features/Equity/OpenPositionCard.swift`:

```swift
import SwiftUI
import BotDesignSystem

struct OpenPositionCard: View {
    let position: PositionPresentation

    var body: some View {
        BotCard(padding: 15) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 9) {
                    Text(position.pair)
                        .font(BotFont.symbol)
                        .foregroundStyle(BotColor.inkStrong)
                    BotBadge(
                        text: position.directionLabel,
                        tone: position.directionSign == .positive ? .positive : .negative
                    )
                    Text(position.leverageText)
                        .font(BotFont.metadataMono)
                        .foregroundStyle(BotColor.grey)
                    Spacer(minLength: 0)
                    Text(position.elapsedText)
                        .font(BotFont.metadataMono)
                        .foregroundStyle(BotColor.greyMuted)
                }
                .padding(.bottom, 14)

                HStack {
                    Text(position.takeProfitText)
                        .foregroundStyle(BotColor.positive)
                    Spacer()
                    Text(position.entryText)
                        .foregroundStyle(BotColor.grey)
                    Spacer()
                    Text(position.stopLossText)
                        .foregroundStyle(BotColor.negative)
                }
                .font(BotFont.badge)
                .tracking(1)
                .padding(.bottom, 6)

                TargetRail(progress: position.railProgress)
                    .padding(.bottom, 16)

                HStack(alignment: .top, spacing: 12) {
                    detail("Quantity", position.quantityText, color: BotColor.ink)
                    detail("Margin", position.marginText, color: BotColor.ink)
                    detail("Stops", position.stopsText, color: BotColor.positive)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("equity.openPosition")
    }

    private func detail(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(BotFont.label)
                .foregroundStyle(BotColor.grey)
            Text(value)
                .font(BotFont.figure)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 7: Write the screen**

Replace `TradingBot/Features/Equity/EquityView.swift`:

```swift
import SwiftUI
import BotDataKit
import BotDesignSystem

struct EquityView: View {
    @State private var viewModel: EquityViewModel

    init(store: SnapshotStore) {
        _viewModel = State(initialValue: EquityViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            StatusHeaderBar(freshnessText: viewModel.freshnessText) {
                await viewModel.refresh()
            }

            // Data is on screen but the last load did not fully succeed — either it
            // came from cache, or a background refresh failed. Never blocks the UI.
            if viewModel.snapshot != nil, let message = viewModel.errorMessage {
                OfflineBanner(message: message)
            }

            content
        }
        .background(BotColor.paper)
        .accessibilityIdentifier("screen.equity")
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingSkeleton()
            Spacer()
        } else if viewModel.snapshot == nil, let message = viewModel.errorMessage {
            ErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    chart
                    tiles
                    openPositionSection
                }
                .padding(.horizontal, BotSpacing.screenHorizontal)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Overline(text: "Equity", color: BotColor.grey)
                .padding(.top, 18)
                .padding(.bottom, 10)

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(viewModel.equityFigure)
                    .font(BotFont.heroFigure)
                    .tracking(-2)
                    .foregroundStyle(BotColor.inkStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityIdentifier("equity.figure")
                Text("USDT")
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.grey)
            }

            HStack(spacing: 8) {
                Text(viewModel.totalPnlText)
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.forSign(viewModel.totalPnlSign))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BotColor.fillForSign(viewModel.totalPnlSign))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(viewModel.subtitleText)
                    .font(BotFont.caption)
                    .foregroundStyle(BotColor.grey)
            }
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var chart: some View {
        if viewModel.curvePoints.isEmpty {
            EmptyStateView(message: "No equity history yet.")
        } else {
            EquityCurveChart(points: viewModel.curvePoints)
                .padding(.top, 18)

            HStack {
                Text(viewModel.curveFromLabel)
                Spacer()
                Text(viewModel.curveToLabel)
            }
            .font(BotFont.badge)
            .foregroundStyle(BotColor.greyMuted)
            .padding(.bottom, 20)
            .overlay(alignment: .bottom) {
                Rectangle().fill(BotColor.hairline).frame(height: 1)
            }
        }
    }

    private var tiles: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: BotSpacing.tileGap),
                GridItem(.flexible(), spacing: BotSpacing.tileGap),
            ],
            spacing: BotSpacing.tileGap
        ) {
            ForEach(viewModel.tiles) { tile in
                StatTile(
                    label: tile.label,
                    value: tile.value,
                    valueColor: color(for: tile),
                    subtitle: tile.subtitle
                )
            }
        }
        .padding(.top, 20)
    }

    /// Balance and Win rate carry no sign tint — the design renders them in ink.
    /// Only Today P/L is sign-tinted, and only Reserved is gold.
    private func color(for tile: TileData) -> Color {
        if tile.isAccent { return BotColor.accent }
        return tile.sign == .flat ? BotColor.ink : BotColor.forSign(tile.sign)
    }

    @ViewBuilder
    private var openPositionSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text("Open position")
                .font(BotFont.sectionTitle)
                .foregroundStyle(BotColor.ink)
            Text(viewModel.openCountText)
                .font(BotFont.metadataMono)
                .foregroundStyle(BotColor.greyMuted)
            Spacer(minLength: 0)
        }
        .padding(.top, BotSpacing.sectionGap)
        .padding(.bottom, 11)

        if let position = viewModel.openPosition {
            OpenPositionCard(position: position)
        } else {
            EmptyStateView(message: "No position open.")
        }
    }
}
```

- [ ] **Step 8: Run the full scheme**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: **TEST SUCCEEDED**.

- [ ] **Step 10: Commit**

```bash
git add TradingBot TradingBotTests
git commit -m "feat: equity screen with hero figure, curve, stat tiles, open position"
```

---

## Task 13: Trades screen

**Files:**
- Create: `TradingBot/Features/Trades/TradesViewModel.swift`
- Modify: `TradingBot/Features/Trades/TradesView.swift`
- Create: `TradingBot/Features/Trades/TradeRowView.swift`
- Test: `TradingBotTests/TradesViewModelTests.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `TradeFilter`, `BreakdownGroup`, `BotFormat`, design system.
- Produces: `TradesViewModel(store:)` exposing `filters: [TradeFilter]`, `selectedFilter`, `chipTitle(for:)`, `rows: [TradeRowPresentation]`, `tallyText`, `bySymbol`, `byRegime`, `symbolMaxAbsolute`, `regimeMaxAbsolute`, `select(_:)`.

- [ ] **Step 1: Write the failing tests**

`TradingBotTests/TradesViewModelTests.swift`:

```swift
import Foundation
import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func loadedViewModel(fixture: String? = nil) async -> TradesViewModel {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return TradesViewModel(store: container.store)
}

@MainActor
@Test func showsEveryTradeByDefault() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.selectedFilter == .all)
    #expect(viewModel.rows.count == 9)
}

@MainActor
@Test func tallyCountsWinsAndLossesFromTheSummary() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.winsText == "11W")
    #expect(viewModel.lossesText == "17L")
}

@MainActor
@Test func theAllChipCarriesTheDerivedCount() async {
    let viewModel = await loadedViewModel()
    // 9 trades in the payload — the chip must not hardcode the design's "28".
    #expect(viewModel.chipTitle(for: .all) == "All 9")
    #expect(viewModel.chipTitle(for: .symbol("BTC")) == "BTC")
    #expect(viewModel.chipTitle(for: .losses) == "Losses")
}

@MainActor
@Test func filteringBySymbolNarrowsTheRows() async {
    let viewModel = await loadedViewModel()
    viewModel.select(.symbol("SOL"))
    #expect(viewModel.rows.count == 5)
    #expect(viewModel.rows.allSatisfy { $0.pair == "SOLUSDT" })

    viewModel.select(.symbol("BTC"))
    #expect(viewModel.rows.count == 4)
}

@MainActor
@Test func filteringByLossesKeepsOnlyNegatives() async {
    let viewModel = await loadedViewModel()
    viewModel.select(.losses)
    #expect(viewModel.rows.count == 5)
    #expect(viewModel.rows.allSatisfy { $0.pnlSign == .negative })
}

@MainActor
@Test func rowsAreSortedNewestFirst() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.rows.first?.dateText == "Jun 30 14:31")
    #expect(viewModel.rows.last?.dateText == "Jun 27 08:35")
}

@MainActor
@Test func rowPresentationMatchesTheDesign() async {
    let viewModel = await loadedViewModel()
    let row = try! #require(viewModel.rows.first)
    #expect(row.pair == "SOLUSDT")
    #expect(row.directionLabel == "▼ SHORT")
    #expect(row.outcomeLabel == "SL")
    #expect(row.pnlText == "-$1.99")
    #expect(row.priceText == "72.95 → 71.85")
    #expect(row.holdText == "2h 26m")
    #expect(row.regimeText == "ranging")
    #expect(abs(row.confidenceFraction - 0.7) < 0.0001)
}

@MainActor
@Test func widePricesDropTheirDecimals() async {
    let viewModel = await loadedViewModel()
    let btc = try! #require(viewModel.rows.first { $0.pair == "BTCUSDT" })
    #expect(btc.priceText == "58,800 → 58,289")
}

@MainActor
@Test func breakdownsCarryTheirNormalisationBase() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.bySymbol.count == 2)
    #expect(viewModel.symbolMaxAbsolute == 18.84)
    #expect(viewModel.byRegime.count == 3)
    #expect(viewModel.regimeMaxAbsolute == 22.99)
}

@MainActor
@Test func emptyHistoryProducesNoRowsAndNoBreakdowns() async {
    let viewModel = await loadedViewModel(fixture: "empty")
    #expect(viewModel.rows.isEmpty)
    #expect(viewModel.bySymbol.isEmpty)
    #expect(viewModel.chipTitle(for: .all) == "All 0")
}

@MainActor
@Test func aFilterMatchingNothingYieldsAnEmptyRowSet() async {
    let viewModel = await loadedViewModel()
    viewModel.select(.symbol("DOGE"))
    #expect(viewModel.rows.isEmpty)
    #expect(viewModel.isFilteredEmpty)
}
```

- [ ] **Step 2: Run to verify failure**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotTests/TradesViewModelTests
```

Expected: FAIL — `cannot find 'TradesViewModel' in scope`.

- [ ] **Step 3: Write the ViewModel**

`TradingBot/Features/Trades/TradesViewModel.swift`:

```swift
import Foundation
import Observation
import BotDataKit
import BotDomain
import BotFormatting

struct TradeRowPresentation: Identifiable, Equatable {
    let id: String
    let pair: String
    let directionLabel: String
    let directionSign: PnLSign
    let outcomeLabel: String
    let outcomeIsWin: Bool
    let pnlText: String
    let pnlSign: PnLSign
    let dateText: String
    let priceText: String
    let holdText: String
    let regimeText: String
    let confidenceFraction: Double
}

@MainActor
@Observable
final class TradesViewModel {
    private let store: SnapshotStore
    private(set) var selectedFilter: TradeFilter = .all

    init(store: SnapshotStore) {
        self.store = store
    }

    var snapshot: Snapshot? { store.state.value }
    var isLoading: Bool { store.state.isLoading && snapshot == nil }
    var isStale: Bool { store.isStale }
    var errorMessage: String? {
        guard snapshot == nil else { return store.lastErrorMessage }
        guard let error = store.state.error else { return nil }
        return (error as? SnapshotError)?.userMessage ?? error.localizedDescription
    }

    let filters: [TradeFilter] = [.all, .symbol("BTC"), .symbol("SOL"), .losses]

    private var allTrades: [ClosedTrade] { snapshot?.closedTrades ?? [] }

    /// The chip count is derived from the payload, never the design's literal 28.
    func chipTitle(for filter: TradeFilter) -> String {
        filter.title(totalCount: allTrades.count)
    }

    func select(_ filter: TradeFilter) {
        selectedFilter = filter
    }

    var winsText: String { "\(snapshot?.summary.wins ?? 0)W" }
    var lossesText: String { "\(snapshot?.summary.losses ?? 0)L" }

    var isFilteredEmpty: Bool { rows.isEmpty && !allTrades.isEmpty }

    var rows: [TradeRowPresentation] {
        selectedFilter
            .apply(to: allTrades)
            .sortedByCloseDateDescending()
            .map { trade in
                let isLong = trade.direction == .long
                let isWin = trade.status == .takeProfit
                return TradeRowPresentation(
                    id: trade.id,
                    pair: trade.pair,
                    directionLabel: isLong ? "▲ LONG" : "▼ SHORT",
                    directionSign: isLong ? .positive : .negative,
                    outcomeLabel: isWin ? "TP" : "SL",
                    outcomeIsWin: isWin,
                    pnlText: BotFormat.signedCurrency(trade.pnl),
                    pnlSign: PnLSign.of(trade.pnl),
                    dateText: BotFormat.stamp(trade.closedAt),
                    priceText: "\(BotFormat.price(trade.entryPrice)) → \(BotFormat.price(trade.exitPrice))",
                    holdText: BotFormat.duration(trade.holdDuration),
                    regimeText: trade.regimeDisplay,
                    confidenceFraction: trade.confidenceFraction
                )
            }
    }

    var bySymbol: [BreakdownGroup] { snapshot?.bySymbol ?? [] }
    var byRegime: [BreakdownGroup] { snapshot?.byRegime ?? [] }
    var symbolMaxAbsolute: Double { bySymbol.maxAbsoluteNet }
    var regimeMaxAbsolute: Double { byRegime.maxAbsoluteNet }

    func refresh() async {
        await store.refresh()
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotTests/TradesViewModelTests
```

Expected: PASS (11 tests).

- [ ] **Step 5: Write the trade row**

`TradingBot/Features/Trades/TradeRowView.swift`:

```swift
import SwiftUI
import BotDesignSystem

struct TradeRowView: View {
    let row: TradeRowPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(row.pair)
                    .font(BotFont.figure)
                    .fontWeight(.medium)
                    .foregroundStyle(BotColor.inkStrong)

                Text(row.directionLabel)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.forSign(row.directionSign))

                BotBadge(text: row.outcomeLabel, tone: row.outcomeIsWin ? .positive : .negative)

                Spacer(minLength: 0)

                Text(row.pnlText)
                    .font(BotFont.pnlFigure)
                    .foregroundStyle(BotColor.forSign(row.pnlSign))
            }

            HStack(spacing: 7) {
                Text(row.dateText)
                Text("·").opacity(0.4)
                Text(row.priceText)
                Text("·").opacity(0.4)
                Text(row.holdText)
                Spacer(minLength: 0)
                Text(row.regimeText).foregroundStyle(BotColor.grey)
                ProgressBar(fraction: row.confidenceFraction, color: BotColor.accent, height: 3)
                    .frame(width: 26)
            }
            .font(BotFont.metadataMono)
            .foregroundStyle(BotColor.greyMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.vertical, BotSpacing.rowVertical)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(row.pair) \(row.directionLabel), \(row.outcomeIsWin ? "take profit" : "stop loss"), "
            + "\(row.pnlText), held \(row.holdText), \(row.regimeText)"
        )
    }
}
```

- [ ] **Step 6: Write the screen**

Replace `TradingBot/Features/Trades/TradesView.swift`:

```swift
import SwiftUI
import BotDataKit
import BotDesignSystem
import BotDomain

struct TradesView: View {
    @State private var viewModel: TradesViewModel

    init(store: SnapshotStore) {
        _viewModel = State(initialValue: TradesViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            // Data is on screen but the last load did not fully succeed — either it
            // came from cache, or a background refresh failed. Never blocks the UI.
            if viewModel.snapshot != nil, let message = viewModel.errorMessage {
                OfflineBanner(message: message)
            }

            content
        }
        .background(BotColor.paper)
        .accessibilityIdentifier("screen.trades")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                Text("Closed trades")
                    .font(BotFont.screenTitle)
                    .foregroundStyle(BotColor.inkStrong)
                Spacer()
                HStack(spacing: 0) {
                    Text(viewModel.winsText).foregroundStyle(BotColor.positive)
                    Text(" / ").foregroundStyle(BotColor.grey)
                    Text(viewModel.lossesText).foregroundStyle(BotColor.negative)
                }
                .font(BotFont.metadataMono)
                .accessibilityLabel("\(viewModel.winsText) wins, \(viewModel.lossesText) losses")
            }

            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    ForEach(Array(viewModel.filters.enumerated()), id: \.offset) { _, filter in
                        Button {
                            viewModel.select(filter)
                        } label: {
                            FilterChipView(
                                title: viewModel.chipTitle(for: filter),
                                isSelected: viewModel.selectedFilter == filter
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("filter.\(identifier(for: filter))")
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
    }

    private func identifier(for filter: TradeFilter) -> String {
        switch filter {
        case .all: return "all"
        case .symbol(let symbol): return symbol.lowercased()
        case .losses: return "losses"
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingSkeleton()
            Spacer()
        } else if viewModel.snapshot == nil, let message = viewModel.errorMessage {
            ErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.rows.isEmpty {
                        EmptyStateView(
                            message: viewModel.isFilteredEmpty
                                ? "No trades match this filter."
                                : "No closed trades yet."
                        )
                    } else {
                        ForEach(viewModel.rows) { row in
                            TradeRowView(row: row)
                        }
                    }

                    if !viewModel.bySymbol.isEmpty {
                        breakdown(
                            title: "By symbol",
                            groups: viewModel.bySymbol,
                            maxAbsolute: viewModel.symbolMaxAbsolute
                        )
                    }

                    if !viewModel.byRegime.isEmpty {
                        breakdown(
                            title: "By regime",
                            groups: viewModel.byRegime,
                            maxAbsolute: viewModel.regimeMaxAbsolute
                        )
                    }

                    Color.clear.frame(height: 24)
                }
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }

    private func breakdown(
        title: String,
        groups: [BreakdownGroup],
        maxAbsolute: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(BotFont.cardTitle)
                .foregroundStyle(BotColor.ink)
                .padding(.horizontal, BotSpacing.screenHorizontal)
                .padding(.top, 22)
                .padding(.bottom, 8)

            ForEach(groups) { group in
                BreakdownRowView(group: group, maxAbsolute: maxAbsolute)
            }
        }
        .accessibilityIdentifier("breakdown.\(title.replacingOccurrences(of: " ", with: "").lowercased())")
    }
}
```

- [ ] **Step 7: Run the full scheme and commit**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: **TEST SUCCEEDED**.

```bash
git add TradingBot TradingBotTests
git commit -m "feat: trades screen with filter chips, rows, symbol and regime breakdowns"
```

---

## Task 14: Review screen — both branches

**Files:**
- Create: `TradingBot/Features/Review/ReviewViewModel.swift`
- Modify: `TradingBot/Features/Review/ReviewView.swift`
- Create: `TradingBot/Features/Review/ReportCard.swift`
- Create: `TradingBot/Features/Review/VetoLogCard.swift`
- Create: `TradingBot/Features/Review/LessonsCard.swift`
- Test: `TradingBotTests/ReviewViewModelTests.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `AIReport`, `VetoLog`, `Lesson`, design system.
- Produces: `ReviewViewModel(store:)` exposing `hasReviewLayer`, `dateText`, `report: ReportPresentation?`, `vetoSummary`, `vetoRows: [VetoRowPresentation]`, `lessons: [LessonPresentation]`, `lessonCountText`, `placeholders: [PlaceholderContent]`.

**This is the task that pays off the nullability insight.** One ViewModel, two branches, both covered by fixtures.

- [ ] **Step 1: Write the failing tests**

`TradingBotTests/ReviewViewModelTests.swift`:

```swift
import Foundation
import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func loadedViewModel(fixture: String? = nil) async -> ReviewViewModel {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return ReviewViewModel(store: container.store)
}

// MARK: - AI enabled

@MainActor
@Test func showsTheReviewLayerWhenPresent() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.hasReviewLayer)
    #expect(viewModel.dateText == "2026-06-30")
}

@MainActor
@Test func presentsTheNarrativeInTypographicQuotes() async {
    let viewModel = await loadedViewModel()
    let report = try! #require(viewModel.report)
    #expect(report.narrative.hasPrefix("\u{201C}"))
    #expect(report.narrative.hasSuffix("\u{201D}"))
    #expect(report.narrative.contains("Choppy fortnight"))
}

@MainActor
@Test func splitsWorkingAndLosingLists() async {
    let viewModel = await loadedViewModel()
    let report = try! #require(viewModel.report)
    #expect(report.working == ["BTC entries in clear trends", "Stops kept losses small"])
    #expect(report.losing.count == 2)
    #expect(report.losing[0] == "SOL trades in ranging regime")
}

@MainActor
@Test func presentsConfigSuggestionsAsCurrentToSuggested() async {
    let viewModel = await loadedViewModel()
    let report = try! #require(viewModel.report)
    #expect(report.suggestions.count == 2)
    #expect(report.suggestions[0].param == "ADX_TREND_MIN_SOLUSDT")
    #expect(report.suggestions[0].current == "25")
    #expect(report.suggestions[0].suggested == "30")
    #expect(report.suggestions[0].rationale == "filter more SOL chop")
}

@MainActor
@Test func summarisesTheVetoLog() async {
    let viewModel = await loadedViewModel()
    let summary = try! #require(viewModel.vetoSummary)
    #expect(summary.proceedText == "26")
    #expect(summary.blockText == "2")
    #expect(summary.winRateText == "41.7%")
    #expect(summary.scoredText == "24 scored")
}

@MainActor
@Test func presentsVetoRowsWithFlagsAndOutcome() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.vetoRows.count == 2)

    let proceeded = viewModel.vetoRows[0]
    #expect(proceeded.symbol == "SOLUSDT")
    #expect(proceeded.signalText == "SELL")
    #expect(proceeded.signalIsBuy == false)
    #expect(proceeded.decisionLabel == "proceed")
    #expect(proceeded.didProceed)
    #expect(proceeded.flags == ["low_adx_chop"])
    #expect(proceeded.outcomeText == "loss")
    #expect(proceeded.timeText == "Jun 30 12:05")
}

@MainActor
@Test func aBlockedSignalWithNoResultReadsNoOutcome() async {
    let viewModel = await loadedViewModel()
    let blocked = viewModel.vetoRows[1]
    #expect(blocked.decisionLabel == "block")
    #expect(blocked.didProceed == false)
    #expect(blocked.signalIsBuy)
    #expect(blocked.outcomeText == "no outcome")
}

@MainActor
@Test func presentsLessons() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.lessonCountText == "1 recent")
    let lesson = try! #require(viewModel.lessons.first)
    #expect(lesson.pair == "SOLUSDT")
    #expect(lesson.outcomeLabel == "SL")
    #expect(lesson.text == "Avoid shorting into established support in a ranging market.")
    #expect(lesson.metaText == "pattern: shorted into support · conf: high")
    #expect(lesson.tags == ["support", "ranging", "short"])
}

// MARK: - AI null — the design's fourth screen

@MainActor
@Test func fallsBackToPlaceholdersWhenTheLayerIsOff() async {
    let viewModel = await loadedViewModel(fixture: "aiNull")
    #expect(viewModel.hasReviewLayer == false)
    #expect(viewModel.report == nil)
    #expect(viewModel.vetoSummary == nil)
    #expect(viewModel.vetoRows.isEmpty)
    #expect(viewModel.lessons.isEmpty)
}

@MainActor
@Test func theHeaderReadsOffWhenTheLayerIsDisabled() async {
    let viewModel = await loadedViewModel(fixture: "aiNull")
    #expect(viewModel.dateText == "off")
}

@MainActor
@Test func providesExactlyThreePlaceholdersWithTheDesignCopy() async {
    let viewModel = await loadedViewModel(fixture: "aiNull")
    #expect(viewModel.placeholders.count == 3)
    #expect(viewModel.placeholders[0].title == "Latest AI report")
    #expect(viewModel.placeholders[1].title == "Veto log")
    #expect(viewModel.placeholders[2].title == "Lessons")
    #expect(viewModel.placeholders[2].description
        == "Captures a post-mortem after each loss with failure patterns and tags.")
}

@MainActor
@Test func placeholdersAreAbsentWhenTheLayerIsOn() async {
    let viewModel = await loadedViewModel()
    #expect(viewModel.placeholders.isEmpty)
}
```

- [ ] **Step 2: Run to verify failure**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotTests/ReviewViewModelTests
```

Expected: FAIL — `cannot find 'ReviewViewModel' in scope`.

- [ ] **Step 3: Write the ViewModel**

`TradingBot/Features/Review/ReviewViewModel.swift`:

```swift
import Foundation
import Observation
import BotDataKit
import BotDomain
import BotFormatting

struct SuggestionPresentation: Identifiable, Equatable {
    let param: String
    let current: String
    let suggested: String
    let rationale: String
    var id: String { param }
}

struct ReportPresentation: Equatable {
    let narrative: String
    let working: [String]
    let losing: [String]
    let suggestions: [SuggestionPresentation]
}

struct VetoSummaryPresentation: Equatable {
    let proceedText: String
    let blockText: String
    let winRateText: String
    let scoredText: String
}

struct VetoRowPresentation: Identifiable, Equatable {
    let id: String
    let symbol: String
    let signalText: String
    let signalIsBuy: Bool
    let decisionLabel: String
    let didProceed: Bool
    let reason: String
    let flags: [String]
    let outcomeText: String
    let outcomeSign: PnLSign
    let timeText: String
}

struct LessonPresentation: Identifiable, Equatable {
    let id: String
    let pair: String
    let outcomeLabel: String
    let timeText: String
    let text: String
    let metaText: String
    let tags: [String]
}

struct PlaceholderContent: Identifiable, Equatable {
    let title: String
    let description: String
    var id: String { title }
}

@MainActor
@Observable
final class ReviewViewModel {
    private let store: SnapshotStore

    init(store: SnapshotStore) {
        self.store = store
    }

    var snapshot: Snapshot? { store.state.value }
    var isLoading: Bool { store.state.isLoading && snapshot == nil }
    var isStale: Bool { store.isStale }
    var errorMessage: String? {
        guard snapshot == nil else { return store.lastErrorMessage }
        guard let error = store.state.error else { return nil }
        return (error as? SnapshotError)?.userMessage ?? error.localizedDescription
    }

    /// The one branch that produces the design's fourth screen.
    var hasReviewLayer: Bool { snapshot?.hasReviewLayer ?? false }

    var dateText: String { snapshot?.aiReport?.date ?? "off" }

    var report: ReportPresentation? {
        guard let report = snapshot?.aiReport else { return nil }
        return ReportPresentation(
            narrative: "\u{201C}\(report.narrative)\u{201D}",
            working: report.whatsWorking,
            losing: report.whatsLosing,
            suggestions: report.configSuggestions.map {
                SuggestionPresentation(
                    param: $0.param, current: $0.current,
                    suggested: $0.suggested, rationale: $0.rationale
                )
            }
        )
    }

    var vetoSummary: VetoSummaryPresentation? {
        guard let veto = snapshot?.veto else { return nil }
        return VetoSummaryPresentation(
            proceedText: "\(veto.proceed)",
            blockText: "\(veto.block)",
            winRateText: BotFormat.percent(veto.proceedWinRate),
            scoredText: "\(veto.scored) scored"
        )
    }

    var vetoRows: [VetoRowPresentation] {
        (snapshot?.veto?.rows ?? []).map { row in
            VetoRowPresentation(
                id: row.id,
                symbol: row.symbol,
                signalText: row.signal == .unknown ? "—" : row.signal.rawValue,
                signalIsBuy: row.signal == .buy,
                decisionLabel: row.decisionLabel,
                didProceed: row.proceed,
                reason: row.reason,
                flags: row.displayFlags,
                outcomeText: row.outcomeLabel,
                outcomeSign: {
                    switch row.outcome {
                    case .win: return .positive
                    case .loss: return .negative
                    case nil: return .flat
                    }
                }(),
                timeText: BotFormat.stamp(row.timestamp)
            )
        }
    }

    var lessons: [LessonPresentation] {
        (snapshot?.lessons ?? []).map { lesson in
            LessonPresentation(
                id: lesson.id,
                pair: lesson.pair,
                outcomeLabel: lesson.outcome == .takeProfit ? "TP" : "SL",
                timeText: BotFormat.stamp(lesson.timestamp),
                text: lesson.lesson,
                metaText: "pattern: \(lesson.failurePattern) · conf: \(lesson.confidence)",
                tags: lesson.tags
            )
        }
    }

    var lessonCountText: String { "\(lessons.count) recent" }

    /// Shown only when the review layer is off. Copy is the design's, verbatim.
    var placeholders: [PlaceholderContent] {
        guard !hasReviewLayer, snapshot != nil else { return [] }
        return [
            PlaceholderContent(
                title: "Latest AI report",
                description: "Enable the review layer for a narrative read on recent performance plus config suggestions."
            ),
            PlaceholderContent(
                title: "Veto log",
                description: "Logs every proceed / block decision and tracks the win rate of trades it let through."
            ),
            PlaceholderContent(
                title: "Lessons",
                description: "Captures a post-mortem after each loss with failure patterns and tags."
            ),
        ]
    }

    func refresh() async {
        await store.refresh()
    }
}
```

- [ ] **Step 4: Run to verify pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotTests/ReviewViewModelTests
```

Expected: PASS (12 tests).

- [ ] **Step 5: Write the report card**

`TradingBot/Features/Review/ReportCard.swift`:

```swift
import SwiftUI
import BotDesignSystem

struct ReportCard: View {
    let report: ReportPresentation

    var body: some View {
        BotCard {
            VStack(alignment: .leading, spacing: 0) {
                Overline(text: "Latest report")
                    .padding(.bottom, 11)

                Text(report.narrative)
                    .font(BotFont.narrative)
                    .foregroundStyle(BotColor.inkBody)
                    .lineSpacing(4)
                    .padding(.bottom, 16)

                bulletList(title: "Working", items: report.working, color: BotColor.positive)
                    .padding(.bottom, 13)
                bulletList(title: "Losing", items: report.losing, color: BotColor.negative)

                if !report.suggestions.isEmpty {
                    Divider().background(BotColor.hairline).padding(.vertical, 14)
                    Overline(text: "Config suggestions", color: BotColor.grey)
                        .padding(.bottom, 10)
                    ForEach(report.suggestions) { suggestion in
                        suggestionRow(suggestion)
                    }
                }
            }
        }
        .accessibilityIdentifier("review.report")
    }

    private func bulletList(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Overline(text: title, color: color)
                .padding(.bottom, 2)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 9) {
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .padding(.top, 7)
                    Text(item)
                        .font(BotFont.listItem)
                        .foregroundStyle(BotColor.grey)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(items.joined(separator: ", "))")
    }

    private func suggestionRow(_ suggestion: SuggestionPresentation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(suggestion.param)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(suggestion.current)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.grey)
                Text("→")
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.accent)
                Text(suggestion.suggested)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(BotColor.positive)
            }
            Text(suggestion.rationale)
                .font(BotFont.metadata)
                .foregroundStyle(BotColor.greyMuted)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(suggestion.param), currently \(suggestion.current), "
            + "suggested \(suggestion.suggested). \(suggestion.rationale)"
        )
    }
}
```

- [ ] **Step 6: Write the veto log and lessons cards**

`TradingBot/Features/Review/VetoLogCard.swift`:

```swift
import SwiftUI
import BotDesignSystem

struct VetoLogCard: View {
    let summary: VetoSummaryPresentation
    let rows: [VetoRowPresentation]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Veto log")
                    .font(BotFont.sectionTitle)
                    .foregroundStyle(BotColor.ink)
                Spacer()
                Text(summary.scoredText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }
            .padding(.horizontal, BotSpacing.cardPadding)
            .padding(.top, 15)
            .padding(.bottom, 12)

            HStack(spacing: 16) {
                labelled("proceed", summary.proceedText, BotColor.positive)
                labelled("block", summary.blockText, BotColor.negative)
                labelled("win rate", summary.winRateText, BotColor.ink)
                Spacer(minLength: 0)
            }
            .font(BotFont.metadataMono)
            .foregroundStyle(BotColor.grey)
            .padding(.horizontal, BotSpacing.cardPadding)
            .padding(.vertical, 9)
            .background(BotColor.surface)
            .overlay(alignment: .top) { hairline }
            .overlay(alignment: .bottom) { hairline }

            ForEach(rows) { row in
                vetoRow(row)
            }
        }
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityIdentifier("review.vetoLog")
    }

    private var hairline: some View {
        Rectangle().fill(BotColor.hairline).frame(height: 1)
    }

    private func labelled(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Text(value).foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private func vetoRow(_ row: VetoRowPresentation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(row.symbol)
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.ink)
                Text(row.signalText)
                    .font(BotFont.metadataMono)
                    .foregroundStyle(row.signalIsBuy ? BotColor.positive : BotColor.negative)
                BotBadge(text: row.decisionLabel, tone: row.didProceed ? .positive : .negative)
                Spacer(minLength: 0)
                Text(row.timeText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }

            Text(row.reason)
                .font(BotFont.caption)
                .foregroundStyle(BotColor.grey)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(row.flags, id: \.self) { flag in
                    Text(flag)
                        .font(BotFont.badge)
                        .foregroundStyle(BotColor.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(BotColor.accentFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous)
                                .stroke(BotColor.accentStroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: BotRadius.badge, style: .continuous))
                }
                Spacer(minLength: 0)
                Text(row.outcomeText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.forSign(row.outcomeSign))
            }
        }
        .padding(.horizontal, BotSpacing.cardPadding)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { hairline }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(row.symbol) \(row.signalText), \(row.decisionLabel). \(row.reason). "
            + "Outcome \(row.outcomeText)"
        )
    }
}
```

`TradingBot/Features/Review/LessonsCard.swift`:

```swift
import SwiftUI
import BotDesignSystem

struct LessonsCard: View {
    let lessons: [LessonPresentation]
    let countText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Lessons")
                    .font(BotFont.sectionTitle)
                    .foregroundStyle(BotColor.ink)
                Spacer()
                Text(countText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }

            ForEach(lessons) { lesson in
                lessonCard(lesson)
            }
        }
        .padding(.horizontal, BotSpacing.cardPadding)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BotColor.cardTop)
        .clipShape(RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BotRadius.card, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
        .accessibilityIdentifier("review.lessons")
    }

    private func lessonCard(_ lesson: LessonPresentation) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(lesson.pair)
                    .font(BotFont.figureSmall)
                    .foregroundStyle(BotColor.inkStrong)
                BotBadge(text: lesson.outcomeLabel, tone: .negative)
                Spacer(minLength: 0)
                Text(lesson.timeText)
                    .font(BotFont.badge)
                    .foregroundStyle(BotColor.greyMuted)
            }

            Text(lesson.text)
                .font(BotFont.body)
                .foregroundStyle(BotColor.inkBody)
                .fixedSize(horizontal: false, vertical: true)

            Text(lesson.metaText)
                .font(BotFont.metadata)
                .foregroundStyle(BotColor.greyMuted)

            HStack(spacing: 5) {
                ForEach(lesson.tags, id: \.self) { tag in
                    TagChip(tag: tag)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(13)
        .background(BotColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BotColor.hairline, lineWidth: 1)
        )
    }
}
```

- [ ] **Step 7: Write the screen**

Replace `TradingBot/Features/Review/ReviewView.swift`:

```swift
import SwiftUI
import BotDataKit
import BotDesignSystem

struct ReviewView: View {
    @State private var viewModel: ReviewViewModel

    init(store: SnapshotStore) {
        _viewModel = State(initialValue: ReviewViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            // Data is on screen but the last load did not fully succeed — either it
            // came from cache, or a background refresh failed. Never blocks the UI.
            if viewModel.snapshot != nil, let message = viewModel.errorMessage {
                OfflineBanner(message: message)
            }

            content
        }
        .background(BotColor.paper)
        .accessibilityIdentifier("screen.review")
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Review")
                .font(BotFont.screenTitle)
                .foregroundStyle(BotColor.inkStrong)
            Spacer()
            Text(viewModel.dateText)
                .font(BotFont.metadataMono)
                .foregroundStyle(viewModel.hasReviewLayer ? BotColor.grey : BotColor.greyMuted)
                .accessibilityIdentifier("review.date")
        }
        .padding(.horizontal, BotSpacing.screenHorizontal)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BotColor.hairline).frame(height: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingSkeleton()
            Spacer()
        } else if viewModel.snapshot == nil, let message = viewModel.errorMessage {
            ErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let report = viewModel.report {
                        ReportCard(report: report)
                    }

                    if let summary = viewModel.vetoSummary {
                        VetoLogCard(summary: summary, rows: viewModel.vetoRows)
                    }

                    if !viewModel.lessons.isEmpty {
                        LessonsCard(
                            lessons: viewModel.lessons,
                            countText: viewModel.lessonCountText
                        )
                    }

                    // The design's fourth screen: one branch, not a separate view.
                    ForEach(viewModel.placeholders) { placeholder in
                        PlaceholderCard(
                            title: placeholder.title,
                            description: placeholder.description
                        )
                        .accessibilityIdentifier("review.placeholder")
                    }
                }
                .padding(.horizontal, BotSpacing.screenHorizontal)
                .padding(.vertical, 18)
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }
}
```

- [ ] **Step 8: Run the full scheme and commit**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: **TEST SUCCEEDED**.

```bash
git add TradingBot TradingBotTests
git commit -m "feat: review screen with AI report, veto log, lessons, and null-state placeholders"
```

---

## Task 15: UI tests across all four design states

**Files:**
- Modify: `TradingBotUITests/LaunchUITests.swift`
- Create: `TradingBotUITests/EquityUITests.swift`
- Create: `TradingBotUITests/TradesUITests.swift`
- Create: `TradingBotUITests/ReviewUITests.swift`
- Create: `TradingBotUITests/ErrorStateUITests.swift`

**Interfaces:**
- Consumes: accessibility identifiers established in Tasks 11–14: `tab.equity|trades|review`, `screen.equity|trades|review`, `equity.figure`, `equity.openPosition`, `header.refresh`, `filter.all|btc|sol|losses`, `breakdown.bysymbol|byregime`, `review.report`, `review.vetoLog`, `review.lessons`, `review.placeholder`, `review.date`, `state.error`, `state.retry`.

- [ ] **Step 1: Write the equity UI tests**

`TradingBotUITests/EquityUITests.swift`:

```swift
import XCTest

final class EquityUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", fixture]
        app.launch()
        return app
    }

    func testShowsTheEquityFigureAndOpenPosition() {
        let app = launch(fixture: "full")
        let figure = app.staticTexts["equity.figure"]
        XCTAssertTrue(figure.waitForExistence(timeout: 10))
        XCTAssertEqual(figure.label, "$116.40")
        XCTAssertTrue(app.otherElements["equity.openPosition"].exists)
    }

    func testShowsNoOpenPositionForAFlatBot() {
        let app = launch(fixture: "empty")
        XCTAssertTrue(app.staticTexts["equity.figure"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.otherElements["equity.openPosition"].exists)
    }

    func testRefreshControlIsAvailable() {
        let app = launch(fixture: "full")
        XCTAssertTrue(app.buttons["header.refresh"].waitForExistence(timeout: 10))
        app.buttons["header.refresh"].tap()
        // The figure must survive a refresh rather than blanking.
        XCTAssertTrue(app.staticTexts["equity.figure"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 2: Write the trades UI tests**

`TradingBotUITests/TradesUITests.swift`:

```swift
import XCTest

final class TradesUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchOnTrades(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", fixture]
        app.launch()
        XCTAssertTrue(app.buttons["tab.trades"].waitForExistence(timeout: 10))
        app.buttons["tab.trades"].tap()
        return app
    }

    func testFilteringBySymbolChangesTheVisibleRowCount() {
        let app = launchOnTrades(fixture: "full")
        XCTAssertTrue(app.buttons["filter.all"].waitForExistence(timeout: 5))

        let allRows = app.cells.count + app.otherElements.matching(
            NSPredicate(format: "label CONTAINS 'USDT'")
        ).count
        XCTAssertGreaterThan(allRows, 0)

        app.buttons["filter.btc"].tap()
        let btcRows = app.otherElements.matching(
            NSPredicate(format: "label CONTAINS 'BTCUSDT'")
        ).count
        let solRowsAfterBtcFilter = app.otherElements.matching(
            NSPredicate(format: "label CONTAINS 'SOLUSDT'")
        ).count
        XCTAssertGreaterThan(btcRows, 0)
        XCTAssertEqual(solRowsAfterBtcFilter, 0, "BTC filter must hide SOL trades")
    }

    func testBreakdownSectionsArePresent() {
        let app = launchOnTrades(fixture: "full")
        XCTAssertTrue(app.otherElements["breakdown.bysymbol"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["breakdown.byregime"].exists)
    }

    func testEmptyHistoryHidesTheBreakdowns() {
        let app = launchOnTrades(fixture: "empty")
        XCTAssertTrue(app.staticTexts["state.empty"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["breakdown.bysymbol"].exists)
    }
}
```

- [ ] **Step 3: Write the review UI tests — both branches**

`TradingBotUITests/ReviewUITests.swift`:

```swift
import XCTest

final class ReviewUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchOnReview(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", fixture]
        app.launch()
        XCTAssertTrue(app.buttons["tab.review"].waitForExistence(timeout: 10))
        app.buttons["tab.review"].tap()
        return app
    }

    func testShowsReportVetoAndLessonsWhenTheLayerIsOn() {
        let app = launchOnReview(fixture: "full")
        XCTAssertTrue(app.otherElements["review.report"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["review.vetoLog"].exists)
        XCTAssertTrue(app.otherElements["review.lessons"].exists)
        XCTAssertEqual(app.staticTexts["review.date"].label, "2026-06-30")
        XCTAssertEqual(app.otherElements.matching(identifier: "review.placeholder").count, 0)
    }

    // The design's fourth screen.
    func testShowsExactlyThreePlaceholdersWhenTheLayerIsOff() {
        let app = launchOnReview(fixture: "aiNull")
        XCTAssertTrue(
            app.otherElements.matching(identifier: "review.placeholder")
                .element(boundBy: 0).waitForExistence(timeout: 5)
        )
        XCTAssertEqual(app.otherElements.matching(identifier: "review.placeholder").count, 3)
        XCTAssertFalse(app.otherElements["review.report"].exists)
        XCTAssertFalse(app.otherElements["review.vetoLog"].exists)
        XCTAssertEqual(app.staticTexts["review.date"].label, "off")
    }
}
```

- [ ] **Step 4: Write the error-state UI test**

`TradingBotUITests/ErrorStateUITests.swift`:

```swift
import XCTest

final class ErrorStateUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testErrorFixtureShowsRetryOnEveryTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", "error"]
        app.launch()

        XCTAssertTrue(app.otherElements["state.error"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["state.retry"].exists)

        app.buttons["tab.trades"].tap()
        XCTAssertTrue(app.otherElements["state.error"].waitForExistence(timeout: 5))

        app.buttons["tab.review"].tap()
        XCTAssertTrue(app.otherElements["state.error"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 5: Run the UI test suite**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotUITests
```

Expected: **TEST SUCCEEDED** (11 UI tests).

If an element is not found, confirm the identifier is on a queryable element. `accessibilityElement(children: .combine)` turns a container into `otherElements`, and a plain `Text` is a `staticTexts`. Adjust the query to match the element type rather than removing the assertion.

- [ ] **Step 6: Commit**

```bash
git add TradingBotUITests
git commit -m "test: UI coverage for all four design states plus error recovery"
```

---

## Task 16: Accessibility, deployment-floor check, final verification

**Files:**
- Modify: `TradingBot/Features/Equity/EquityView.swift` (Dynamic Type audit)
- Create: `TradingBotTests/AccessibilityTests.swift`
- Create: `README.md`

**Interfaces:**
- Consumes: everything built so far. Produces no new API.

- [ ] **Step 1: Write accessibility tests**

`TradingBotTests/AccessibilityTests.swift`:

```swift
import Testing
import BotDataKit
import BotDomain
@testable import TradingBot

@MainActor
private func viewModel(fixture: String? = nil) async -> EquityViewModel {
    let container = AppContainer(arguments: fixture.map { ["-fixture", $0] } ?? [])
    await container.store.refresh()
    return EquityViewModel(store: container.store)
}

@MainActor
@Test func everyTileExposesAReadableLabel() async {
    let model = await viewModel()
    for tile in model.tiles {
        #expect(tile.label.isEmpty == false)
        #expect(tile.value.isEmpty == false)
        #expect(tile.subtitle.isEmpty == false)
    }
}

// Colour must never be the only carrier of meaning.
@MainActor
@Test func directionIsConveyedByTextNotOnlyColour() async {
    let trades = await TradesViewModelForTesting.make()
    for row in trades.rows {
        #expect(row.directionLabel.contains("LONG") || row.directionLabel.contains("SHORT"))
        #expect(row.outcomeLabel == "TP" || row.outcomeLabel == "SL")
    }
}

@MainActor
@Test func vetoDecisionsCarryATextLabel() async {
    let container = AppContainer(arguments: [])
    await container.store.refresh()
    let review = ReviewViewModel(store: container.store)
    for row in review.vetoRows {
        #expect(row.decisionLabel == "proceed" || row.decisionLabel == "block")
        #expect(row.outcomeText.isEmpty == false)
    }
}

@MainActor
enum TradesViewModelForTesting {
    static func make() async -> TradesViewModel {
        let container = AppContainer(arguments: [])
        await container.store.refresh()
        return TradesViewModel(store: container.store)
    }
}
```

- [ ] **Step 2: Run the accessibility tests**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TradingBotTests/AccessibilityTests
```

Expected: PASS (3 tests).

- [ ] **Step 3: Verify the iOS 18 deployment floor**

The project targets iOS 18.0 but only an iOS 26.5 device exists. Create a floor device and run against it:

```bash
xcrun simctl create "iPhone 16 (18.6)" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16 \
  com.apple.CoreSimulator.SimRuntime.iOS-18-6
```

Expected: prints a UUID. If the device type is unavailable, list options with `xcrun simctl list devicetypes | grep iPhone` and pick an available iPhone type.

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 16 (18.6)'
```

Expected: **TEST SUCCEEDED**. Any failure here is a real iOS 18 incompatibility — most likely an API introduced after 18.0. Fix it with an availability guard or an 18.0-compatible alternative; do not raise the deployment target without asking.

- [ ] **Step 4: Confirm the build is warning-free under strict concurrency**

```bash
xcodebuild build -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "warning:" | sort -u
```

Expected: no output. Fix any warning that appears — `SWIFT_STRICT_CONCURRENCY = complete` is a global constraint.

- [ ] **Step 5: Run the whole suite one final time**

```bash
cd Packages/TradingBotKit && swift test && cd -
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: both green.

- [ ] **Step 6: Write the README**

`README.md`:

```markdown
# Trading Bot for iPhone

A read-only SwiftUI companion for a crypto trading bot. It renders one JSON snapshot
across three tabs — Equity, Trades, Review — and never places, modifies, or closes a
trade.

## Requirements

- Xcode 26+, iOS 18.0 minimum
- No external dependencies

## Structure

| Path | Responsibility |
|---|---|
| `Packages/TradingBotKit/Sources/BotDomain` | Models and pure logic. No dependencies. |
| `Packages/TradingBotKit/Sources/BotFormatting` | Display formatting, pinned to `en_US_POSIX` / UTC. |
| `Packages/TradingBotKit/Sources/BotDataKit` | Provider, DTOs, HTTP, cache, polling store. |
| `Packages/TradingBotKit/Sources/BotDesignSystem` | Tokens, fonts, reusable components. |
| `TradingBot/` | App shell and one View + ViewModel per tab. |

Views contain no formatting and no business logic — ViewModels expose view-ready values.

## Running the tests

```bash
# Fast: package units only
cd Packages/TradingBotKit && swift test

# Everything, including UI tests
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Fixtures

The app selects its data source from a launch argument, which is how the UI tests stay
deterministic:

| Argument | Result |
|---|---|
| *(none)* or `-fixture full` | Full sample snapshot |
| `-fixture aiNull` | Review layer disabled — placeholder screen |
| `-fixture empty` | A live bot with no history |
| `-fixture error` | Load always fails — error and retry state |

## Pointing at a live dashboard

`TradingBot/AppContainer.swift` is the only place that chooses a data source. Replace
`BundledSnapshotProvider` with `RemoteSnapshotProvider(baseURL:)`. Nothing else changes.

## Fonts

Bodoni Moda, Plus Jakarta Sans, and IBM Plex Mono ship in the design-system package
under the SIL Open Font License; their licence files sit alongside them.
```

- [ ] **Step 7: Commit**

```bash
git add TradingBot TradingBotTests README.md
git commit -m "test: accessibility coverage, iOS 18 floor verification, README"
```

---

## Verification checklist

Run through this before declaring the plan complete:

- [ ] `cd Packages/TradingBotKit && swift test` — green
- [ ] `cd Packages/TradingBotKit && TZ=Asia/Tokyo swift test` — green (formatter pinning holds)
- [ ] Full scheme green on iPhone 17 Pro (iOS 26.5)
- [ ] Full scheme green on iPhone 16 (iOS 18.6) — deployment floor
- [ ] Build produces no warnings under `SWIFT_STRICT_CONCURRENCY = complete`
- [ ] All four design states render: full, AI-null, empty, error
- [ ] No `View` file contains a number-to-string conversion or a conditional colour
- [ ] No login screen, no write operations to the exchange or bot config

