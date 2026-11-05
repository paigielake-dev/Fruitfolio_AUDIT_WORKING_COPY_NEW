import Foundation

/// Single local snapshot. Corrupt originals stay untouched and read-only;
/// candidate mutations encode successfully before either storage or state changes.
nonisolated final class Prompt27ALocalContextPersistence {
    private(set) var context: Prompt27AUserReproductiveContext
    private(set) var storageUnreadable = false
    private let defaults: UserDefaults
    private let key: String
    private let codec: Prompt27AContextCodec
    enum Failure: Error { case unreadableStorage }

    init(defaults: UserDefaults, key: String, codec: Prompt27AContextCodec = .init()) {
        self.defaults = defaults; self.key = key; self.codec = codec
        context = .unspecified
        guard let object = defaults.object(forKey: key) else { return }
        guard let data = object as? Data else { storageUnreadable = true; return }
        do { context = try codec.decode(data) }
        catch { storageUnreadable = true }
    }
    func apply(_ mutation: (inout Prompt27AUserReproductiveContext) throws -> Void) throws {
        guard !storageUnreadable else { throw Failure.unreadableStorage }
        var candidate = context
        try mutation(&candidate)
        let data = try codec.encode(candidate)
        defaults.set(data, forKey: key)
        context = candidate
    }
    func exportJSON() throws -> Data {
        guard !storageUnreadable else { throw Failure.unreadableStorage }
        return try codec.encode(context)
    }
    /// Only explicit user-directed erase may remove an unreadable original.
    func erase() {
        defaults.removeObject(forKey: key)
        context = .unspecified
        storageUnreadable = false
    }
}
