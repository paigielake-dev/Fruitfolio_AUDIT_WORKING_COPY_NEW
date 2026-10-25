import Foundation

/// Phase 21 consumes Phase 16's already-established contextual classification.
/// It does not calculate a new phase, fertile window, or ovulation date.
@MainActor
struct Prompt21BodyBiologyLoader {
    var todayLoader = Prompt16TodayLoader()

    func load(
        now: Date = Date()
    ) async throws -> Prompt21BodyBiologyInput {
        let today = try await todayLoader.load(now: now)
        let title = today.context.title
        let explanation = today.context.explanation
        let state = Self.mapEstablishedContextTitle(title)

        let kind: Prompt21BodyBiologyContextKind
        switch state {
        case .estimatedOvulation:
            kind = .estimated
        case .neutral:
            kind = .educational
        case .follicularEarly, .follicularLater, .luteal, .menstruation:
            kind = .calculated
        }

        return Prompt21BodyBiologyInput(
            state: state,
            contextKind: kind,
            cycleDay: today.cycleDay,
            confirmedCycleDayOne:
                state == .menstruation && today.cycleDay == 1,
            upstreamContextTitle: title,
            upstreamContextExplanation: explanation
        )
    }

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
