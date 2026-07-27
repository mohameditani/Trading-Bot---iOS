import Foundation

enum Fixtures {
    /// A minimal but complete payload with the review layer present.
    static let full = """
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 87.26, "equity": 116.40, "open": 1, "total": 28,
        "wins": 11, "losses": 17, "win_rate": 39.3, "total_pnl": -12.74,
        "today_total": 3, "today_wins": 1, "today_losses": 2, "today_pnl": -2.22 },
      "curve": [ { "t": "2026-06-20", "equity": 100.0 }, { "t": "2026-06-30", "equity": 87.26 } ],
      "open_positions": [ { "pair": "SOLUSDT", "direction": "short", "entry_price": 73.10,
        "quantity": 0.8, "leverage": 2, "margin": 29.24, "take_profit": 70.91,
        "stop_loss": 74.20, "timestamp": "2026-06-30T14:00:00Z", "exchange_stops": true } ],
      "closed_trades": [ { "closed_at": "2026-06-30T14:31:00Z", "pair": "SOLUSDT",
        "direction": "short", "entry_price": 72.95, "exit_price": 71.85, "quantity": 1.2,
        "pnl": -1.99, "status": "closed_sl", "regime": "ranging", "confidence": 7,
        "timestamp": "2026-06-30T12:05:00Z" } ],
      "by_symbol": [ { "key": "BTCUSDT", "trades": 14, "win_rate": 50.0, "net_pnl": 6.10 } ],
      "by_regime": [ { "key": "ranging", "trades": 13, "win_rate": 23.1, "net_pnl": -22.99 } ],
      "ai_report": { "date": "2026-06-30", "narrative": "Choppy fortnight.",
        "whats_working": ["BTC entries in clear trends"],
        "whats_losing": ["SOL trades in ranging regime"],
        "config_suggestions": [ { "param": "ADX_TREND_MIN_SOLUSDT", "current": "25",
          "suggested": "30", "rationale": "filter more SOL chop" } ] },
      "veto": { "proceed": 26, "block": 2, "scored": 24, "proceed_win_rate": 41.7,
        "rows": [ { "ts": "2026-06-30T12:05:00Z", "symbol": "SOLUSDT", "signal": "SELL",
          "proceed": true, "reason": "trend intact, no red flag",
          "risk_flags": ["low_adx_chop"], "news_flag": false, "outcome": "loss" } ] },
      "lessons": [ { "ts": "2026-06-30T14:31:00Z", "pair": "SOLUSDT", "outcome": "closed_sl",
        "lesson": "Avoid shorting into established support in a ranging market.",
        "failure_pattern": "shorted into support", "confidence": "high",
        "tags": ["support", "ranging", "short"] } ]
    }
    """.data(using: .utf8)!

    /// The same payload with the entire review layer absent — drives the AI-null screen.
    static let aiNull = """
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 87.26, "equity": 116.40, "open": 0, "total": 28,
        "wins": 11, "losses": 17, "win_rate": 39.3, "total_pnl": -12.74,
        "today_total": 3, "today_wins": 1, "today_losses": 2, "today_pnl": -2.22 },
      "curve": [ { "t": "2026-06-20", "equity": 100.0 } ],
      "open_positions": [],
      "closed_trades": [],
      "by_symbol": [],
      "by_regime": [],
      "ai_report": null,
      "veto": null,
      "lessons": null
    }
    """.data(using: .utf8)!

    /// Unrecognised direction, status, and signal values.
    static let unknownEnums = """
    {
      "generated_at": "2026-06-30T15:22:45Z",
      "summary": { "balance": 1, "equity": 1, "open": 0, "total": 1,
        "wins": 0, "losses": 1, "win_rate": 0, "total_pnl": -1,
        "today_total": 0, "today_wins": 0, "today_losses": 0, "today_pnl": 0 },
      "curve": [],
      "open_positions": [],
      "closed_trades": [ { "closed_at": "2026-06-30T14:31:00Z", "pair": "XRPUSDT",
        "direction": "sideways", "entry_price": 1, "exit_price": 1, "quantity": 1,
        "pnl": -1, "status": "closed_manual", "regime": "chop", "confidence": 3,
        "timestamp": "2026-06-30T12:05:00Z" } ],
      "by_symbol": [], "by_regime": [],
      "ai_report": null, "veto": null, "lessons": null
    }
    """.data(using: .utf8)!

    static let malformed = Data("{ this is not json".utf8)
}
