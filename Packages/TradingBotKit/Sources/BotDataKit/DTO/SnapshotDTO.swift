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
    /// The bot's newest ledger write. Absent from older payloads, nil when it has
    /// never traded.
    let lastActivity: Date?
    let maxHoldHours: Double?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case summary, curve, veto, lessons
        case openPositions = "open_positions"
        case closedTrades = "closed_trades"
        case bySymbol = "by_symbol"
        case byRegime = "by_regime"
        case aiReport = "ai_report"
        case lastActivity = "last_activity"
        case maxHoldHours = "max_hold_hours"
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
