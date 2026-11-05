import Foundation
import Combine

/// Private local records; no Ask, prediction, analytics or account connection.
@MainActor
final class FruitfolioHormoneMeasurementStore: ObservableObject {
    static let shared = FruitfolioHormoneMeasurementStore()
    static let persistenceKey = "fruitfolio.hormoneMeasurements.v1"
    @Published private(set) var records: [FruitfolioHormoneMeasurement]
    @Published private(set) var storageUnreadable: Bool
    private let persistence: FruitfolioHormoneMeasurementPersistence

    init(defaults: UserDefaults = .standard, key: String = persistenceKey) {
        let persistence = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: key)
        self.persistence = persistence
        records = persistence.records
        storageUnreadable = persistence.storageUnreadable
    }
    func history(hormone: FruitfolioMeasuredHormone? = nil) -> [FruitfolioHormoneMeasurement] {
        persistence.history(hormone: hormone)
    }
    func save(_ measurement: FruitfolioHormoneMeasurement, locale: Locale = .current) throws {
        try persistence.save(measurement, locale: locale)
        refresh()
    }
    func delete(id: UUID) throws { try persistence.delete(id: id); refresh() }
    func exportJSON() throws -> Data { try persistence.exportJSON() }
    /// Existing UI requires explicit destructive confirmation.
    func eraseAllMeasurements() { persistence.eraseAllMeasurements(); refresh() }
    private func refresh() { records = persistence.records; storageUnreadable = persistence.storageUnreadable }
}
