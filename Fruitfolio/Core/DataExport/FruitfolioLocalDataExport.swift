import Foundation

/// Explicit saved-data scope. Never sweeps preferences, caches, model files,
/// research assets or unsaved Ask conversations into an export.
enum FruitfolioLocalDataExport {
    struct PreferenceRecord: Sendable {
        let key: String
        let data: Data
        let isRawData: Bool
    }
    struct Result: Sendable {
        let url: URL
        let warnings: [String]
    }
    struct Manifest: Codable {
        let formatVersion: Int
        let createdAt: Date
        let preferences: [String: String]
        let savedFiles: [String]
        let warnings: [String]
        let notes: String
    }
    static let preferenceKeys = [
        "fruitfolio.prompt12.accountPrivacy.v1", "fruitfolio.prompt10.savedLibrary.v2",
        "fruitfolio.hormoneMeasurements.v1", "fruitfolio.prompt27a.userReproductiveContext.v1",
        FruitfolioUsernamePersistence.defaultKey,
        FruitfolioUsernamePersistence.defaultKey + ".initialized",
        FruitfolioUsernamePersistence.defaultKey + ".nonIdentifyingConfirmation",
        FruitfolioUsernamePersistence.recordKey(), "fruitfolio.prompt28.fruitBasket.v1",
        "fruitfolio.settings.globallyMuted", "fruitfolio.settings.musicEnabled", "fruitfolio.settings.rainEnabled",
        "fruitfolio.settings.soundEffectsEnabled", "fruitfolio.settings.typingASMREnabled",
        "fruitfolio.settings.musicVolume", "fruitfolio.settings.rainVolume", "fruitfolio.settings.soundEffectsVolume",
        "fruitfolio.settings.typingVolume", "fruitfolio.settings.reduceAnimationOverride",
        "fruitfolio.settings.onboardingCompleted", "fruitfolio.settings.language"
    ]

    static func capturePreferences(defaults: UserDefaults) throws -> [PreferenceRecord] {
        try preferenceKeys.compactMap { key in
            guard let value = defaults.object(forKey: key) else { return nil }
            if let bytes = value as? Data { return PreferenceRecord(key: key, data: bytes, isRawData: true) }
            let bytes = try PropertyListSerialization.data(fromPropertyList: ["key": key, "value": value], format: .xml, options: 0)
            return PreferenceRecord(key: key, data: bytes, isRawData: false)
        }
    }

    static func create(preferences: [PreferenceRecord], applicationSupport: URL,
                       output: URL, createdAt: Date = Date()) throws -> Result {
        var entries: [FruitfolioZIPArchive.Entry] = []
        var mapping: [String: String] = [:]
        var savedFiles: [String] = []
        var warnings: [String] = []
        for record in preferences {
            try Task.checkCancellation()
            // Reject arbitrary keys supplied by an accidental alternate caller.
            guard preferenceKeys.contains(record.key), mapping[record.key] == nil else { throw FruitfolioZIPArchive.Failure.invalidPath }
            let suffix: String
            if record.isRawData {
                suffix = (try? JSONSerialization.jsonObject(with: record.data, options: [.fragmentsAllowed])) != nil ? ".json" : ".bin"
                if suffix == ".bin" { warnings.append("The saved record for \(record.key) is not readable JSON; original bytes are retained.") }
            } else { suffix = ".plist" }
            let path = "preferences/" + record.key + suffix
            mapping[record.key] = path
            entries.append(.init(path: path, payload: .bytes(record.data)))
        }
        let fileManager = FileManager.default
        // Canonicalize the trusted sandbox root (iOS may use /var aliases),
        // then reject links inside the explicitly scoped saved-data tree.
        let root = applicationSupport.standardizedFileURL.resolvingSymlinksInPath()
        func include(_ relative: String) throws {
            try Task.checkCancellation()
            let source = root.appendingPathComponent(relative)
            guard source.resolvingSymlinksInPath() == source.standardizedFileURL else { throw FruitfolioZIPArchive.Failure.invalidSource }
            guard fileManager.fileExists(atPath: source.path) else { return }
            let attributes = try fileManager.attributesOfItem(atPath: source.path)
            guard attributes[.type] as? FileAttributeType == .typeRegular else { throw FruitfolioZIPArchive.Failure.invalidSource }
            entries.append(.init(path: relative, payload: .file(source)))
            savedFiles.append(relative)
        }
        for file in ["Fruitfolio/CycleTracker/prompt13_cycle_archive_v1.json",
                     "Fruitfolio/CycleTracker/prompt14_cycle_onboarding_v1.json",
                     "Fruitfolio/CycleDomain/daily-logs-v1.json"] { try include(file) }
        if let library = preferences.first(where: { $0.key == "fruitfolio.prompt10.savedLibrary.v2" }) {
            if library.isRawData, let books = try? JSONDecoder().decode([Prompt10Encyclopedia].self, from: library.data) {
                let ids = Set(books.flatMap(\.chapters).flatMap(\.pages).flatMap { $0.importedImageIDs ?? [] })
                for id in ids.sorted() {
                    guard UUID(uuidString: id) != nil else {
                        warnings.append("A saved image identifier is invalid; that image was not included.")
                        continue
                    }
                    let path = "Fruitfolio/SavedLibraryMedia/" + id + ".image"
                    try include(path)
                    if !savedFiles.contains(path) { warnings.append("A referenced saved image is missing: \(id).") }
                }
            } else {
                warnings.append("The saved library could not be decoded. Its original record is included; referenced images could not be identified safely.")
            }
        }
        let manifest = Manifest(formatVersion: 1, createdAt: createdAt, preferences: mapping,
            savedFiles: savedFiles, warnings: warnings,
            notes: "Private local saved-data export. JSON/bin records preserve stored bytes; plist files preserve other preference values. Imported images are included only when referenced by readable saved pages. Unsaved Ask conversations, caches, model/research resources and cloud-only data are excluded. Files are read sequentially, not as a cross-domain transaction. No automatic import/restore or clinical validation is claimed. ZIP is not encrypted; keep it somewhere private.")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        entries.insert(.init(path: "manifest.json", payload: .bytes(try encoder.encode(manifest))), at: 0)
        try FruitfolioZIPArchive.write(entries, to: output)
        return Result(url: output, warnings: warnings)
    }
}
