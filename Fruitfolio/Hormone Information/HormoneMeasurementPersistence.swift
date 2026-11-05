import Foundation

/// Exact local storage implementation, exercised on Foundation without mocks.
nonisolated final class FruitfolioHormoneMeasurementPersistence {
    private(set) var records: [FruitfolioHormoneMeasurement] = []
    private(set) var storageUnreadable = false
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
        guard let object = defaults.object(forKey: key) else { return }
        guard let data = object as? Data else { storageUnreadable = true; return }
        do {
            let decoded = try JSONDecoder().decode([FruitfolioHormoneMeasurement].self, from: data)
            guard Set(decoded.map(\.id)).count == decoded.count else { storageUnreadable = true; return }
            records = decoded
        } catch { storageUnreadable = true }
    }

    func history(hormone: FruitfolioMeasuredHormone? = nil) -> [FruitfolioHormoneMeasurement] {
        records.filter { hormone == nil || $0.hormone == hormone }.sorted {
            let left = $0.dayForOrdering()
            let right = $1.dayForOrdering()
            if let left, let right, left != right { return left > right }
            if (left == nil) != (right == nil) { return left != nil }
            // No test time was collected. UUID is a deterministic same-day tie,
            // not a fabricated order of laboratory concentrations.
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func save(_ measurement: FruitfolioHormoneMeasurement, locale: Locale = .current) throws {
        guard !storageUnreadable else { throw FruitfolioHormoneMeasurementError.unreadableStorage }
        var recorded = measurement
        if recorded.resultLocaleIdentifier == nil { recorded.resultLocaleIdentifier = locale.identifier }
        try recorded.validate(locale: locale)
        var updated = records
        if let index = updated.firstIndex(where: { $0.id == recorded.id }) { updated[index] = recorded }
        else { updated.append(recorded) }
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
