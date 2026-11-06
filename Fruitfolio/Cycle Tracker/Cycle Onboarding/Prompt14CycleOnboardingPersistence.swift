import Foundation

nonisolated protocol Prompt14OnboardingPersistence: Sendable {
    func load() async throws -> Prompt14OnboardingDraft
    func save(_ draft: Prompt14OnboardingDraft) async throws
    func erase() async throws
}

nonisolated enum Prompt14OnboardingPersistenceError: LocalizedError, Equatable, Sendable {
    case unavailable, storageChanged, unsupportedFormat
    var errorDescription: String? {
        switch self {
        case .unavailable: return "saved cycle setup could not be accessed. please try again."
        case .storageChanged: return "saved cycle setup needs to be reloaded before this change can be saved or erased. the original file is preserved."
        case .unsupportedFormat: return "saved cycle setup contains fields this version cannot safely update. the original file is preserved."
        }
    }
}

actor Prompt14FileOnboardingPersistence: Prompt14OnboardingPersistence {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var hasSnapshot = false
    private var expectedData: Data?
    private var protectionError: Prompt14OnboardingPersistenceError?

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.fileURL = base
                .appendingPathComponent("Fruitfolio", isDirectory: true)
                .appendingPathComponent("CycleTracker", isDirectory: true)
                .appendingPathComponent("prompt14_cycle_onboarding_v1.json", isDirectory: false)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    private func readData() throws -> Data? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do { return try Data(contentsOf: fileURL) }
        catch { throw Prompt14OnboardingPersistenceError.unavailable }
    }

    private func requireCurrentSnapshot() throws {
        guard try readData() == expectedData else { throw Prompt14OnboardingPersistenceError.storageChanged }
    }

    func load() async throws -> Prompt14OnboardingDraft {
        let data = try readData()
        expectedData = data; hasSnapshot = true; protectionError = nil
        guard let data else { return Prompt14OnboardingDraft() }
        do {
            let draft = try decoder.decode(Prompt14OnboardingDraft.self, from: data)
            guard draft.schemaVersion == 1,
                  FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: try encoder.encode(draft)) else {
                throw Prompt14OnboardingPersistenceError.unsupportedFormat
            }
            return draft
        } catch let error as Prompt14OnboardingPersistenceError { protectionError = error; throw error }
        catch { protectionError = .unavailable; throw Prompt14OnboardingPersistenceError.unavailable }
    }

    func save(_ draft: Prompt14OnboardingDraft) async throws {
        try Task.checkCancellation()
        if !hasSnapshot {
            expectedData = try readData(); hasSnapshot = true
            if expectedData != nil { protectionError = .storageChanged }
        }
        if let protectionError { throw protectionError }
        try requireCurrentSnapshot()
        guard draft.schemaVersion == 1 else { throw Prompt14OnboardingPersistenceError.unsupportedFormat }
        do {
            let data = try encoder.encode(draft)
            try requireCurrentSnapshot()
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            expectedData = data
        } catch let error as Prompt14OnboardingPersistenceError { throw error }
        catch { throw Prompt14OnboardingPersistenceError.unavailable }
    }

    func erase() async throws {
        try Task.checkCancellation()
        if !hasSnapshot { expectedData = try readData(); hasSnapshot = true }
        try requireCurrentSnapshot()
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) { try FileManager.default.removeItem(at: fileURL) }
            expectedData = nil; protectionError = nil
        } catch { throw Prompt14OnboardingPersistenceError.unavailable }
    }

}

actor Prompt14InMemoryOnboardingPersistence: Prompt14OnboardingPersistence {
    private var draft: Prompt14OnboardingDraft

    init(draft: Prompt14OnboardingDraft = Prompt14OnboardingDraft()) {
        self.draft = draft
    }

    func load() async throws -> Prompt14OnboardingDraft { draft }
    func save(_ draft: Prompt14OnboardingDraft) async throws { self.draft = draft }
    func erase() async throws { draft = Prompt14OnboardingDraft() }
}
