# Trading Bot for iPhone

A read-only SwiftUI companion for a crypto trading bot. It renders one JSON snapshot
across three tabs — Equity, Trades, Review — and never places, modifies, or closes a
trade.

Built from the Claude Design project *Crypto trading bot dashboard* (`Mobile App.dc.html`).
The design spec and implementation plan live in `docs/superpowers/`.

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

Views contain no formatting and no business logic — ViewModels expose view-ready
values. That is what makes every screen testable without instantiating a UI.

`BotDomain` deliberately depends on nothing, so its logic tests run in milliseconds
with no networking, no SwiftUI, and no fixtures beyond plain values.

## Running the tests

```bash
# Fast: package units only (~114 tests)
cd Packages/TradingBotKit && swift test

# Everything, including UI tests
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Formatters are locale- and timezone-pinned, which you can verify:

```bash
cd Packages/TradingBotKit && TZ=Asia/Tokyo swift test
```

## Fixtures

The app selects its data source from a launch argument, which is how the UI tests stay
deterministic — no live network, no timing dependence.

| Argument | Result |
|---|---|
| *(none)* or `-fixture full` | Full sample snapshot |
| `-fixture aiNull` | Review layer disabled — placeholder screen |
| `-fixture empty` | A live bot with no history |
| `-fixture error` | Load always fails — error and retry state |

## The AI-null screen

`ai_report`, `veto`, and `lessons` are nullable in the data contract. That single fact
produces the design's fourth screen: when `ai_report` is nil the Review tab renders
three "Not enabled yet" placeholders instead of the report. It is one branch in
`ReviewViewModel`, not a separate screen, and both branches are covered by fixtures.

## Values the app derives rather than hardcodes

The mockup contains hand-placed numbers that would misrepresent any other snapshot.
These are computed and unit-tested instead:

- **The position rail marker** (`64%` in the design) — `(entry − TP) / (SL − TP)`,
  clamped. The ratio is signed, not absolute: using `|entry − TP|` would put a deeply
  winning position at the stop-loss end of the rail.
- **The `All 28` filter chip count** — derived from the payload's trade count.
- **Breakdown bar widths** — normalised against the largest *absolute* net P/L, so a
  heavy loss reads full-width just as a heavy gain does.

## Pointing at a live dashboard

`TradingBot/AppContainer.swift` is the only place that chooses a data source. Replace
`BundledSnapshotProvider` with `RemoteSnapshotProvider(baseURL:)`. Nothing else changes —
`HTTPClient` and `RemoteSnapshotProvider` are already implemented and tested against a
mock `URLProtocol`.

## Fonts

Bodoni Moda, Plus Jakarta Sans, and IBM Plex Mono ship in the design-system package
under the SIL Open Font License; their licence files sit alongside them in
`Packages/TradingBotKit/Sources/BotDesignSystem/Resources/Fonts/`.

Bodoni Moda and Plus Jakarta Sans are variable fonts; IBM Plex Mono ships as static
faces. `BotFont` resolves both through CoreText family lookup, so the exact file naming
of a Google Fonts release does not matter.

## Related branches

`archive/prior-5tab-build` holds an earlier implementation written against a different,
5-tab login-gated spec. It is reference material only; nothing in this branch derives
from its UI.
