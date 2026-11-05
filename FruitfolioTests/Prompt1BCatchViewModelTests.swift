#if canImport(Combine)
import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BCatchViewModelTests: XCTestCase {
    func testActualModelAwardsStarOnlyAfterEntryAndSettlementExactlyOnce() throws {
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

    func testActualModelPreservesWhichFruitWasCaughtAfterItsEntry() throws {
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
}
#endif
