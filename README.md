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
# Fast: package units only (156 tests)
cd Packages/TradingBotKit && swift test

# Everything: 57 cases — app ViewModels, accessibility, and 11 UI tests
xcodebuild test -project TradingBot.xcodeproj -scheme TradingBot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Note that `xcodebuild` interleaves concurrent test output, so a `grep '^Test case'`
tally can undercount. Trust `** TEST SUCCEEDED **` and the failure count.

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

## Pointing at the live dashboard

The app talks to the bot's read-only Flask dashboard (`dashboard.py` in the
`Trading-Bot` repo), which serves `GET /api/data` behind HTTP Basic auth.

```bash
cd TradingBot/Resources
cp dashboard-config.example.json dashboard-config.json
# then fill in "password" — the DASHBOARD_PASSWORD from the bot's .env
```

`dashboard-config.json` is **gitignored**. With the file absent, or any of
`baseURL`/`username`/`password` left blank, the app stays on its bundled sample
snapshot — so a half-filled config can never send a placeholder credential into the
dashboard's per-IP lockout.

Three details of that server the app has to accommodate:

**Naive timestamps.** The bot writes `datetime.now().isoformat()` — no timezone
(`2026-06-24T03:25:02.737831`). Foundation's `.iso8601` strategy rejects those
outright, so `BotDate` parses them explicitly and assumes UTC. That assumption lives
in one constant, `BotDate.assumedZoneForNaiveTimestamps`; change it if the host is
ever moved off UTC.

**A self-signed certificate.** `CN=trading-dashboard`, so iOS refuses it by default.
The app pins its SHA-256 fingerprint rather than disabling ATS — an ATS exception
would accept *any* certificate for that address, while a pin accepts exactly one.
Re-read the fingerprint after rotating the cert:

```bash
echo | openssl s_client -connect 165.227.151.108:8443 2>/dev/null \
  | openssl x509 -outform DER | shasum -a 256
```

`certificateSHA256` takes a list, so you can carry the old and new pins together
across a rotation.

**Failure modes that must not be retried.** `401` (bad credentials), `429` (the
dashboard's 5-minute per-IP lockout after 10 failures) and `503` (fail-closed when
`DASHBOARD_PASSWORD` is unset) each map to their own message and are never retried —
retrying a 401 is precisely how a wrong password becomes a lockout.

## Is the bot still alive?

The header's `just now / 12s ago` describes **our fetch**. The dashboard keeps serving
its last payload after the bot process stops, so that alone would read "just now" for
a bot that died days ago.

The app therefore also shows the bot's own heartbeat — `last_activity`, the newest
ledger write — as `last trade Nh ago`, and turns the status dot red once that exceeds
the bot's `MAX_HOLD_HOURS`. That threshold is the bot's own: it force-closes any
position older than the window, so it cannot stay silent through one while holding a
position. It still cannot *prove* the process died — a genuinely quiet market also
stops producing writes — so it reports the gap and leaves the judgement to you.

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
