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

    func saveImageData(_ data: Data) throws -> String {
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        var directory = root
        var flags = URLResourceValues()
        flags.isExcludedFromBackup = true
        try directory.setResourceValues(flags)
        let id = UUID().uuidString.lowercased()
        try data.write(to: validatedURL(for: id), options: [.atomic, .completeFileProtection])
        return id
    }

    func data(for id: String) -> Data? {
        guard let url = try? validatedURL(for: id) else { return nil }
        return try? Data(contentsOf: url)
    }

    func delete(_ id: String) throws {
        let target = try validatedURL(for: id)
        if fileManager.fileExists(atPath: target.path) { try fileManager.removeItem(at: target) }
    }

    private func validatedURL(for id: String) throws -> URL {
        guard UUID(uuidString: id) != nil else { throw CocoaError(.fileReadInvalidFileName) }
        return root.appendingPathComponent(id).appendingPathExtension("image")
    }
}
