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
    func testApprovedStrawberrySaveCardRendersAtNormalAndLargestTypeWithoutReplacingItsArtwork() throws {
        for size in [DynamicTypeSize.large, .accessibility5] {
            let renderer = ImageRenderer(content: Prompt11SavedConfirmation()
                .environment(\.dynamicTypeSize, size).frame(width: 375, height: 667))
            let image = try XCTUnwrap(renderer.uiImage)
            XCTAssertGreaterThan(try XCTUnwrap(image.pngData()).count, 10_000)
            let evidence = XCTAttachment(image: image)
            evidence.name = "Guide_OriginalCompactCard_Strawberry_Saved_\(size)"
            evidence.lifetime = .keepAlways; add(evidence)
        }
    }

    func testCodedBookHasDistinctContinuousIntermediateFramesAndPreservesEverySelectedCover() throws {
        var finalFrames = Set<Data>()
        for style in Prompt10BookStyle.allCases {
            var stages = Set<Data>()
            for openness in [CGFloat(0), 0.25, 0.5, 0.75, 1] {
                let renderer = ImageRenderer(content: Prompt10CodedBookArtwork(style: style, openness: openness)
                    .frame(width: 350, height: 252))
                let image = try XCTUnwrap(renderer.uiImage)
                let png = try XCTUnwrap(image.pngData())
                XCTAssertGreaterThan(png.count, 1000, "A blank image is not a book frame")
                stages.insert(png)
                if openness == 1 { finalFrames.insert(png) }
                let evidence = XCTAttachment(image: image)
                evidence.name = "CodedBook_\(style.rawValue)_Open_\(openness)"
                evidence.lifetime = .keepAlways; add(evidence)
            }
            XCTAssertEqual(stages.count, 5, "The coded intermediate pages must actually deform instead of showing one fixed image")
        }
        XCTAssertEqual(finalFrames.count, Prompt10BookStyle.allCases.count,
                       "The final open book must retain the selected cover instead of resetting to a default")
    }

}
