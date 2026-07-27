import Foundation
import Observation
import BotDataKit
import BotDomain
import BotFormatting

struct SuggestionPresentation: Identifiable, Equatable {
    let param: String
    let current: String
    let suggested: String
    let rationale: String
    var id: String { param }
}

struct ReportPresentation: Equatable {
    let narrative: String
    let working: [String]
    let losing: [String]
    let suggestions: [SuggestionPresentation]
}

struct VetoSummaryPresentation: Equatable {
    let proceedText: String
    let blockText: String
    let winRateText: String
    let scoredText: String
}

struct VetoRowPresentation: Identifiable, Equatable {
    let id: String
    let symbol: String
    let signalText: String
    let signalIsBuy: Bool
    let decisionLabel: String
    let didProceed: Bool
    let reason: String
    let flags: [String]
    let outcomeText: String
    let outcomeSign: PnLSign
    let timeText: String
}

struct LessonPresentation: Identifiable, Equatable {
    let id: String
    let pair: String
    let outcomeLabel: String
    let timeText: String
    let text: String
    let metaText: String
    let tags: [String]
}

struct PlaceholderContent: Identifiable, Equatable {
    let title: String
    let description: String
    var id: String { title }
}

@MainActor
@Observable
final class ReviewViewModel {
    private let store: SnapshotStore

    init(store: SnapshotStore) {
        self.store = store
    }

    var snapshot: Snapshot? { store.state.value }
    var isLoading: Bool { store.state.isLoading && snapshot == nil }
    var isStale: Bool { store.isStale }
    var errorMessage: String? {
        guard snapshot == nil else { return store.lastErrorMessage }
        guard let error = store.state.error else { return nil }
        return (error as? SnapshotError)?.userMessage ?? error.localizedDescription
    }

    /// The one branch that produces the design's fourth screen.
    var hasReviewLayer: Bool { snapshot?.hasReviewLayer ?? false }

    var dateText: String { snapshot?.aiReport?.date ?? "off" }

    var report: ReportPresentation? {
        guard let report = snapshot?.aiReport else { return nil }
        return ReportPresentation(
            narrative: "\u{201C}\(report.narrative)\u{201D}",
            working: report.whatsWorking,
            losing: report.whatsLosing,
            suggestions: report.configSuggestions.map {
                SuggestionPresentation(
                    param: $0.param, current: $0.current,
                    suggested: $0.suggested, rationale: $0.rationale
                )
            }
        )
    }

    var vetoSummary: VetoSummaryPresentation? {
        guard let veto = snapshot?.veto else { return nil }
        return VetoSummaryPresentation(
            proceedText: "\(veto.proceed)",
            blockText: "\(veto.block)",
            winRateText: BotFormat.percent(veto.proceedWinRate),
            scoredText: "\(veto.scored) scored"
        )
    }

    var vetoRows: [VetoRowPresentation] {
        (snapshot?.veto?.rows ?? []).map { row in
            let sign: PnLSign
            switch row.outcome {
            case .win: sign = .positive
            case .loss: sign = .negative
            case nil: sign = .flat
            }
            return VetoRowPresentation(
                id: row.id,
                symbol: row.symbol,
                signalText: row.signal == .unknown ? "—" : row.signal.rawValue,
                signalIsBuy: row.signal == .buy,
                decisionLabel: row.decisionLabel,
                didProceed: row.proceed,
                reason: row.reason,
                flags: row.displayFlags,
                outcomeText: row.outcomeLabel,
                outcomeSign: sign,
                timeText: BotFormat.stamp(row.timestamp)
            )
        }
    }

    var lessons: [LessonPresentation] {
        (snapshot?.lessons ?? []).map { lesson in
            LessonPresentation(
                id: lesson.id,
                pair: lesson.pair,
                outcomeLabel: lesson.outcome == .takeProfit ? "TP" : "SL",
                timeText: BotFormat.stamp(lesson.timestamp),
                text: lesson.lesson,
                metaText: "pattern: \(lesson.failurePattern) · conf: \(lesson.confidence)",
                tags: lesson.tags
            )
        }
    }

    var lessonCountText: String { "\(lessons.count) recent" }

    /// Shown only when the review layer is off. Copy is the design's, verbatim.
    var placeholders: [PlaceholderContent] {
        guard !hasReviewLayer, snapshot != nil else { return [] }
        return [
            PlaceholderContent(
                title: "Latest AI report",
                description: "Enable the review layer for a narrative read on recent performance plus config suggestions."
            ),
            PlaceholderContent(
                title: "Veto log",
                description: "Logs every proceed / block decision and tracks the win rate of trades it let through."
            ),
            PlaceholderContent(
                title: "Lessons",
                description: "Captures a post-mortem after each loss with failure patterns and tags."
            ),
        ]
    }

    func refresh() async {
        await store.refresh()
    }
}
