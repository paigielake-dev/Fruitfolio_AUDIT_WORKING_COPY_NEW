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
    /// Stable symbols are retained literally in translated controlled labels.
    /// This is not a scientific terminology/clinical-quality signoff.
    var protectedAbbreviations: [String] {
        switch self {
        case .estradiol: return ["E2"]
        case .lh: return ["LH"]
        case .fsh: return ["FSH"]
        case .amh: return ["AMH"]
        case .progesterone, .testosterone, .prolactin, .other: return []
        }
    }

}

/// Only formats the platform actually recognizes may interpret a result.
/// Opaque legacy identifiers remain metadata; Foundation's fallback separator
/// is not evidence of the report's notation. Supported hyphen/underscore
/// regional aliases share a lookup, without rewriting the stored identifier.
nonisolated enum FruitfolioHormoneReportFormat {
    private static let platformIdentifiers: [String: String] = Locale.availableIdentifiers.sorted().reduce(into: [:]) { result, identifier in
        result[normalized(identifier)] = identifier
    }
    private static func normalized(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "-", with: "_").lowercased()
    }
    static func decimalSeparator(for identifier: String?) -> String? {
        guard let identifier, !identifier.isEmpty,
              let recognized = platformIdentifiers[normalized(identifier)],
              let separator = Locale(identifier: recognized).decimalSeparator, !separator.isEmpty else { return nil }
        return separator
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
        guard let separator = FruitfolioHormoneReportFormat.decimalSeparator(for: resultLocaleIdentifier ?? locale.identifier) else {
            throw FruitfolioHormoneMeasurementError.resultFormatRequired
        }
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

/// Snapshot of one editor session, checked against the actual current record.
/// Other measurements can change independently; no draft is merged implicitly.
enum FruitfolioMeasurementSaveIntent: Equatable, Sendable {
    case create(UUID)
    case edit(FruitfolioHormoneMeasurement)

    func validate(candidate: FruitfolioHormoneMeasurement, current: FruitfolioHormoneMeasurement?) throws {
        switch self {
        case .create(let id):
            guard candidate.id == id, current == nil else { throw FruitfolioHormoneMeasurementError.editingConflict }
        case .edit(let baseline):
            guard candidate.id == baseline.id, current == baseline else {
                throw FruitfolioHormoneMeasurementError.editingConflict
            }
        }
    }
}

enum FruitfolioHormoneMeasurementError: LocalizedError, Equatable {
    case editingConflict, resultFormatRequired, invalidRequiredFields, unreadableStorage, unsupportedStorage, storageChanged, confirmationChanged
    var errorDescription: String? {
        switch self {
        case .editingConflict:
            return "this measurement changed or was removed while you were editing. your draft is still here. close the editor to review the latest saved record before trying again."
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

