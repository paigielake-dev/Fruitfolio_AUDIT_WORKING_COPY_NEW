import XCTest
@testable import Fruitfolio

final class Prompt1BMADLADManifestTests: XCTestCase {
    private func manifest(file: String = "MADLAD400.gguf", hash: String = String(repeating: "a", count: 64)) -> FruitfolioMADLADManifest {
        FruitfolioMADLADManifest(modelFile: file, sha256: hash,
            sourceRepository: "google/madlad400-3b-mt", sourceRevision: String(repeating: "b", count: 40),
            architecture: "t5", tokenizer: "embedded-sentencepiece", supportedLanguageTags: ["en", "es"],
            contextLength: 512, maximumOutputTokens: 256)
    }
    func testUnverifiedDigestAndEscapingResourcePathsAreRejected() {
        XCTAssertThrowsError(try manifest(file: "../model.gguf").validate())
        XCTAssertThrowsError(try manifest(hash: "unverified").validate())
        XCTAssertNoThrow(try manifest().validate())
    }
    func testLFSPointerIsNotAcceptedAsAnExecutableModel() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("version https://git-lfs.github.com/spec/v1\n".utf8).write(to: url)
        XCTAssertThrowsError(try manifest().verifyModel(at: url)) { error in
            XCTAssertEqual(error as? FruitfolioTranslationError, .incompatibleModel)
        }
    }
}
