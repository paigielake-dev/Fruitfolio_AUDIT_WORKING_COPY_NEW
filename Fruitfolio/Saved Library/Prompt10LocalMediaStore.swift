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
        let id = UUID().uuidString.lowercased()
        try data.write(to: url(for: id), options: [.atomic])
        return id
    }

    func data(for id: String) -> Data? {
        try? Data(contentsOf: url(for: id))
    }

    func delete(_ id: String) throws {
        let target = url(for: id)
        if fileManager.fileExists(atPath: target.path) { try fileManager.removeItem(at: target) }
    }

    private func url(for id: String) -> URL {
        root.appendingPathComponent(id).appendingPathExtension("image")
    }
}
