import Foundation

nonisolated protocol Prompt14OnboardingPersistence: Sendable {
    func load() async throws -> Prompt14OnboardingDraft
    func save(_ draft: Prompt14OnboardingDraft) async throws
    func erase() async throws
}

actor Prompt14FileOnboardingPersistence: Prompt14OnboardingPersistence {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

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

    func load() async throws -> Prompt14OnboardingDraft {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return Prompt14OnboardingDraft()
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(Prompt14OnboardingDraft.self, from: data)
    }

    func save(_ draft: Prompt14OnboardingDraft) async throws {
        let folder = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = try encoder.encode(draft)
        try data.write(to: fileURL, options: .atomic)
    }

    func erase() async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
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
