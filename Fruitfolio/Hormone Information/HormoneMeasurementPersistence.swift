import Foundation

/// Exact local storage implementation, exercised on Foundation without mocks.
nonisolated final class FruitfolioHormoneMeasurementPersistence {
    private(set) var records: [FruitfolioHormoneMeasurement] = []
    private(set) var storageUnreadable = false
    private(set) var protectionReason: FruitfolioHormoneMeasurementError?
    private var expectedPersistedObject: NSObject?
    private(set) var revision = UUID()
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
        reload()
    }

    /// Read only. Never repair an unsupported/corrupt saved record by writing it.
    func reload() {
        revision = UUID()
        records = []
        storageUnreadable = false
        protectionReason = nil
        expectedPersistedObject = defaults.object(forKey: key) as? NSObject
        guard let object = expectedPersistedObject else { return }
        guard let data = object as? Data else {
            storageUnreadable = true; protectionReason = .unreadableStorage; return
        }
        do {
            let decoded = try JSONDecoder().decode([FruitfolioHormoneMeasurement].self, from: data)
            guard Set(decoded.map(\.id)).count == decoded.count else {
                storageUnreadable = true; protectionReason = .unreadableStorage; return
            }
            records = decoded
            if !FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: try JSONEncoder().encode(decoded)) {
                protectionReason = .unsupportedStorage
            }
        } catch { storageUnreadable = true; protectionReason = .unreadableStorage }
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
        try requireWritable()
        var recorded = measurement
        let previous = records.first { $0.id == recorded.id }
        if recorded.resultLocaleIdentifier == nil, let previous, previous.resultLocaleIdentifier == nil {
            guard recorded.result == previous.result, recorded.unit == previous.unit else {
                throw FruitfolioHormoneMeasurementError.resultFormatRequired
            }
            // Preserve the historical unknown; do not reinterpret its number.
            try recorded.validateRequiredMetadata()
        } else {
            if recorded.resultLocaleIdentifier == nil {
                recorded.resultLocaleIdentifier = previous?.resultLocaleIdentifier ?? locale.identifier
            }
            try recorded.validate(locale: locale)
        }
        var updated = records
        if let index = updated.firstIndex(where: { $0.id == recorded.id }) { updated[index] = recorded }
        else { updated.append(recorded) }
        try persist(updated)
    }

    func delete(id: UUID) throws {
        try requireWritable()
        try persist(records.filter { $0.id != id })
    }

    func exportJSON() throws -> Data {
        try requireWritable()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(history())
    }

    /// Call only after explicit destructive confirmation by the user.
    func eraseAllMeasurements() throws {
        // Explicit erasure may remove the unreadable baseline the user confirmed,
        // but must not erase a newer record that appeared after confirmation.
        try requireCurrentSnapshot()
        defaults.removeObject(forKey: key)
        expectedPersistedObject = nil
        revision = UUID()
        records = []
        storageUnreadable = false
        protectionReason = nil
    }

    private func requireWritable() throws {
        if let protectionReason { throw protectionReason }
        try requireCurrentSnapshot()
    }

    private func requireCurrentSnapshot() throws {
        guard defaults.object(forKey: key) as? NSObject == expectedPersistedObject else {
            protectionReason = .storageChanged
            throw FruitfolioHormoneMeasurementError.storageChanged
        }
    }

    private func persist(_ updated: [FruitfolioHormoneMeasurement]) throws {
        let data = try JSONEncoder().encode(updated)
        try requireWritable()
        defaults.set(data, forKey: key)
        records = updated
        expectedPersistedObject = data as NSData
        revision = UUID()
    }
}
