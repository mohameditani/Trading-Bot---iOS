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
