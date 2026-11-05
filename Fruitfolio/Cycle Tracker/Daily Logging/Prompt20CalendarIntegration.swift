import Foundation

/// Phase 20 -> Phase 19 presentation bridge.
///
/// Daily Logging records observations only. This bridge intentionally exposes only
/// calendar metadata that Phase 19 already knows how to render. In particular,
/// a bleeding observation NEVER becomes `recordedPeriod` here, and no fertility,
/// ovulation, cycle-day, or predicted-period state is created by Phase 20.
@MainActor
enum Prompt20CalendarIntegration {
    static func supplementalProvider(
        repository: (any Prompt20DailyLogRepository)? = nil,
        ownerID: Prompt20DailyLogOwnerID? = nil
    ) -> Prompt19CalendarSupplementalProvider {
        let resolvedRepository =
            repository ?? Prompt20CycleDailyLogStore.shared

        let resolvedOwnerID =
            ownerID ?? Prompt20DailyLogOwnerID.localDevice

        return Prompt19CalendarSupplementalProvider { month, calendar in
            let logs =
                try await resolvedRepository.allActiveLogs(
                    ownerID: resolvedOwnerID
                )

            return Prompt20CalendarProjection.annotations(for: logs, month: month, calendar: calendar)
        }
    }

    static func annotations(
        for logs: [Prompt20DailyLog],
        month: Prompt19CalendarMonth,
        calendar: Calendar
    ) -> [Prompt19CalendarDayAnnotation] {
        Prompt20CalendarProjection.annotations(for: logs, month: month, calendar: calendar)
    }
}
