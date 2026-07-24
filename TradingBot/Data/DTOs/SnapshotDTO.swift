import Foundation

struct SnapshotDTO: Codable {
    let dashboard: DashboardDTO
    let portfolio: PortfolioDTO
    let positions: [PositionDTO]
    let trades: [TradeDTO]
    let insights: InsightsDTO
    let breakdown: BreakdownDTO

    struct DashboardDTO: Codable {
        let totalEquity: Double
        let balance: Double
        let winRate: Double
        let todayPnL: Double
        let allTimePnL: Double
        let openPositionsCount: Int
        let totalTrades: Int
        let equityCurve: [EquityPointDTO]
    }

    struct PortfolioDTO: Codable {
        let equityCurve: [EquityPointDTO]
        let high: Double
        let low: Double
        let current: Double
        let rangeStart: Date
        let rangeEnd: Date
    }

    struct EquityPointDTO: Codable {
        let date: Date
        let equity: Double
    }

    struct PositionDTO: Codable {
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

    struct TradeDTO: Codable {
        let id: String
        let closedAt: Date
        let symbol: String
        let side: String
        let entryPrice: Double
        let exitPrice: Double
        let pnl: Double
    }

    struct InsightsDTO: Codable {
        let vetoLog: [VetoEntryDTO]
        let lessons: [LessonDTO]
    }

    struct VetoEntryDTO: Codable {
        let id: String
        let timestamp: Date
        let symbol: String
        let side: String
        let status: String
        let reason: String
    }

    struct LessonDTO: Codable {
        let id: String
        let title: String
        let detail: String
        let tags: [String]
    }

    struct BreakdownDTO: Codable {
        let bySymbol: [SymbolBreakdownDTO]
        let byRegime: [RegimeBreakdownDTO]
    }

    struct SymbolBreakdownDTO: Codable {
        let symbol: String
        let trades: Int
        let winRate: Double
        let netPnL: Double
    }

    struct RegimeBreakdownDTO: Codable {
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
