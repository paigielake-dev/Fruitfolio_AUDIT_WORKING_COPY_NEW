import Foundation

/// Keeps the last successfully encoded snapshot. An unreadable original is
/// never replaced by an empty library; failed encoding never commits a copy.
struct Prompt10SavedLibraryPersistence {
    private let defaults: UserDefaults
    private let key: String
    private(set) var committed: [Prompt10Encyclopedia] = []
    private(set) var storageUnreadable = false

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
        guard defaults.object(forKey: key) != nil else { return }
        guard let data = defaults.data(forKey: key) else {
            storageUnreadable = true
            return
        }
        do { committed = try JSONDecoder().decode([Prompt10Encyclopedia].self, from: data) }
        catch { storageUnreadable = true }
    }

    mutating func commit(_ candidate: [Prompt10Encyclopedia]) throws {
        guard !storageUnreadable else { throw Prompt10LibraryError.unreadableStorage }
        let data: Data
        do { data = try JSONEncoder().encode(candidate) }
        catch { throw Prompt10LibraryError.persistenceFailure }
        defaults.set(data, forKey: key)
        committed = candidate
    }
}
