import Foundation
import Combine

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
