import Foundation

public protocol Prompt20DailyLogRepository: Sendable {
    func load(
        ownerID: Prompt20DailyLogOwnerID,
        date: Prompt20LocalDay
    ) async throws -> Prompt20DailyLog?

    func save(
        ownerID: Prompt20DailyLogOwnerID,
        date: Prompt20LocalDay,
        draft: Prompt20DailyLogDraft,
        now: Date,
        requestID: UUID,
        expectation: Prompt20DailyLogSaveExpectation
    ) async throws -> Prompt20DailyLog?

    func allActiveLogs(
        ownerID: Prompt20DailyLogOwnerID
    ) async throws -> [Prompt20DailyLog]
}

/// Compatibility for existing explicit programmatic writes. User editors use
/// the required snapshot-bearing method instead of silently opting out.
public extension Prompt20DailyLogRepository {
    func save(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay,
              draft: Prompt20DailyLogDraft, now: Date, requestID: UUID) async throws -> Prompt20DailyLog? {
        try await save(ownerID: ownerID, date: date, draft: draft, now: now,
                       requestID: requestID, expectation: .unchecked)
    }
}

/// Explicit read-only recovery capability; reload never rewrites a saved file.
public protocol Prompt20ReloadableDailyLogRepository: Prompt20DailyLogRepository {
    func reloadSavedLogs() async throws
}

public actor Prompt20CycleDailyLogStore:
    Prompt20ReloadableDailyLogRepository {

    public static let shared =
        Prompt20CycleDailyLogStore()

    private struct StorageKey:
        Hashable,
        Codable,
        Sendable {

        let ownerID:
            Prompt20DailyLogOwnerID

        let date:
            Prompt20LocalDay
    }

    private struct Envelope:
        Codable,
        Sendable {

        var schemaVersion: Int

        var logs:
            [Prompt20DailyLog]

        var recentlyProcessedRequestIDs:
            [UUID]
    }

    private nonisolated static let schemaVersion =
        1

    private nonisolated static let maxRememberedRequestIDs =
        128

    private let fileURL:
        URL?

    private let calendar:
        Calendar

    private var expectedPersistedData: Data?
    private var loaded =
        false

    private var logsByKey:
        [StorageKey: Prompt20DailyLog] =
        [:]

    private var processedRequestIDs:
        [UUID] =
        []

    private var processedRequestSet:
        Set<UUID> =
        []

    public init(
        fileURL: URL? =
            Prompt20CycleDailyLogStore
                .defaultFileURL(),
        calendar: Calendar =
            .current
    ) {
        self.fileURL =
            fileURL

        self.calendar =
            calendar
    }

    public func load(
        ownerID:
            Prompt20DailyLogOwnerID,
        date:
            Prompt20LocalDay
    ) async throws
        -> Prompt20DailyLog? {

        try ensureLoaded()

        let log =
            logsByKey[
                StorageKey(
                    ownerID:
                        ownerID,
                    date:
                        date
                )
            ]

        guard
            log?.isDeleted
                == false
        else {
            return nil
        }

        return log
    }

    public func save(
        ownerID:
            Prompt20DailyLogOwnerID,
        date:
            Prompt20LocalDay,
        draft:
            Prompt20DailyLogDraft,
        now:
            Date = Date(),
        requestID:
            UUID = UUID(),
        expectation: Prompt20DailyLogSaveExpectation = .unchecked
    ) async throws
        -> Prompt20DailyLog? {

        try Task.checkCancellation()
        try ensureLoaded()

        // Pure rules run within this actor transaction. A suspension between
        // reading the baseline and committing could overwrite another save.
        let dateIsFuture = Prompt20DailyLogRules.isFuture(date, relativeTo: now, calendar: calendar)

        guard
            !dateIsFuture
        else {
            throw
                Prompt20DailyLogDomainError
                    .futureDate
        }

        let key =
            StorageKey(
                ownerID:
                    ownerID,
                date:
                    date
            )

        /*
         A repeated request ID must behave
         idempotently.

         If the request has already been
         processed, return the currently
         persisted value without writing
         another revision.
         */
        if processedRequestSet
            .contains(
                requestID
            ) {

            let existing =
                logsByKey[
                    key
                ]

            return
                existing?.isDeleted
                    == false
                ? existing
                : nil
        }

        let previousLog =
            logsByKey[
                key
            ]

        try expectation.validate(current: previousLog?.isDeleted == false ? previousLog : nil)

        let previousRequestIDs =
            processedRequestIDs

        let previousRequestSet =
            processedRequestSet

        let candidate = try Prompt20DailyLogRules.makeLog(
            ownerID: ownerID, date: date, draft: draft, existing: previousLog, now: now)
        try Task.checkCancellation()

        if candidate
            .hasRecordedContent {

            logsByKey[
                key
            ] =
                candidate

        } else if let previousLog {

            /*
             Preserve a tombstone rather than
             silently erasing persistence history.

             This maintains revision ordering and
             prevents an older external record from
             resurrecting deleted data later.
             */
            var tombstone =
                previousLog

            tombstone.periodEvent =
                nil

            tombstone.bleeding =
                nil

            tombstone.symptoms =
                nil

            tombstone.temperature =
                nil

            tombstone.cervicalFluid =
                nil

            tombstone.medications =
                []

            tombstone.generalNote =
                nil

            tombstone.updatedAt =
                now

            tombstone.revision = candidate.revision

            tombstone.isDeleted =
                true

            logsByKey[
                key
            ] =
                tombstone
        }

        remember(
            requestID
        )

        /*
         Persistence is transactional from the
         caller's perspective.

         If disk writing fails, restore both the
         log state and idempotency state.
         */
        do {
            try persist()

        } catch {
            if let previousLog {
                logsByKey[
                    key
                ] =
                    previousLog

            } else {
                logsByKey
                    .removeValue(
                        forKey:
                            key
                    )
            }

            processedRequestIDs =
                previousRequestIDs

            processedRequestSet =
                previousRequestSet

            throw error
        }

        let saved =
            logsByKey[
                key
            ]

        return
            saved?.isDeleted
                == false
            ? saved
            : nil
    }

    public func allActiveLogs(
        ownerID:
            Prompt20DailyLogOwnerID
    ) async throws
        -> [Prompt20DailyLog] {

        try ensureLoaded()

        return
            logsByKey
                .values
                .filter {
                    $0.ownerID
                        == ownerID
                    &&
                    !$0.isDeleted
                }
                .sorted {
                    $0.date
                        <
                    $1.date
                }
    }

    public func reloadSavedLogs() async throws {
        resetCache()
        try ensureLoaded()
    }

    public func resetInMemoryCacheForTesting() { resetCache() }

    private func resetCache() {
        loaded = false
        expectedPersistedData = nil
        logsByKey = [:]
        processedRequestIDs = []
        processedRequestSet = []
    }

    private func readPersistedData() throws -> Data? {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do { return try Data(contentsOf: fileURL) }
        catch { throw Prompt20DailyLogDomainError.persistenceUnavailable }
    }

    private func requireCurrentSnapshot() throws {
        guard fileURL != nil else { return }
        guard try readPersistedData() == expectedPersistedData else {
            throw Prompt20DailyLogDomainError.storageChanged
        }
    }

    private func ensureLoaded() throws {
        if loaded { try requireCurrentSnapshot(); return }
        guard let data = try readPersistedData() else {
            expectedPersistedData = nil
            loaded = true
            return
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let envelope = try decoder.decode(Envelope.self, from: data)
            guard envelope.schemaVersion == Self.schemaVersion else {
                throw Prompt20DailyLogDomainError.unsupportedPersistence
            }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            guard FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: try encoder.encode(envelope)),
                  envelope.recentlyProcessedRequestIDs.count <= Self.maxRememberedRequestIDs else {
                throw Prompt20DailyLogDomainError.unsupportedPersistence
            }
            // Ambiguous records must not be silently coalesced then rewritten.
            var reconstructed: [StorageKey: Prompt20DailyLog] = [:]
            var identities = Set<UUID>()
            for log in envelope.logs {
                let key = StorageKey(ownerID: log.ownerID, date: log.date)
                guard reconstructed[key] == nil, identities.insert(log.id).inserted else {
                    throw Prompt20DailyLogDomainError.corruptPersistence
                }
                reconstructed[key] = log
            }
            guard Set(envelope.recentlyProcessedRequestIDs).count == envelope.recentlyProcessedRequestIDs.count else {
                throw Prompt20DailyLogDomainError.corruptPersistence
            }
            logsByKey = reconstructed
            processedRequestIDs = envelope.recentlyProcessedRequestIDs
            processedRequestSet = Set(processedRequestIDs)
            expectedPersistedData = data
            loaded = true
        } catch let error as Prompt20DailyLogDomainError { throw error }
        catch { throw Prompt20DailyLogDomainError.corruptPersistence }
    }

    private func remember(
        _ requestID:
            UUID
    ) {
        guard
            !processedRequestSet
                .contains(
                    requestID
                )
        else {
            return
        }

        processedRequestIDs
            .append(
                requestID
            )

        processedRequestSet
            .insert(
                requestID
            )

        if
            processedRequestIDs
                .count
            >
            Self
                .maxRememberedRequestIDs {

            let overflow =
                processedRequestIDs
                    .count
                -
                Self
                    .maxRememberedRequestIDs

            let removed =
                processedRequestIDs
                    .prefix(
                        overflow
                    )

            for id
                in removed {

                processedRequestSet
                    .remove(
                        id
                    )
            }

            processedRequestIDs
                .removeFirst(
                    overflow
                )
        }
    }

    private func
        persist() throws {

        guard
            let fileURL
        else {
            return
        }

        try requireCurrentSnapshot()

        let directory =
            fileURL
                .deletingLastPathComponent()

        do {
            try FileManager
                .default
                .createDirectory(
                    at:
                        directory,
                    withIntermediateDirectories:
                        true
                )

            let envelope =
                Envelope(
                    schemaVersion:
                        Self
                            .schemaVersion,
                    logs:
                        logsByKey
                            .values
                            .sorted {
                                if
                                    $0.ownerID
                                        .rawValue
                                    !=
                                    $1.ownerID
                                        .rawValue {

                                    return
                                        $0.ownerID
                                            .rawValue
                                        <
                                        $1.ownerID
                                            .rawValue
                                }

                                return
                                    $0.date
                                    <
                                    $1.date
                            },
                    recentlyProcessedRequestIDs:
                        processedRequestIDs
                )

            let encoder =
                JSONEncoder()

            encoder.dateEncodingStrategy =
                .millisecondsSince1970

            encoder.outputFormatting =
                [
                    .sortedKeys
                ]

            let data =
                try encoder
                    .encode(
                        envelope
                    )

            try requireCurrentSnapshot()
            try data.write(
                to:
                    fileURL,
                options:
                    .atomic
            )

            expectedPersistedData = data

        } catch let error as Prompt20DailyLogDomainError {
            throw error
        } catch {
            throw
                Prompt20DailyLogDomainError
                    .persistenceUnavailable
        }
    }

    /*
     This is a pure filesystem-location factory.

     Marking it nonisolated prevents the project's
     default MainActor isolation from making the
     actor's default argument require an actor hop.
     */
    public nonisolated static func
        defaultFileURL() -> URL? {

        let fileManager =
            FileManager
                .default

        guard
            let support =
                fileManager
                    .urls(
                        for:
                            .applicationSupportDirectory,
                        in:
                            .userDomainMask
                    )
                    .first
        else {
            return nil
        }

        return
            support
                .appendingPathComponent(
                    "Fruitfolio",
                    isDirectory:
                        true
                )
                .appendingPathComponent(
                    "CycleDomain",
                    isDirectory:
                        true
                )
                .appendingPathComponent(
                    "daily-logs-v1.json",
                    isDirectory:
                        false
                )
    }
}

// MARK: - In-memory repository

public actor
    Prompt20InMemoryDailyLogRepository:
    Prompt20DailyLogRepository {

    private var logs:
        [String: Prompt20DailyLog] =
        [:]

    private var processedRequestIDs:
        Set<UUID> =
        []

    private let calendar:
        Calendar

    public init(
        calendar:
            Calendar = .current
    ) {
        self.calendar =
            calendar
    }

    public func load(
        ownerID:
            Prompt20DailyLogOwnerID,
        date:
            Prompt20LocalDay
    ) async throws
        -> Prompt20DailyLog? {

        logs[
            key(
                ownerID:
                    ownerID,
                date:
                    date
            )
        ]
    }

    public func save(
        ownerID:
            Prompt20DailyLogOwnerID,
        date:
            Prompt20LocalDay,
        draft:
            Prompt20DailyLogDraft,
        now:
            Date,
        requestID:
            UUID,
        expectation: Prompt20DailyLogSaveExpectation = .unchecked
    ) async throws
        -> Prompt20DailyLog? {

        try Task.checkCancellation()
        let dateIsFuture = Prompt20DailyLogRules.isFuture(date, relativeTo: now, calendar: calendar)

        guard
            !dateIsFuture
        else {
            throw
                Prompt20DailyLogDomainError
                    .futureDate
        }

        let storageKey =
            key(
                ownerID:
                    ownerID,
                date:
                    date
            )

        /*
         Match production-store idempotency:
         processing the same request twice must
         not create another logical save.
         */
        if processedRequestIDs
            .contains(
                requestID
            ) {

            return
                logs[
                    storageKey
                ]
        }

        let existing =
            logs[
                storageKey
            ]

        try expectation.validate(current: existing?.isDeleted == false ? existing : nil)

        let candidate = try Prompt20DailyLogRules.makeLog(
            ownerID: ownerID, date: date, draft: draft, existing: existing, now: now)
        try Task.checkCancellation()

        processedRequestIDs
            .insert(
                requestID
            )

        if candidate
            .hasRecordedContent {

            logs[
                storageKey
            ] =
                candidate

            return candidate
        }

        logs
            .removeValue(
                forKey:
                    storageKey
            )

        return nil
    }

    public func allActiveLogs(
        ownerID:
            Prompt20DailyLogOwnerID
    ) async throws
        -> [Prompt20DailyLog] {

        logs
            .values
            .filter {
                $0.ownerID
                    == ownerID
                &&
                !$0.isDeleted
            }
            .sorted {
                $0.date
                    <
                $1.date
            }
    }

    private func key(
        ownerID:
            Prompt20DailyLogOwnerID,
        date:
            Prompt20LocalDay
    ) -> String {

        "\(ownerID.rawValue)|\(date.year)-\(date.month)-\(date.day)"
    }
}
