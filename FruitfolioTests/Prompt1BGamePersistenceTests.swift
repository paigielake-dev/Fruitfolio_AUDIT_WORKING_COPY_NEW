import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BGamePersistenceTests: XCTestCase {
    private func defaults() throws -> (String, UserDefaults) {
        let name = "Fruitfolio.game-persistence-tests." + UUID().uuidString
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }
    func testExistingStateKeysAndProgressSurviveStoreReinitialization() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertNil(try store.load())
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", totalRoundsCompleted: 3, totalFruitCaught: 30, totalSuccessfulRounds: 3, bestScore: 300)
        state.questionHistory["fixture"] = ["source:version:question"]
        state.controlMode = .classification
        try store.save(state)
        let original = try XCTUnwrap(defaults.data(forKey: "game"))
        let next = Prompt28GamePersistence(defaults: defaults, key: "game")
        let loaded = try XCTUnwrap(next.load())
        XCTAssertEqual(loaded.topicProgress, state.topicProgress)
        XCTAssertEqual(loaded.questionHistory, state.questionHistory)
        XCTAssertEqual(loaded.controlMode, .classification)
        XCTAssertEqual(defaults.data(forKey: "game"), original, "Loading must not rewrite existing source bytes")
    }
    func testWrongStoredTypeAndCorruptBytesAreNeverOverwritten() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("original wrong-type value", forKey: "game")
        let wrong = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try wrong.load())
        XCTAssertThrowsError(try wrong.save(.init()))
        XCTAssertEqual(defaults.string(forKey: "game"), "original wrong-type value")
        let bytes = Data([0xff, 0x00, 0x7b])
        defaults.set(bytes, forKey: "game")
        let corrupt = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try corrupt.load())
        XCTAssertThrowsError(try corrupt.save(.init()))
        XCTAssertTrue(corrupt.isWriteBlocked)
        XCTAssertEqual(defaults.data(forKey: "game"), bytes)
    }
    func testStaleWriterCannotReplaceNewerProgressAndReloadPreservesIt() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let first = Prompt28GamePersistence(defaults: defaults, key: "game")
        let second = Prompt28GamePersistence(defaults: defaults, key: "game")
        _ = try first.load(); _ = try second.load()
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", bestScore: 100)
        try second.save(state)
        let committed = defaults.data(forKey: "game")
        XCTAssertThrowsError(try first.save(.init()))
        XCTAssertEqual(first.failure, .changedElsewhere)
        XCTAssertEqual(defaults.data(forKey: "game"), committed)
        var fresh = try XCTUnwrap(first.load())
        fresh.controlMode = .classification
        try first.save(fresh)
        let reloaded = try XCTUnwrap(Prompt28GamePersistence(defaults: defaults, key: "game").load())
        XCTAssertEqual(reloaded.topicProgress["fixture"]?.bestScore, 100)
        XCTAssertEqual(reloaded.controlMode, .classification)
    }
    func testDeletedProgressCannotBeResurrectedByAnOldView() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let old = Prompt28GamePersistence(defaults: defaults, key: "game")
        _ = try old.load()
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", bestScore: 100)
        try old.save(state)
        defaults.removeObject(forKey: "game")
        XCTAssertThrowsError(try old.save(state))
        XCTAssertNil(defaults.object(forKey: "game"))
        XCTAssertNil(try old.load(), "Only explicit reload accepts the cleared state")
        try old.save(.init())
        XCTAssertTrue(try XCTUnwrap(Prompt28GamePersistence(defaults: defaults, key: "game").load()).topicProgress.isEmpty)
    }
    func testFutureFormatAndInvalidCountersRemainReadOnlyWithOriginalData() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        var state = Prompt28PersistedGameState(); state.schemaVersion = 2
        let future = try JSONEncoder().encode(state)
        defaults.set(future, forKey: "game")
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try store.load())
        XCTAssertEqual(store.failure, .unsupportedFormat)
        XCTAssertThrowsError(try store.save(.init()))
        XCTAssertEqual(defaults.data(forKey: "game"), future)
        state.schemaVersion = 1
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", bestScore: -1)
        let invalid = try JSONEncoder().encode(state)
        defaults.set(invalid, forKey: "game")
        XCTAssertThrowsError(try store.load())
        XCTAssertEqual(store.failure, .invalidState)
        XCTAssertEqual(defaults.data(forKey: "game"), invalid)
    }
    func testLegacyDocumentWithoutFormatOrTierFieldsLoadsWithoutMigrationWrite() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", totalRoundsCompleted: 3, totalSuccessfulRounds: 3)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        json.removeValue(forKey: "schemaVersion")
        var topics = try XCTUnwrap(json["topicProgress"] as? [String: [String: Any]])
        topics["fixture"]?.removeValue(forKey: "successesInCurrentLevel")
        json["topicProgress"] = topics
        let bytes = try JSONSerialization.data(withJSONObject: json)
        defaults.set(bytes, forKey: "game")
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        let loaded = try XCTUnwrap(store.load())
        XCTAssertNil(loaded.schemaVersion)
        XCTAssertNil(loaded.topicProgress["fixture"]?.successesInCurrentLevel)
        XCTAssertEqual(defaults.data(forKey: "game"), bytes)
    }
    func testBlindWriteBeforeLoadingIsRefused() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let bytes = Data("keep this original".utf8)
        defaults.set(bytes, forKey: "game")
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try store.save(.init()))
        XCTAssertEqual(defaults.data(forKey: "game"), bytes)
    }
    func testTierResetAndNextWinRemainGentleAcrossPersistenceReinitialization() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let writer = Prompt28GamePersistence(defaults: defaults, key: "game")
        _ = try writer.load()
        var state = Prompt28PersistedGameState()
        let old = Prompt28TopicProgress(normalizedTopicID: "fixture", currentGameLevel: 8, highestGameLevelReached: 8,
            totalRoundsCompleted: 200, totalSuccessfulRounds: 200, bestScore: 20000)
        state.topicProgress["fixture"] = Prompt28ProgressionPolicy.resettingLevel(old)
        try writer.save(state)
        let next = Prompt28GamePersistence(defaults: defaults, key: "game")
        var restored = try XCTUnwrap(next.load())
        restored.topicProgress["fixture"] = Prompt28ProgressionPolicy.afterSuccessfulRound(try XCTUnwrap(restored.topicProgress["fixture"]))
        try next.save(restored)
        let final = try XCTUnwrap(Prompt28GamePersistence(defaults: defaults, key: "game").load()).topicProgress["fixture"]
        XCTAssertEqual(final?.currentGameLevel, 1)
        XCTAssertEqual(final?.successesInCurrentLevel, 1)
        XCTAssertEqual(final?.highestGameLevelReached, 8)
        XCTAssertEqual(final?.totalSuccessfulRounds, 201)
        XCTAssertEqual(final?.bestScore, 20000)
    }

}
