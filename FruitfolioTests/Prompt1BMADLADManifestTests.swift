import XCTest
@testable import Fruitfolio

final class Prompt1BMADLADManifestTests: XCTestCase {
    private func manifest(file: String = "MADLAD400.gguf", hash: String = String(repeating: "a", count: 64)) -> FruitfolioMADLADManifest {
        FruitfolioMADLADManifest(modelFile: file, sha256: hash,
            sourceRepository: "google/madlad400-3b-mt", sourceRevision: String(repeating: "b", count: 40),
            architecture: "t5", tokenizer: "embedded-sentencepiece", supportedLanguageTags: ["en", "es"],
            contextLength: 512, maximumOutputTokens: 256)
    }
    private func integer(_ value: UInt64, bytes: Int = 8) -> Data {
        Data((0..<bytes).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) })
    }
    private func ggufString(_ text: String) -> Data {
        integer(UInt64(text.utf8.count)) + Data(text.utf8)
    }
    private func header(_ entries: [(String, UInt64, Data)], version: UInt64 = 3) -> Data {
        var data = Data("GGUF".utf8) + integer(version, bytes: 4) + integer(0) + integer(UInt64(entries.count))
        for (key, type, value) in entries {
            data += ggufString(key) + integer(type, bytes: 4) + value
        }
        return data
    }
    private func verifyHeader(_ data: Data) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try data.write(to: url)
        try manifest().verifyExecutableMetadata(at: url)
    }

    func testHeaderPreflightRequiresActualT5ArchitectureAndTokenizer() throws {
        let architecture = ("general.architecture", UInt64(8), ggufString("t5"))
        let tokenizer = ("tokenizer.ggml.model", UInt64(8), ggufString("t5"))
        XCTAssertNoThrow(try verifyHeader(header([architecture, tokenizer])))
        XCTAssertNoThrow(try verifyHeader(header([architecture, tokenizer], version: 2)))
        for entries in [[], [architecture], [tokenizer],
                        [("general.architecture", UInt64(8), ggufString("qwen2")), tokenizer],
                        [architecture, ("tokenizer.ggml.model", UInt64(8), ggufString("llama"))],
                        [architecture, tokenizer, architecture],
                        [("general.architecture", UInt64(4), integer(5, bytes: 4)), tokenizer]] {
            XCTAssertThrowsError(try verifyHeader(header(entries))) {
                XCTAssertEqual($0 as? FruitfolioTranslationError, .incompatibleModel)
            }
        }
        // A metadata-only fixture is not a model and does not prove inference.
    }

    func testHeaderPreflightSkipsVocabularyArraysWithoutLosingFollowingMetadata() throws {
        let vocabulary = integer(8, bytes: 4) + integer(3) + ggufString("<pad>") + ggufString("é") + ggufString("<2es>")
        let scores = integer(6, bytes: 4) + integer(3) + Data(repeating: 0, count: 12)
        let data = header([
            ("tokenizer.ggml.tokens", 9, vocabulary),
            ("general.name", 8, ggufString("test fixture only")),
            ("tokenizer.ggml.scores", 9, scores),
            ("general.architecture", 8, ggufString("t5")),
            ("tokenizer.ggml.model", 8, ggufString("t5"))])
        XCTAssertNoThrow(try verifyHeader(data))
        for length in [0, 4, 12, 23, data.count - 1] {
            XCTAssertThrowsError(try verifyHeader(Data(data.prefix(length))))
        }
    }

    func testHeaderPreflightRejectsUnsupportedAndUnboundedMetadata() throws {
        let valid: [(String, UInt64, Data)] = [
            ("general.architecture", 8, ggufString("t5")),
            ("tokenizer.ggml.model", 8, ggufString("t5"))]
        let invalidValues: [(String, UInt64, Data)] = [
            ("oversized.string", 8, integer(UInt64.max)),
            ("oversized.array", 9, integer(8, bytes: 4) + integer(UInt64.max)),
            ("nested.array", 9, integer(9, bytes: 4) + integer(1)),
            ("unknown.type", 99, Data())]
        for value in invalidValues {
            XCTAssertThrowsError(try verifyHeader(header(valid + [value])))
        }
        XCTAssertThrowsError(try verifyHeader(header(valid, version: 1)))
        XCTAssertThrowsError(try verifyHeader(Data("GGUF".utf8) + integer(3, bytes: 4) + integer(0) + integer(UInt64.max)))
        XCTAssertThrowsError(try verifyHeader(header([(String(repeating: "k", count: 1025), 8, ggufString("x"))] + valid)))
    }

    func testCancelledHeaderPreflightCannotAcceptCompatibleMetadata() async throws {
        let data = header([("general.architecture", 8, ggufString("t5")), ("tokenizer.ggml.model", 8, ggufString("t5"))])
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try data.write(to: url)
        let config = manifest()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            XCTAssertThrowsError(try config.verifyExecutableMetadata(at: url)) { XCTAssertTrue($0 is CancellationError) }
        }
        try await task.value
    }

    func testManifestLoaderDistinguishesMissingMalformedOversizedAndInvalidResources() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertThrowsError(try FruitfolioMADLADManifest.load(at: url)) {
            XCTAssertEqual($0 as? FruitfolioTranslationError, .resourcesMissing)
        }
        for data in [Data(), Data("not JSON".utf8), try JSONEncoder().encode(manifest(hash: "invalid"))] {
            try data.write(to: url)
            XCTAssertThrowsError(try FruitfolioMADLADManifest.load(at: url)) {
                XCTAssertEqual($0 as? FruitfolioTranslationError, .invalidManifest)
            }
        }
        let encoded = try JSONEncoder().encode(manifest())
        try (encoded + Data(repeating: 32, count: 65_536)).write(to: url)
        XCTAssertThrowsError(try FruitfolioMADLADManifest.load(at: url)) {
            XCTAssertEqual($0 as? FruitfolioTranslationError, .invalidManifest)
        }
        // The inclusive resource boundary accepts valid JSON plus whitespace.
        try (encoded + Data(repeating: 32, count: 65_536 - encoded.count)).write(to: url)
        XCTAssertEqual(try FruitfolioMADLADManifest.load(at: url), manifest())
        try encoded.write(to: url)
        XCTAssertEqual(try FruitfolioMADLADManifest.load(at: url), manifest())
    }

    func testCancelledManifestLoaderCannotAcceptValidResources() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try JSONEncoder().encode(manifest()).write(to: url)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            XCTAssertThrowsError(try FruitfolioMADLADManifest.load(at: url)) { XCTAssertTrue($0 is CancellationError) }
        }
        try await task.value
    }

    func testAbsentModelFileReportsMissingResourcesInsteadOfAnOpaqueFileError() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try manifest().verifyModel(at: url)) {
            XCTAssertEqual($0 as? FruitfolioTranslationError, .resourcesMissing)
        }
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
    func testActualNativeRuntimeRecoversFromMissingAndMalformedResourcesWithoutFakeOutput() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        let url = directory.appendingPathComponent("MADLAD400.manifest.json")
        let cases: [(Data?, FruitfolioTranslationError)] = [
            (nil, .resourcesMissing), (Data("not JSON".utf8), .invalidManifest),
            (try JSONEncoder().encode(manifest()), .resourcesMissing)]
        for (data, expected) in cases {
            if let data { try data.write(to: url) }
            do {
                _ = try await runtime.translate("source text", targetTag: "es")
                XCTFail("Missing/invalid resources cannot produce a translation")
            } catch { XCTAssertEqual(error as? FruitfolioTranslationError, expected) }
            await runtime.releaseResources()
        }
    }

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
