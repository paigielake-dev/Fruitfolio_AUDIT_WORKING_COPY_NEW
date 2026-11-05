import Foundation
import Combine

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

/// Private, local records. This store has no connection to Ask, analytics,
/// cycle confidence, educational curves, or account synchronization.
@MainActor
final class FruitfolioHormoneMeasurementStore: ObservableObject {
    static let shared = FruitfolioHormoneMeasurementStore()
    static let persistenceKey = "fruitfolio.hormoneMeasurements.v1"
    @Published private(set) var records: [FruitfolioHormoneMeasurement] = []
    @Published private(set) var storageUnreadable = false
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = persistenceKey) {
        self.defaults = defaults
        self.key = key
        if let data = defaults.data(forKey: key) {
            do { records = try JSONDecoder().decode([FruitfolioHormoneMeasurement].self, from: data) }
            catch { storageUnreadable = true }
        }
    }

    func history(hormone: FruitfolioMeasuredHormone? = nil) -> [FruitfolioHormoneMeasurement] {
        records.filter { hormone == nil || $0.hormone == hormone }.sorted {
            $0.testDate == $1.testDate ? $0.id.uuidString < $1.id.uuidString : $0.testDate > $1.testDate
        }
    }

    func save(_ measurement: FruitfolioHormoneMeasurement, locale: Locale = .current) throws {
        guard !storageUnreadable else { throw FruitfolioHormoneMeasurementError.unreadableStorage }
        try measurement.validate(locale: locale)
        var updated = records
        if let index = updated.firstIndex(where: { $0.id == measurement.id }) { updated[index] = measurement }
        else { updated.append(measurement) }
        try persist(updated)
    }

    func delete(id: UUID) throws {
        guard !storageUnreadable else { throw FruitfolioHormoneMeasurementError.unreadableStorage }
        try persist(records.filter { $0.id != id })
    }

    func exportJSON() throws -> Data {
        guard !storageUnreadable else { throw FruitfolioHormoneMeasurementError.unreadableStorage }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(history())
    }

    /// Call only after explicit destructive confirmation by the user.
    func eraseAllMeasurements() {
        defaults.removeObject(forKey: key)
        records = []
        storageUnreadable = false
    }

    private func persist(_ updated: [FruitfolioHormoneMeasurement]) throws {
        let data = try JSONEncoder().encode(updated)
        defaults.set(data, forKey: key)
        records = updated
    }
}
