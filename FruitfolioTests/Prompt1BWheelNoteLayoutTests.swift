import XCTest
@testable import Fruitfolio

final class Prompt1BWheelNoteLayoutTests: XCTestCase {
    func testTapedNotePreservesNativeRatioAndStaysInsideEveryWheelQuadrant() {
        for size in [CGSize(width: 90, height: 120), CGSize(width: 320, height: 320), CGSize(width: 430, height: 430)] {
            for fraction in stride(from: 0.0, through: 1, by: 0.1) {
                let frame = Prompt18WheelNoteLayout.frame(in: size, fraction: fraction, idealWidth: 340)
                XCTAssertGreaterThanOrEqual(frame.minX, 0)
                XCTAssertGreaterThanOrEqual(frame.minY, 0)
                XCTAssertLessThanOrEqual(frame.maxX, size.width + 0.001)
                XCTAssertLessThanOrEqual(frame.maxY, size.height + 0.001)
                XCTAssertEqual(frame.height / frame.width, 499.0 / 497.0, accuracy: 0.000001)
            }
        }
    }
    func testCollapsedOrInvalidHostDoesNotCreateNegativeOrNonfiniteGeometry() {
        for size in [CGSize.zero, CGSize(width: -20, height: 80), CGSize(width: Double.nan, height: Double.infinity)] {
            let frame = Prompt18WheelNoteLayout.frame(in: size, fraction: .nan)
            XCTAssertTrue(frame.origin.x.isFinite && frame.origin.y.isFinite && frame.width.isFinite && frame.height.isFinite)
            XCTAssertGreaterThanOrEqual(frame.width, 0); XCTAssertGreaterThanOrEqual(frame.height, 0)
        }
    }
}
