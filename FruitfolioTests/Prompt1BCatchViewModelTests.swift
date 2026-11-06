#if canImport(Combine)
import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BCatchViewModelTests: XCTestCase {
    func testActualModelAwardsStarOnlyAfterEntryAndSettlementExactlyOnce() async throws {
        let name = "Fruitfolio.star-entry." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        model.screen = .catchActive
        let geometry = Prompt28CatchGeometry(playfield: CGSize(width: 390, height: 700))
        model.updatePlayfield(size: geometry.playfield)
        let crossing = (geometry.mouth(basketX: 0.5).minY - geometry.starSize / 2) / geometry.playfield.height
        model.activeStars = [.init(x: 0.5, y: crossing - 0.002, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)]
        model.advanceGameplayFrame(delta: 0.04, now: Date())
        XCTAssertEqual(model.catchTransits.count, 1)
        XCTAssertEqual(model.session?.availableStarPasses, 0)
        XCTAssertEqual(model.basketCount, 0)
        for _ in 0..<5 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.session?.availableStarPasses, 0)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.session?.availableStarPasses, 1)
        XCTAssertEqual(model.basketCount, 0)
        XCTAssertTrue(model.catchTransits.isEmpty)
        XCTAssertTrue(model.collectedFruit.isEmpty)
    }

    func testActualModelPreservesWhichFruitWasCaughtAfterItsEntry() async throws {
        let name = "Fruitfolio.fruit-entry." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        model.screen = .catchActive
        let geometry = Prompt28CatchGeometry(playfield: CGSize(width: 390, height: 700))
        model.updatePlayfield(size: geometry.playfield)
        let crossing = (geometry.mouth(basketX: 0.5).minY - geometry.fruitSize / 2) / geometry.playfield.height
        model.activeFruit = [.init(fruitID: .pear, classification: .good, x: 0.5, y: crossing - 0.002,
                                   fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)]
        model.advanceGameplayFrame(delta: 0.04, now: Date())
        XCTAssertEqual(model.basketCount, 0)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.basketCount, 1)
        XCTAssertEqual(model.collectedFruit, [.pear])
        model.advanceGameplayFrame(delta: .nan, now: Date())
        XCTAssertEqual(model.basketCount, 1)
    }
    func testClassificationStarCatchIsDelayedAndDoubleSelectionCannotDuplicateAward() async throws {
        let name = "Fruitfolio.classification-star." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        model.setControlMode(.classification)
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        model.screen = .catchActive
        model.classificationStarAvailable = true
        model.classificationStarDecision(accept: true)
        model.classificationStarDecision(accept: true)
        XCTAssertEqual(model.catchTransits.count, 1)
        XCTAssertEqual(model.session?.availableStarPasses, 0)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.session?.availableStarPasses, 1)
        XCTAssertEqual(model.basketCount, 0)
        XCTAssertTrue(model.activeFruit.isEmpty)
        XCTAssertTrue(model.activeStars.isEmpty)
        model.pause()
    }

    func testClassificationStarCanPassWithoutPenaltyOrFruitCount() async throws {
        let name = "Fruitfolio.classification-skip." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        model.setControlMode(.classification)
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        model.screen = .catchActive
        model.classificationStarAvailable = true
        model.classificationStarDecision(accept: false)
        XCTAssertFalse(model.classificationStarAvailable)
        XCTAssertTrue(model.catchTransits.isEmpty)
        XCTAssertEqual(model.session?.availableStarPasses, 0)
        XCTAssertEqual(model.basketCount, 0)
        XCTAssertEqual(model.screen, .catchActive)
    }

    func testActualFailedAndSuccessfulResultsKeepCapturesAndCountersExact() async throws {
        let name = "Fruitfolio.round-results." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        defer { model.leaveScreen() }
        model.setControlMode(.classification)
        model.currentQuestion = Prompt28Question(id: "fixture", topicQuery: "fixture", normalizedTopic: "fixture", category: "test-only",
            educationalDifficulty: .easy, questionText: "nonmedical test question", answerOptions: [.init(id: "a", text: "one"), .init(id: "b", text: "two")],
            correctAnswerID: "a", explanation: "nonmedical test fixture", sourceIDs: ["fixture"], sourceTitles: ["Fixture"],
            catchConceptID: "visual-starred-fruit", catchRule: "starred fruit", goodFruitIDs: [.pear], badFruitIDs: [.lemon],
            contentVersion: "fixture", reviewStatus: "test-only", createdAt: Date())
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        model.beginCatch()
        func settle() { for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) } }
        func catchFruit(_ fruit: Prompt28FruitID, _ classification: Prompt28FruitClassification) {
            model.classificationStarAvailable = false
            model.classificationFruit = .init(fruitID: fruit, classification: classification, x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
            model.classificationDecision(accept: true); settle()
        }
        model.classificationFruit = nil
        model.classificationStarAvailable = true
        model.classificationStarDecision(accept: true); settle()
        catchFruit(.lemon, .bad) // One pass protects this actual adverse catch.
        for _ in 0..<7 { catchFruit(.pear, .good) }
        XCTAssertNil(model.roundResult)
        catchFruit(.lemon, .bad) // No pass remains; this ends the attempt.
        model.sceneBecameInactive()
        let failed = try XCTUnwrap(model.roundResult)
        XCTAssertFalse(failed.succeeded)
        XCTAssertEqual(failed.caughtFruit.count, 7)
        XCTAssertEqual(failed.starsCollected, 1)
        XCTAssertEqual(failed.starPassesSpent, 1)
        XCTAssertEqual(failed.scoreChange, 70)
        XCTAssertEqual(store.progress(for: "fixture")?.totalFruitCaught, 7)
        model.retryRound()
        for _ in 0..<10 { catchFruit(.pear, .good) }
        model.sceneBecameInactive()
        let completed = try XCTUnwrap(model.roundResult)
        XCTAssertTrue(completed.succeeded)
        XCTAssertNotEqual(completed.roundID, failed.roundID)
        XCTAssertEqual(completed.caughtFruit, Array(repeating: .pear, count: 10))
        XCTAssertEqual(completed.scoreChange, 100)
        XCTAssertEqual(completed.cumulativeScore, 170)
        XCTAssertEqual(failed.caughtFruit.count, 7, "The prior immutable result must not become the next round")
        XCTAssertEqual(store.progress(for: "fixture")?.totalFruitCaught, 17)
        XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, 1)
        XCTAssertEqual(store.progress(for: "fixture")?.totalRoundsCompleted, 2)
        XCTAssertEqual(store.progress(for: "fixture")?.totalSuccessfulRounds, 1)
        model.sceneBecameInactive(); model.resume(); model.sceneBecameInactive()
        await Task.yield()
        XCTAssertEqual(store.progress(for: "fixture")?.totalRoundsCompleted, 2)
    }

}
#endif
