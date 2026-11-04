import XCTest
@testable import Fruitfolio

final class BasketArtworkProjectionTests: XCTestCase {
    func testProjectionNeverGuessesFruitAndNeverDropsPendingPresentationArtwork() {
        let fruit = Prompt28SettledCatch(id: UUID(), assetID: Prompt28FruitID.pear.assetID, isStar: false, collected: true)
        let stars = (0..<12).map { _ in Prompt28SettledCatch(id: UUID(), assetID: .fruitbasket_star, isStar: true, collected: true) }
        let pending = Prompt28SettledCatch(id: UUID(), assetID: .fruitbasket_star, isStar: true, collected: false)
        let actual = [fruit] + stars + [pending]
        let result = Prompt28BasketArtworkProjection(catches: actual)
        XCTAssertTrue(result.visibleCatches.contains(fruit))
        XCTAssertTrue(result.visibleCatches.contains(pending), "Hidden pending stars cannot receive their real settling callback")
        XCTAssertEqual(result.visibleCatches.filter { $0.isStar && $0.collected }.count, 8)
        XCTAssertEqual(result.additionalCollectedStars, 4)
        XCTAssertEqual(result.registeredStars, 12)
        XCTAssertTrue(Set(result.visibleCatches.map(\.id)).isSubset(of: Set(actual.map(\.id))))
        XCTAssertEqual(actual.count, 14, "Drawing projection must not mutate the authoritative catch records")
    }
    func testEmptyActualRecordsNeverProduceDecorativePoolCatches() {
        let result = Prompt28BasketArtworkProjection(catches: [])
        XCTAssertTrue(result.visibleCatches.isEmpty)
        XCTAssertEqual(result.additionalCollectedStars, 0)
        XCTAssertEqual(result.registeredStars, 0)
    }
}
