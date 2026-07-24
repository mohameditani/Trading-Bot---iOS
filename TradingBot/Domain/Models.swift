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
