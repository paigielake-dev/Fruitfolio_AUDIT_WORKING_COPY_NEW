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

    /// Accept decimal digits from any script, but never signs, fractions,
    /// separators or a partial/overflowing integer for a reported cycle day.
    static func parseCycleDay(_ text: String) throws -> Int? {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }
        var ascii = ""
        for scalar in input.unicodeScalars {
            guard CharacterSet.decimalDigits.contains(scalar),
                  let digit = Character(String(scalar)).wholeNumberValue else {
                throw FruitfolioHormoneMeasurementError.invalidRequiredFields
            }
            ascii += String(digit)
        }
        guard let day = Int(ascii), day > 0 else {
            throw FruitfolioHormoneMeasurementError.invalidRequiredFields
        }
        return day
    }

    // A notes-only edit may preserve an unknown legacy result format without
    // treating the current device language as historical laboratory evidence.
    func validateRequiredMetadata() throws {
        guard testDate.timeIntervalSinceReferenceDate.isFinite,
              !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              hormone != .other || !otherHormoneName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              cycleDay == nil || cycleDay! > 0 else {
            throw FruitfolioHormoneMeasurementError.invalidRequiredFields
        }
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
        try validateRequiredMetadata()
    }
}

enum FruitfolioHormoneMeasurementError: LocalizedError, Equatable {
    case resultFormatRequired, invalidRequiredFields, unreadableStorage, unsupportedStorage, storageChanged, confirmationChanged
    var errorDescription: String? {
        switch self {
        case .resultFormatRequired:
            return "choose the decimal separator used on the report before changing this result. the original value and unknown format have been preserved."
        case .invalidRequiredFields:
            return "enter a hormone, a valid non-negative numerical result, and its unit. cycle day, when provided, must be positive."
        case .confirmationChanged:
            return "the saved measurement record changed after this confirmation opened. nothing was deleted. review the current record before trying again."
        case .unsupportedStorage:
            return "saved measurements contain fields this version cannot safely update. readable values remain available, and the original data has been preserved."
        case .storageChanged:
            return "saved measurements changed or were cleared elsewhere. the latest saved data has been preserved. reload it before making changes or exporting."
        case .unreadableStorage:
            return "saved measurements could not be read. the original data has been preserved."
        }
    }
}

