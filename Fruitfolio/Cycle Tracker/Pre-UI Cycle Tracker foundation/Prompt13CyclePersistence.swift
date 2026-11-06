import Foundation

nonisolated protocol Prompt13CyclePersistence: Sendable {
    func load() async throws
        -> Prompt13CycleArchive

    func save(
        _ archive: Prompt13CycleArchive
    ) async throws

    func erase() async throws
}

actor Prompt13FileCyclePersistence:
    Prompt13CyclePersistence
{
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var hasSnapshot = false
    private var expectedData: Data?
    private var protectionError: Prompt13CycleError?

    init(
        fileURL: URL? = nil
    ) {
        if let fileURL {
            self.fileURL =
                fileURL
        } else {
            let base =
                FileManager
                    .default
                    .urls(
                        for:
                            .applicationSupportDirectory,
                        in:
                            .userDomainMask
                    )
                    .first ??
                FileManager
                    .default
                    .temporaryDirectory

            self.fileURL =
                base
                    .appendingPathComponent(
                        "Fruitfolio",
                        isDirectory: true
                    )
                    .appendingPathComponent(
                        "CycleTracker",
                        isDirectory: true
                    )
                    .appendingPathComponent(
                        "prompt13_cycle_archive_v1.json",
                        isDirectory: false
                    )
        }

        let encoder =
            JSONEncoder()

        encoder.dateEncodingStrategy =
            .iso8601

        encoder.outputFormatting =
            [.sortedKeys]

        self.encoder =
            encoder

        let decoder =
            JSONDecoder()

        decoder.dateDecodingStrategy =
            .iso8601

        self.decoder =
            decoder
    }

    private func readData() throws -> Data? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do { return try Data(contentsOf: fileURL) }
        catch { throw Prompt13CycleError.persistenceFailure }
    }

    private func requireCurrentSnapshot() throws {
        guard try readData() == expectedData else { throw Prompt13CycleError.storageChanged }
    }

    func load() async throws -> Prompt13CycleArchive {
        let data = try readData()
        expectedData = data; hasSnapshot = true; protectionError = nil
        guard let data else { return Prompt13CycleArchive() }
        do {
            let archive = try decoder.decode(Prompt13CycleArchive.self, from: data)
            guard archive.schemaVersion == 1,
                  FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: try encoder.encode(archive)) else {
                throw Prompt13CycleError.unsupportedPersistence
            }
            return archive
        } catch let error as Prompt13CycleError { protectionError = error; throw error }
        catch { protectionError = .persistenceFailure; throw Prompt13CycleError.persistenceFailure }
    }

    func save(_ archive: Prompt13CycleArchive) async throws {
        try Task.checkCancellation()
        if !hasSnapshot {
            expectedData = try readData(); hasSnapshot = true
            if expectedData != nil { protectionError = .storageChanged }
        }
        if let protectionError { throw protectionError }
        try requireCurrentSnapshot()
        guard archive.schemaVersion == 1 else { throw Prompt13CycleError.unsupportedPersistence }
        do {
            let data = try encoder.encode(archive)
            try requireCurrentSnapshot()
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            expectedData = data
        } catch let error as Prompt13CycleError { throw error }
        catch { throw Prompt13CycleError.persistenceFailure }
    }

    /// Explicit erasure may remove an unsupported baseline, never a newer file.
    func erase() async throws {
        try Task.checkCancellation()
        if !hasSnapshot { expectedData = try readData(); hasSnapshot = true }
        try requireCurrentSnapshot()
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) { try FileManager.default.removeItem(at: fileURL) }
            expectedData = nil; protectionError = nil
        } catch { throw Prompt13CycleError.persistenceFailure }
    }

}

actor Prompt13InMemoryCyclePersistence:
    Prompt13CyclePersistence
{
    private var archive:
        Prompt13CycleArchive

    init(
        archive:
            Prompt13CycleArchive =
            Prompt13CycleArchive()
    ) {
        self.archive =
            archive
    }

    func load()
        async throws
        -> Prompt13CycleArchive
    {
        archive
    }

    func save(
        _ archive: Prompt13CycleArchive
    ) async throws {
        self.archive =
            archive
    }

    func erase()
        async throws
    {
        archive =
            Prompt13CycleArchive(
                localProfileID:
                    archive.localProfileID,
                deviceID:
                    archive.deviceID
            )
    }
}
