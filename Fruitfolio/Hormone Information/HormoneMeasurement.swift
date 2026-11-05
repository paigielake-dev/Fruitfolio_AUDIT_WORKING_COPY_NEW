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

struct FruitfolioHormoneMeasurement: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var hormone: FruitfolioMeasuredHormone = .estradiol
    var otherHormoneName = ""
    var result = ""
    var unit = ""
    var testDate = Date()
    var sampleType = ""
    var cycleDay: Int?
    var laboratoryReferenceRange = ""
    var notes = ""

    var hormoneName: String { hormone == .other ? otherHormoneName : hormone.label }

    func validate(locale: Locale = .current) throws {
        let input = result.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: input)
        scanner.locale = locale
        var value = Decimal()
        guard !input.isEmpty, scanner.scanDecimal(&value), scanner.isAtEnd,
              !value.isNaN, value >= 0,
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

