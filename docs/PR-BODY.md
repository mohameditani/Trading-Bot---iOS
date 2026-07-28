# Trading Bot for iPhone — read-only 3-tab companion

Implements the Claude Design project *Crypto trading bot dashboard*
(`Mobile App.dc.html`) as a native iOS app.

## What this is

A read-only SwiftUI companion that renders one JSON snapshot across three tabs —
**Equity**, **Trades**, **Review**. It places no orders, writes no bot configuration,
and has no authentication. All four design states are implemented, including the
"AI null" screen.

## Architecture

Reusable code lives in a local Swift package with four modules, each with its own
test target:

| Module | Responsibility |
|---|---|
| `BotDomain` | Models and pure logic. **No dependencies** — its tests run in milliseconds. |
| `BotFormatting` | Display formatting, pinned to `en_US_POSIX` / UTC. |
| `BotDataKit` | Provider protocol, DTOs, HTTP + retry, disk cache, polling store. |
| `BotDesignSystem` | Tokens, bundled fonts, reusable components. |

The app target is thin: three `@Observable` ViewModels, three Views, one composition
root. **No View contains formatting or business logic** — ViewModels expose view-ready
values, which is what makes every screen testable without a UI.

## The key modelling decision

`ai_report`, `veto`, and `lessons` are nullable in the data contract. That single fact
produces the design's fourth screen: when `ai_report` is nil the Review tab renders
three "Not enabled yet" placeholders. It is **one branch in `ReviewViewModel`**, not a
separate screen, and both branches are covered by fixtures.

## Values derived rather than hardcoded

The mockup contains hand-placed numbers that would misrepresent any other snapshot:

- **Position rail marker** (`64%` in the design) → `(entry − TP) / (SL − TP)`, clamped.
  The ratio is *signed*: `|entry − TP|` would place a deeply winning position at the
  stop-loss end of the rail.
- **`All 28` chip count** → derived from the payload.
- **Breakdown bar widths** → normalised against the largest *absolute* net P/L, so a
  heavy loss reads full-width just as a heavy gain does.

## Testing

| Suite | Result |
|---|---|
| Package units | 116 passing |
| Same under `TZ=Asia/Tokyo` | 116 passing — formatter pinning holds |
| Full scheme, iPhone 17 Pro (iOS 26.5) | 57 cases, 0 failures |
| Full scheme, iPhone 16 (iOS 18.6 floor) | passing, UI tests included |
| Strict-concurrency build | no warnings |

UI tests are deterministic via launch-argument fixtures (`-fixture full | aiNull |
empty | error`) — no live network, no timing dependence.

## Defects found and fixed during the build

1. Rail-marker formula placed winning positions at the stop-loss end.
2. `SnapshotStore` retained itself forever (`guard let self` hoisted above the poll
   loop); its `deinit` also could not compile under Swift 6.
3. **Screen-level accessibility identifiers propagated onto children and overrode
   theirs** — a real VoiceOver bug, not just a test failure.
4. Card containers were not exposed as accessibility elements at all.
5. Parallel tests clobbered shared URL-mock state, making retry counts meaningless.
6. An empty SwiftPM resource bundle fails codesign.
7. Test epoch constants were ~6 days off (the UTC pinning was correct; the literals
   were not).

Each fix is regression-tested, and the spec and plan were corrected so the documents
match what shipped.

## Not included

No ordering, no bot-config writes, no login — all out of scope per the design, which
states the intent as *"Read-only. Same data contract as the web terminal."*

Live data is a one-line change in `TradingBot/AppContainer.swift`
(`RemoteSnapshotProvider(baseURL:)`); `HTTPClient` and `RemoteSnapshotProvider` are
already implemented and tested against a mock `URLProtocol`, but the dashboard's
credentials do not exist yet.

## Review notes

- Spec: `docs/superpowers/specs/2026-07-25-trading-bot-ios-design.md`
- Plan: `docs/superpowers/plans/2026-07-25-trading-bot-ios.md`
- `archive/prior-5tab-build` (local) holds an earlier build against a different 5-tab,
  login-gated spec. Reference only; nothing here derives from its UI.
- The editorial layout has **not been visually verified** — no simulator access during
  the build. Tests assert exact values but cannot confirm it looks right.
