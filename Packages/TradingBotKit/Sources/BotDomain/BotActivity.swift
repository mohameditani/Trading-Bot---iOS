import Foundation

/// How recently the bot last wrote to its ledger.
///
/// This is deliberately distinct from how recently *we* fetched. The dashboard keeps
/// serving its last payload after the bot process dies, so a fetch-freshness indicator
/// alone would read "just now" for a bot that stopped days ago.
public enum BotActivityStatus: Equatable, Sendable {
    /// The payload carried no activity timestamp — the bot has never traded.
    case unknown
    /// Last ledger write within the expected window.
    case recent(TimeInterval)
    /// Nothing written for longer than the bot's own max-hold window.
    case overdue(TimeInterval)

    public var interval: TimeInterval? {
        switch self {
        case .unknown: return nil
        case .recent(let value), .overdue(let value): return value
        }
    }

    public var isOverdue: Bool {
        if case .overdue = self { return true }
        return false
    }
}

public enum BotActivity {
    /// Classifies the gap since the bot's last ledger write.
    ///
    /// The threshold is the bot's own `MAX_HOLD_HOURS`, not an invented number: the bot
    /// force-closes any position older than that, so it cannot go a full window without
    /// writing while it holds one. Exceeding it is a real "worth a look" signal rather
    /// than a guess.
    ///
    /// Note this cannot *prove* the process died — a genuinely quiet market also stops
    /// producing writes. It reports the gap honestly and leaves the judgement to the
    /// reader.
    public static func status(
        lastActivity: Date?,
        now: Date,
        maxHoldHours: Double
    ) -> BotActivityStatus {
        guard let lastActivity else { return .unknown }
        let elapsed = max(0, now.timeIntervalSince(lastActivity))
        let window = max(0, maxHoldHours) * 3_600
        // A non-positive window would make every bot permanently overdue.
        guard window > 0 else { return .recent(elapsed) }
        return elapsed > window ? .overdue(elapsed) : .recent(elapsed)
    }
}
