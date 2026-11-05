import XCTest
@testable import Fruitfolio

final class Prompt1BSpotlightGeometryTests: XCTestCase {
    func testHighlightTracksActualTargetAfterViewportOrButtonResize() throws {
        for size in [CGSize(width: 240, height: 320), CGSize(width: 393, height: 852)] {
            let viewport = CGRect(origin: .zero, size: size)
            let button = CGRect(x: size.width * 0.12, y: size.height * 0.25, width: size.width * 0.33, height: 70)
            let highlight = try XCTUnwrap(Prompt07SpotlightGeometry.highlight(target: button, viewport: viewport))
            XCTAssertEqual(highlight, button.insetBy(dx: -6, dy: -6))
            XCTAssertTrue(viewport.contains(highlight))
        }
    }
    func testEdgeHighlightClipsAndInvalidOrOffscreenFramesAreOmitted() throws {
        let viewport = CGRect(x: 0, y: 0, width: 200, height: 300)
        XCTAssertEqual(Prompt07SpotlightGeometry.highlight(target: CGRect(x: -2, y: 4, width: 80, height: 50), viewport: viewport),
                       CGRect(x: 0, y: 0, width: 84, height: 60))
        for target in [CGRect.zero, CGRect(x: 300, y: 10, width: 50, height: 50), CGRect(x: CGFloat.nan, y: 0, width: 50, height: 50)] {
            XCTAssertNil(Prompt07SpotlightGeometry.highlight(target: target, viewport: viewport))
        }
        XCTAssertNil(Prompt07SpotlightGeometry.highlight(target: nil, viewport: viewport))
    }
}
