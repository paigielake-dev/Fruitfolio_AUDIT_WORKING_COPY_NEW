import Foundation

/// Keeps the last successfully encoded snapshot. An unreadable original is
/// never replaced by an empty library; failed encoding never commits a copy.
struct Prompt10SavedLibraryPersistence {
    private let defaults: UserDefaults
    private let key: String
    private(set) var committed: [Prompt10Encyclopedia] = []
    private(set) var storageUnreadable = false
    private(set) var protectionReason: Prompt10LibraryError?
    private var expectedPersistedObject: NSObject?

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
        expectedPersistedObject = defaults.object(forKey: key) as? NSObject
        guard expectedPersistedObject != nil else { return }
        guard let data = defaults.data(forKey: key) else {
            storageUnreadable = true
            protectionReason = .unreadableStorage
            return
        }
        do {
            committed = try JSONDecoder().decode([Prompt10Encyclopedia].self, from: data)
            let encoded = try JSONEncoder().encode(committed)
            if !FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: encoded) {
                protectionReason = .unsupportedStorage
            }
        } catch {
            storageUnreadable = true
            protectionReason = .unreadableStorage
        }
    }

    mutating func commit(_ candidate: [Prompt10Encyclopedia]) throws {
        if let protectionReason { throw protectionReason }
        guard defaults.object(forKey: key) as? NSObject == expectedPersistedObject else {
            protectionReason = .storageChanged
            throw Prompt10LibraryError.storageChanged
        }
        let data: Data
        do { data = try JSONEncoder().encode(candidate) }
        catch { throw Prompt10LibraryError.persistenceFailure }
        defaults.set(data, forKey: key)
        committed = candidate
        expectedPersistedObject = data as NSData
    }

    /// Explicitly accept the latest saved baseline without writing or merging it.
    mutating func reload() {
        self = Self(defaults: defaults, key: key)
    }
}
