import XCTest
@testable import Fruitfolio

final class Prompt1BGGUFResourceTests: XCTestCase {
    func testLFSPointerAndTruncatedMagicAreNotExecutableModelResources() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        for bytes in [Data("version https://git-lfs.github.com/spec/v1\n".utf8), Data("GGUF".utf8)] {
            try bytes.write(to: url)
            XCTAssertFalse(FruitfolioGGUFResource.isReadableModel(at: url))
        }
    }
    func testActualRestoredOrBundledModelHasValidResourceHeader() throws {
        let configured = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_MODEL_PATH"].map(URL.init(fileURLWithPath:))
        guard let url = configured ?? Bundle.main.url(forResource: "FruitfolioAI", withExtension: "gguf") else {
            throw XCTSkip("The actual model resource was not configured for this test target")
        }
        XCTAssertTrue(FruitfolioGGUFResource.isReadableModel(at: url), "A pointer is not a model resource")
        // Header presence alone does not prove successful model inference.
    }
}
