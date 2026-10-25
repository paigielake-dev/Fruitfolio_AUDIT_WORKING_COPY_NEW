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

    func load()
        async throws
        -> Prompt13CycleArchive
    {
        guard
            FileManager
                .default
                .fileExists(
                    atPath:
                        fileURL.path
                )
        else {
            return Prompt13CycleArchive()
        }

        do {
            let data =
                try Data(
                    contentsOf:
                        fileURL
                )

            return
                try decoder.decode(
                    Prompt13CycleArchive.self,
                    from: data
                )
        } catch {
            throw
                Prompt13CycleError
                    .persistenceFailure
        }
    }

    func save(
        _ archive: Prompt13CycleArchive
    ) async throws {
        do {
            let directory =
                fileURL
                    .deletingLastPathComponent()

            try FileManager
                .default
                .createDirectory(
                    at: directory,
                    withIntermediateDirectories:
                        true
                )

            let data =
                try encoder.encode(
                    archive
                )

            try data.write(
                to: fileURL,
                options: [.atomic]
            )
        } catch {
            throw
                Prompt13CycleError
                    .persistenceFailure
        }
    }

    func erase()
        async throws
    {
        do {
            guard
                FileManager
                    .default
                    .fileExists(
                        atPath:
                            fileURL.path
                    )
            else {
                return
            }

            try FileManager
                .default
                .removeItem(
                    at: fileURL
                )
        } catch {
            throw
                Prompt13CycleError
                    .persistenceFailure
        }
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
