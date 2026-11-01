import Foundation
import Combine

@MainActor
final class HormoneMeasurementStore: ObservableObject {
    static let shared = HormoneMeasurementStore()
    @Published private(set) var measurements: [HormoneMeasurement] = []
    @Published private(set) var loadError: String?
    private let fileURL: URL
    private var canWrite = true

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FruitfolioPrivate", isDirectory: true)
            .appendingPathComponent("hormone-measurements-v1.json")
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else { return }
        do {
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: self.fileURL))
            guard snapshot.version == 1 else { throw StoreError.unsupportedVersion }
            measurements = snapshot.measurements
        } catch {
            // Never replace unreadable health records with an empty snapshot.
            canWrite = false
            loadError = "your stored measurements could not be opened. the original file has been preserved."
        }
    }

    func save(_ measurement: HormoneMeasurement) throws {
        guard canWrite else { throw StoreError.unreadableStorage }
        if let error = measurement.validationError { throw StoreError.validation(error) }
        var updated = measurements
        var record = measurement
        record.updatedAt = Date()
        if let index = updated.firstIndex(where: { $0.id == record.id }) {
            record.createdAt = updated[index].createdAt
            updated[index] = record
        } else { updated.append(record) }
        try persist(updated)
        measurements = updated
    }

    func delete(id: UUID) throws {
        guard canWrite else { throw StoreError.unreadableStorage }
        let updated = measurements.filter { $0.id != id }
        try persist(updated)
        measurements = updated
    }

    /// Explicit deletion also permits recovery from corrupt storage.
    func eraseAll() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        measurements = []
        loadError = nil
        canWrite = true
    }

    private func persist(_ records: [HormoneMeasurement]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var privateDirectory = directory
        var flags = URLResourceValues()
        flags.isExcludedFromBackup = true
        try privateDirectory.setResourceValues(flags)
        let data = try JSONEncoder().encode(Snapshot(version: 1, measurements: records))
        #if os(iOS)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: fileURL, options: .atomic)
        #endif
    }

    private struct Snapshot: Codable { let version: Int; let measurements: [HormoneMeasurement] }
    enum StoreError: LocalizedError {
        case validation(String), unreadableStorage, unsupportedVersion
        var errorDescription: String? {
            switch self {
            case .validation(let message): return message
            case .unreadableStorage: return "stored measurements could not be opened. no changes have been saved."
            case .unsupportedVersion: return "this measurement file uses an unsupported version."
            }
        }
    }
}
