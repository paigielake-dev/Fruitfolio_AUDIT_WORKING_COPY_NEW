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
    func testStreamingDigestAcceptsExactBytesAndRejectsSameHeaderMutation() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("GGUFfixture".utf8).write(to: url)
        let config = manifest(hash: "006770b014ffd382cd06d5148bb662d33f0b7448a316d85bfd415356b5f2aef1")
        XCTAssertNoThrow(try config.verifyModel(at: url))
        try Data("GGUFfixturf".utf8).write(to: url)
        XCTAssertThrowsError(try config.verifyModel(at: url)) { error in
            XCTAssertEqual(error as? FruitfolioTranslationError, .checksumMismatch)
        }
        // Hash acceptance does not establish executable T5 compatibility.
    }
    func testDigestStreamsAcrossMegabyteReadBoundaryAgainstIndependentKnownValue() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        var data = Data("GGUF".utf8)
        let block = Data((0...255).map { UInt8($0) })
        for _ in 0..<5000 { data.append(block) }
        data.append(Data("end".utf8))
        try data.write(to: url)
        XCTAssertNoThrow(try manifest(hash: "d10bf46e57ddb610a60aad1bf8cce6f9a6c4dd54360485270ac16ce57d2918a2").verifyModel(at: url))
    }
    func testCancelledVerificationCannotAcceptEvenCorrectBytes() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("GGUFfixture".utf8).write(to: url)
        let config = manifest(hash: "006770b014ffd382cd06d5148bb662d33f0b7448a316d85bfd415356b5f2aef1")
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            XCTAssertThrowsError(try config.verifyModel(at: url)) { error in
                XCTAssertTrue(error is CancellationError)
            }
        }
        try await task.value
    }

    #if canImport(llama)
    func testNativeMADLADRejectsActualAssistantArchitectureAfterChecksumVerification() async throws {
        guard let path = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_MODEL_PATH"],
              FileManager.default.fileExists(atPath: path) else {
            throw XCTSkip("Actual assistant model required for negative architecture verification")
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        // Deliberately wrong architecture: this fixture must never produce MT.
        try FileManager.default.createSymbolicLink(at: directory.appendingPathComponent("MADLAD400.gguf"),
                                                  withDestinationURL: URL(fileURLWithPath: path))
        let config = manifest(hash: "74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db")
        try JSONEncoder().encode(config).write(to: directory.appendingPathComponent("MADLAD400.manifest.json"))
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        await runtime.releaseResources()
        await runtime.releaseResources()
        do {
            _ = try await runtime.translate("test-only source", targetTag: "es")
            XCTFail("Assistant architecture must never be substituted for MADLAD")
        } catch {
            XCTAssertEqual(error as? FruitfolioTranslationError, .incompatibleModel)
        }
        await runtime.releaseResources()
    }
    #endif

}
