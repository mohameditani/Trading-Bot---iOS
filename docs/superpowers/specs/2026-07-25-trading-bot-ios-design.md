# Trading Bot for iPhone — Design Spec

**Date:** 2026-07-25
**Source design:** Claude Design project `b1d83f6d-83b4-4223-a257-ca9b4f55a46f`, file `Mobile App.dc.html` ("Crypto trading bot dashboard")
**Status:** Approved for planning

---

## 1. Summary

A native iOS companion app for an existing crypto trading bot. The app is **read-only**: it renders one JSON snapshot of bot state across three tabs. It places no orders, changes no configuration, and holds no funds.

The source design states the intent directly: *"Read-only. Same data contract as the web terminal — equity, positions, trades, breakdown and the AI layer — re-cut for a thumb."*

### Decisions taken during brainstorming

| Decision | Choice | Rationale |
|---|---|---|
| Prior 13-commit build | Salvage data layer, rebuild UI | Built against an older 5-tab, login-gated spec; its networking/data layer is design-agnostic and already tested |
| Data source | Bundled JSON + pluggable remote | Real dashboard is behind Basic auth with no credentials available; provider protocol makes the swap a config change |
| Packaging | One local package, four modules | Real module boundaries and independent test targets, one manifest to maintain |
| Fonts | Bundle the three real families | The editorial look depends on them; all are SIL OFL licensed |
| Minimum iOS | 18.0 | Swift 6 concurrency, `@Observable`, Swift Testing, Swift Charts; still reaches iPhone XS |

### Prior work

A previous session's 13 commits were orphaned (the branch had no refs). They were recovered from git's object store and preserved on branch `archive/prior-5tab-build` (`99ec373`). They are **reference material only** — no code is carried over verbatim. Design-agnostic logic (HTTP client shape, provider protocol, DTO/mapper approach, cache, polling store, formatter rules) informs the new package modules, which are written fresh against this spec.

---

## 2. Non-goals

Explicitly out of scope for this build:

- Placing, modifying, or closing trades — the app never writes to the exchange
- Editing bot configuration (config suggestions are **displayed**, never applied)
- Authentication / login (the design has no login; the prior build's login screen is not carried over)
- iPad or macOS layouts — iPhone portrait only
- Push notifications, widgets, watch app
- Charting interactions (the equity curve has no tooltips or selection in the design)

---

## 3. Data contract

One JSON document is the entire input. Field names below are the wire format (snake_case).

```
generated_at    : ISO8601 timestamp
summary         : balance, equity, open, total, wins, losses, win_rate,
                  total_pnl, today_total, today_wins, today_losses, today_pnl
curve           : [{ t: "YYYY-MM-DD", equity: Double }]
open_positions  : [{ pair, direction, entry_price, quantity, leverage, margin,
                     take_profit, stop_loss, timestamp, exchange_stops }]
closed_trades   : [{ closed_at, pair, direction, entry_price, exit_price, quantity,
                     pnl, status, regime, confidence, timestamp }]
by_symbol       : [{ key, trades, win_rate, net_pnl }]
by_regime       : [{ key, trades, win_rate, net_pnl }]
ai_report       : { date, narrative, whats_working[], whats_losing[],
                    config_suggestions[{ param, current, suggested, rationale }] }   -- NULLABLE
veto            : { proceed, block, scored, proceed_win_rate,
                    rows[{ ts, symbol, signal, proceed, reason, risk_flags[],
                           news_flag, outcome }] }                                    -- NULLABLE
lessons         : [{ ts, pair, outcome, lesson, failure_pattern, confidence, tags[] }] -- NULLABLE/EMPTY
```

### The nullability insight

`ai_report`, `veto`, and `lessons` being nullable is the single most important fact in this spec. It is what produces screen 4 of the design ("Review — AI null").

The AI-null screen is **not a separate screen to build**. It is one branch inside `ReviewViewModel`. Both branches are exercised by feeding two fixtures, so full coverage of the design's fourth screen costs one extra test file, not one extra feature.

**Enumerated value handling.** `direction` is `long`/`short`; `status` is `closed_tp`/`closed_sl`; `signal` is `BUY`/`SELL`; `outcome` is `win`/`loss`/`null`. Unknown values decode to an explicit `.unknown` case rather than throwing — a snapshot with one unrecognised regime must still render every other row. Decoding failures are surfaced, not swallowed; unknown *enum values* are tolerated. This distinction is deliberate and tested.

---

## 4. Architecture

```
Trading-Bot-iOS/
├── Packages/TradingBotKit/
│   ├── Package.swift
│   ├── Sources/
│   │   ├── BotDomain/          models + pure logic; no dependencies
│   │   ├── BotFormatting/      number/date/duration formatting
│   │   ├── BotDataKit/         provider, DTOs, HTTP, cache, store
│   │   └── BotDesignSystem/    tokens, fonts, reusable views
│   └── Tests/
│       ├── BotDomainTests/
│       ├── BotFormattingTests/
│       ├── BotDataKitTests/
│       └── BotDesignSystemTests/
├── TradingBot/                 app target (thin)
│   ├── TradingBotApp.swift
│   ├── AppContainer.swift      composition root
│   ├── RootTabView.swift
│   ├── Features/
│   │   ├── Equity/  EquityView.swift  EquityViewModel.swift
│   │   ├── Trades/  TradesView.swift  TradesViewModel.swift
│   │   └── Review/  ReviewView.swift  ReviewViewModel.swift
│   └── Resources/  snapshot.json, Fonts/*.ttf
├── TradingBotTests/            ViewModel tests
└── TradingBotUITests/
```

### Module dependency graph

```
BotDomain      (no deps)
BotFormatting  → BotDomain
BotDataKit     → BotDomain
BotDesignSystem → BotDomain, BotFormatting
App            → all four
```

`BotDomain` depending on nothing is what allows its logic tests to run in milliseconds with no networking, no SwiftUI, and no fixtures beyond plain values.

### MVVM

Each tab has a `@MainActor @Observable` ViewModel. The ViewModel:

- holds a `LoadState<T>` (`idle` / `loading` / `loaded(T)` / `failed(Error)`) plus an `isRefreshing` flag
- exposes **view-ready values** — pre-formatted strings, resolved colours, computed bar widths

The View performs no formatting and no business logic. This is the property that makes the ViewModels testable without instantiating a UI, and it is a hard rule: if a View contains a number-to-string conversion or a conditional colour, it belongs in the ViewModel or the design system.

### Data flow

```
SnapshotProvider (protocol)
   ├── BundledSnapshotProvider   reads Resources/snapshot.json
   └── RemoteSnapshotProvider    HTTPClient + retry
            ↓
   SnapshotRepository            decode + disk cache, cache-on-success
            ↓
   SnapshotStore  (@Observable)  polls, owns LoadState, drives freshness
            ↓
   EquityViewModel / TradesViewModel / ReviewViewModel
            ↓
   Views
```

One `SnapshotStore` instance is shared across all three tabs, so a refresh updates every tab at once and the app makes one request rather than three.

`AppContainer` is the composition root and the only place that decides which provider is live. Switching to the real dashboard is a single line there plus a base URL — no changes in any ViewModel or View.

### Freshness indicator

The design's header shows `just now` for the first 3 seconds, then `Ns ago`, cycling to 30. This is a display concern driven by `SnapshotStore`'s last-success timestamp and a timer owned by the store. The timer is cancelled on teardown.

---

## 5. Screens

All three tabs share a custom tab bar. SwiftUI's stock `TabView` cannot express the design's 9px uppercase IBM Plex Mono labels, so the tab bar is a reusable design-system component (`BotTabBar`) over a `TabView` with a hidden system bar.

Tabs: **EQUITY** (chart icon), **TRADES** (lines icon), **REVIEW** (star icon). Active `#8c6e2a`, inactive `#63686f`.

### 5.1 Equity

- **Status header** — live dot (green, with a soft ring), `bot`, `· binance futures`, freshness text, refresh icon
- **Hero** — equity figure at 46px mono weight 300 with -2px tracking, `USDT` suffix, all-time P/L chip tinted by sign, `all-time · N trades`
- **Equity curve** — 148pt Swift Charts line, `#bf362c` at 2pt, gradient fill `rgba(191,54,44,.20)` → clear, smoothed, no axes, no interaction. Beneath it: first and last point as `Jun 20  $100.00` / `Jun 30  $87.26`
- **Stat tiles** — 2×2 grid: Balance (`realized cash`), Today P/L (sign-tinted, `1W / 2L · 3 trades`), Win rate (`11 of 28 closed`), Reserved (gold, `1 position margin`)
- **Open position card** — pair, direction badge, leverage, elapsed time; a **TP↔entry↔SL rail** with a marker at the entry's proportional position; then Quantity / Margin / Stops

The design hardcodes the rail marker at `left:64%`. This spec computes it. The rail is always drawn take-profit (green) on the left to stop-loss (red) on the right, whichever side of the entry those prices sit on, so one direction-agnostic formula covers both long and short:

```
marker = |entry − TP| / |SL − TP|        clamped to 0…1
```

For the sample short (TP 70.91, entry 73.10, SL 74.20) that gives 66.6%, close to the design's hand-placed 64%. When `SL == TP` the denominator is zero and the marker defaults to 0.5. Computing it is correct — a hardcoded marker would misrepresent every other position.

Note: the curve's final value (`87.26`) equals `summary.balance`, not `summary.equity` (`116.40`). This is reproduced as-is — the app renders the contract faithfully and does not reconcile server-side figures.

### 5.2 Trades

- **Header** — `Closed trades` with a `11W / 17L` tally
- **Filter chips** — `All 28`, `BTC`, `SOL`, `Losses`; active chip is solid `#23262c` with `#faf9f6` text. The count in `All N` is derived, not literal.
- **Trade rows** — pair, direction, TP/SL badge, P/L right-aligned and sign-tinted; second line: timestamp · `entry → exit` · hold duration · regime · a 26pt confidence bar
- **By symbol** and **By regime** breakdowns — key, trade count, win rate (tinted: ≥50% green, ≥33% grey, else red), a proportional bar, net P/L

Bar widths normalise against the **maximum absolute** net P/L across the rows, so a group's magnitude reads correctly whether it is a profit or a loss.

Rows sort by `closed_at` descending. Filters are pure functions over the trade list.

### 5.3 Review — AI enabled

- **Latest report card** — `LATEST REPORT` gold overline; the narrative as italic Bodoni in typographic quotes; a green **Working** list and a red **Losing** list; then **Config suggestions** as `param  current → suggested` with a rationale line
- **Veto log** — `N scored` header; a summary strip (`proceed 26`, `block 2`, `win rate 41.7%`); rows with symbol, signal (BUY green / SELL red), a proceed/block badge, timestamp, reason, risk-flag chips, and outcome (`no outcome` when null)
- **Lessons** — `N recent`; each card carries pair, outcome badge, timestamp, the lesson text, `pattern: … · conf: …`, and `#tag` chips

Config suggestions are strictly informational. Nothing in this screen is actionable.

### 5.4 Review — AI null

When `ai_report` is nil, the header date reads `off` and the body renders three placeholder cards (circle-alert icon, title, `NOT ENABLED YET`, description):

1. **Latest AI report** — "Enable the review layer for a narrative read on recent performance plus config suggestions."
2. **Veto log** — "Logs every proceed / block decision and tracks the win rate of trades it let through."
3. **Lessons** — "Captures a post-mortem after each loss with failure patterns and tags."

---

## 6. Design system

### Colour tokens

| Token | Value | Use |
|---|---|---|
| `paper` | `#faf9f6` | screen background |
| `cardTop` / `cardBottom` | `#ffffff` / `#fbf9f5` | raised card gradient |
| `surface` | `#f7f5f1` | inset strips, lesson cards |
| `chipNeutral` | `#edeae4` | tag chips |
| `track` | `#e7e4de` | progress-bar tracks |
| `inkStrong` | `#15171b` | hero figures |
| `ink` | `#23262c` | primary text |
| `inkBody` | `#33373e` | paragraph text |
| `grey` | `#5c616a` | labels |
| `greyMuted` | `#63686f` | metadata |
| `positive` | `#1a7c54` | gains, TP, proceed |
| `negative` | `#bf362c` | losses, SL, block |
| `accent` | `#8c6e2a` | gold — active tab, overlines, confidence |
| `hairline` | `rgba(22,24,28,0.10)` | dividers, borders |

Tinted chip backgrounds derive from `positive`/`negative`/`accent` at low opacity rather than being separate constants.

### Typography

- **Bodoni Moda** — screen titles (27), section headings (19–22), placeholder titles (18), italic narrative (17)
- **Plus Jakarta Sans** — body and labels (10–13.5)
- **IBM Plex Mono** — **every figure**, plus tab labels and overlines (9–46)

The mono-for-all-numbers rule is what keeps columns aligned and gives the design its instrument-panel character. It is a system-wide constraint, not per-view styling.

Fonts are registered at launch and exposed only as semantic styles (`.heroFigure`, `.sectionTitle`, `.metadata`) so no call site references a font name or raw point size. Dynamic Type is supported via scaled metrics relative to each style's base size.

### Components

`BotTabBar`, `StatusHeaderBar`, `HeroFigure`, `StatTile`, `SectionHeading`, `FilterChip`, `OutcomeBadge`, `DirectionLabel`, `TargetRail`, `BreakdownRow`, `ConfidenceBar`, `TagChip`, `EquityCurveChart`, `ReportCard`, `PlaceholderCard`, `LoadingSkeleton`, `ErrorStateView`.

Each is initialised from plain values — no ViewModel or network type crosses into the design system. That keeps `BotDesignSystem` previewable and reusable in isolation.

---

## 7. Error, empty, and offline states

| Condition | Behaviour |
|---|---|
| First load, no cache | Skeleton placeholders matching final layout |
| Load fails, cache exists | Render cached data with an offline banner |
| Load fails, no cache | Full-screen error with retry |
| Refresh fails, data on screen | Keep data, surface a non-blocking banner |
| `open_positions` empty | Open-position card replaced by a quiet empty row |
| `closed_trades` empty | Trades list shows an empty state; breakdowns hidden |
| Filter matches nothing | "No trades match" within the list, chips still active |
| `ai_report` nil | AI-null placeholders (§5.4) |

Every state is reachable in tests by controlling the mock provider — none require network conditions.

---

## 8. Testing

Swift Testing (`@Test`) for units; XCUITest for UI.

### Unit tests by module

**BotDomain** — rail marker position (long, short, entry at bounds, out-of-range clamping, `SL == TP` guard); hold duration (minutes, hours, exact hour, negative/zero); breakdown bar normalisation (all-positive, all-negative, mixed, single row, all-zero); confidence width; P/L sign bucketing; trade filter and sort; derived win/loss counts.

**BotFormatting** — currency (`$87.26`), signed (`+$1.76`, `-$12.74`, zero, nil → `—`); price threshold (`58,800` at ≥1000 vs `73.10` below); percentage (`39.3%`); timestamp (`Jun 30 14:31`, **UTC**); day (`Jun 20`); freshness (`just now` under 3s, `12s ago`, 30s rollover). Locale is pinned to `en_US_POSIX` and timezone to UTC so results do not vary by machine — a defect flagged in the prior build.

**BotDataKit** — decoding with `ai_report` present and absent; unknown enum values falling back to `.unknown`; malformed JSON surfacing an error; HTTP retry on transient failure, no retry on 4xx, error mapping via a mock `URLProtocol`; cache write-on-success and read-on-failure; store polling cadence and cancellation.

**BotDesignSystem** — token resolution and font registration.

**App (TradingBotTests)** — each ViewModel against mock providers: loaded/empty/error mapping, `ReviewViewModel` across both AI branches, `TradesViewModel` filter behaviour, shared-store propagation across tabs.

### UI tests

Determinism comes from launch arguments that select a fixture (`-fixture full`, `-fixture aiNull`, `-fixture empty`, `-fixture error`) — no live network, no timing dependence.

1. Launch and land on Equity with expected figures
2. Navigate all three tabs; correct tab is highlighted
3. Trades filter chips change the visible row count
4. Review with `full` shows narrative, veto rows, and lessons
5. Review with `aiNull` shows exactly three placeholder cards
6. Error fixture shows retry; retry recovers to loaded

Key elements carry accessibility identifiers, which serve both the tests and VoiceOver.

### Accessibility

Figures get spoken labels (`-$12.74` → "minus twelve dollars seventy-four"); colour is never the sole carrier of meaning — direction and outcome always pair a tint with a text label or glyph; Dynamic Type is supported; contrast is verified for the grey-on-paper pairings, which are the weakest in the palette.

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| Contract inferred from a mockup, not a live API | All wire types isolated in DTOs behind a mapper; only the mapper changes when the real API lands |
| Real dashboard unreachable / auth unknown | Bundled provider is the default; remote is implemented and tested but not wired live |
| Font licensing | All three families are SIL OFL, which permits embedding; licence files ship with the app |
| Dense mono figures vs large Dynamic Type | Scaled metrics plus layout tests at accessibility sizes |
| Design's hardcoded values (`64%` marker, `All 28`) | Derived from data instead, with the formulas unit-tested |

---

## 10. Definition of done

- Three tabs match the design's typography, palette, and spacing
- All four design states render, including AI-null
- Reusable code lives in `TradingBotKit` with four modules and four test targets
- `swift test` passes at package level; the full scheme passes in Xcode
- UI tests pass on the iPhone 17 Pro simulator
- No formatting or business logic in any View
- App builds clean under Swift 6 strict concurrency with no warnings
