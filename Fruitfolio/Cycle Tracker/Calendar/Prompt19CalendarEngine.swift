import Foundation

public struct Prompt19CalendarEngine: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        var calendar = calendar
        calendar.firstWeekday = 1
        self.calendar = calendar
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

    public func monthTitle(
        _ month: Prompt19CalendarMonth
    ) -> String {
        let abbreviations = [
            "jan",
            "feb",
            "mar",
            "apr",
            "may",
            "jun",
            "jul",
            "aug",
            "sep",
            "oct",
            "nov",
            "dec"
        ]

        guard month.month >= 1,
              month.month <= abbreviations.count
        else {
            return "\(month.year)"
        }

        return "\(abbreviations[month.month - 1]) \(month.year)"
    }

    public func displayDateTitle(_ key: Prompt19CalendarDateKey) -> String {
        guard let date = key.date(in: calendar) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date).lowercased()
    }

    public func accessibilityLabel(
        for cell: Prompt19CalendarCell
    ) -> String {
        guard let key = cell.key,
              let date = key.date(in: calendar)
        else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .long

        var parts = [formatter.string(from: date)]

        if let cycleDay = cell.annotation?.cycleDay {
            parts.append("cycle day \(cycleDay)")
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

        return parts.joined(separator: ", ")
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
        }

        merged.temperatureDisplay =
            incoming.temperatureDisplay
            ?? merged.temperatureDisplay

        merged.noteText =
            incoming.noteText
            ?? merged.noteText

        return merged
    }
}
