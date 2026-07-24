# Trading Bot iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-quality SwiftUI iOS app replicating the 6-screen trading-bot dashboard mockup (`Unknown.png`), driven by a swappable JSON data contract until the real backend API becomes accessible.

**Architecture:** Pragmatic Clean MVVM — Domain (pure models + repository protocols), Data (DTOs, providers, caching repositories), Core (networking, DI), DesignSystem, and per-feature View/@Observable-ViewModel folders. One `BotDataProvider` protocol isolates the unknown real API; Phase 1 ships a bundled `snapshot.json` plus an HTTP provider against a configurable base URL.

**Tech Stack:** Xcode 26.6, Swift 6, SwiftUI, Swift Charts, Observation, async/await, Swift Testing, XCUITest. iOS 18.0 minimum. No third-party dependencies. No XcodeGen/Tuist — the `.xcodeproj` is a checked-in, hand-written Xcode 16-style project using synchronized folders.

## Global Constraints

- iOS deployment target: **18.0** exactly; Swift version **6.0**; strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`).
- No third-party packages or CocoaPods. Apple frameworks only (SwiftUI, Charts, Foundation, Observation, XCTest).
- UI reference is `/Users/mohamedelitani/Desktop/Trading-Bot-iOS/Unknown.png` — replicate layout, typography, colors, and data values as closely as HIG allows.
- No force unwraps, no `try!`, no `fatalError` outside tests. No mock data in production code paths — sample data lives only in `TradingBot/Resources/snapshot.json` and test fixtures.
- Spec: `docs/superpowers/specs/2026-07-24-trading-bot-ios-design.md`. Do not create or modify any backend.
- Commit after every task. Commit messages: `feat: ...` / `test: ...` conventional style.
- All build/test commands run from repo root `/Users/mohamedelitani/Desktop/Trading-Bot-iOS`.
- Scheme/destination for every command: `-project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16'` (simulator created in Task 1).

---

### Task 1: Xcode project scaffold, simulator, app shell

**Files:**
- Create: `TradingBot.xcodeproj/project.pbxproj`
- Create: `TradingBot.xcodeproj/xcshareddata/xcschemes/TradingBot.xcscheme`
- Create: `TradingBot/TradingBotApp.swift`
- Create: `TradingBot/Features/Root/MainTabView.swift`
- Create: `.gitignore`

**Interfaces:**
- Produces: `TradingBotApp` (@main), `MainTabView` (TabView with 5 tabs: Dashboard, Portfolio, Positions, History, Insights). Every later task adds files under `TradingBot/` — the synchronized-folder project picks them up with no pbxproj edits.

- [ ] **Step 1: Write .gitignore**

```gitignore
.DS_Store
build/
DerivedData/
xcuserdata/
*.xcuserstate
```

- [ ] **Step 2: Create the iPhone 16 simulator (iOS 18.6)**

```bash
xcrun simctl create "iPhone 16" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-18-6
```

Expected: prints a device UUID. If it fails because a device named "iPhone 16" already exists, run `xcrun simctl list devices | grep "iPhone 16"` and continue.

- [ ] **Step 3: Write the Xcode project**

Create `TradingBot.xcodeproj/project.pbxproj` exactly as below. It uses Xcode 16 synchronized folders (`PBXFileSystemSynchronizedRootGroup`), so any `.swift` file added under `TradingBot/`, `TradingBotTests/`, or `TradingBotUITests/` is compiled automatically — no pbxproj edits in later tasks.

```
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {

/* Begin PBXFileSystemSynchronizedRootGroup section */
		AA1000000000000000000010 /* TradingBot */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = TradingBot;
			sourceTree = "<group>";
		};
		AA1000000000000000000011 /* TradingBotTests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = TradingBotTests;
			sourceTree = "<group>";
		};
		AA1000000000000000000012 /* TradingBotUITests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = TradingBotUITests;
			sourceTree = "<group>";
		};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
		AA1000000000000000000020 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AA1000000000000000000021 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AA1000000000000000000022 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		AA1000000000000000000001 = {
			isa = PBXGroup;
			children = (
				AA1000000000000000000010 /* TradingBot */,
				AA1000000000000000000011 /* TradingBotTests */,
				AA1000000000000000000012 /* TradingBotUITests */,
				AA1000000000000000000002 /* Products */,
			);
			sourceTree = "<group>";
		};
		AA1000000000000000000002 /* Products */ = {
			isa = PBXGroup;
			children = (
				AA1000000000000000000003 /* TradingBot.app */,
				AA1000000000000000000004 /* TradingBotTests.xctest */,
				AA1000000000000000000005 /* TradingBotUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		AA1000000000000000000100 /* TradingBot */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AA1000000000000000000300 /* Build configuration list for PBXNativeTarget "TradingBot" */;
			buildPhases = (
				AA1000000000000000000200 /* Sources */,
				AA1000000000000000000020 /* Frameworks */,
				AA1000000000000000000201 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				AA1000000000000000000010 /* TradingBot */,
			);
			name = TradingBot;
			packageProductDependencies = (
			);
			productName = TradingBot;
			productReference = AA1000000000000000000003 /* TradingBot.app */;
			productType = "com.apple.product-type.application";
		};
		AA1000000000000000000101 /* TradingBotTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AA1000000000000000000301 /* Build configuration list for PBXNativeTarget "TradingBotTests" */;
			buildPhases = (
				AA1000000000000000000202 /* Sources */,
				AA1000000000000000000021 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				AA1000000000000000000400 /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				AA1000000000000000000011 /* TradingBotTests */,
			);
			name = TradingBotTests;
			packageProductDependencies = (
			);
			productName = TradingBotTests;
			productReference = AA1000000000000000000004 /* TradingBotTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
		AA1000000000000000000102 /* TradingBotUITests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AA1000000000000000000302 /* Build configuration list for PBXNativeTarget "TradingBotUITests" */;
			buildPhases = (
				AA1000000000000000000203 /* Sources */,
				AA1000000000000000000022 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				AA1000000000000000000401 /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				AA1000000000000000000012 /* TradingBotUITests */,
			);
			name = TradingBotUITests;
			packageProductDependencies = (
			);
			productName = TradingBotUITests;
			productReference = AA1000000000000000000005 /* TradingBotUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		AA1000000000000000000000 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2600;
				LastUpgradeCheck = 2600;
				TargetAttributes = {
					AA1000000000000000000100 = {
						CreatedOnToolsVersion = 26.0;
					};
					AA1000000000000000000101 = {
						CreatedOnToolsVersion = 26.0;
						TestTargetID = AA1000000000000000000100;
					};
					AA1000000000000000000102 = {
						CreatedOnToolsVersion = 26.0;
						TestTargetID = AA1000000000000000000100;
					};
				};
			};
			buildConfigurationList = AA1000000000000000000303 /* Build configuration list for PBXProject "TradingBot" */;
			compatibilityVersion = "Xcode 15.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = AA1000000000000000000001;
			minimizedProjectReferenceProxies = 1;
			preferredProjectObjectVersion = 77;
			productRefGroup = AA1000000000000000000002 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				AA1000000000000000000100 /* TradingBot */,
				AA1000000000000000000101 /* TradingBotTests */,
				AA1000000000000000000102 /* TradingBotUITests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		AA1000000000000000000201 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		AA1000000000000000000200 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AA1000000000000000000202 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		AA1000000000000000000203 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		AA1000000000000000000400 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = AA1000000000000000000100 /* TradingBot */;
			targetProxy = AA1000000000000000000500 /* PBXContainerItemProxy */;
		};
		AA1000000000000000000401 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = AA1000000000000000000100 /* TradingBot */;
			targetProxy = AA1000000000000000000501 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin PBXContainerItemProxy section */
		AA1000000000000000000500 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = AA1000000000000000000000 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = AA1000000000000000000100;
			remoteInfo = TradingBot;
		};
		AA1000000000000000000501 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = AA1000000000000000000000 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = AA1000000000000000000100;
			remoteInfo = TradingBot;
		};
/* End PBXContainerItemProxy section */

/* Begin XCBuildConfiguration section */
		AA1000000000000000000600 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		AA1000000000000000000601 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		AA1000000000000000000602 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tradingbot.ios;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		AA1000000000000000000603 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tradingbot.ios;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		AA1000000000000000000604 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tradingbot.ios.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/TradingBot.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TradingBot";
			};
			name = Debug;
		};
		AA1000000000000000000605 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tradingbot.ios.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/TradingBot.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TradingBot";
			};
			name = Release;
		};
		AA1000000000000000000606 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tradingbot.ios.uitests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = TradingBot;
			};
			name = Debug;
		};
		AA1000000000000000000607 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tradingbot.ios.uitests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = TradingBot;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		AA1000000000000000000300 /* Build configuration list for PBXNativeTarget "TradingBot" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA1000000000000000000602 /* Debug */,
				AA1000000000000000000603 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AA1000000000000000000301 /* Build configuration list for PBXNativeTarget "TradingBotTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA1000000000000000000604 /* Debug */,
				AA1000000000000000000605 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AA1000000000000000000302 /* Build configuration list for PBXNativeTarget "TradingBotUITests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA1000000000000000000606 /* Debug */,
				AA1000000000000000000607 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AA1000000000000000000303 /* Build configuration list for PBXProject "TradingBot" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA1000000000000000000600 /* Debug */,
				AA1000000000000000000601 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = AA1000000000000000000000 /* Project object */;
}
```

- [ ] **Step 4: Write the shared scheme**

Create `TradingBot.xcodeproj/xcshareddata/xcschemes/TradingBot.xcscheme`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "AA1000000000000000000100"
               BuildableName = "TradingBot.app"
               BlueprintName = "TradingBot"
               ReferencedContainer = "container:TradingBot.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "AA1000000000000000000101"
               BuildableName = "TradingBotTests.xctest"
               BlueprintName = "TradingBotTests"
               ReferencedContainer = "container:TradingBot.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "AA1000000000000000000102"
               BuildableName = "TradingBotUITests.xctest"
               BlueprintName = "TradingBotUITests"
               ReferencedContainer = "container:TradingBot.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "AA1000000000000000000100"
            BuildableName = "TradingBot.app"
            BlueprintName = "TradingBot"
            ReferencedContainer = "container:TradingBot.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "AA1000000000000000000100"
            BuildableName = "TradingBot.app"
            BlueprintName = "TradingBot"
            ReferencedContainer = "container:TradingBot.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
```

- [ ] **Step 5: Write the app entry point and tab shell**

`TradingBot/TradingBotApp.swift`:

```swift
import SwiftUI

@main
struct TradingBotApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
```

`TradingBot/Features/Root/MainTabView.swift`:

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                PlaceholderScreen(title: "Dashboard")
            }
            Tab("Portfolio", systemImage: "chart.pie.fill") {
                PlaceholderScreen(title: "Portfolio")
            }
            Tab("Positions", systemImage: "square.stack.3d.up.fill") {
                PlaceholderScreen(title: "Positions")
            }
            Tab("History", systemImage: "clock.fill") {
                PlaceholderScreen(title: "History")
            }
            Tab("Insights", systemImage: "lightbulb.fill") {
                PlaceholderScreen(title: "Insights")
            }
        }
    }
}

struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        NavigationStack {
            Text(title)
                .navigationTitle(title)
        }
    }
}
```

- [ ] **Step 6: Build to verify the scaffold compiles**

```bash
xcodebuild build -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO | tail -5
```

Expected: `** BUILD SUCCEEDED **`. If it fails with a pbxproj parse error, re-check the file was written byte-for-byte.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: Xcode project scaffold with tab shell and iPhone 16 simulator"
```

---

### Task 2: Design system — colors, typography, formatting, cards, badges, state views

**Files:**
- Create: `TradingBot/DesignSystem/AppColors.swift`
- Create: `TradingBot/DesignSystem/AppTypography.swift`
- Create: `TradingBot/DesignSystem/Formatters.swift`
- Create: `TradingBot/DesignSystem/Components/CardView.swift`
- Create: `TradingBot/DesignSystem/Components/BadgeView.swift`
- Create: `TradingBot/DesignSystem/Components/SkeletonView.swift`
- Create: `TradingBot/DesignSystem/Components/StateViews.swift`
- Create: `TradingBot/DesignSystem/LoadState.swift`
- Test: `TradingBotTests/DesignSystem/FormattersTests.swift`

**Interfaces:**
- Produces (used by all feature tasks):
  - `AppColors.pnlPositive`, `AppColors.pnlNegative`, `AppColors.cardBackground`, `AppColors.secondaryText`
  - `Formatters.currency(_ value: Double, decimals: Int = 2) -> String` → `"$179.79"` / `"-$21.70"` (minus BEFORE the $)
  - `Formatters.percent(_ value: Double) -> String` → `"22.2%"`
  - `Formatters.price(_ value: Double) -> String` → `"65,413.1"` (1 decimal, grouping)
  - `CardView<Content: View>`, `BadgeView(text:color:)`, `SkeletonView()`, `ErrorStateView(message:retry:)`, `EmptyStateView(title:systemImage:)`
  - `enum LoadState<Value>: Equatable` with cases `loading, loaded(Value), refreshing(Value), empty, error(String, Value?)` where `Value: Equatable`

- [ ] **Step 1: Write the failing formatter tests**

`TradingBotTests/DesignSystem/FormattersTests.swift`:

```swift
import Testing
@testable import TradingBot

@Suite("Formatters")
struct FormattersTests {
    @Test func currencyPositive() {
        #expect(Formatters.currency(179.79) == "$179.79")
    }

    @Test func currencyNegativePlacesMinusBeforeDollar() {
        #expect(Formatters.currency(-21.70) == "-$21.70")
    }

    @Test func currencyZero() {
        #expect(Formatters.currency(0) == "$0.00")
    }

    @Test func percentOneDecimal() {
        #expect(Formatters.percent(0.222) == "22.2%")
    }

    @Test func priceGroupingOneDecimal() {
        #expect(Formatters.price(65413.1) == "65,413.1")
    }

    @Test func priceSmallValue() {
        #expect(Formatters.price(78.3) == "78.3")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/FormattersTests 2>&1 | tail -5
```

Expected: FAIL — `cannot find 'Formatters' in scope`.

- [ ] **Step 3: Implement the design system**

`TradingBot/DesignSystem/Formatters.swift`:

```swift
import Foundation

enum Formatters {
    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.negativeFormat = "-$#,##0.00"
        return f
    }()

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()

    static func currency(_ value: Double, decimals: Int = 2) -> String {
        currencyFormatter.minimumFractionDigits = decimals
        currencyFormatter.maximumFractionDigits = decimals
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    static func price(_ value: Double) -> String {
        priceFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
```

`TradingBot/DesignSystem/AppColors.swift`:

```swift
import SwiftUI

enum AppColors {
    static let pnlPositive = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let pnlNegative = Color(red: 0.94, green: 0.27, blue: 0.23)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let secondaryText = Color.secondary
    static let blockedAmber = Color(red: 0.95, green: 0.61, blue: 0.07)

    static func pnl(_ value: Double) -> Color {
        value >= 0 ? pnlPositive : pnlNegative
    }
}
```

`TradingBot/DesignSystem/AppTypography.swift`:

```swift
import SwiftUI

enum AppTypography {
    static let largeEquity = Font.system(size: 34, weight: .bold, design: .default).monospacedDigit()
    static let statValue = Font.system(size: 17, weight: .semibold).monospacedDigit()
    static let statLabel = Font.system(size: 13, weight: .regular)
    static let cardTitle = Font.system(size: 15, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
}
```

`TradingBot/DesignSystem/LoadState.swift`:

```swift
import Foundation

enum LoadState<Value: Equatable>: Equatable {
    case loading
    case loaded(Value)
    case refreshing(Value)
    case empty
    case error(String, Value?)

    var value: Value? {
        switch self {
        case .loaded(let value), .refreshing(let value): value
        case .error(_, let last): last
        case .loading, .empty: nil
        }
    }
}
```

`TradingBot/DesignSystem/Components/CardView.swift`:

```swift
import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
```

`TradingBot/DesignSystem/Components/BadgeView.swift`:

```swift
import SwiftUI

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppTypography.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityLabel(text)
    }
}
```

`TradingBot/DesignSystem/Components/SkeletonView.swift`:

```swift
import SwiftUI

struct SkeletonView: View {
    var height: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: height)
            .accessibilityHidden(true)
    }
}
```

`TradingBot/DesignSystem/Components/StateViews.swift`:

```swift
import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .accessibilityIdentifier("errorState")
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage)
            .accessibilityIdentifier("emptyState")
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/FormattersTests 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: design system — colors, typography, formatters, cards, badges, state views"
```

---

### Task 3: Domain models, DTOs, mappers, sample snapshot.json

**Files:**
- Create: `TradingBot/Domain/Models.swift`
- Create: `TradingBot/Data/DTOs/SnapshotDTO.swift`
- Create: `TradingBot/Data/Mappers/SnapshotMapper.swift`
- Create: `TradingBot/Resources/snapshot.json`
- Test: `TradingBotTests/Data/SnapshotMapperTests.swift`

**Interfaces:**
- Produces (consumed by Tasks 4–10):
  - Domain: `struct DashboardSummary: Equatable, Sendable` (totalEquity, balance, winRate, todayPnL, allTimePnL: Double; openPositionsCount, totalTrades: Int; equityCurve: [EquityPoint])
  - `struct EquityPoint: Equatable, Sendable` (date: Date, equity: Double)
  - `struct PortfolioSummary: Equatable, Sendable` (equityCurve: [EquityPoint], high, low, current: Double, rangeStart, rangeEnd: Date)
  - `struct Position: Equatable, Sendable, Identifiable` (id: String, symbol, side: TradeSide, entryPrice, currentPrice, quantity: Double, leverage: Int, margin, takeProfit, stopLoss, unrealizedPnL: Double, openedAt: Date)
  - `enum TradeSide: String, Equatable, Sendable { case long = "LONG", short = "SHORT" }`
  - `struct Trade: Equatable, Sendable, Identifiable` (id: String, closedAt: Date, symbol, side: TradeSide, entryPrice, exitPrice, pnl: Double)
  - `struct InsightFeed: Equatable, Sendable` (vetoLog: [VetoEntry], lessons: [Lesson])
  - `struct VetoEntry: Equatable, Sendable, Identifiable` (id: String, timestamp: Date, symbol, side: String (BUY/SELL order direction), status: VetoStatus, reason: String)
  - `enum VetoStatus: String, Equatable, Sendable { case proceed = "PROCEED", blocked = "BLOCKED" }`
  - `struct Lesson: Equatable, Sendable, Identifiable` (id: String, title, detail: String, tags: [String])
  - `struct Breakdown: Equatable, Sendable` (bySymbol: [SymbolBreakdown], byRegime: [RegimeBreakdown])
  - `struct SymbolBreakdown: Equatable, Sendable, Identifiable` (id: String = symbol; symbol: String, trades: Int, winRate, netPnL: Double)
  - `struct RegimeBreakdown: Equatable, Sendable, Identifiable` (id: String = regime; regime: String, trades: Int, winRate: Double)
  - Aggregate: `struct BotSnapshot: Equatable, Sendable` (dashboard: DashboardSummary, portfolio: PortfolioSummary, positions: [Position], trades: [Trade], insights: InsightFeed, breakdown: Breakdown)
  - DTO: `struct SnapshotDTO: Decodable` with nested DTOs; `enum SnapshotMapper { static func map(_ dto: SnapshotDTO) -> BotSnapshot }`
  - JSON dates: ISO8601 with fractional seconds (`2026-07-23T08:15:00Z`).

- [ ] **Step 1: Write the failing mapper tests**

`TradingBotTests/Data/SnapshotMapperTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/SnapshotMapperTests 2>&1 | tail -5
```

Expected: FAIL — cannot find `SnapshotDTO` / `SnapshotMapper` in scope.

- [ ] **Step 3: Implement domain models**

`TradingBot/Domain/Models.swift`:

```swift
import Foundation

struct EquityPoint: Equatable, Sendable {
    let date: Date
    let equity: Double
}

struct DashboardSummary: Equatable, Sendable {
    let totalEquity: Double
    let balance: Double
    let winRate: Double
    let todayPnL: Double
    let allTimePnL: Double
    let openPositionsCount: Int
    let totalTrades: Int
    let equityCurve: [EquityPoint]
}

struct PortfolioSummary: Equatable, Sendable {
    let equityCurve: [EquityPoint]
    let high: Double
    let low: Double
    let current: Double
    let rangeStart: Date
    let rangeEnd: Date
}

enum TradeSide: String, Equatable, Sendable {
    case long = "LONG"
    case short = "SHORT"
}

struct Position: Equatable, Sendable, Identifiable {
    let id: String
    let symbol: String
    let side: TradeSide
    let entryPrice: Double
    let currentPrice: Double
    let quantity: Double
    let leverage: Int
    let margin: Double
    let takeProfit: Double
    let stopLoss: Double
    let unrealizedPnL: Double
    let openedAt: Date
}

struct Trade: Equatable, Sendable, Identifiable {
    let id: String
    let closedAt: Date
    let symbol: String
    let side: TradeSide
    let entryPrice: Double
    let exitPrice: Double
    let pnl: Double
}

enum VetoStatus: String, Equatable, Sendable {
    case proceed = "PROCEED"
    case blocked = "BLOCKED"
}

struct VetoEntry: Equatable, Sendable, Identifiable {
    let id: String
    let timestamp: Date
    let symbol: String
    let side: String // BUY / SELL order direction — not TradeSide
    let status: VetoStatus
    let reason: String
}

struct Lesson: Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let tags: [String]
}

struct InsightFeed: Equatable, Sendable {
    let vetoLog: [VetoEntry]
    let lessons: [Lesson]
}

struct SymbolBreakdown: Equatable, Sendable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let trades: Int
    let winRate: Double
    let netPnL: Double
}

struct RegimeBreakdown: Equatable, Sendable, Identifiable {
    var id: String { regime }
    let regime: String
    let trades: Int
    let winRate: Double
}

struct Breakdown: Equatable, Sendable {
    let bySymbol: [SymbolBreakdown]
    let byRegime: [RegimeBreakdown]
}

struct BotSnapshot: Equatable, Sendable {
    let dashboard: DashboardSummary
    let portfolio: PortfolioSummary
    let positions: [Position]
    let trades: [Trade]
    let insights: InsightFeed
    let breakdown: Breakdown
}
```

- [ ] **Step 4: Implement DTO + mapper**

`TradingBot/Data/DTOs/SnapshotDTO.swift`:

```swift
import Foundation

struct SnapshotDTO: Decodable {
    let dashboard: DashboardDTO
    let portfolio: PortfolioDTO
    let positions: [PositionDTO]
    let trades: [TradeDTO]
    let insights: InsightsDTO
    let breakdown: BreakdownDTO

    struct DashboardDTO: Decodable {
        let totalEquity: Double
        let balance: Double
        let winRate: Double
        let todayPnL: Double
        let allTimePnL: Double
        let openPositionsCount: Int
        let totalTrades: Int
        let equityCurve: [EquityPointDTO]
    }

    struct PortfolioDTO: Decodable {
        let equityCurve: [EquityPointDTO]
        let high: Double
        let low: Double
        let current: Double
        let rangeStart: Date
        let rangeEnd: Date
    }

    struct EquityPointDTO: Decodable {
        let date: Date
        let equity: Double
    }

    struct PositionDTO: Decodable {
        let id: String
        let symbol: String
        let side: String
        let entryPrice: Double
        let currentPrice: Double
        let quantity: Double
        let leverage: Int
        let margin: Double
        let takeProfit: Double
        let stopLoss: Double
        let unrealizedPnL: Double
        let openedAt: Date
    }

    struct TradeDTO: Decodable {
        let id: String
        let closedAt: Date
        let symbol: String
        let side: String
        let entryPrice: Double
        let exitPrice: Double
        let pnl: Double
    }

    struct InsightsDTO: Decodable {
        let vetoLog: [VetoEntryDTO]
        let lessons: [LessonDTO]
    }

    struct VetoEntryDTO: Decodable {
        let id: String
        let timestamp: Date
        let symbol: String
        let side: String
        let status: String
        let reason: String
    }

    struct LessonDTO: Decodable {
        let id: String
        let title: String
        let detail: String
        let tags: [String]
    }

    struct BreakdownDTO: Decodable {
        let bySymbol: [SymbolBreakdownDTO]
        let byRegime: [RegimeBreakdownDTO]
    }

    struct SymbolBreakdownDTO: Decodable {
        let symbol: String
        let trades: Int
        let winRate: Double
        let netPnL: Double
    }

    struct RegimeBreakdownDTO: Decodable {
        let regime: String
        let trades: Int
        let winRate: Double
    }
}

extension JSONDecoder {
    static var snapshot: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
```

`TradingBot/Data/Mappers/SnapshotMapper.swift`:

```swift
import Foundation

enum SnapshotMapper {
    static func map(_ dto: SnapshotDTO) -> BotSnapshot {
        BotSnapshot(
            dashboard: DashboardSummary(
                totalEquity: dto.dashboard.totalEquity,
                balance: dto.dashboard.balance,
                winRate: dto.dashboard.winRate,
                todayPnL: dto.dashboard.todayPnL,
                allTimePnL: dto.dashboard.allTimePnL,
                openPositionsCount: dto.dashboard.openPositionsCount,
                totalTrades: dto.dashboard.totalTrades,
                equityCurve: dto.dashboard.equityCurve.map { EquityPoint(date: $0.date, equity: $0.equity) }
            ),
            portfolio: PortfolioSummary(
                equityCurve: dto.portfolio.equityCurve.map { EquityPoint(date: $0.date, equity: $0.equity) },
                high: dto.portfolio.high,
                low: dto.portfolio.low,
                current: dto.portfolio.current,
                rangeStart: dto.portfolio.rangeStart,
                rangeEnd: dto.portfolio.rangeEnd
            ),
            positions: dto.positions.map {
                Position(
                    id: $0.id,
                    symbol: $0.symbol,
                    side: TradeSide(rawValue: $0.side) ?? .long,
                    entryPrice: $0.entryPrice,
                    currentPrice: $0.currentPrice,
                    quantity: $0.quantity,
                    leverage: $0.leverage,
                    margin: $0.margin,
                    takeProfit: $0.takeProfit,
                    stopLoss: $0.stopLoss,
                    unrealizedPnL: $0.unrealizedPnL,
                    openedAt: $0.openedAt
                )
            },
            trades: dto.trades.map {
                Trade(
                    id: $0.id,
                    closedAt: $0.closedAt,
                    symbol: $0.symbol,
                    side: TradeSide(rawValue: $0.side) ?? .long,
                    entryPrice: $0.entryPrice,
                    exitPrice: $0.exitPrice,
                    pnl: $0.pnl
                )
            },
            insights: InsightFeed(
                vetoLog: dto.insights.vetoLog.map {
                    VetoEntry(
                        id: $0.id,
                        timestamp: $0.timestamp,
                        symbol: $0.symbol,
                        side: $0.side,
                        status: VetoStatus(rawValue: $0.status) ?? .proceed,
                        reason: $0.reason
                    )
                },
                lessons: dto.insights.lessons.map {
                    Lesson(id: $0.id, title: $0.title, detail: $0.detail, tags: $0.tags)
                }
            ),
            breakdown: Breakdown(
                bySymbol: dto.breakdown.bySymbol.map {
                    SymbolBreakdown(symbol: $0.symbol, trades: $0.trades, winRate: $0.winRate, netPnL: $0.netPnL)
                },
                byRegime: dto.breakdown.byRegime.map {
                    RegimeBreakdown(regime: $0.regime, trades: $0.trades, winRate: $0.winRate)
                }
            )
        )
    }
}
```

- [ ] **Step 5: Write the sample snapshot.json**

`TradingBot/Resources/snapshot.json` — values taken from the mockup. Generate ~30 equity-curve points trending 200 → 80 between 2026-06-24 and 2026-07-23 (write them out; do not compute at runtime):

```json
{
  "dashboard": {
    "totalEquity": 179.79,
    "balance": 81.67,
    "winRate": 0.222,
    "todayPnL": 0.0,
    "allTimePnL": -21.7,
    "openPositionsCount": 1,
    "totalTrades": 27,
    "equityCurve": [
      { "date": "2026-06-24T00:00:00Z", "equity": 201.5 },
      { "date": "2026-06-27T00:00:00Z", "equity": 196.2 },
      { "date": "2026-06-30T00:00:00Z", "equity": 189.8 },
      { "date": "2026-07-03T00:00:00Z", "equity": 172.4 },
      { "date": "2026-07-06T00:00:00Z", "equity": 158.1 },
      { "date": "2026-07-09T00:00:00Z", "equity": 149.6 },
      { "date": "2026-07-12T00:00:00Z", "equity": 133.2 },
      { "date": "2026-07-15T00:00:00Z", "equity": 121.7 },
      { "date": "2026-07-18T00:00:00Z", "equity": 104.3 },
      { "date": "2026-07-21T00:00:00Z", "equity": 91.5 },
      { "date": "2026-07-23T00:00:00Z", "equity": 79.8 }
    ]
  },
  "portfolio": {
    "high": 185.0,
    "low": 75.0,
    "current": 79.8,
    "rangeStart": "2026-06-24T00:00:00Z",
    "rangeEnd": "2026-07-23T00:00:00Z",
    "equityCurve": [
      { "date": "2026-06-24T00:00:00Z", "equity": 185.0 },
      { "date": "2026-06-27T00:00:00Z", "equity": 181.2 },
      { "date": "2026-06-30T00:00:00Z", "equity": 174.8 },
      { "date": "2026-07-03T00:00:00Z", "equity": 160.4 },
      { "date": "2026-07-06T00:00:00Z", "equity": 148.1 },
      { "date": "2026-07-09T00:00:00Z", "equity": 139.6 },
      { "date": "2026-07-12T00:00:00Z", "equity": 125.2 },
      { "date": "2026-07-15T00:00:00Z", "equity": 114.7 },
      { "date": "2026-07-18T00:00:00Z", "equity": 99.3 },
      { "date": "2026-07-21T00:00:00Z", "equity": 87.5 },
      { "date": "2026-07-23T00:00:00Z", "equity": 79.8 }
    ]
  },
  "positions": [
    {
      "id": "pos-1",
      "symbol": "BTCUSDT",
      "side": "LONG",
      "entryPrice": 65413.1,
      "currentPrice": 64857.0,
      "quantity": 0.003,
      "leverage": 2,
      "margin": 98.12,
      "takeProfit": 67375.5,
      "stopLoss": 64431.9,
      "unrealizedPnL": -1.67,
      "openedAt": "2026-07-23T07:55:00Z"
    }
  ],
  "trades": [
    { "id": "tr-1", "closedAt": "2026-07-23T08:15:00Z", "symbol": "BTCUSDT", "side": "LONG", "entryPrice": 65071.3, "exitPrice": 64857.0, "pnl": -2.34 },
    { "id": "tr-2", "closedAt": "2026-07-22T09:40:00Z", "symbol": "SOLUSDT", "side": "LONG", "entryPrice": 78.3, "exitPrice": 77.1, "pnl": -1.72 },
    { "id": "tr-3", "closedAt": "2026-07-21T04:06:00Z", "symbol": "BTCUSDT", "side": "LONG", "entryPrice": 63977.9, "exitPrice": 65898.5, "pnl": 5.6 }
  ],
  "insights": {
    "vetoLog": [
      { "id": "v-1", "timestamp": "2026-07-23T07:52:00Z", "symbol": "BTCUSDT", "side": "SELL", "status": "PROCEED", "reason": "Strong bearish momentum aligned with trend. Risk-reward favorable." },
      { "id": "v-2", "timestamp": "2026-07-22T08:12:00Z", "symbol": "SOLUSDT", "side": "BUY", "status": "BLOCKED", "reason": "Overextended above Bollinger Band top. High risk of mean reversion." },
      { "id": "v-3", "timestamp": "2026-07-21T03:48:00Z", "symbol": "BTCUSDT", "side": "BUY", "status": "PROCEED", "reason": "Pullback to key support with bullish divergence. Good entry zone." }
    ],
    "lessons": [
      { "id": "l-1", "title": "Buying near Bollinger Band tops", "detail": "Repeated losses from entering long positions when price is overextended above the upper Bollinger Band.", "tags": ["chasing_up", "no_extension", "overextended_entry"] },
      { "id": "l-2", "title": "Chasing pumps in low volume", "detail": "Entering during sharp price spikes on low volume leads to fakeouts and immediate reversals.", "tags": ["low_volume", "fakeout"] }
    ]
  },
  "breakdown": {
    "bySymbol": [
      { "symbol": "SOLUSDT", "trades": 18, "winRate": 0.222, "netPnL": -16.15 },
      { "symbol": "BTCUSDT", "trades": 9, "winRate": 0.222, "netPnL": -5.55 }
    ],
    "byRegime": [
      { "regime": "Trending Up", "trades": 16, "winRate": 0.25 },
      { "regime": "Trending Down", "trades": 8, "winRate": 0.125 },
      { "regime": "Transitioning", "trades": 2, "winRate": 0.0 },
      { "regime": "Ranging", "trades": 1, "winRate": 1.0 }
    ]
  }
}
```

Note: `VetoEntryDTO.side` in the fixture uses BUY/SELL (order direction), so `VetoEntry.side` stays a plain `String`; only `Position`/`Trade` use the `TradeSide` enum. The mapper code above already reflects this.

- [ ] **Step 6: Run tests to verify they pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/SnapshotMapperTests 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: domain models, snapshot DTO/mapper, sample data fixture"
```

---

### Task 4: BotDataProvider protocol, bundled provider, caching repository

**Files:**
- Create: `TradingBot/Data/BotDataProvider.swift`
- Create: `TradingBot/Data/BundledBotDataProvider.swift`
- Create: `TradingBot/Core/Storage/JSONCacheStore.swift`
- Create: `TradingBot/Data/SnapshotRepository.swift`
- Test: `TradingBotTests/Data/SnapshotRepositoryTests.swift`
- Test: `TradingBotTests/Data/MockBotDataProvider.swift`

**Interfaces:**
- Consumes: `BotSnapshot`, `SnapshotDTO`, `SnapshotMapper`, `JSONDecoder.snapshot` (Task 3).
- Produces (consumed by Tasks 5–10):
  - `protocol BotDataProvider: Sendable { func fetchSnapshot() async throws -> BotSnapshot }`
  - `struct BundledBotDataProvider: BotDataProvider` (reads `snapshot.json` from `Bundle.main`)
  - `actor JSONCacheStore` with `func load() -> BotSnapshot?` and `func save(_ snapshot: BotSnapshot)`
  - `struct SnapshotRepository: Sendable` with `init(provider: any BotDataProvider, cache: JSONCacheStore)` and `func snapshot() async -> LoadState<BotSnapshot>` — returns cached/bundled data on failure instead of throwing
  - `enum SnapshotRepositoryError: Error { case noData }`

- [ ] **Step 1: Write the failing repository tests**

`TradingBotTests/Data/MockBotDataProvider.swift`:

```swift
import Foundation
@testable import TradingBot

final class MockBotDataProvider: BotDataProvider, @unchecked Sendable {
    var result: Result<BotSnapshot, Error>
    var callCount = 0

    init(result: Result<BotSnapshot, Error>) {
        self.result = result
    }

    func fetchSnapshot() async throws -> BotSnapshot {
        callCount += 1
        return try result.get()
    }
}
```

`TradingBotTests/Data/SnapshotRepositoryTests.swift`:

```swift
import Foundation
import Testing
@testable import TradingBot

@Suite("SnapshotRepository")
struct SnapshotRepositoryTests {
    private func makeSnapshot(equity: Double = 179.79) -> BotSnapshot {
        let point = EquityPoint(date: Date(timeIntervalSince1970: 1_752_192_000), equity: equity)
        let curve = [point]
        return BotSnapshot(
            dashboard: DashboardSummary(totalEquity: equity, balance: 81.67, winRate: 0.222, todayPnL: 0, allTimePnL: -21.7, openPositionsCount: 1, totalTrades: 27, equityCurve: curve),
            portfolio: PortfolioSummary(equityCurve: curve, high: 185, low: 75, current: 79.8, rangeStart: point.date, rangeEnd: point.date),
            positions: [],
            trades: [],
            insights: InsightFeed(vetoLog: [], lessons: []),
            breakdown: Breakdown(bySymbol: [], byRegime: [])
        )
    }

    private func makeCache() -> JSONCacheStore {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        return JSONCacheStore(directory: dir)
    }

    @Test func returnsLoadedOnSuccess() async {
        let repo = SnapshotRepository(provider: MockBotDataProvider(result: .success(makeSnapshot())), cache: makeCache())
        let state = await repo.snapshot()
        #expect(state.value?.dashboard.totalEquity == 179.79)
        guard case .loaded = state else { Issue.record("expected .loaded, got \(state)"); return }
    }

    @Test func fallsBackToCacheOnFailure() async {
        let cache = makeCache()
        await cache.save(makeSnapshot(equity: 100))
        let repo = SnapshotRepository(provider: MockBotDataProvider(result: .failure(URLError(.notConnectedToInternet))), cache: cache)
        let state = await repo.snapshot()
        #expect(state.value?.dashboard.totalEquity == 100)
        guard case .error = state else { Issue.record("expected .error with cached value, got \(state)"); return }
    }

    @Test func cacheRoundTrip() async {
        let cache = makeCache()
        await cache.save(makeSnapshot(equity: 42))
        let loaded = await cache.load()
        #expect(loaded?.dashboard.totalEquity == 42)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/SnapshotRepositoryTests 2>&1 | tail -5
```

Expected: FAIL — cannot find `BotDataProvider` / `SnapshotRepository` / `JSONCacheStore`.

- [ ] **Step 3: Implement provider protocol and bundled provider**

`TradingBot/Data/BotDataProvider.swift`:

```swift
import Foundation

protocol BotDataProvider: Sendable {
    func fetchSnapshot() async throws -> BotSnapshot
}
```

`TradingBot/Data/BundledBotDataProvider.swift`:

```swift
import Foundation

struct BundledBotDataProvider: BotDataProvider {
    enum BundledError: Error {
        case missingResource
    }

    func fetchSnapshot() async throws -> BotSnapshot {
        guard let url = Bundle.main.url(forResource: "snapshot", withExtension: "json") else {
            throw BundledError.missingResource
        }
        let data = try Data(contentsOf: url)
        let dto = try JSONDecoder.snapshot.decode(SnapshotDTO.self, from: data)
        return SnapshotMapper.map(dto)
    }
}
```

- [ ] **Step 4: Implement the cache store**

`TradingBot/Core/Storage/JSONCacheStore.swift`:

```swift
import Foundation

actor JSONCacheStore {
    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.fileURL = dir.appending(path: "snapshot-cache.json")
    }

    func load() -> BotSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let dto = try? JSONDecoder.snapshot.decode(SnapshotDTO.self, from: data)
        return dto.map(SnapshotMapper.map)
    }

    func save(_ snapshot: BotSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(SnapshotMapper.dto(from: snapshot)) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}
```

Add the reverse mapper to `TradingBot/Data/Mappers/SnapshotMapper.swift` (append inside `enum SnapshotMapper`):

```swift
    static func dto(from snapshot: BotSnapshot) -> SnapshotDTO {
        SnapshotDTO(
            dashboard: SnapshotDTO.DashboardDTO(
                totalEquity: snapshot.dashboard.totalEquity,
                balance: snapshot.dashboard.balance,
                winRate: snapshot.dashboard.winRate,
                todayPnL: snapshot.dashboard.todayPnL,
                allTimePnL: snapshot.dashboard.allTimePnL,
                openPositionsCount: snapshot.dashboard.openPositionsCount,
                totalTrades: snapshot.dashboard.totalTrades,
                equityCurve: snapshot.dashboard.equityCurve.map { SnapshotDTO.EquityPointDTO(date: $0.date, equity: $0.equity) }
            ),
            portfolio: SnapshotDTO.PortfolioDTO(
                equityCurve: snapshot.portfolio.equityCurve.map { SnapshotDTO.EquityPointDTO(date: $0.date, equity: $0.equity) },
                high: snapshot.portfolio.high,
                low: snapshot.portfolio.low,
                current: snapshot.portfolio.current,
                rangeStart: snapshot.portfolio.rangeStart,
                rangeEnd: snapshot.portfolio.rangeEnd
            ),
            positions: snapshot.positions.map {
                SnapshotDTO.PositionDTO(id: $0.id, symbol: $0.symbol, side: $0.side.rawValue, entryPrice: $0.entryPrice, currentPrice: $0.currentPrice, quantity: $0.quantity, leverage: $0.leverage, margin: $0.margin, takeProfit: $0.takeProfit, stopLoss: $0.stopLoss, unrealizedPnL: $0.unrealizedPnL, openedAt: $0.openedAt)
            },
            trades: snapshot.trades.map {
                SnapshotDTO.TradeDTO(id: $0.id, closedAt: $0.closedAt, symbol: $0.symbol, side: $0.side.rawValue, entryPrice: $0.entryPrice, exitPrice: $0.exitPrice, pnl: $0.pnl)
            },
            insights: SnapshotDTO.InsightsDTO(
                vetoLog: snapshot.insights.vetoLog.map {
                    SnapshotDTO.VetoEntryDTO(id: $0.id, timestamp: $0.timestamp, symbol: $0.symbol, side: $0.side, status: $0.status.rawValue, reason: $0.reason)
                },
                lessons: snapshot.insights.lessons.map {
                    SnapshotDTO.LessonDTO(id: $0.id, title: $0.title, detail: $0.detail, tags: $0.tags)
                }
            ),
            breakdown: SnapshotDTO.BreakdownDTO(
                bySymbol: snapshot.breakdown.bySymbol.map {
                    SnapshotDTO.SymbolBreakdownDTO(symbol: $0.symbol, trades: $0.trades, winRate: $0.winRate, netPnL: $0.netPnL)
                },
                byRegime: snapshot.breakdown.byRegime.map {
                    SnapshotDTO.RegimeBreakdownDTO(regime: $0.regime, trades: $0.trades, winRate: $0.winRate)
                }
            )
        )
    }
```

For this to compile, `SnapshotDTO` and all nested DTOs must gain `Encodable` conformance and memberwise initializers. In `SnapshotDTO.swift`: change every `Decodable` to `Codable`, and add explicit memberwise `init`s (Codable structs' synthesized memberwise init is internal — fine within the module, so just changing to `Codable` is enough; the mapper lives in the same module). No other change needed.

- [ ] **Step 5: Implement the repository**

`TradingBot/Data/SnapshotRepository.swift`:

```swift
import Foundation

struct SnapshotRepository: Sendable {
    let provider: any BotDataProvider
    let cache: JSONCacheStore

    func snapshot() async -> LoadState<BotSnapshot> {
        do {
            let snapshot = try await provider.fetchSnapshot()
            await cache.save(snapshot)
            return .loaded(snapshot)
        } catch {
            if let cached = await cache.load() {
                return .error(error.localizedDescription, cached)
            }
            return .error(error.localizedDescription, nil)
        }
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/SnapshotRepositoryTests 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: BotDataProvider protocol, bundled provider, JSON cache, snapshot repository"
```

---

### Task 5: HTTP client, remote provider, app configuration, DI container

**Files:**
- Create: `TradingBot/Core/Networking/HTTPClient.swift`
- Create: `TradingBot/Core/Networking/HTTPError.swift`
- Create: `TradingBot/Data/RemoteBotDataProvider.swift`
- Create: `TradingBot/Core/AppConfiguration.swift`
- Create: `TradingBot/Core/DI/AppContainer.swift`
- Modify: `TradingBot/TradingBotApp.swift`
- Test: `TradingBotTests/Networking/HTTPClientTests.swift`

**Interfaces:**
- Consumes: `BotDataProvider`, `SnapshotRepository`, `JSONCacheStore`, `LoadState` (Task 4).
- Produces:
  - `enum HTTPError: Error, Equatable { case invalidURL, httpStatus(Int), decoding, transport(String) }` with `var userMessage: String`
  - `struct HTTPClient: Sendable { init(session: URLSession = .shared); func get(_ url: URL) async throws -> Data }` — 10s timeout, maps errors to `HTTPError`, retries once on `.timedOut`/`.networkConnectionLost`
  - `struct RemoteBotDataProvider: BotDataProvider { init(baseURL: URL, client: HTTPClient) }` — GETs `<baseURL>/snapshot.json`
  - `struct AppConfiguration: Sendable { var baseURL: URL? }` — `nil` means bundled-only (Phase 1 default)
  - `@Observable final class AppContainer { let repository: SnapshotRepository }` — composition root
  - `TradingBotApp` injects `AppContainer` via `@State` + `.environment(container)`

- [ ] **Step 1: Write the failing HTTP client tests**

`TradingBotTests/Networking/HTTPClientTests.swift`:

```swift
import Foundation
import Testing
@testable import TradingBot

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else { return }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data { client?.urlProtocol(self, didLoad: data) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("HTTPClient")
struct HTTPClientTests {
    private func makeClient() -> HTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return HTTPClient(session: URLSession(configuration: config))
    }

    private func url() -> URL {
        URL(string: "https://example.com/snapshot.json")! // swiftlint:disable:this force_unwrapping
    }

    @Test func returnsDataOn200() async throws {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)! // test-only
            return (response, Data("{\"ok\":true}".utf8))
        }
        let data = try await makeClient().get(url())
        #expect(String(data: data, encoding: .utf8) == "{\"ok\":true}")
    }

    @Test func throwsHTTPStatusOn404() async {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)! // test-only
            return (response, nil)
        }
        do {
            _ = try await makeClient().get(url())
            Issue.record("expected throw")
        } catch let error as HTTPError {
            #expect(error == .httpStatus(404))
        } catch {
            Issue.record("wrong error type: \(error)")
        }
    }

    @Test func userMessagesAreReadable() {
        #expect(!HTTPError.httpStatus(401).userMessage.isEmpty)
        #expect(!HTTPError.transport("offline").userMessage.isEmpty)
    }
}
```

Note: the two `!` in the stub handler are inside test-only code and unavoidable with `HTTPURLResponse`; keep them, do not add lint suppressions elsewhere.

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/HTTPClientTests 2>&1 | tail -5
```

Expected: FAIL — cannot find `HTTPClient` / `HTTPError`.

- [ ] **Step 3: Implement HTTPError and HTTPClient**

`TradingBot/Core/Networking/HTTPError.swift`:

```swift
import Foundation

enum HTTPError: Error, Equatable {
    case invalidURL
    case httpStatus(Int)
    case decoding
    case transport(String)

    var userMessage: String {
        switch self {
        case .invalidURL:
            "Invalid server address."
        case .httpStatus(401):
            "Session expired. Please sign in again."
        case .httpStatus(403):
            "You don't have access to this resource."
        case .httpStatus(404):
            "The requested data was not found."
        case .httpStatus(let code) where code >= 500:
            "The server is having trouble. Try again shortly."
        case .httpStatus(let code):
            "Request failed (HTTP \(code))."
        case .decoding:
            "Received unexpected data from the server."
        case .transport:
            "Network unavailable. Check your connection and retry."
        }
    }
}
```

`TradingBot/Core/Networking/HTTPClient.swift`:

```swift
import Foundation

struct HTTPClient: Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"
        return try await perform(request, allowRetry: true)
    }

    private func perform(_ request: URLRequest, allowRetry: Bool) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw HTTPError.transport("invalid response")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw HTTPError.httpStatus(http.statusCode)
            }
            return data
        } catch let error as HTTPError {
            throw error
        } catch let error as URLError where allowRetry && (error.code == .timedOut || error.code == .networkConnectionLost) {
            return try await perform(request, allowRetry: false)
        } catch {
            throw HTTPError.transport(error.localizedDescription)
        }
    }
}
```

- [ ] **Step 4: Implement remote provider, configuration, and container**

`TradingBot/Data/RemoteBotDataProvider.swift`:

```swift
import Foundation

struct RemoteBotDataProvider: BotDataProvider {
    let baseURL: URL
    let client: HTTPClient

    func fetchSnapshot() async throws -> BotSnapshot {
        let url = baseURL.appending(path: "snapshot.json")
        let data = try await client.get(url)
        guard let dto = try? JSONDecoder.snapshot.decode(SnapshotDTO.self, from: data) else {
            throw HTTPError.decoding
        }
        return SnapshotMapper.map(dto)
    }
}
```

`TradingBot/Core/AppConfiguration.swift`:

```swift
import Foundation

struct AppConfiguration: Sendable {
    /// Base URL of the bot dashboard, e.g. https://165.227.151.108:8443
    /// `nil` = bundled snapshot only (Phase 1 default until API credentials exist).
    var baseURL: URL? = nil
}
```

`TradingBot/Core/DI/AppContainer.swift`:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class AppContainer {
    let repository: SnapshotRepository

    init(configuration: AppConfiguration = AppConfiguration()) {
        let provider: any BotDataProvider
        if let baseURL = configuration.baseURL {
            provider = RemoteBotDataProvider(baseURL: baseURL, client: HTTPClient())
        } else {
            provider = BundledBotDataProvider()
        }
        self.repository = SnapshotRepository(provider: provider, cache: JSONCacheStore())
    }

    /// Test seam: inject any repository.
    init(repository: SnapshotRepository) {
        self.repository = repository
    }
}
```

Modify `TradingBot/TradingBotApp.swift`:

```swift
import SwiftUI

@main
struct TradingBotApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(container)
        }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/HTTPClientTests 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: HTTP client with retry, remote provider, app configuration, DI container"
```

---

### Task 6: SnapshotStore — shared polling state for all screens

**Files:**
- Create: `TradingBot/Data/SnapshotStore.swift`
- Test: `TradingBotTests/Data/SnapshotStoreTests.swift`

**Interfaces:**
- Consumes: `SnapshotRepository`, `LoadState`, `BotSnapshot` (Task 4), `MockBotDataProvider` (Task 4 test target).
- Produces (consumed by Tasks 7–11):
  - `@Observable @MainActor final class SnapshotStore` with:
    - `private(set) var state: LoadState<BotSnapshot> = .loading`
    - `init(repository: SnapshotRepository, pollInterval: Duration = .seconds(5))`
    - `func refresh() async` — one fetch; sets `.refreshing(current)` when data exists, `.loaded`/`.error` on result
    - `func startPolling()` — cancels any existing loop, then loops `refresh()` + `try? await Task.sleep(for: pollInterval)` until cancelled
    - `func stopPolling()`

- [ ] **Step 1: Write the failing store tests**

`TradingBotTests/Data/SnapshotStoreTests.swift`:

```swift
import Foundation
import Testing
@testable import TradingBot

@Suite("SnapshotStore")
@MainActor
struct SnapshotStoreTests {
    private func makeSnapshot(equity: Double = 179.79) -> BotSnapshot {
        let point = EquityPoint(date: Date(timeIntervalSince1970: 1_752_192_000), equity: equity)
        return BotSnapshot(
            dashboard: DashboardSummary(totalEquity: equity, balance: 81.67, winRate: 0.222, todayPnL: 0, allTimePnL: -21.7, openPositionsCount: 1, totalTrades: 27, equityCurve: [point]),
            portfolio: PortfolioSummary(equityCurve: [point], high: 185, low: 75, current: 79.8, rangeStart: point.date, rangeEnd: point.date),
            positions: [],
            trades: [],
            insights: InsightFeed(vetoLog: [], lessons: []),
            breakdown: Breakdown(bySymbol: [], byRegime: [])
        )
    }

    private func makeStore(result: Result<BotSnapshot, Error>) -> (SnapshotStore, MockBotDataProvider) {
        let provider = MockBotDataProvider(result: result)
        let repo = SnapshotRepository(provider: provider, cache: JSONCacheStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        return (SnapshotStore(repository: repo, pollInterval: .seconds(3600)), provider)
    }

    @Test func refreshLoadsSnapshot() async {
        let (store, _) = makeStore(result: .success(makeSnapshot()))
        await store.refresh()
        #expect(store.state.value?.dashboard.totalEquity == 179.79)
        guard case .loaded = store.state else { Issue.record("expected .loaded, got \(store.state)"); return }
    }

    @Test func refreshFailureKeepsPreviousValueAsError() async {
        let (store, provider) = makeStore(result: .success(makeSnapshot()))
        await store.refresh()
        provider.result = .failure(URLError(.notConnectedToInternet))
        await store.refresh()
        guard case .error(_, let last) = store.state else { Issue.record("expected .error, got \(store.state)"); return }
        #expect(last?.dashboard.totalEquity == 179.79)
    }

    @Test func startPollingFetchesRepeatedly() async throws {
        let (store, provider) = makeStore(result: .success(makeSnapshot()))
        let repo = SnapshotRepository(provider: provider, cache: JSONCacheStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        let pollingStore = SnapshotStore(repository: repo, pollInterval: .milliseconds(50))
        pollingStore.startPolling()
        try await Task.sleep(for: .milliseconds(200))
        pollingStore.stopPolling()
        #expect(provider.callCount >= 2)
        _ = store
    }

    @Test func stopPollingCancelsLoop() async throws {
        let (store, provider) = makeStore(result: .success(makeSnapshot()))
        let repo = SnapshotRepository(provider: provider, cache: JSONCacheStore(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        let pollingStore = SnapshotStore(repository: repo, pollInterval: .milliseconds(50))
        pollingStore.startPolling()
        try await Task.sleep(for: .milliseconds(120))
        pollingStore.stopPolling()
        let countAfterStop = provider.callCount
        try await Task.sleep(for: .milliseconds(150))
        #expect(provider.callCount == countAfterStop)
        _ = store
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/SnapshotStoreTests 2>&1 | tail -5
```

Expected: FAIL — cannot find `SnapshotStore`.

- [ ] **Step 3: Implement SnapshotStore**

`TradingBot/Data/SnapshotStore.swift`:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class SnapshotStore {
    private(set) var state: LoadState<BotSnapshot> = .loading

    private let repository: SnapshotRepository
    private let pollInterval: Duration
    private var pollingTask: Task<Void, Never>?

    init(repository: SnapshotRepository, pollInterval: Duration = .seconds(5)) {
        self.repository = repository
        self.pollInterval = pollInterval
    }

    func refresh() async {
        if let current = state.value {
            state = .refreshing(current)
        }
        state = await repository.snapshot()
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: self?.pollInterval ?? .seconds(5))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/SnapshotStoreTests 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`. (Timing-sensitive tests use 50ms intervals; if flaky on a slow machine, raise to 100ms — do not delete them.)

- [ ] **Step 5: Wire the store into the container**

Modify `TradingBot/Core/DI/AppContainer.swift` — replace the whole file:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class AppContainer {
    let repository: SnapshotRepository
    let store: SnapshotStore

    init(configuration: AppConfiguration = AppConfiguration()) {
        let provider: any BotDataProvider
        if let baseURL = configuration.baseURL {
            provider = RemoteBotDataProvider(baseURL: baseURL, client: HTTPClient())
        } else {
            provider = BundledBotDataProvider()
        }
        let repository = SnapshotRepository(provider: provider, cache: JSONCacheStore())
        self.repository = repository
        self.store = SnapshotStore(repository: repository)
    }

    /// Test seam: inject any repository.
    init(repository: SnapshotRepository) {
        self.repository = repository
        self.store = SnapshotStore(repository: repository)
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: SnapshotStore polling state shared across screens"
```

---

### Task 7: Dashboard screen

**Files:**
- Create: `TradingBot/Features/Dashboard/DashboardView.swift`
- Create: `TradingBot/DesignSystem/Components/StatItemView.swift`
- Create: `TradingBot/DesignSystem/Components/EquityChartView.swift`
- Modify: `TradingBot/Features/Root/MainTabView.swift`

**Interfaces:**
- Consumes: `SnapshotStore` (Task 6) via `@Environment(AppContainer.self)` → `container.store`; `DashboardSummary`, `EquityPoint`; `CardView`, `SkeletonView`, `ErrorStateView`, `Formatters`, `AppColors`, `AppTypography` (Task 2).
- Produces:
  - `struct EquityChartView: View { init(points: [EquityPoint], showsAxes: Bool = false) }` — Swift Charts area+line, red gradient (mockup curve is declining/red), reused by Portfolio (Task 8) with `showsAxes: true`
  - `struct DashboardView: View { init(store: SnapshotStore) }`

- [ ] **Step 1: Implement reusable components**

`TradingBot/DesignSystem/Components/StatItemView.swift`:

```swift
import SwiftUI

struct StatItemView: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTypography.statLabel)
                .foregroundStyle(AppColors.secondaryText)
            HStack(spacing: 6) {
                Text(value)
                    .font(AppTypography.statValue)
                    .foregroundStyle(valueColor)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
```

`TradingBot/DesignSystem/Components/EquityChartView.swift`:

```swift
import Charts
import SwiftUI

struct EquityChartView: View {
    let points: [EquityPoint]
    var showsAxes: Bool = false

    private var trendColor: Color {
        guard let first = points.first?.equity, let last = points.last?.equity else {
            return AppColors.pnlNegative
        }
        return last >= first ? AppColors.pnlPositive : AppColors.pnlNegative
    }

    var body: some View {
        Chart(points, id: \.date) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .foregroundStyle(trendColor)
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Equity", point.equity)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [trendColor.opacity(0.25), trendColor.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis(showsAxes ? .visible : .hidden)
        .chartYAxis(showsAxes ? .visible : .hidden)
        .accessibilityLabel("Equity curve")
    }
}
```

- [ ] **Step 2: Implement DashboardView**

`TradingBot/Features/Dashboard/DashboardView.swift` (matches mockup screen 1: header "Trading Bot" + bell, Total Equity hero, 2×3 stat grid, Equity Curve card):

```swift
import SwiftUI

struct DashboardView: View {
    let store: SnapshotStore

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Trading Bot")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "bell")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Notifications")
                    }
                }
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            loadingView
        case .loaded(let snapshot), .refreshing(let snapshot):
            dashboardContent(snapshot.dashboard)
        case .empty:
            EmptyStateView(title: "No data yet", systemImage: "tray")
        case .error(let message, let last):
            if let last {
                dashboardContent(last.dashboard)
                    .overlay(alignment: .top) { offlineBanner(message) }
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func dashboardContent(_ summary: DashboardSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Equity")
                        .font(AppTypography.statLabel)
                        .foregroundStyle(AppColors.secondaryText)
                    Text(Formatters.currency(summary.totalEquity))
                        .font(AppTypography.largeEquity)
                        .contentTransition(.numericText())
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("totalEquity")

                CardView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StatItemView(label: "Balance", value: Formatters.currency(summary.balance))
                        StatItemView(label: "All-Time P/L", value: Formatters.currency(summary.allTimePnL), valueColor: AppColors.pnl(summary.allTimePnL))
                        StatItemView(label: "Win Rate", value: Formatters.percent(summary.winRate))
                        StatItemView(label: "Open Positions", value: "\(summary.openPositionsCount)", systemImage: "person.crop.circle")
                        StatItemView(label: "Today P/L", value: Formatters.currency(summary.todayPnL), valueColor: AppColors.pnl(summary.todayPnL))
                        StatItemView(label: "Total Trades", value: "\(summary.totalTrades)", systemImage: "chart.bar.fill")
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Equity Curve (All-Time)")
                            .font(AppTypography.cardTitle)
                        EquityChartView(points: summary.equityCurve)
                            .frame(height: 140)
                    }
                }
            }
            .padding(16)
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                SkeletonView(height: 44)
                CardView { SkeletonView(height: 160) }
                CardView { SkeletonView(height: 180) }
            }
            .padding(16)
        }
    }

    private func offlineBanner(_ message: String) -> some View {
        Text("Offline — showing last known data")
            .font(AppTypography.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 4)
            .accessibilityLabel(message)
    }
}
```

- [ ] **Step 3: Wire DashboardView into the tab shell**

Modify `TradingBot/Features/Root/MainTabView.swift` — replace the whole file. Note the `.task { container.store.startPolling() }` on the TabView: polling starts once for the whole app; individual screens never start their own loops.

```swift
import SwiftUI

struct MainTabView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView(store: container.store)
            }
            Tab("Portfolio", systemImage: "chart.pie.fill") {
                PlaceholderScreen(title: "Portfolio")
            }
            Tab("Positions", systemImage: "square.stack.3d.up.fill") {
                PlaceholderScreen(title: "Positions")
            }
            Tab("History", systemImage: "clock.fill") {
                PlaceholderScreen(title: "History")
            }
            Tab("Insights", systemImage: "lightbulb.fill") {
                PlaceholderScreen(title: "Insights")
            }
        }
        .task { container.store.startPolling() }
    }
}

struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        NavigationStack {
            Text(title)
                .navigationTitle(title)
        }
    }
}
```

- [ ] **Step 4: Build and visually verify in the simulator**

```bash
xcodebuild build -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`. Then boot and screenshot:

```bash
xcrun simctl boot "iPhone 16" 2>/dev/null; open -a Simulator
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests 2>&1 | tail -3
```

Expected: `** TEST SUCCEEDED **` (full unit suite green with the new files).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: dashboard screen with stat grid and equity chart"
```

---

### Task 8: Portfolio screen

**Files:**
- Create: `TradingBot/Features/Portfolio/PortfolioView.swift`
- Modify: `TradingBot/Features/Root/MainTabView.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `PortfolioSummary`, `EquityChartView(showsAxes:)`, `CardView`, `Formatters`, state views (Tasks 2, 6, 7).
- Produces: `struct PortfolioView: View { init(store: SnapshotStore) }` — matches mockup screen 2: date-range header, large equity chart with axes, High/Low/Current row.

- [ ] **Step 1: Implement PortfolioView**

`TradingBot/Features/Portfolio/PortfolioView.swift`:

```swift
import SwiftUI

struct PortfolioView: View {
    let store: SnapshotStore

    private static let rangeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Portfolio")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Date range")
                    }
                }
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView { CardView { SkeletonView(height: 320) }.padding(16) }
        case .loaded(let snapshot), .refreshing(let snapshot):
            portfolioContent(snapshot.portfolio)
        case .empty:
            EmptyStateView(title: "No portfolio data", systemImage: "chart.pie")
        case .error(let message, let last):
            if let last {
                portfolioContent(last.portfolio)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func portfolioContent(_ portfolio: PortfolioSummary) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("\(Self.rangeFormatter.string(from: portfolio.rangeStart)) - \(Self.rangeFormatter.string(from: portfolio.rangeEnd))")
                        .font(AppTypography.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("dateRangeSelector")

                CardView {
                    EquityChartView(points: portfolio.equityCurve, showsAxes: true)
                        .frame(height: 300)
                }

                CardView {
                    HStack {
                        StatItemView(label: "High", value: Formatters.currency(portfolio.high, decimals: 0), valueColor: AppColors.pnlPositive)
                        StatItemView(label: "Low", value: Formatters.currency(portfolio.low, decimals: 0), valueColor: AppColors.pnlNegative)
                        StatItemView(label: "Current", value: Formatters.currency(portfolio.current))
                    }
                }
            }
            .padding(16)
        }
    }
}
```

- [ ] **Step 2: Replace the Portfolio placeholder in MainTabView**

In `TradingBot/Features/Root/MainTabView.swift`, replace:

```swift
            Tab("Portfolio", systemImage: "chart.pie.fill") {
                PlaceholderScreen(title: "Portfolio")
            }
```

with:

```swift
            Tab("Portfolio", systemImage: "chart.pie.fill") {
                PortfolioView(store: container.store)
            }
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild build -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: portfolio screen with full equity chart and high/low/current stats"
```

---

### Task 9: Open Positions screen

**Files:**
- Create: `TradingBot/Features/Positions/PositionsView.swift`
- Create: `TradingBot/Features/Positions/PositionCardView.swift`
- Modify: `TradingBot/Features/Root/MainTabView.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `Position`, `TradeSide`, `BadgeView`, `CardView`, `StatItemView`, `Formatters`, `AppColors` (Tasks 2, 3, 6).
- Produces: `struct PositionsView: View { init(store: SnapshotStore) }`, `struct PositionCardView: View { init(position: Position) }` — matches mockup screen 3: "N Open Position(s)" subtitle, card with symbol icon, LONG badge, duration, Entry Price/Quantity, Leverage/Margin, Take-Profit (green)/Stop-Loss (red).

- [ ] **Step 1: Implement PositionCardView**

`TradingBot/Features/Positions/PositionCardView.swift`:

```swift
import SwiftUI

struct PositionCardView: View {
    let position: Position

    private var durationText: String {
        let interval = Date.now.timeIntervalSince(position.openedAt)
        let minutes = max(1, Int(interval / 60))
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h \(minutes % 60)m" }
        return "\(hours / 24)d \(hours % 24)h"
    }

    var body: some View {
        CardView {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(position.symbol)
                        .font(AppTypography.cardTitle)
                    BadgeView(
                        text: position.side.rawValue,
                        color: position.side == .long ? AppColors.pnlPositive : AppColors.pnlNegative
                    )
                    Spacer()
                    Label(durationText, systemImage: "clock")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItemView(label: "Entry Price", value: Formatters.price(position.entryPrice))
                    StatItemView(label: "Quantity", value: String(format: "%.4f", position.quantity))
                    StatItemView(label: "Leverage", value: "\(position.leverage)x")
                    StatItemView(label: "Margin", value: Formatters.currency(position.margin))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Take-Profit")
                            .font(AppTypography.statLabel)
                            .foregroundStyle(.secondary)
                        Text(Formatters.price(position.takeProfit))
                            .font(AppTypography.statValue)
                            .foregroundStyle(AppColors.pnlPositive)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stop-Loss")
                            .font(AppTypography.statLabel)
                            .foregroundStyle(.secondary)
                        Text(Formatters.price(position.stopLoss))
                            .font(AppTypography.statValue)
                            .foregroundStyle(AppColors.pnlNegative)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unrealized P/L")
                            .font(AppTypography.statLabel)
                            .foregroundStyle(.secondary)
                        Text(Formatters.currency(position.unrealizedPnL))
                            .font(AppTypography.statValue)
                            .foregroundStyle(AppColors.pnl(position.unrealizedPnL))
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("positionCard")
    }
}
```

- [ ] **Step 2: Implement PositionsView**

`TradingBot/Features/Positions/PositionsView.swift`:

```swift
import SwiftUI

struct PositionsView: View {
    let store: SnapshotStore

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Open Positions")
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView { CardView { SkeletonView(height: 200) }.padding(16) }
        case .loaded(let snapshot), .refreshing(let snapshot):
            positionsContent(snapshot.positions)
        case .empty:
            EmptyStateView(title: "No open positions", systemImage: "square.stack.3d.up")
        case .error(let message, let last):
            if let last {
                positionsContent(last.positions)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    @ViewBuilder
    private func positionsContent(_ positions: [Position]) -> some View {
        if positions.isEmpty {
            EmptyStateView(title: "No open positions", systemImage: "square.stack.3d.up")
        } else {
            List(positions) { position in
                PositionCardView(position: position)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top) {
                Text("\(positions.count) Open Position\(positions.count == 1 ? "" : "s")")
                    .font(AppTypography.statLabel)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(AppColors.screenBackground)
            }
        }
    }
}
```

- [ ] **Step 3: Replace the Positions placeholder in MainTabView**

```swift
            Tab("Positions", systemImage: "square.stack.3d.up.fill") {
                PositionsView(store: container.store)
            }
```

- [ ] **Step 4: Build to verify**

```bash
xcodebuild build -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: open positions screen with live position cards"
```

---

### Task 10: Trade History screen (search + result filter, TDD)

**Files:**
- Create: `TradingBot/Features/History/HistoryViewModel.swift`
- Create: `TradingBot/Features/History/HistoryView.swift`
- Modify: `TradingBot/Features/Root/MainTabView.swift`
- Test: `TradingBotTests/History/HistoryViewModelTests.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `Trade`, `TradeSide`, design system (Tasks 2, 3, 6).
- Produces:
  - `@Observable @MainActor final class HistoryViewModel` with `var searchText: String`, `var filter: TradeFilter`, `func update(trades: [Trade])`, `var visibleTrades: [Trade]`
  - `enum TradeFilter: String, CaseIterable, Sendable { case all = "All", wins = "Wins", losses = "Losses" }`
  - `struct HistoryView: View { init(store: SnapshotStore) }` — matches mockup screen 4: date/time + symbol + LONG badge rows, entry→exit prices, P/L with win/loss icon, search field, filter menu.

- [ ] **Step 1: Write the failing view model tests**

`TradingBotTests/History/HistoryViewModelTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/HistoryViewModelTests 2>&1 | tail -5
```

Expected: FAIL — cannot find `HistoryViewModel`.

- [ ] **Step 3: Implement HistoryViewModel**

`TradingBot/Features/History/HistoryViewModel.swift`:

```swift
import Foundation
import Observation

enum TradeFilter: String, CaseIterable, Sendable {
    case all = "All"
    case wins = "Wins"
    case losses = "Losses"
}

@Observable
@MainActor
final class HistoryViewModel {
    var searchText = ""
    var filter: TradeFilter = .all

    private var trades: [Trade] = []

    func update(trades: [Trade]) {
        self.trades = trades.sorted { $0.closedAt > $1.closedAt }
    }

    var visibleTrades: [Trade] {
        trades.filter { trade in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .wins: matchesFilter = trade.pnl > 0
            case .losses: matchesFilter = trade.pnl < 0
            }
            let matchesSearch = searchText.isEmpty
                || trade.symbol.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests/HistoryViewModelTests 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Implement HistoryView**

`TradingBot/Features/History/HistoryView.swift`:

```swift
import SwiftUI

struct HistoryView: View {
    let store: SnapshotStore
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("Trade History")
                .searchable(text: $viewModel.searchText, prompt: "Search symbol")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Filter", selection: $viewModel.filter) {
                                ForEach(TradeFilter.allCases, id: \.self) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .accessibilityLabel("Filter trades")
                        }
                    }
                }
                .refreshable { await store.refresh() }
        }
        .onChange(of: store.state.value?.trades) { _, trades in
            viewModel.update(trades: trades ?? [])
        }
        .task { viewModel.update(trades: store.state.value?.trades ?? []) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            List(0..<5, id: \.self) { _ in SkeletonView(height: 56) }
        case .loaded, .refreshing:
            tradeList
        case .empty:
            EmptyStateView(title: "No trades yet", systemImage: "clock")
        case .error(let message, let last):
            if last != nil {
                tradeList
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    @ViewBuilder
    private var tradeList: some View {
        if viewModel.visibleTrades.isEmpty {
            EmptyStateView(title: "No matching trades", systemImage: "magnifyingglass")
        } else {
            List(viewModel.visibleTrades) { trade in
                TradeRowView(trade: trade)
            }
            .listStyle(.plain)
            .accessibilityIdentifier("tradeList")
        }
    }
}

struct TradeRowView: View {
    let trade: Trade

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dayFormatter.string(from: trade.closedAt))
                    .font(AppTypography.caption)
                Text(Self.timeFormatter.string(from: trade.closedAt))
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(trade.symbol)
                        .font(AppTypography.body.weight(.semibold))
                    Image(systemName: trade.side == .long ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(trade.side == .long ? AppColors.pnlPositive : AppColors.pnlNegative)
                    Text(trade.side.rawValue)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Text(Formatters.price(trade.entryPrice))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(Formatters.price(trade.exitPrice))
                }
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(Formatters.currency(trade.pnl))
                    .font(AppTypography.statValue)
                    .foregroundStyle(AppColors.pnl(trade.pnl))
                Image(systemName: trade.pnl >= 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(AppColors.pnl(trade.pnl))
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
```

- [ ] **Step 6: Replace the History placeholder in MainTabView**

```swift
            Tab("History", systemImage: "clock.fill") {
                HistoryView(store: container.store)
            }
```

- [ ] **Step 7: Build and run the unit suite**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:TradingBotTests 2>&1 | tail -3
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat: trade history with search, win/loss filter, sorted rows"
```

---

### Task 11: AI Insights + Breakdown screens

**Files:**
- Create: `TradingBot/Features/Insights/InsightsView.swift`
- Create: `TradingBot/Features/Insights/VetoEntryCardView.swift`
- Create: `TradingBot/Features/Insights/LessonCardView.swift`
- Create: `TradingBot/Features/Breakdown/BreakdownView.swift`
- Modify: `TradingBot/Features/Root/MainTabView.swift`

**Interfaces:**
- Consumes: `SnapshotStore`, `InsightFeed`, `VetoEntry`, `Lesson`, `VetoStatus`, `Breakdown`, `SymbolBreakdown`, `RegimeBreakdown`, design system (Tasks 2, 3, 6).
- Produces:
  - `struct InsightsView: View { init(store: SnapshotStore) }` — mockup screen 5: "Veto Log (Recent)" section with View All, status pills (PROCEED green / BLOCKED red), "Lessons (Pattern Analysis)" section with tag chips; navigation pushes `BreakdownView`
  - `struct BreakdownView: View { init(store: SnapshotStore) }` — mockup screen 6: "By Symbol | By Regime" segmented control, win-rate progress bars, net P/L per symbol

- [ ] **Step 1: Implement the Insights cards**

`TradingBot/Features/Insights/VetoEntryCardView.swift`:

```swift
import SwiftUI

struct VetoEntryCardView: View {
    let entry: VetoEntry
    @State private var isExpanded = false

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(Self.timestampFormatter.string(from: entry.timestamp))
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.symbol)
                        .font(AppTypography.body.weight(.semibold))
                    Text(entry.side)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    BadgeView(
                        text: entry.status.rawValue,
                        color: entry.status == .proceed ? AppColors.pnlPositive : AppColors.pnlNegative
                    )
                }
                Text(entry.reason)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
                if !isExpanded {
                    Button("Show more") { withAnimation { isExpanded = true } }
                        .font(AppTypography.caption)
                }
            }
        }
        .onTapGesture { withAnimation { isExpanded.toggle() } }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to expand")
    }
}
```

`TradingBot/Features/Insights/LessonCardView.swift`:

```swift
import SwiftUI

struct LessonCardView: View {
    let lesson: Lesson

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundStyle(AppColors.blockedAmber)
                    Text(lesson.title)
                        .font(AppTypography.cardTitle)
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.blockedAmber)
                        .font(.caption)
                }
                Text(lesson.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(lesson.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

/// Minimal wrapping layout for tag chips (iOS 18 has no built-in flow layout).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
```

- [ ] **Step 2: Implement InsightsView**

`TradingBot/Features/Insights/InsightsView.swift`:

```swift
import SwiftUI

struct InsightsView: View {
    let store: SnapshotStore

    var body: some View {
        NavigationStack {
            content
                .background(AppColors.screenBackground)
                .navigationTitle("AI Insights")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            BreakdownView(store: store)
                        } label: {
                            Image(systemName: "info.circle")
                                .accessibilityLabel("Breakdown analytics")
                        }
                    }
                }
                .refreshable { await store.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView {
                VStack(spacing: 16) {
                    CardView { SkeletonView(height: 90) }
                    CardView { SkeletonView(height: 90) }
                }
                .padding(16)
            }
        case .loaded(let snapshot), .refreshing(let snapshot):
            insightsContent(snapshot.insights)
        case .empty:
            EmptyStateView(title: "No insights yet", systemImage: "lightbulb")
        case .error(let message, let last):
            if let last {
                insightsContent(last.insights)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func insightsContent(_ feed: InsightFeed) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Veto Log (Recent)")
                ForEach(feed.vetoLog) { entry in
                    VetoEntryCardView(entry: entry)
                }

                sectionHeader("Lessons (Pattern Analysis)")
                ForEach(feed.lessons) { lesson in
                    LessonCardView(lesson: lesson)
                }
            }
            .padding(16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.cardTitle)
            Spacer()
            Text("View All")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 3: Implement BreakdownView**

`TradingBot/Features/Breakdown/BreakdownView.swift`:

```swift
import SwiftUI

struct BreakdownView: View {
    let store: SnapshotStore
    @State private var mode: Mode = .bySymbol

    enum Mode: String, CaseIterable {
        case bySymbol = "By Symbol"
        case byRegime = "By Regime"
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Breakdown mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            content
        }
        .background(AppColors.screenBackground)
        .navigationTitle("Breakdown")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ScrollView { CardView { SkeletonView(height: 200) }.padding(16) }
        case .loaded(let snapshot), .refreshing(let snapshot):
            breakdownContent(snapshot.breakdown)
        case .empty:
            EmptyStateView(title: "No breakdown data", systemImage: "chart.bar")
        case .error(let message, let last):
            if let last {
                breakdownContent(last.breakdown)
            } else {
                ErrorStateView(message: message) { Task { await store.refresh() } }
            }
        }
    }

    private func breakdownContent(_ breakdown: Breakdown) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                switch mode {
                case .bySymbol:
                    CardView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("By Symbol")
                                .font(AppTypography.cardTitle)
                            ForEach(breakdown.bySymbol) { item in
                                SymbolBreakdownRow(item: item)
                            }
                        }
                    }
                case .byRegime:
                    CardView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("By Regime")
                                .font(AppTypography.cardTitle)
                            ForEach(breakdown.byRegime) { item in
                                RegimeBreakdownRow(item: item)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct SymbolBreakdownRow: View {
    let item: SymbolBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.symbol)
                    .font(AppTypography.body.weight(.semibold))
                Spacer()
                Text(Formatters.percent(item.winRate))
                    .font(AppTypography.statValue)
                Text(Formatters.currency(item.netPnL))
                    .font(AppTypography.statValue)
                    .foregroundStyle(AppColors.pnl(item.netPnL))
            }
            HStack {
                Text("\(item.trades) Trades")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Win Rate")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                Text("Net P/L")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: item.winRate)
                .tint(AppColors.pnl(item.netPnL))
        }
        .accessibilityElement(children: .combine)
    }
}

struct RegimeBreakdownRow: View {
    let item: RegimeBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.regime)
                    .font(AppTypography.body.weight(.semibold))
                Spacer()
                Text(Formatters.percent(item.winRate))
                    .font(AppTypography.statValue)
            }
            Text("\(item.trades) Trades")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: item.winRate)
                .tint(item.winRate >= 0.2 ? AppColors.pnlPositive : AppColors.pnlNegative)
        }
        .accessibilityElement(children: .combine)
    }
}
```

- [ ] **Step 4: Replace the Insights placeholder in MainTabView**

```swift
            Tab("Insights", systemImage: "lightbulb.fill") {
                InsightsView(store: container.store)
            }
```

After this step `PlaceholderScreen` is unused — delete it from `MainTabView.swift`.

- [ ] **Step 5: Build to verify**

```bash
xcodebuild build -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: AI insights feed and breakdown analytics screens"
```

---

### Task 12: UI tests, launch check, README, final verification

**Files:**
- Create: `TradingBotUITests/TradingBotUITests.swift`
- Create: `TradingBotUITests/TradingBotLaunchTests.swift`
- Create: `README.md`
- Create: `docs/api-contract.md`

**Interfaces:**
- Consumes: everything; exercises accessibility identifiers `totalEquity`, `dateRangeSelector`, `positionCard`, `tradeList`, `errorState`, `emptyState` set in Tasks 7–11.

- [ ] **Step 1: Write the UI smoke tests**

`TradingBotUITests/TradingBotUITests.swift`:

```swift
import XCTest

final class TradingBotUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testDashboardShowsTotalEquity() {
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "totalEquity").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Balance"].exists)
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists)
    }

    func testTabNavigationToAllScreens() {
        let tabs = app.tabBars
        tabs.buttons["Portfolio"].tap()
        XCTAssertTrue(app.navigationBars["Portfolio"].waitForExistence(timeout: 5))

        tabs.buttons["Positions"].tap()
        XCTAssertTrue(app.navigationBars["Open Positions"].waitForExistence(timeout: 5))

        tabs.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["Trade History"].waitForExistence(timeout: 5))

        tabs.buttons["Insights"].tap()
        XCTAssertTrue(app.navigationBars["AI Insights"].waitForExistence(timeout: 5))
    }

    func testInsightsPushesBreakdown() {
        app.tabBars.buttons["Insights"].tap()
        app.navigationBars["AI Insights"].buttons["Breakdown analytics"].tap()
        XCTAssertTrue(app.navigationBars["Breakdown"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["By Regime"].exists)
    }

    func testHistoryShowsTrades() {
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["BTCUSDT"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SOLUSDT"].exists)
    }
}
```

`TradingBotUITests/TradingBotLaunchTests.swift`:

```swift
import XCTest

final class TradingBotLaunchTests: XCTestCase {
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
```

- [ ] **Step 2: Run the full test suite (unit + UI)**

```bash
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **` with all 4 UI tests + launch metric + all unit suites passing. If a UI test is flaky on first simulator boot, re-run once before investigating.

- [ ] **Step 3: Write README.md**

```markdown
# Trading Bot iOS

Native SwiftUI companion app for the trading-bot dashboard at `https://165.227.151.108:8443`.

## Status

Phase 1: UI + JSON data contract. The live API sits behind HTTP Basic auth; until
credentials are available the app reads a bundled `snapshot.json` that mirrors the
dashboard's data shape. Set `AppConfiguration.baseURL` to point at the live server —
the networking, caching, and repository layers need no other changes.

## Architecture

- `TradingBot/Domain` — pure models (`BotSnapshot` and slices), no framework dependencies
- `TradingBot/Data` — `BotDataProvider` protocol, bundled/remote providers, DTOs, mappers,
  `SnapshotRepository` (remote → disk cache fallback), `SnapshotStore` (5s polling, `@Observable`)
- `TradingBot/Core` — `HTTPClient` (retry, typed errors), `AppConfiguration`, `AppContainer` (DI)
- `TradingBot/DesignSystem` — colors, typography, formatters, cards, badges, skeletons, `LoadState`
- `TradingBot/Features` — Dashboard, Portfolio, Positions, History, Insights, Breakdown
  (each: SwiftUI view + `@Observable` view model where the screen has logic)

## Build & Test

Requires Xcode 26+. An "iPhone 16" simulator on iOS 18.6 is expected:

    xcrun simctl create "iPhone 16" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-18-6
    xcodebuild build -project TradingBot.xcodeproj -scheme TradingBot \
      -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
    xcodebuild test  -project TradingBot.xcodeproj -scheme TradingBot \
      -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO

## Data contract

See `docs/api-contract.md`.
```

- [ ] **Step 4: Write docs/api-contract.md**

```markdown
# API Contract (Phase 1 — inferred)

Single JSON document. Phase 1 source: bundled `TradingBot/Resources/snapshot.json`
or `GET <baseURL>/snapshot.json`. Dates: ISO 8601 (`2026-07-23T08:15:00Z`).
Money: USD doubles. Rates: 0–1 fractions. This contract is inferred from the UI
mockup pending access to the real dashboard API (Basic-auth protected); Phase 2
will diff it against the live endpoints and adjust the DTO layer only.

- `dashboard`: totalEquity, balance, winRate, todayPnL, allTimePnL,
  openPositionsCount, totalTrades, equityCurve: [{date, equity}]
- `portfolio`: equityCurve, high, low, current, rangeStart, rangeEnd
- `positions`: [{id, symbol, side(LONG|SHORT), entryPrice, currentPrice, quantity,
  leverage, margin, takeProfit, stopLoss, unrealizedPnL, openedAt}]
- `trades`: [{id, closedAt, symbol, side, entryPrice, exitPrice, pnl}]
- `insights`: { vetoLog: [{id, timestamp, symbol, side(BUY|SELL), status(PROCEED|BLOCKED),
  reason}], lessons: [{id, title, detail, tags}] }
- `breakdown`: { bySymbol: [{symbol, trades, winRate, netPnL}],
  byRegime: [{regime, trades, winRate}] }
```

- [ ] **Step 5: Final full verification**

```bash
xcodebuild clean test -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`. Then launch the app in the simulator and compare against `Unknown.png`:

```bash
xcrun simctl boot "iPhone 16" 2>/dev/null || true
open -a Simulator
xcrun simctl install booted "$(xcodebuild -project TradingBot.xcodeproj -scheme TradingBot -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug CODE_SIGNING_ALLOWED=NO -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/TradingBot.app"
xcrun simctl launch booted com.tradingbot.ios
sleep 5
xcrun simctl io booted screenshot /tmp/tradingbot-dashboard.png
```

Read `/tmp/tradingbot-dashboard.png` and compare with `Unknown.png` screen 1. Iterate on layout mismatches (this loop is expected to take a few passes; each fix is its own commit).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "test: UI smoke tests and launch metric; docs: README and API contract"
```

---

## Out of scope (explicitly deferred to Phase 2+)

- Real authentication (Basic auth + Keychain), live endpoint integration
- Swipe actions on positions, date-range picker interaction, pagination/infinite scroll
  (needs real API semantics — do not fake them)
- WidgetKit, App Intents, biometrics, certificate pinning, localization catalogs
