import Foundation
import CoreFoundation

nonisolated final class FruitfolioUsernamePersistence {
    struct Snapshot: Equatable {
        let username: String
        let confirmedNonIdentifying: Bool
    }
    private struct Record: Codable, Equatable {
        let schemaVersion: Int
        let username: String
        let confirmedNonIdentifying: Bool
    }
    private struct LegacyState: Equatable {
        let username: String?
        let confirmation: String?
        let initialized: Bool?
        let gameUsername: String?
        var candidate: String { username ?? (initialized == true ? "" : (gameUsername ?? "")) }
        static func == (lhs: Self, rhs: Self) -> Bool {
            same(lhs.username, rhs.username) && same(lhs.confirmation, rhs.confirmation) &&
                lhs.initialized == rhs.initialized && same(lhs.gameUsername, rhs.gameUsername)
        }
        private static func same(_ lhs: String?, _ rhs: String?) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none): return true
            case (.some(let lhs), .some(let rhs)): return lhs.utf8.elementsEqual(rhs.utf8)
            default: return false
            }
        }
    }
    private struct Read {
        let snapshot: Snapshot
        let recordPresent: Bool
        let data: Data?
        let legacy: LegacyState?
        let issue: String?
    }
    private enum Failure: Error { case unsupported }
    static let defaultKey = "fruitfolio.identity.publicUsername.v1"
    static func recordKey(for key: String = FruitfolioUsernamePersistence.defaultKey) -> String { key + ".snapshot.v2" }
    private let defaults: UserDefaults
    private let key: String
    private var recordKey: String { Self.recordKey(for: key) }
    private var hasLoaded = false
    private var expectedPresent = false
    private var expectedData: Data?
    private var expectedLegacy: LegacyState?
    private(set) var storageIssue: String?
    private static let unsupported = "the saved username format is not supported by this version. the original record is preserved. reload a compatible record before changing it."
    private static let changed = "the saved username changed elsewhere. your edit was not saved. review the current name and confirm your edit again."
    private static let unacknowledged = "the username could not be saved to local storage. your edit was not reported as saved."

    init(defaults: UserDefaults, key: String) { self.defaults = defaults; self.key = key }

    /// Explicit reads establish the baseline. UI diagnostics must use inspect()
    /// so a redraw cannot silently authorize overwriting a newer writer's name.
    func load() -> Snapshot {
        let read = readStored()
        hasLoaded = true
        expectedPresent = read.recordPresent
        expectedData = read.data
        expectedLegacy = read.legacy
        storageIssue = read.issue
        return read.snapshot
    }
    func inspect() -> Snapshot { readStored().snapshot }

    @discardableResult
    func save(_ raw: String, confirmedNonIdentifying: Bool, identifyingText: [String]) -> String? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message = FruitfolioPseudonymPolicy.validationMessage(for: cleaned,
            confirmedNonIdentifying: confirmedNonIdentifying, identifyingText: identifyingText) { return message }
        return commit(.init(schemaVersion: 2, username: cleaned, confirmedNonIdentifying: true))
    }

    /// The empty record is an acknowledged tombstone. Legacy originals remain
    /// intact, but cannot resurrect an active name in this application's reader.
    @discardableResult
    func clear() -> String? {
        commit(.init(schemaVersion: 2, username: "", confirmedNonIdentifying: false))
    }

    private func commit(_ record: Record) -> String? {
        if !hasLoaded { _ = load() }
        guard storageIssue == nil else { return storageIssue }
        guard baselineMatches() else { return Self.changed }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(record) else { return Self.unacknowledged }
        if expectedPresent, let expectedData,
           let previous = try? JSONDecoder().decode(Record.self, from: expectedData), previous == record { return nil }
        // One preference object holds name and consent together. There is no
        // interval where a new name is paired with an older confirmation field.
        defaults.set(data, forKey: recordKey)
        guard let actual = defaults.object(forKey: recordKey) as? Data, actual == data else {
            return Self.unacknowledged
        }
        expectedPresent = true
        expectedData = data
        expectedLegacy = nil
        storageIssue = nil
        return nil
    }

    private func baselineMatches() -> Bool {
        if expectedPresent {
            guard let expectedData, let current = defaults.object(forKey: recordKey) as? Data else { return false }
            return current == expectedData
        }
        guard defaults.object(forKey: recordKey) == nil, let expectedLegacy,
              let current = try? legacyState() else { return false }
        return current == expectedLegacy
    }

    private func readStored() -> Read {
        guard let object = defaults.object(forKey: recordKey) else {
            guard let legacy = try? legacyState() else {
                return .init(snapshot: legacyFallback(), recordPresent: false, data: nil, legacy: nil, issue: Self.unsupported)
            }
            let name = Prompt28LeaderboardUsernamePolicy.isValid(legacy.candidate) ? legacy.candidate : ""
            return .init(snapshot: .init(username: name,
                confirmedNonIdentifying: !name.isEmpty && legacy.confirmation == name),
                recordPresent: false, data: nil, legacy: legacy, issue: nil)
        }
        guard let data = object as? Data, data.count <= 16 * 1024,
              let record = try? JSONDecoder().decode(Record.self, from: data),
              record.schemaVersion == 2,
              (record.username.isEmpty ? !record.confirmedNonIdentifying :
                Prompt28LeaderboardUsernamePolicy.isValid(record.username) && record.confirmedNonIdentifying),
              let encoded = try? JSONEncoder().encode(record),
              FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: encoded) else {
            var readable = legacyFallback()
            if let data = object as? Data, data.count <= 16 * 1024,
               let record = try? JSONDecoder().decode(Record.self, from: data),
               Prompt28LeaderboardUsernamePolicy.isValid(record.username) {
                readable = .init(username: record.username, confirmedNonIdentifying: false)
            }
            return .init(snapshot: readable, recordPresent: true, data: object as? Data, legacy: nil, issue: Self.unsupported)
        }
        return .init(snapshot: .init(username: record.username, confirmedNonIdentifying: record.confirmedNonIdentifying),
                     recordPresent: true, data: data, legacy: nil, issue: nil)
    }

    private func legacyState() throws -> LegacyState {
        func text(_ key: String) throws -> String? {
            guard let object = defaults.object(forKey: key) else { return nil }
            guard let text = object as? String else { throw Failure.unsupported }
            return text
        }
        let username = try text(key)
        let confirmation = try text(key + ".nonIdentifyingConfirmation")
        var initialized: Bool?
        if let object = defaults.object(forKey: key + ".initialized") {
            guard let number = object as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { throw Failure.unsupported }
            initialized = number.boolValue
        }
        let gameName: String?
        if username == nil, initialized != true {
            gameName = defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1")
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                .flatMap { $0["leaderboardPseudonym"] as? String }
        } else { gameName = nil }
        return .init(username: username, confirmation: confirmation, initialized: initialized, gameUsername: gameName)
    }
    private func legacyFallback() -> Snapshot {
        let candidate = defaults.string(forKey: key) ?? ""
        return .init(username: Prompt28LeaderboardUsernamePolicy.isValid(candidate) ? candidate : "", confirmedNonIdentifying: false)
    }
}
