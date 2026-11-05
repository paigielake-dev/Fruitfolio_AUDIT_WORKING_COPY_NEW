import Foundation

enum FruitfolioMeasuredHormone: String, CaseIterable, Codable, Identifiable, Sendable {
    case estradiol, progesterone, lh, fsh, testosterone, prolactin, amh, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .estradiol: return "Estradiol (E2)"
        case .progesterone: return "Progesterone"
        case .lh: return "Luteinizing hormone (LH)"
        case .fsh: return "Follicle-stimulating hormone (FSH)"
        case .testosterone: return "Testosterone"
        case .prolactin: return "Prolactin"
        case .amh: return "Anti-Müllerian hormone (AMH)"
        case .other: return "Other Hormone"
        }
    }
}

enum FruitfolioHormoneTestDatePrecision: String, Codable, Sendable { case day }

struct FruitfolioHormoneMeasurement: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var hormone: FruitfolioMeasuredHormone = .estradiol
    var otherHormoneName = ""
    var result = ""
    var resultLocaleIdentifier: String?
    var unit = ""
    // Compatibility Date value; the form collects a day, never a clinical time.
    var testDate = Date()
    var testDatePrecision: FruitfolioHormoneTestDatePrecision? = .day
    var reportedTestDay: Prompt13LocalDate?
    var testDateEntryTimeZoneIdentifier: String?
    var sampleType = ""
    var cycleDay: Int?
    var laboratoryReferenceRange = ""
    var notes = ""

    var hormoneName: String { hormone == .other ? otherHormoneName : hormone.label }

    mutating func setReportedTestDate(_ date: Date, calendar: Calendar) throws {
        let day = try Prompt13LocalDate(date, calendar: calendar)
        guard reportedTestDay != day || testDateEntryTimeZoneIdentifier == nil || testDatePrecision != .day else { return }
        testDate = date
        reportedTestDay = day
        testDatePrecision = .day
        testDateEntryTimeZoneIdentifier = calendar.timeZone.identifier
    }

    func dateForDisplay(calendar: Calendar = .autoupdatingCurrent) -> Date? {
        if let reportedTestDay { return try? reportedTestDay.foundationDate(in: calendar) }
        return testDate.timeIntervalSinceReferenceDate.isFinite ? testDate : nil
    }
    func dayForOrdering(calendar: Calendar = .autoupdatingCurrent) -> Prompt13LocalDate? {
        reportedTestDay ?? (try? Prompt13LocalDate(testDate, calendar: calendar))
    }

    func validate(locale: Locale = .current) throws {
        let input = result.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsingLocale = resultLocaleIdentifier.map { Locale(identifier: $0) } ?? locale
        let separator = parsingLocale.decimalSeparator ?? "."
        let digitNormalized = input.unicodeScalars.map { scalar -> String in
            if CharacterSet.decimalDigits.contains(scalar), let digit = Character(String(scalar)).wholeNumberValue {
                return String(digit)
            }
            return String(scalar)
        }.joined()
        let escapedSeparator = NSRegularExpression.escapedPattern(for: separator)
        let pattern = "^[+]?(?:[0-9]+(?:" + escapedSeparator + "[0-9]*)?|" + escapedSeparator + "[0-9]+)(?:[eE][+-]?[0-9]+)?$"
        let fullNumber = digitNormalized.range(of: pattern, options: .regularExpression) != nil
        let normalized = digitNormalized.replacingOccurrences(of: separator, with: ".")
        guard !input.isEmpty, fullNumber,
              let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")),
              !value.isNaN, value >= 0, testDate.timeIntervalSinceReferenceDate.isFinite,
              !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FruitfolioHormoneMeasurementError.invalidRequiredFields
        }
        guard hormone != .other || !otherHormoneName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              cycleDay == nil || cycleDay! > 0 else {
            throw FruitfolioHormoneMeasurementError.invalidRequiredFields
        }
    }
}

enum FruitfolioHormoneMeasurementError: LocalizedError {
    case invalidRequiredFields, unreadableStorage
    var errorDescription: String? {
        switch self {
        case .invalidRequiredFields:
            return "enter a hormone, a valid non-negative numerical result, and its unit. cycle day, when provided, must be positive."
        case .unreadableStorage:
            return "saved measurements could not be read. the original data has been preserved."
        }
    }
}

