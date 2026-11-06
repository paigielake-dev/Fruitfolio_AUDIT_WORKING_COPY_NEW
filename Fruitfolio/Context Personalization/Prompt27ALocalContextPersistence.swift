import Foundation

/// Single local snapshot. Corrupt originals stay untouched and read-only;
/// candidate mutations encode successfully before either storage or state changes.
nonisolated final class Prompt27ALocalContextPersistence {
    private(set) var context: Prompt27AUserReproductiveContext
    private(set) var storageUnreadable = false
    private(set) var protectionReason: Failure?
    private var expectedPersistedObject: NSObject?
    private(set) var revision = UUID()
    private let defaults: UserDefaults
    private let key: String
    private let codec: Prompt27AContextCodec
    enum Failure: LocalizedError, Equatable, Sendable {
        case unreadableStorage, unsupportedStorage, storageChanged, confirmationChanged
        var errorDescription: String? {
            switch self {
            case .confirmationChanged: return "your saved context changed after this screen or confirmation opened. nothing was overwritten or cleared. review the saved context before trying again."
            case .unreadableStorage: return "your saved context could not be read. the original local data has been preserved; changes are paused."
            case .unsupportedStorage: return "your saved context contains fields this version cannot safely update. readable selections remain available. the original data has been preserved; changes are paused."
            case .storageChanged: return "your saved context changed or was cleared elsewhere. the latest local data has been preserved. reload it before making changes, exporting or clearing."
            }
        }
    }

    init(defaults: UserDefaults, key: String, codec: Prompt27AContextCodec = .init()) {
        self.defaults = defaults; self.key = key; self.codec = codec
        context = .unspecified
        reload()
    }
    func apply(_ mutation: (inout Prompt27AUserReproductiveContext) throws -> Void) throws {
        try requireWritable()
        var candidate = context
        try mutation(&candidate)
        let data = try codec.encode(candidate)
        try requireWritable()
        defaults.set(data, forKey: key)
        context = candidate
        expectedPersistedObject = data as NSData
        revision = UUID()
    }
    func exportJSON() throws -> Data {
        try requireWritable()
        return try codec.encode(context)
    }
    /// Only explicit user-directed erase may remove an unreadable original.
    func erase() throws {
        try requireCurrentSnapshot()
        defaults.removeObject(forKey: key)
        expectedPersistedObject = nil
        context = .unspecified
        storageUnreadable = false
        protectionReason = nil
        revision = UUID()
    }
    func reload() {
        context = .unspecified
        storageUnreadable = false
        protectionReason = nil
        revision = UUID()
        expectedPersistedObject = defaults.object(forKey: key) as? NSObject
        guard let object = expectedPersistedObject else { return }
        guard let data = object as? Data else {
            storageUnreadable = true; protectionReason = .unreadableStorage; return
        }
        do {
            context = try codec.decode(data)
            if !FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: try codec.encode(context)) {
                protectionReason = .unsupportedStorage
            }
        } catch { storageUnreadable = true; protectionReason = .unreadableStorage }
    }
    private func requireWritable() throws {
        if let protectionReason { throw protectionReason }
        try requireCurrentSnapshot()
    }
    private func requireCurrentSnapshot() throws {
        guard defaults.object(forKey: key) as? NSObject == expectedPersistedObject else {
            protectionReason = .storageChanged
            throw Failure.storageChanged
        }
    }
}
