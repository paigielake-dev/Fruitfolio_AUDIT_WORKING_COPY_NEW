import XCTest
import UIKit
import ImageIO
@testable import Fruitfolio

final class Prompt1BImagePreparationTests: XCTestCase {
    func testInvalidBytesAreRejectedBeforePersistence() async {
        do {
            _ = try await Prompt10ImagePreparation.prepare(Data([0, 1, 2, 3]))
            XCTFail("Arbitrary bytes must not be accepted as a photo")
        } catch { XCTAssertTrue(error is Prompt10ImagePreparationError) }
    }

    @MainActor
    func testLargeImportedImageIsDecodedAndBounded() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 1000)).image { context in
            UIColor.blue.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 3000, height: 1000))
        }
        let input = try XCTUnwrap(image.pngData())
        let result = try await Prompt10ImagePreparation.prepare(input)
        let decoded = try XCTUnwrap(UIImage(data: result)?.cgImage)
        XCTAssertLessThanOrEqual(max(decoded.width, decoded.height), 2048)
        XCTAssertEqual(Double(decoded.width) / Double(decoded.height), 3, accuracy: 0.01)
    }
}
