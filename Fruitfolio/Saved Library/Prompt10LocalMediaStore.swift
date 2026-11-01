import Foundation

/// Owns user-imported Saved Library media locally. UserDefaults stores only IDs.
struct Prompt10LocalMediaStore: Sendable {
    static let shared = Prompt10LocalMediaStore()

    private let fileManager: FileManager
    private let root: URL

    init(fileManager: FileManager = .default, root: URL? = nil) {
        self.fileManager = fileManager
        if let root {
            self.root = root
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.root = base.appendingPathComponent("Fruitfolio/SavedLibraryMedia", isDirectory: true)
        }
    }

    private func prepareRoot() throws {
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        var directory = root
        var flags = URLResourceValues()
        flags.isExcludedFromBackup = true
        try directory.setResourceValues(flags)
    }

    func saveImageData(_ data: Data) throws -> String {
        try prepareRoot()
        let id = UUID().uuidString.lowercased()
        let target = try validatedURL(for: id)
        try data.write(to: target, options: [.atomic, .completeFileProtection])
        do {
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: target.path)
        } catch {
            try? fileManager.removeItem(at: target)
            throw error
        }
        return id
    }

    /// Draft bytes stay separate from committed pages. Recovery promotes only
    /// IDs present in readable library metadata; abandoned drafts are removed.
    func stageImageData(_ data: Data) throws -> String {
        try prepareRoot()
        let pending = Prompt10LocalMediaStore(fileManager: fileManager,
            root: root.appendingPathComponent("Pending", isDirectory: true))
        return try pending.saveImageData(data)
    }

    func reconcile(referencedIDs: Set<String>, discardAbandonedDrafts: Bool) throws {
        let pendingRoot = root.appendingPathComponent("Pending", isDirectory: true)
        for id in referencedIDs {
            let destination = try validatedURL(for: id)
            let staged = pendingRoot.appendingPathComponent(id).appendingPathExtension("image")
            if !fileManager.fileExists(atPath: destination.path), fileManager.fileExists(atPath: staged.path) {
                try fileManager.moveItem(at: staged, to: destination)
            }
        }
        try prune(directory: root, keeping: referencedIDs)
        if discardAbandonedDrafts { try prune(directory: pendingRoot, keeping: []) }
    }

    private func prune(directory: URL, keeping ids: Set<String>) throws {
        guard fileManager.fileExists(atPath: directory.path) else { return }
        for url in try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            // Never remove unknown files or descend into unrelated directories.
            guard url.pathExtension == "image", UUID(uuidString: url.deletingPathExtension().lastPathComponent) != nil,
                  !ids.contains(url.deletingPathExtension().lastPathComponent) else { continue }
            try fileManager.removeItem(at: url)
        }
    }

    func data(for id: String) -> Data? {
        guard let url = try? validatedURL(for: id) else { return nil }
        if let committed = try? Data(contentsOf: url) { return committed }
        let staged = root.appendingPathComponent("Pending", isDirectory: true).appendingPathComponent(url.lastPathComponent)
        return try? Data(contentsOf: staged)
    }

    func delete(_ id: String) throws {
        let target = try validatedURL(for: id)
        if fileManager.fileExists(atPath: target.path) { try fileManager.removeItem(at: target) }
        let staged = root.appendingPathComponent("Pending", isDirectory: true).appendingPathComponent(target.lastPathComponent)
        if fileManager.fileExists(atPath: staged.path) { try fileManager.removeItem(at: staged) }
    }

    private func validatedURL(for id: String) throws -> URL {
        guard UUID(uuidString: id) != nil else { throw CocoaError(.fileReadInvalidFileName) }
        return root.appendingPathComponent(id).appendingPathExtension("image")
    }
}
