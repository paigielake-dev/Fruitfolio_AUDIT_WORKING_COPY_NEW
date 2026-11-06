import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BObstacleGeometryTests: XCTestCase {
    private func library() throws -> Prompt28ObstacleMaskLibrary {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_OBSTACLE_MASKS_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "Prompt28ObstacleMasks", withExtension: "json"))
        return try .load(url: url)
    }
    func testActualMasksHaveSourceAspectAndSparsePaintInsteadOfRectangularObstacles() throws {
        let library = try library()
        XCTAssertEqual(Set(library.masks.keys), Set(["vines", "branch", "puddle"]))
        for mask in library.masks.values {
            var painted = 0
            for row in 0..<mask.rows {
                for column in 0..<mask.columns { if mask.isPainted(column: column, row: row) { painted += 1 } }
            }
            XCTAssertGreaterThan(painted, 0)
            XCTAssertLessThan(painted, mask.rows * mask.columns)
            XCTAssertEqual(mask.sourceSHA256.count, 64)
            let frame = CGRect(x: 10, y: 20, width: 100, height: 100 * mask.sourceSize.height / mask.sourceSize.width)
            XCTAssertTrue(mask.intersects(frame, imageFrame: frame))
            XCTAssertFalse(mask.intersects(CGRect(x: 10, y: 20, width: 1, height: 1), imageFrame: frame))
        }
    }
    func testVinesCannotAffectAnObjectInTheMiddleOfTheField() throws {
        let geometry = Prompt28ObstacleGeometry(playfield: CGSize(width: 390, height: 700), level: 3, library: try library())
        let object = geometry.objectRect(x: 0.5, y: 0.54, size: 52)
        XCTAssertFalse(geometry.touches("vines", object: object))
        XCTAssertTrue(geometry.touches("vines", object: try XCTUnwrap(geometry.frame("vines"))))
    }
    func testMirroredBranchPaintActuallyReachesTheRightPlayfieldEdge() throws {
        let geometry = Prompt28ObstacleGeometry(playfield: CGSize(width: 390, height: 700), level: 3, library: try library())
        let frame = try XCTUnwrap(geometry.frame("branch"))
        XCTAssertGreaterThan(frame.maxX, geometry.playfield.width)
        XCTAssertTrue(geometry.touches("branch", object: CGRect(x: 388, y: 0, width: 5, height: 700)))
        XCTAssertFalse(geometry.touches("branch", object: CGRect(x: 0, y: 0, width: 100, height: 700)))
    }
    func testBasketPuddleContactDependsOnItsPaintedFootprint() throws {
        let geometry = Prompt28ObstacleGeometry(playfield: CGSize(width: 390, height: 700), level: 6, library: try library())
        XCTAssertTrue(geometry.basketTouchesPuddle(at: 0.5))
        XCTAssertFalse(geometry.basketTouchesPuddle(at: 0.1))
        XCTAssertFalse(geometry.basketTouchesPuddle(at: 0.9))
    }
    func testInvalidGeometryAndMissingManifestNeverCreatePhantomPaint() throws {
        XCTAssertThrowsError(try Prompt28ObstacleMaskLibrary.load(url: nil))
        let geometry = Prompt28ObstacleGeometry(playfield: .zero, level: 3, library: try library())
        XCTAssertNil(geometry.frame("branch"))
        XCTAssertFalse(geometry.touches("vines", object: CGRect(x: 0, y: 0, width: 30, height: 30)))
    }
    func testPuddleGroundPlaneFollowsVisibleBasketInLandscape() throws {
        for size in [CGSize(width: 390, height: 220), CGSize(width: 620, height: 320)] {
            let geometry = Prompt28ObstacleGeometry(playfield: size, level: 6, library: try library())
            XCTAssertTrue(geometry.basketTouchesPuddle(at: 0.5))
            let frame = try XCTUnwrap(geometry.frame("puddle"))
            XCTAssertLessThanOrEqual(frame.maxY, size.height)
        }
    }

}
