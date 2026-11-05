import Foundation

/// Phase 21 consumes Phase 16's already-established contextual classification.
/// It does not calculate a new phase, fertile window, or ovulation date.
@MainActor
struct Prompt21BodyBiologyLoader {
    var todayLoader = Prompt16TodayLoader()

    func load(
        now: Date = Date()
    ) async throws -> Prompt21BodyBiologyInput {
        Self.makeInput(from: try await todayLoader.load(now: now))
    }

    /// Consume the stable state, never localized/user-facing prose. The current
    /// Today contract supplies no typed ovulation/luteal/follicular phase; those
    /// presentations must not be inferred from words or cycle-day arithmetic.
    nonisolated static func makeInput(from today: Prompt16TodayState) -> Prompt21BodyBiologyInput {
        let state: Prompt21BodyBiologyState
        switch today.context {
        case .menstruation:
            // Bleeding alone (including spotting) does not establish menstruation.
            state = today.hasRecordedBleedingToday && (today.hasReportedOpenPeriod || today.cycleDay == 1)
                ? .menstruation : .neutral
        case .cycleContext, .insufficientData, .reportedOpenPeriod: state = .neutral
        }
        return Prompt21BodyBiologyInput(
            state: state,
            contextKind: state == .neutral ? .educational : .calculated,
            cycleDay: today.cycleDay,
            confirmedCycleDayOne: state == .menstruation && today.cycleDay == 1 && today.hasRecordedBleedingToday,
            upstreamContextTitle: today.context.title,
            upstreamContextExplanation: today.context.explanation
        )
    }

    /// Legacy title mapper retained for compatibility; production uses makeInput.
    /// This maps only the semantic context title already emitted by the existing
    /// Cycle Tracker. It never derives biology from the calendar date itself.
    /// Unknown or broader states deliberately fall back to neutral education.
    nonisolated static func mapEstablishedContextTitle(
        _ title: String
    ) -> Prompt21BodyBiologyState {
        let normalized = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.contains("menstru") {
            return .menstruation
        }

        if normalized.contains("ovulat") {
            return .estimatedOvulation
        }

        if normalized.contains("luteal") {
            return .luteal
        }

        if normalized.contains("follicular") {
            if normalized.contains("later") || normalized.contains("late") {
                return .follicularLater
            }
            return .follicularEarly
        }

        return .neutral
    }
}
