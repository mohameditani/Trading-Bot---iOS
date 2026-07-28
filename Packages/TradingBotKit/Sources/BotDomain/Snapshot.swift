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
    /// The bot's newest ledger write — its own heartbeat, distinct from how recently
    /// we fetched. Nil when the bot has never traded.
    public let lastActivity: Date?
    /// The bot's `MAX_HOLD_HOURS`; the window after which it force-closes a position.
    public let maxHoldHours: Double

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
        lessons: [Lesson],
        lastActivity: Date? = nil,
        maxHoldHours: Double = 72
    ) {
        self.lastActivity = lastActivity
        self.maxHoldHours = maxHoldHours
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

    /// True when the review layer has something to show.
    public var hasReviewLayer: Bool { aiReport != nil }

    /// How stale the bot's own ledger is, judged against its max-hold window.
    public func activityStatus(now: Date) -> BotActivityStatus {
        BotActivity.status(
            lastActivity: lastActivity,
            now: now,
            maxHoldHours: maxHoldHours
        )
    }
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
