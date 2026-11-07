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

extension Prompt1BWheelNoteLayoutTests {
    func testMeasuredAnnotationLeadersReachActualIntervalBoundaryWithoutCrossingWheelInterior() throws {
        for side in [90.0, 320, 430] {
            let wheel = CGRect(x: 23, y: 180, width: side, height: side)
            let radius = min(side * 0.66, 286) / 2
            for above in [false, true] {
                let callout = CGRect(x: 25, y: above ? 5 : wheel.maxY + 12, width: side / 3, height: 160)
                for fraction in stride(from: 0.0, through: 1, by: 0.025) {
                    let arrow = try XCTUnwrap(Prompt18WheelAnnotationGeometry.arrow(callout: callout,
                        wheel: wheel, fraction: fraction, above: above))
                    XCTAssertEqual(hypot(arrow.tip.x - wheel.midX, arrow.tip.y - wheel.midY), radius, accuracy: 0.000001)
                    XCTAssertEqual(arrow.secondBend.y, arrow.tip.y)
                    XCTAssertGreaterThan(abs(arrow.secondBend.x - wheel.midX), radius)
                    XCTAssertEqual(arrow.firstBend.x, arrow.secondBend.x)
                    XCTAssertEqual(arrow.tail.x, callout.midX)
                    XCTAssertTrue(above ? arrow.tail.y > callout.maxY : arrow.tail.y < callout.minY)
                    for point in [arrow.tail, arrow.firstBend, arrow.secondBend, arrow.tip, arrow.left, arrow.right] {
                        XCTAssertTrue(point.x.isFinite && point.y.isFinite)
                    }
                }
            }
        }
    }

    func testUnavailableAnnotationGeometryCannotInventAnArrow() {
        let valid = CGRect(x: 0, y: 0, width: 320, height: 320)
        for fraction in [Double.nan, .infinity, -0.1, 1.1] {
            XCTAssertNil(Prompt18WheelAnnotationGeometry.arrow(callout: valid, wheel: valid,
                fraction: fraction, above: true))
        }
        XCTAssertNil(Prompt18WheelAnnotationGeometry.arrow(callout: .zero, wheel: valid, fraction: 0.5, above: true))
        XCTAssertNil(Prompt18WheelAnnotationGeometry.arrow(callout: valid, wheel: .zero, fraction: 0.5, above: true))
    }
}
