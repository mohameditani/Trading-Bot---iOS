import Foundation

public struct ConfigSuggestion: Equatable, Sendable, Identifiable {
    public let param: String
    public let current: String
    public let suggested: String
    public let rationale: String

    public var id: String { param }

    public init(param: String, current: String, suggested: String, rationale: String) {
        self.param = param
        self.current = current
        self.suggested = suggested
        self.rationale = rationale
    }
}

public struct AIReport: Equatable, Sendable {
    public let date: String
    public let narrative: String
    public let whatsWorking: [String]
    public let whatsLosing: [String]
    public let configSuggestions: [ConfigSuggestion]

    public init(
        date: String, narrative: String, whatsWorking: [String],
        whatsLosing: [String], configSuggestions: [ConfigSuggestion]
    ) {
        self.date = date
        self.narrative = narrative
        self.whatsWorking = whatsWorking
        self.whatsLosing = whatsLosing
        self.configSuggestions = configSuggestions
    }
}

public enum VetoSignal: String, Equatable, Sendable {
    case buy = "BUY"
    case sell = "SELL"
    case unknown

    public init(wire: String) {
        self = VetoSignal(rawValue: wire.uppercased()) ?? .unknown
    }
}

public enum VetoOutcome: String, Equatable, Sendable {
    case win
    case loss

    public init?(wire: String?) {
        guard let wire, let value = VetoOutcome(rawValue: wire.lowercased()) else { return nil }
        self = value
    }
}

public struct VetoRow: Equatable, Sendable, Identifiable {
    public let timestamp: Date
    public let symbol: String
    public let signal: VetoSignal
    public let proceed: Bool
    public let reason: String
    public let riskFlags: [String]
    public let newsFlag: Bool
    public let outcome: VetoOutcome?

    public var id: String { "\(symbol)-\(timestamp.timeIntervalSince1970)" }

    public init(
        timestamp: Date, symbol: String, signal: VetoSignal, proceed: Bool,
        reason: String, riskFlags: [String], newsFlag: Bool, outcome: VetoOutcome?
    ) {
        self.timestamp = timestamp
        self.symbol = symbol
        self.signal = signal
        self.proceed = proceed
        self.reason = reason
        self.riskFlags = riskFlags
        self.newsFlag = newsFlag
        self.outcome = outcome
    }

    /// Risk flags plus a synthetic "news" chip, exactly as the design composes them.
    public var displayFlags: [String] {
        riskFlags + (newsFlag ? ["news"] : [])
    }

    public var outcomeLabel: String { outcome?.rawValue ?? "no outcome" }
    public var decisionLabel: String { proceed ? "proceed" : "block" }
}

public struct VetoLog: Equatable, Sendable {
    public let proceed: Int
    public let block: Int
    public let scored: Int
    public let proceedWinRate: Double
    public let rows: [VetoRow]

    public init(proceed: Int, block: Int, scored: Int, proceedWinRate: Double, rows: [VetoRow]) {
        self.proceed = proceed
        self.block = block
        self.scored = scored
        self.proceedWinRate = proceedWinRate
        self.rows = rows
    }
}

public struct Lesson: Equatable, Sendable, Identifiable {
    public let timestamp: Date
    public let pair: String
    public let outcome: TradeStatus
    public let lesson: String
    public let failurePattern: String
    public let confidence: String
    public let tags: [String]

    public var id: String { "\(pair)-\(timestamp.timeIntervalSince1970)" }

    public init(
        timestamp: Date, pair: String, outcome: TradeStatus, lesson: String,
        failurePattern: String, confidence: String, tags: [String]
    ) {
        self.timestamp = timestamp
        self.pair = pair
        self.outcome = outcome
        self.lesson = lesson
        self.failurePattern = failurePattern
        self.confidence = confidence
        self.tags = tags
    }
}
