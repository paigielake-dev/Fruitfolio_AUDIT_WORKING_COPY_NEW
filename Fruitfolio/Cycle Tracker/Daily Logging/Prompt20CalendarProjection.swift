import Foundation

/// Pure projection to the display calendar. Stored civil dates stay canonical;
/// no bleeding observation is promoted into a period or fertility prediction.
nonisolated enum Prompt20CalendarProjection {
    static func annotations(for logs: [Prompt20DailyLog], month: Prompt19CalendarMonth,
        calendar: Calendar) -> [Prompt19CalendarDayAnnotation] {
        logs.compactMap { log -> Prompt19CalendarDayAnnotation? in
            guard !log.isDeleted, let absolute = log.date.date(in: calendar) else { return nil }
            let key = Prompt19CalendarDateKey(date: absolute, calendar: calendar)
            guard key.year == month.year, key.month == month.month else { return nil }
            let summary = Prompt20DailyLogRules.summary(for: log)
            return Prompt19CalendarDayAnnotation(key: key, recordedPeriod: false, predictedPeriod: false,
                fertileEstimated: false, ovulationEstimated: false, symptomsLogged: summary.hasSymptoms,
                bbtRecorded: summary.hasBasalTemperature, noteAdded: summary.hasGeneralNote,
                symptomSummary: summary.symptomNames, temperatureDisplay: summary.hasBasalTemperature ? summary.temperatureDisplay : nil,
                noteText: summary.hasGeneralNote ? summary.notePreview : nil)
        }.sorted { $0.key < $1.key }
    }
}
