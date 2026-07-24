# Trading Bot iOS — Design Spec

Date: 2026-07-24
Status: Approved (approach approved via Q&A; design presented and accepted by proceeding)

## Context

- Working directory `Trading-Bot-iOS` is an empty git repo containing only `Unknown.png`, a 6-screen mobile UI mockup (Dashboard, Portfolio, Open Positions, Trade History, AI Insights, Breakdown).
- The "existing project" is a deployed trading-bot dashboard at `https://165.227.151.108:8443` (Python/gunicorn, Flask-style routing). The site sits behind HTTP Basic auth (realm "dashboard"); no credentials are available yet. Probing shows only `/` exists; all API paths return 404 without auth, so the real API surface cannot be enumerated now.
- User decision: **define the JSON data contract now** (inferred from the mockup), isolate it behind provider protocols, and swap in the real API later ("rely on the json for now"). The original spec's "no invented APIs" constraint is explicitly relaxed by the user for this first build.

## Goals (Phase 1 — this build)

- Production-quality SwiftUI app replicating the mockup's 6 screens with tab navigation.
- Poll-driven live updates against a configurable JSON snapshot source; bundled sample JSON ships in-app.
- Full state coverage per screen: loading / loaded / refreshing / empty / error / offline.
- Reusable design system matching the mockup's visual language (dark cards, red/green P/L accents, charts).
- Unit tests for data mapping, view models, polling, error handling; UI smoke tests.

## Non-goals (deferred)

- Real authentication, Basic auth, Keychain, biometrics — Phase 2, when API access exists.
- Websockets — the backend is gunicorn/Flask; polling is the correct assumption until proven otherwise.
- WidgetKit, App Intents, App Shortcuts, certificate pinning, SwiftData, SwiftLint CI, 90% coverage mandate.
- Any backend creation or modification.

## Architecture

Pragmatic Clean MVVM. Four boundaries, protocol-based, single composition root.

```
TradingBot/
├── TradingBotApp.swift          Entry point, builds AppContainer
├── Core/
│   ├── Networking/              APIClient (protocol), HTTPClient, HTTPError, RetryPolicy, Reachability
│   ├── Storage/                 JSONCacheStore (file-based), KeychainStore (stub for Phase 2)
│   └── DI/                      AppContainer — wires providers, repositories, view models
├── Domain/                      Pure models: DashboardSummary, EquityPoint, Position, Trade,
│                                VetoEntry, Lesson, SymbolBreakdown, RegimeBreakdown
│                                + repository protocols (no JSON, no Foundation networking types)
├── Data/
│   ├── DTOs/                    Codable DTOs mirroring snapshot.json + mappers to Domain
│   ├── BotDataProvider          Protocol: one method per data slice
│   ├── RemoteBotDataProvider    HTTP fetch from configurable base URL
│   ├── BundledBotDataProvider   Reads bundled snapshot.json (fallback/offline)
│   └── Repositories/            Caching repositories: remote → cache → bundled
├── DesignSystem/                AppColors, AppTypography, Card, Badge, Tag, SkeletonView,
│                                ErrorView, EmptyStateView, P/L formatting, chart styling
└── Features/
    ├── Root/                    MainTabView (Dashboard, Portfolio, Positions, History, Insights)
    ├── Dashboard/               DashboardView + DashboardViewModel
    ├── Portfolio/               PortfolioView + PortfolioViewModel
    ├── Positions/               PositionsView + PositionsViewModel
    ├── History/                 HistoryView + HistoryViewModel
    ├── Insights/                InsightsView + InsightsViewModel  (hosts Breakdown sections)
    └── Breakdown/               BreakdownView + BreakdownViewModel
TradingBotTests/                 Swift Testing unit tests
TradingBotUITests/               XCUITest smoke tests
```

Notes:
- Breakdown is reached from Insights in the mockup (bottom tab shows 5 tabs; screen 6 is "Breakdown"). Final navigation decided in implementation: either a 6th tab or pushed from Insights.
- View models use `@Observable` (Observation framework), Swift 6 concurrency, `async/await`.
- Repositories and providers are actors or `@Sendable` value types; no singletons except the composition root.

## Data Contract (snapshot.json)

Single JSON document; each key optional so partial snapshots still decode. Field names match the mockup's data exactly; exact key spelling is defined in the DTOs at implementation time and documented in `docs/api-contract.md`.

- `dashboard`: totalEquity, balance, winRate, todayPnL, allTimePnL, openPositionsCount, totalTrades, equityCurve: [EquityPoint]
- `portfolio`: equityCurve: [EquityPoint], high, low, current, rangeStart, rangeEnd
- `positions`: [{ symbol, side(LONG/SHORT), entryPrice, currentPrice, quantity, leverage, margin, takeProfit, stopLoss, unrealizedPnL, openedAt }]
- `trades`: [{ id, closedAt, symbol, side, entryPrice, exitPrice, pnl, result(win/loss) }]
- `insights`: vetoLog: [{ timestamp, symbol, side, status(PROCEED/BLOCKED), reason }], lessons: [{ title, detail, tags }]
- `breakdown`: bySymbol: [{ symbol, trades, winRate, netPnL }], byRegime: [{ regime, trades, winRate }]

## Networking & Updates

- `BotDataProvider` protocol with one async method per slice; repositories compose remote → disk cache → bundled JSON.
- Polling: structured-concurrency loop per view model (configurable interval, default 5s), cancelled on disappear; `.refreshable` pull-to-refresh everywhere.
- All errors funnel through `HTTPError` → user-facing `ErrorView` with retry; offline shows cached data plus an offline badge.
- Base URL is a build/runtime setting (`AppConfiguration`), defaulting to bundled data until the real API lands.

## State Management

Single `LoadState<Value>` enum: `loading, loaded(Value), refreshing(Value), empty, error(AppError, lastValue: Value?)`. Every feature screen renders from it; skeletons for loading, cached content for refreshing/offline.

## Design System

Extracted from the mockup: dark/light adaptive palette, green (#34C759-family) / red P/L accents, card component with subtle border, numeric typography with monospaced digits, LONG/SHORT and PROCEED/BLOCKED badges, section headers with "View All", win-rate progress bars (Breakdown), Apple Charts line/area charts with red-gradient equity curve. Supports Dynamic Type, VoiceOver labels, Reduce Motion.

## Testing

- Swift Testing: DTO→domain mappers, LoadState transitions, view model polling/cancellation, repository cache fallback chain, error mapping.
- XCUITest: app launches into Dashboard, tab navigation to all screens, pull-to-refresh, error-state retry.
- No force unwraps; strict concurrency checking on.

## Phasing

1. **Phase 1 (this plan):** scaffold, design system, data contract, all 6 screens, polling, cache, tests.
2. **Phase 2:** real API integration — Basic auth + Keychain, endpoint swap inside provider layer, contract diffing against real responses.
3. **Later:** widgets, intents, biometrics, pinning — only if still wanted.

## Open Risks

- Real API shape may differ from inferred contract — mitigated by provider isolation; only Data layer changes.
- Mockup is one static image; interactions (date-range selector, filters, swipe actions) are implemented per HIG where ambiguous.
