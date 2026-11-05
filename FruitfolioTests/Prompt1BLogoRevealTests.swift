import XCTest
@testable import Fruitfolio

final class Prompt1BLogoRevealTests: XCTestCase {
    func testRevealOriginStaysRegisteredToLogoAcrossViewportsAndProgress() {
        for size in [CGSize(width: 280, height: 346), CGSize(width: 644, height: 795)] {
            let initial = Prompt04LogoRevealGeometry.metrics(size: size, progress: 0)
            for progress: CGFloat in [0.01, 0.25, 0.5, 0.9, 1] {
                let metrics = Prompt04LogoRevealGeometry.metrics(size: size, progress: progress)
                XCTAssertEqual(metrics.center, initial.center)
                XCTAssertGreaterThan(metrics.diameter, initial.diameter)
                XCTAssertEqual(metrics.center.x / size.width, 335.0 / 644, accuracy: 0.0001)
                XCTAssertEqual(metrics.center.y / size.height, 321.0 / 795, accuracy: 0.0001)
            }
        }
    }

    func testCompletedMaskCoversEntireCanvasAndInvalidInputsAreSafe() {
        XCTAssertEqual(Prompt04LogoRevealGeometry.metrics(size: CGSize(width: 644, height: 795), progress: 1).finalCoverage, 1)
        XCTAssertEqual(Prompt04LogoRevealGeometry.metrics(size: .zero, progress: 1).diameter, 0)
        XCTAssertEqual(Prompt04LogoRevealGeometry.metrics(size: CGSize(width: 100, height: 100), progress: .nan).progress, 0)
    }
}
