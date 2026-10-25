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

            return await MainActor.run {
                annotations(
                    for: logs,
                    month: month,
                    calendar: calendar
                )
            }
        }
    }

    static func annotations(
        for logs: [Prompt20DailyLog],
        month: Prompt19CalendarMonth,
        calendar: Calendar
    ) -> [Prompt19CalendarDayAnnotation] {
        logs.compactMap { log in
            guard !log.isDeleted,
                  log.date.year == month.year,
                  log.date.month == month.month
            else {
                return nil
            }

            let summary =
                Prompt20DailyLogRules.summary(
                    for: log
                )

            let key =
                Prompt19CalendarDateKey(
                    year: log.date.year,
                    month: log.date.month,
                    day: log.date.day
                )

            let bbtRecorded =
                summary.hasBasalTemperature

            let noteAdded =
                summary.hasGeneralNote

            return Prompt19CalendarDayAnnotation(
                key: key,
                recordedPeriod: false,
                predictedPeriod: false,
                fertileEstimated: false,
                ovulationEstimated: false,
                symptomsLogged: summary.hasSymptoms,
                bbtRecorded: bbtRecorded,
                noteAdded: noteAdded,
                symptomSummary: summary.symptomNames,
                temperatureDisplay:
                    bbtRecorded
                    ? summary.temperatureDisplay
                    : nil,
                noteText:
                    noteAdded
                    ? summary.notePreview
                    : nil
            )
        }
        .sorted {
            $0.key < $1.key
        }
    }
}
