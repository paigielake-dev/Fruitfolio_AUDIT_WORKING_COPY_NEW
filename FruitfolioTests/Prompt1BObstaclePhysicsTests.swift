import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BObstaclePhysicsTests: XCTestCase {
    private enum Failure: Error { case missingPaint }
    private func geometry(level: Int = 3) throws -> Prompt28ObstacleGeometry {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_OBSTACLE_MASKS_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "Prompt28ObstacleMasks", withExtension: "json"))
        return .init(playfield: CGSize(width: 390, height: 700), level: level, library: try .load(url: url))
    }
    private func paintedPoint(_ name: String, in geometry: Prompt28ObstacleGeometry) throws -> CGPoint {
        let mask = try XCTUnwrap(geometry.library.masks[name])
        let frame = try XCTUnwrap(geometry.frame(name))
        for row in 0..<mask.rows {
            for column in 0..<mask.columns where mask.isPainted(column: column, row: row) {
                let fraction = (CGFloat(column) + 0.5) / CGFloat(mask.columns)
                return CGPoint(x: (frame.minX + frame.width * (name == "branch" ? 1 - fraction : fraction)) / geometry.playfield.width,
                               y: (frame.minY + frame.height * (CGFloat(row) + 0.5) / CGFloat(mask.rows)) / geometry.playfield.height)
            }
        }
        XCTFail("Required source paint is missing; this must not become a skipped physics test")
        throw Failure.missingPaint
    }
    func testWindChangesTrajectoryInCodeWithoutChangingCapturedBaseSpeed() throws {
        let geometry = try geometry()
        var right = Prompt28FallingFruit(fruitID: .pear, classification: .good, x: 0.5, y: 0.1, fallSpeed: 0.2, horizontalDrift: 0, rotationDegrees: 0)
        var left = right
        Prompt28ObstaclePhysics.advanceFruit(&right, delta: 0.04, geometry: geometry, obstacles: [.wind], lanes: 0.08...0.92, windDirection: 1, weather: .breezy)
        Prompt28ObstaclePhysics.advanceFruit(&left, delta: 0.04, geometry: geometry, obstacles: [.wind], lanes: 0.08...0.92, windDirection: -1, weather: .breezy)
        XCTAssertGreaterThan(right.x, 0.5)
        XCTAssertLessThan(left.x, 0.5)
        XCTAssertEqual(right.fallSpeed, 0.2)
        XCTAssertEqual(right.horizontalDrift, 0)
        XCTAssertEqual(right.y, left.y)
    }
    func testPaintedVinesSlowGoodFruitAndStarsButNeverBadFruit() throws {
        let geometry = try geometry()
        let point = try paintedPoint("vines", in: geometry)
        var good = Prompt28FallingFruit(fruitID: .pear, classification: .good, x: point.x, y: point.y, fallSpeed: 0.2, horizontalDrift: 0, rotationDegrees: 0)
        var bad = Prompt28FallingFruit(fruitID: .lemon, classification: .bad, x: point.x, y: point.y, fallSpeed: 0.2, horizontalDrift: 0, rotationDegrees: 0)
        var star = Prompt28FallingStar(x: point.x, y: point.y, fallSpeed: 0.2, horizontalDrift: 0, rotationDegrees: 0)
        XCTAssertTrue(Prompt28ObstaclePhysics.advanceFruit(&good, delta: 0.04, geometry: geometry, obstacles: [.vines], lanes: 0.08...0.92, windDirection: 1, weather: .clear))
        XCTAssertFalse(Prompt28ObstaclePhysics.advanceFruit(&bad, delta: 0.04, geometry: geometry, obstacles: [.vines], lanes: 0.08...0.92, windDirection: 1, weather: .clear))
        XCTAssertTrue(Prompt28ObstaclePhysics.advanceStar(&star, delta: 0.04, geometry: geometry, obstacles: [.vines], lanes: 0.08...0.92, windDirection: 1, weather: .clear))
        XCTAssertLessThan(good.y - point.y, bad.y - point.y)
        XCTAssertLessThan(star.y - point.y, bad.y - point.y)
        XCTAssertFalse(bad.isInVines)
        XCTAssertGreaterThan(good.vineContactTime, 0)
        XCTAssertFalse(Prompt28ObstaclePhysics.advanceFruit(&good, delta: 0.04, geometry: geometry, obstacles: [.vines], lanes: 0.08...0.92, windDirection: 1, weather: .clear), "Remaining in the same leaves must not replay entry audio every frame")
    }
    func testInvisibleMiddleFieldDoesNotSlowAnOtherwiseIdenticalFruit() throws {
        let geometry = try geometry()
        var fruit = Prompt28FallingFruit(fruitID: .pear, classification: .good, x: 0.5, y: 0.54, fallSpeed: 0.2, horizontalDrift: 0, rotationDegrees: 0)
        Prompt28ObstaclePhysics.advanceFruit(&fruit, delta: 0.04, geometry: geometry, obstacles: [.vines], lanes: 0.08...0.92, windDirection: 1, weather: .clear)
        XCTAssertFalse(fruit.isInVines)
        XCTAssertEqual(fruit.y, 0.548, accuracy: 0.000001)
    }
    func testActualBranchPaintProducesOneBoundedBounceAndPersistentDeflection() throws {
        let geometry = try geometry()
        let point = try paintedPoint("branch", in: geometry)
        var fruit = Prompt28FallingFruit(fruitID: .pear, classification: .good, x: point.x, y: point.y, fallSpeed: 0.2, horizontalDrift: 0.01, rotationDegrees: 0)
        Prompt28ObstaclePhysics.advanceFruit(&fruit, delta: 0.04, geometry: geometry, obstacles: [.branch], lanes: 0.08...0.92, windDirection: 1, weather: .clear)
        XCTAssertTrue(fruit.branchDeflected)
        XCTAssertLessThan(try XCTUnwrap(fruit.horizontalVelocityAfterBranch), 0)
        XCTAssertLessThan(fruit.y, point.y)
        let x = fruit.x
        for _ in 0..<8 { Prompt28ObstaclePhysics.advanceFruit(&fruit, delta: 0.04, geometry: geometry, obstacles: [.branch], lanes: 0.08...0.92, windDirection: 1, weather: .clear) }
        XCTAssertEqual(fruit.branchBounceRemaining, 0)
        XCTAssertLessThan(fruit.x, x)
        XCTAssertEqual(fruit.fallSpeed, 0.2)
        XCTAssertEqual(fruit.horizontalDrift, 0.01)
    }
    func testPuddleResistanceFollowsTargetThenRestoresDryResponse() throws {
        let geometry = try geometry(level: 6)
        let first = Prompt28ObstaclePhysics.moveBasket(position: 0.1, target: 0.9, delta: 0.04, geometry: geometry, puddleActive: true)
        XCTAssertLessThan(first.position, 0.9)
        XCTAssertGreaterThan(first.position, 0.1)
        XCTAssertEqual(first.resistance, 1)
        var result = first
        for _ in 0..<100 { result = Prompt28ObstaclePhysics.moveBasket(position: result.position, target: 0.9, delta: 0.04, geometry: geometry, puddleActive: true) }
        XCTAssertEqual(result.position, 0.9, accuracy: 0.000001)
        XCTAssertEqual(result.resistance, 0)
        let dry = Prompt28ObstaclePhysics.moveBasket(position: 0.1, target: 0.12, delta: 0.04, geometry: geometry, puddleActive: true)
        XCTAssertEqual(dry.position, 0.12)
        XCTAssertEqual(dry.resistance, 0)
    }
    func testEverySoftRainRoundIncludesAPuddleAtAllSupportedLevels() {
        let engine = Prompt28FruitBasketEngine()
        for level in 1...12 {
            for round in 1...24 where engine.weather(level: level, round: round) == .softRain {
                XCTAssertTrue(engine.activeObstacles(level: level, round: round).contains(.puddle))
            }
        }
    }
}
