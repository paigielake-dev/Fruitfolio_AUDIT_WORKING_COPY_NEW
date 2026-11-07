import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

final class FounderOverrideIntegrationTests: XCTestCase {
    func testSharedModalBlurMatchesFounderApprovedCanonicalNonTourTreatment() {
        XCTAssertEqual(FruitfolioModalBlurSpec.radius, 8)
        XCTAssertEqual(FruitfolioModalBlurSpec.contentScale, 0.985, accuracy: 0.0001)
        XCTAssertEqual(FruitfolioModalBlurSpec.dimOpacity, 0.14, accuracy: 0.0001)
        XCTAssertEqual(FruitfolioModalBlurSpec.animationDuration, 0.20, accuracy: 0.0001)
        XCTAssertEqual(FruitfolioModalBlurSpec.reducedMotionDuration, 0.12, accuracy: 0.0001)
    }

    @MainActor
    func testSharedModalBackdropRendersOneNeutralDimInsteadOfAFeatureTint() throws {
        let renderer = ImageRenderer(content: ZStack {
            Color.white
            FruitfolioModalBackdrop()
        }.frame(width: 4, height: 4))
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        var pixel = [UInt8](repeating: 0, count: 4)
        try pixel.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(data: bytes.baseAddress, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        XCTAssertLessThanOrEqual(abs(Int(pixel[0]) - Int(pixel[1])), 1)
        XCTAssertLessThanOrEqual(abs(Int(pixel[1]) - Int(pixel[2])), 1)
        XCTAssertGreaterThan(pixel[0], 200)
        XCTAssertLessThan(pixel[0], 250)
        XCTAssertEqual(pixel[3], 255)
    }

    func testReducedMotionModalNeverScalesBackground() {
        XCTAssertEqual(FruitfolioModalBlurSpec.scale(active: true, reduceMotion: true), 1)
        XCTAssertEqual(FruitfolioModalBlurSpec.scale(active: false, reduceMotion: true), 1)
        XCTAssertEqual(FruitfolioModalBlurSpec.scale(active: false, reduceMotion: false), 1)
        XCTAssertEqual(FruitfolioModalBlurSpec.scale(active: true, reduceMotion: false), 0.985, accuracy: 0.0001)
    }

    func testPrompt40IsNotRepresentedAsANewProductionPass() {
        XCTAssertFalse(Prompt53ScreenInventory.requiredRoutes.contains("decoration"))
    }

    func testSavedSelectionCanonicalColors() {
        XCTAssertEqual(Prompt55AskSelectionStyle.textHex, "#800000")
        XCTAssertEqual(Prompt55AskSelectionStyle.selectedHighlightHex, "#F4C7C7")
        XCTAssertEqual(Prompt55AskSelectionStyle.sourcesHeading, "sources ˚ ☆ ‧ ₊")
    }
}
