import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BCatchPresentationTests: XCTestCase {
    func testMeasuredHUDNeverOverlapsOrConsumesTheMinimumRealPlayfield() {
        for size in [CGSize(width: 390, height: 780), CGSize(width: 320, height: 480),
                     CGSize(width: 844, height: 320), CGSize(width: 620, height: 176)] {
            for content: CGFloat in [0, 44, 92, 300, 5000, .nan] {
                let viewport = Prompt28GameplayViewport(available: size, headerContentHeight: content)
                XCTAssertTrue(viewport.canPresentPlayfield)
                XCTAssertGreaterThanOrEqual(viewport.headerHeight, 44)
                XCTAssertGreaterThanOrEqual(viewport.playfieldHeight, 132)
                XCTAssertEqual(viewport.headerHeight + viewport.playfieldHeight, size.height)
                let geometry = Prompt28CatchGeometry(playfield: .init(width: min(size.width, 620), height: viewport.playfieldHeight))
                XCTAssertTrue(geometry.isValid)
                let basket = geometry.artRect(basketX: 0.5).offsetBy(dx: 0, dy: viewport.headerHeight)
                XCTAssertGreaterThanOrEqual(basket.minY, viewport.headerHeight)
                XCTAssertLessThanOrEqual(basket.maxY, size.height + 0.001)
            }
        }
    }

    func testInsufficientOrNonfiniteViewportDoesNotFabricatePlayableGeometry() {
        for size in [CGSize.zero, CGSize(width: 390, height: 175), CGSize(width: 0, height: 700),
                     CGSize(width: CGFloat.infinity, height: 700), CGSize(width: 390, height: CGFloat.nan)] {
            let viewport = Prompt28GameplayViewport(available: size, headerContentHeight: 92)
            XCTAssertFalse(viewport.canPresentPlayfield)
            XCTAssertEqual(viewport.headerHeight, 0)
            XCTAssertEqual(viewport.playfieldHeight, 0)
        }
    }

    func testOldHighCenterThresholdDoesNotAwardAnAboveBasketObject() {
        let geometry = Prompt28CatchGeometry(playfield: CGSize(width: 390, height: 700))
        XCTAssertFalse(geometry.crossedMouth(x: 0.5, previousY: 0.80, currentY: 0.83, basketX: 0.5, objectSize: geometry.starSize))
    }
    func testLeadingEdgeCrossingStartsEntryOnlyInsideTheActualMouth() {
        let geometry = Prompt28CatchGeometry(playfield: CGSize(width: 390, height: 700))
        let threshold = (geometry.mouth(basketX: 0.5).minY - geometry.starSize / 2) / geometry.playfield.height
        XCTAssertTrue(geometry.crossedMouth(x: 0.5, previousY: threshold - 0.001, currentY: threshold + 0.001, basketX: 0.5, objectSize: geometry.starSize))
        XCTAssertFalse(geometry.crossedMouth(x: 0.1, previousY: threshold - 0.001, currentY: threshold + 0.001, basketX: 0.5, objectSize: geometry.starSize))
        XCTAssertFalse(geometry.crossedMouth(x: 0.5, previousY: threshold + 0.01, currentY: threshold + 0.02, basketX: 0.5, objectSize: geometry.starSize))
    }
    func testBothKindsFullyEnterBeforeCompletionAndStayInsideHorizontalAperture() {
        for size in [CGSize(width: 240, height: 380), CGSize(width: 390, height: 700), CGSize(width: 620, height: 900)] {
            let geometry = Prompt28CatchGeometry(playfield: size)
            for kind: Prompt28CatchTransit.Kind in [.star, .fruit(.apple, .good)] {
                for offset in [-0.09, 0, 0.09] {
                    var transit = Prompt28CatchTransit(id: UUID(), kind: kind, relativeX: offset)
                    XCTAssertFalse(transit.advance(by: Prompt28CatchTransit.entryDuration))
                    XCTAssertEqual(transit.progress, 1)
                    let pose = geometry.pose(for: transit, basketX: 0.5, reducedMotion: false)
                    let mouth = geometry.mouth(basketX: 0.5)
                    XCTAssertGreaterThanOrEqual(pose.center.y - pose.size.height / 2, mouth.minY - 0.000001)
                    XCTAssertGreaterThanOrEqual(pose.center.x - pose.size.width / 2, mouth.minX - 0.000001)
                    XCTAssertLessThanOrEqual(pose.center.x + pose.size.width / 2, mouth.maxX + 0.000001)
                }
            }
        }
    }
    func testFlattenedSettleIsVisibleBeforeExactlyOneCompletionEvent() {
        var transit = Prompt28CatchTransit(id: UUID(), kind: .star, relativeX: 0)
        XCTAssertFalse(transit.advance(by: Prompt28CatchTransit.entryDuration))
        XCTAssertEqual(transit.progress, 1)
        XCTAssertTrue(transit.advance(by: Prompt28CatchTransit.duration))
        XCTAssertFalse(transit.advance(by: 1))
    }
    func testReducedMotionUsesSettledPoseWithoutEarlyCompletion() {
        let geometry = Prompt28CatchGeometry(playfield: CGSize(width: 390, height: 700))
        var transit = Prompt28CatchTransit(id: UUID(), kind: .star, relativeX: 0)
        let still = geometry.pose(for: transit, basketX: 0.5, reducedMotion: true)
        XCTAssertGreaterThanOrEqual(still.center.y - still.size.height / 2, geometry.mouth(basketX: 0.5).minY)
        XCTAssertEqual(transit.elapsed, 0)
        XCTAssertFalse(transit.advance(by: -1))
        XCTAssertFalse(transit.advance(by: .nan))
    }
    func testRareStarsHaveGuaranteedFruitSpacingWithoutCappingCollectedPasses() {
        var planner = Prompt28RareStarPlanner()
        var stars = 0
        var fruitSinceStar = 0
        for _ in 0..<1_000 {
            if planner.shouldDropStar(randomUnit: 0) {
                XCTAssertGreaterThanOrEqual(fruitSinceStar, 8)
                stars += 1; fruitSinceStar = 0
            } else { fruitSinceStar += 1 }
        }
        XCTAssertGreaterThan(stars, 10)
        let engine = Prompt28FruitBasketEngine()
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        for _ in 0..<stars { _ = engine.registerStarCatch(session: &session) }
        XCTAssertEqual(session.availableStarPasses, stars)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
    }
    func testNonrareDrawsAndInvalidRandomValuesNeverForceABonus() {
        var planner = Prompt28RareStarPlanner()
        for _ in 0..<100 { XCTAssertFalse(planner.shouldDropStar(randomUnit: 0.5)) }
        XCTAssertFalse(planner.shouldDropStar(randomUnit: .nan))
        XCTAssertFalse(planner.shouldDropStar(randomUnit: -0.1))
        XCTAssertTrue(planner.shouldDropStar(randomUnit: 0))
    }
    func testInvalidViewportAndNonfinitePositionsCannotCatchObjects() {
        let collapsed = Prompt28CatchGeometry(playfield: .zero)
        XCTAssertFalse(collapsed.crossedMouth(x: 0.5, previousY: 0, currentY: 1, basketX: 0.5, objectSize: 30))
        let valid = Prompt28CatchGeometry(playfield: CGSize(width: 390, height: 700))
        XCTAssertFalse(valid.crossedMouth(x: .nan, previousY: 0, currentY: 1, basketX: 0.5, objectSize: 30))
    }
    func testClassificationSettlementUsesTheSameTransitWithinItsBasketCanvas() {
        let size = CGSize(width: 150, height: 132)
        for kind: Prompt28CatchTransit.Kind in [.star, .fruit(.pear, .good)] {
            var transit = Prompt28CatchTransit(id: UUID(), kind: kind, relativeX: 0)
            XCTAssertFalse(transit.advance(by: Prompt28CatchTransit.entryDuration))
            let pose = Prompt28CatchGeometry.localPose(for: transit, basketSize: size, reducedMotion: false)
            XCTAssertGreaterThanOrEqual(pose.center.x - pose.size.width / 2, 0)
            XCTAssertLessThanOrEqual(pose.center.x + pose.size.width / 2, size.width)
            XCTAssertGreaterThanOrEqual(pose.center.y - pose.size.height / 2, 0)
            XCTAssertLessThanOrEqual(pose.center.y + pose.size.height / 2, size.height)
            XCTAssertTrue(transit.advance(by: Prompt28CatchTransit.duration))
        }
    }

    func testBasketAndFullyEnteredItemsStayOnScreenInShortLandscapeField() {
        for size in [CGSize(width: 390, height: 220), CGSize(width: 240, height: 380), CGSize(width: 620, height: 320)] {
            let geometry = Prompt28CatchGeometry(playfield: size)
            XCTAssertGreaterThanOrEqual(geometry.basketCenterY - 66, 0)
            XCTAssertLessThanOrEqual(geometry.basketCenterY + 66, size.height)
            for kind: Prompt28CatchTransit.Kind in [.star, .fruit(.pear, .good)] {
                var transit = Prompt28CatchTransit(id: UUID(), kind: kind, relativeX: 0)
                _ = transit.advance(by: Prompt28CatchTransit.duration)
                let pose = geometry.pose(for: transit, basketX: 0.5, reducedMotion: false)
                XCTAssertLessThanOrEqual(pose.center.y + pose.size.height / 2, size.height)
                XCTAssertGreaterThanOrEqual(pose.center.y - pose.size.height / 2, 0)
            }
        }
    }

}
