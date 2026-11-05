import XCTest
@testable import Fruitfolio

final class Prompt1BBookMotionTests: XCTestCase {
    func testSameSourceBookMovesToCenterBeforeSettlingIntoCompleteFinalFrame() {
        let source = CGRect(x: 24, y: 340, width: 116, height: 142)
        let viewport = CGSize(width: 390, height: 750)
        XCTAssertEqual(Prompt10BookMotion.frame(from: source, in: viewport, progress: 0), source)
        let centered = Prompt10BookMotion.frame(from: source, in: viewport, progress: 0.5)
        let final = Prompt10BookMotion.finalFrame(in: viewport)
        XCTAssertEqual(centered.midX, final.midX)
        XCTAssertEqual(centered.midY, final.midY)
        XCTAssertEqual(Prompt10BookMotion.frame(from: source, in: viewport, progress: 1), final)
        XCTAssertLessThan(abs(Prompt10BookMotion.frame(from: source, in: viewport, progress: 0.500001).width - centered.width), 0.01)
    }
    func testWholeBookRemainsInsideSmallAndLargeViewportsWithoutPageZoom() {
        for size in [CGSize(width: 320, height: 480), CGSize(width: 1024, height: 768)] {
            let frame = Prompt10BookMotion.finalFrame(in: size)
            XCTAssertGreaterThanOrEqual(frame.minX, 0)
            XCTAssertGreaterThanOrEqual(frame.minY, 0)
            XCTAssertLessThanOrEqual(frame.maxX, size.width)
            XCTAssertLessThanOrEqual(frame.maxY, size.height)
        }
        XCTAssertEqual(Prompt10BookMotion.unit(.nan), 0)
        XCTAssertEqual(Prompt10BookMotion.unit(-1), 0)
        XCTAssertEqual(Prompt10BookMotion.unit(4), 1)
    }
}
