import Foundation

public enum TradeDirection: String, Equatable, Sendable, CaseIterable {
    case long
    case short
    case unknown

    /// Decodes tolerantly — an unrecognised direction must not break the whole snapshot.
    public init(wire: String) {
        self = TradeDirection(rawValue: wire.lowercased()) ?? .unknown
    }
}

public enum TradeStatus: String, Equatable, Sendable {
    case takeProfit
    case stopLoss
    case unknown

    public init(wire: String) {
        switch wire.lowercased() {
        case "closed_tp": self = .takeProfit
        case "closed_sl": self = .stopLoss
        default: self = .unknown
        }
    }
}

public enum PnLSign: Equatable, Sendable {
    case positive, negative, flat

    public static func of(_ value: Double) -> PnLSign {
        if value > 0 { return .positive }
        if value < 0 { return .negative }
        return .flat
    }
}

public struct Position: Equatable, Sendable, Identifiable {
    public let pair: String
    public let direction: TradeDirection
    public let entryPrice: Double
    public let quantity: Double
    public let leverage: Int
    public let margin: Double
    public let takeProfit: Double
    public let stopLoss: Double
    public let openedAt: Date
    public let exchangeStops: Bool

    public var id: String { "\(pair)-\(openedAt.timeIntervalSince1970)" }

    public init(
        pair: String, direction: TradeDirection, entryPrice: Double, quantity: Double,
        leverage: Int, margin: Double, takeProfit: Double, stopLoss: Double,
        openedAt: Date, exchangeStops: Bool
    ) {
        self.pair = pair
        self.direction = direction
        self.entryPrice = entryPrice
        self.quantity = quantity
        self.leverage = leverage
        self.margin = margin
        self.takeProfit = takeProfit
        self.stopLoss = stopLoss
        self.openedAt = openedAt
        self.exchangeStops = exchangeStops
    }
}

public struct ClosedTrade: Equatable, Sendable, Identifiable {
    public let closedAt: Date
    public let openedAt: Date
    public let pair: String
    public let direction: TradeDirection
    public let entryPrice: Double
    public let exitPrice: Double
    public let quantity: Double
    public let pnl: Double
    public let status: TradeStatus
    public let regime: String
    public let confidence: Int

    public var id: String { "\(pair)-\(closedAt.timeIntervalSince1970)" }

    public init(
        closedAt: Date, openedAt: Date, pair: String, direction: TradeDirection,
        entryPrice: Double, exitPrice: Double, quantity: Double, pnl: Double,
        status: TradeStatus, regime: String, confidence: Int
    ) {
        self.closedAt = closedAt
        self.openedAt = openedAt
        self.pair = pair
        self.direction = direction
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.quantity = quantity
        self.pnl = pnl
        self.status = status
        self.regime = regime
        self.confidence = confidence
    }

    /// The regime with underscores replaced by spaces, as the design renders it.
    public var regimeDisplay: String { regime.replacingOccurrences(of: "_", with: " ") }
}
