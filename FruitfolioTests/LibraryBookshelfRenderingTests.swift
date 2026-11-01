import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class LibraryBookshelfRenderingTests: XCTestCase {
    func testEmptyAndPopulatedLibraryUseIdenticalApprovedShelfPixels() throws {
        func render(_ empty: Bool) throws -> Data {
            let renderer = ImageRenderer(content: Prompt10LibraryHero(isEmpty: empty).frame(width: 375, height: 210))
            let image = try XCTUnwrap(renderer.uiImage)
            let data = try XCTUnwrap(image.pngData())
            XCTAssertGreaterThan(data.count, 10_000, "A blank render cannot verify the original watercolor shelf")
            return data
        }
        XCTAssertEqual(try render(true), try render(false), "Saved books must never add duplicate art to the decorative shelf")
    }
}
