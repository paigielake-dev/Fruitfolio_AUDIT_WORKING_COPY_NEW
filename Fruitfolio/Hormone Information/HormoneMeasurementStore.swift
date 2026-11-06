import Foundation
#if canImport(Combine)
import Combine
#endif

/// Private local records; no Ask, prediction, analytics or account connection.
@MainActor
final class FruitfolioHormoneMeasurementStore {
    static let shared = FruitfolioHormoneMeasurementStore()
    static let persistenceKey = "fruitfolio.hormoneMeasurements.v1"
    #if canImport(Combine)
    @Published
    #endif
    private(set) var records: [FruitfolioHormoneMeasurement]
    #if canImport(Combine)
    @Published
    #endif
    private(set) var storageUnreadable: Bool
    #if canImport(Combine)
    @Published
    #endif
    private(set) var storageProtectionReason: FruitfolioHormoneMeasurementError?
    private let persistence: FruitfolioHormoneMeasurementPersistence

    init(defaults: UserDefaults = .standard, key: String = persistenceKey) {
        let persistence = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: key)
        self.persistence = persistence
        records = persistence.records
        storageUnreadable = persistence.storageUnreadable
        storageProtectionReason = persistence.protectionReason
    }
    func history(hormone: FruitfolioMeasuredHormone? = nil) -> [FruitfolioHormoneMeasurement] {
        persistence.history(hormone: hormone)
    }
    func save(_ measurement: FruitfolioHormoneMeasurement, locale: Locale = .current) throws {
        defer { refresh() }
        try persistence.save(measurement, locale: locale)
    }
    func delete(id: UUID) throws { defer { refresh() }; try persistence.delete(id: id) }
    func exportJSON() throws -> Data { defer { refresh() }; return try persistence.exportJSON() }
    /// Existing UI requires explicit destructive confirmation.
    func eraseAllMeasurements() throws { defer { refresh() }; try persistence.eraseAllMeasurements() }
    func reloadSavedMeasurements() { persistence.reload(); refresh() }
    private func refresh() {
        records = persistence.records
        storageUnreadable = persistence.storageUnreadable
        storageProtectionReason = persistence.protectionReason
    }
}

#if canImport(Combine)
extension FruitfolioHormoneMeasurementStore: ObservableObject {}
#endif
