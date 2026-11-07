import Foundation

public struct Prompt19CalendarEngine: Sendable {
    public var calendar: Calendar
    public var displayLocale: Locale

    public init(calendar: Calendar = .current, displayLocale: Locale = Locale(identifier: "en_US_POSIX")) {
        var calendar = calendar
        calendar.firstWeekday = 1
        self.calendar = calendar
        self.displayLocale = displayLocale
    }

    public func buildMonth(
        month: Prompt19CalendarMonth,
        annotations: [Prompt19CalendarDateKey: Prompt19CalendarDayAnnotation],
        today: Date,
        selected: Prompt19CalendarDateKey?
    ) -> Prompt19CalendarMonthModel {
        guard let first = month.firstDate(in: calendar),
              let dayRange = calendar.range(of: .day, in: .month, for: first)
        else {
            return Prompt19CalendarMonthModel(
                month: month,
                cells: [],
                weekRowCount: 0
            )
        }

        let firstWeekday = calendar.component(.weekday, from: first)
        let leadingBlankCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        let totalSlots = leadingBlankCount + dayRange.count
        let weekRowCount = Int(ceil(Double(totalSlots) / 7.0))
        let cellCount = weekRowCount * 7
        let todayKey = Prompt19CalendarDateKey(date: today, calendar: calendar)

        var cells: [Prompt19CalendarCell] = []
        cells.reserveCapacity(cellCount)

        for index in 0..<cellCount {
            let dayIndex = index - leadingBlankCount + 1

            guard dayRange.contains(dayIndex) else {
                cells.append(
                    Prompt19CalendarCell(
                        key: nil,
                        dateNumber: nil,
                        isInDisplayedMonth: false,
                        isToday: false,
                        isSelected: false,
                        annotation: nil
                    )
                )
                continue
            }

            let key = Prompt19CalendarDateKey(
                year: month.year,
                month: month.month,
                day: dayIndex
            )

            cells.append(
                Prompt19CalendarCell(
                    key: key,
                    dateNumber: dayIndex,
                    isInDisplayedMonth: true,
                    isToday: key == todayKey,
                    isSelected: key == selected,
                    annotation: annotations[key]
                )
            )
        }

        return Prompt19CalendarMonthModel(
            month: month,
            cells: cells,
            weekRowCount: weekRowCount
        )
    }

    public func displayNumber(_ number: Int) -> String {
        number.formatted(.number.grouping(.never).locale(displayLocale))
    }

    public var weekdaySymbols: [String] {
        var symbolsCalendar = calendar
        symbolsCalendar.locale = displayLocale
        let symbols = symbolsCalendar.veryShortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return symbols }
        let offset = ((calendar.firstWeekday - 1) % 7 + 7) % 7
        return Array(symbols[offset...] + symbols[..<offset])
    }

    private func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = displayLocale
        // Display language never changes the calendar system or timezone used
        // for stored civil-day keys and deterministic predictions.
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return formatter
    }

    public func monthTitle(_ month: Prompt19CalendarMonth) -> String {
        guard let date = month.firstDate(in: calendar) else { return displayNumber(month.year) }
        let formatter = formatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM y")
        let value = formatter.string(from: date)
        return displayLocale.language.languageCode?.identifier == "en"
            ? value.lowercased(with: displayLocale) : value
    }

    public func displayDateTitle(_ key: Prompt19CalendarDateKey) -> String {
        guard let date = key.date(in: calendar) else { return "" }
        let formatter = formatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM d")
        let value = formatter.string(from: date)
        return displayLocale.language.languageCode?.identifier == "en"
            ? value.lowercased(with: displayLocale) : value
    }

    public func accessibilityLabel(for cell: Prompt19CalendarCell) -> String {
        accessibilityCopy(for: cell).source
    }

    public func accessibilityCopy(for cell: Prompt19CalendarCell) -> Prompt19CalendarAccessibilityCopy {
        guard let key = cell.key,
              let date = key.date(in: calendar)
        else {
            return .init(source: "", protectedLiterals: [])
        }

        let formatter = formatter()
        formatter.dateStyle = .full
        let dateLiteral = formatter.string(from: date)
        var protectedLiterals = [dateLiteral]
        var parts = [dateLiteral]

        if let cycleDay = cell.annotation?.cycleDay {
            let number = displayNumber(cycleDay)
            protectedLiterals.append(number)
            parts.append("cycle day \(number)")
        }

        if cell.annotation?.recordedPeriod == true {
            parts.append("recorded period")
        } else {
            if cell.annotation?.predictedPeriod == true {
                parts.append("predicted period")
            }

            if cell.annotation?.fertileEstimated == true {
                parts.append("estimated fertile window")
            }

            if cell.annotation?.ovulationEstimated == true {
                parts.append("estimated ovulation")
            }
        }

        if cell.annotation?.symptomsLogged == true {
            parts.append("symptoms logged")
        }

        if cell.annotation?.bbtRecorded == true {
            parts.append("temperature recorded")
        }

        if cell.annotation?.noteAdded == true {
            parts.append("note added")
        }

        if cell.isToday {
            parts.append("today")
        }

        if cell.isSelected {
            parts.append("selected")
        }

        return .init(source: parts.joined(separator: ", "), protectedLiterals: protectedLiterals)
    }

    public func cycleDay(
        for key: Prompt19CalendarDateKey,
        recordedCycleStarts: [Prompt19CalendarDateKey],
        today: Prompt19CalendarDateKey
    ) -> Int? {
        guard key <= today else {
            return nil
        }

        let starts = Array(Set(recordedCycleStarts)).sorted()

        guard let start = starts.last(where: { $0 <= key }),
              let startDate = start.date(in: calendar),
              let targetDate = key.date(in: calendar)
        else {
            return nil
        }

        if let nextStart = starts.first(where: { $0 > start }),
           key >= nextStart {
            return nil
        }

        guard let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: startDate),
            to: calendar.startOfDay(for: targetDate)
        ).day,
        days >= 0
        else {
            return nil
        }

        return days + 1
    }

    public func keys(
        in window: ClosedRange<Date>,
        restrictedTo month: Prompt19CalendarMonth
    ) -> [Prompt19CalendarDateKey] {
        var result: [Prompt19CalendarDateKey] = []
        var cursor = calendar.startOfDay(for: window.lowerBound)
        let end = calendar.startOfDay(for: window.upperBound)

        while cursor <= end {
            let key = Prompt19CalendarDateKey(
                date: cursor,
                calendar: calendar
            )

            if key.year == month.year &&
                key.month == month.month {
                result.append(key)
            }

            guard let next = calendar.date(
                byAdding: .day,
                value: 1,
                to: cursor
            ) else {
                break
            }

            cursor = next
        }

        return result
    }

    public func merging(
        _ incoming: Prompt19CalendarDayAnnotation,
        into existing: Prompt19CalendarDayAnnotation?
    ) -> Prompt19CalendarDayAnnotation {
        guard var merged = existing else {
            return incoming
        }

        merged.cycleDay =
            incoming.cycleDay
            ?? merged.cycleDay

        merged.recordedPeriod =
            merged.recordedPeriod
            || incoming.recordedPeriod

        merged.predictedPeriod =
            merged.predictedPeriod
            || incoming.predictedPeriod

        merged.fertileEstimated =
            merged.fertileEstimated
            || incoming.fertileEstimated

        merged.ovulationEstimated =
            merged.ovulationEstimated
            || incoming.ovulationEstimated

        merged.symptomsLogged =
            merged.symptomsLogged
            || incoming.symptomsLogged

        merged.bbtRecorded =
            merged.bbtRecorded
            || incoming.bbtRecorded

        merged.noteAdded =
            merged.noteAdded
            || incoming.noteAdded

        if !incoming.symptomSummary.isEmpty {
            merged.symptomSummary =
                incoming.symptomSummary
            merged.symptomSummaryIsAuthoredUI = incoming.symptomSummaryIsAuthoredUI
        }

        if let temperature = incoming.temperatureDisplay {
            merged.temperatureDisplay = temperature
            merged.temperatureDisplayProtectedLiterals = incoming.temperatureDisplayProtectedLiterals
        }

        merged.noteText =
            incoming.noteText
            ?? merged.noteText

        return merged
    }
}

/// Native-locale date/number literals stay exact while controlled state labels
/// use the existing shared on-device translation/accessibility presentation.
public struct Prompt19CalendarAccessibilityCopy: Equatable, Sendable {
    public let source: String
    public let protectedLiterals: [String]
}
