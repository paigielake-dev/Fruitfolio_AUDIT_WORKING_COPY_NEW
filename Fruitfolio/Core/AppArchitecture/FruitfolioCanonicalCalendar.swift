import Foundation

/// Persistent cycle/day components are Gregorian civil dates. UI calendars may
/// have different eras/months; only the caller's time zone crosses this boundary.
nonisolated enum FruitfolioCanonicalCalendar {
    static func gregorian(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
    static func components(of date: Date, calendar: Calendar) -> DateComponents {
        guard date.timeIntervalSinceReferenceDate.isFinite else { return DateComponents() }
        return gregorian(timeZone: calendar.timeZone).dateComponents([.year, .month, .day], from: date)
    }
    static func date(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day) else { return nil }
        let canonical = gregorian(timeZone: calendar.timeZone)
        var components = DateComponents()
        components.calendar = canonical; components.timeZone = canonical.timeZone
        components.era = 1; components.year = year; components.month = month; components.day = day; components.hour = 12
        guard let result = canonical.date(from: components) else { return nil }
        let check = canonical.dateComponents([.era, .year, .month, .day], from: result)
        guard check.era == 1, check.year == year, check.month == month, check.day == day else { return nil }
        return result
    }
}
