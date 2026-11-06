import Foundation
import XCTest
@testable import Fruitfolio

#if DEBUG && canImport(llama)
/// These deterministic, UNTRAINED tensors exercise the native T5 graph only.
/// No official MADLAD weights, translation or clinical accuracy is asserted.
final class Prompt1BT5ExecutionContractTests: XCTestCase {
    func testActualEncoderDecoderRejectEmptyOutputAndReleaseReloadBothT5Graphs() async throws {
        for gated in [false, true] {
            let directory = try SyntheticT5Contract.write(gated: gated)
            defer { try? FileManager.default.removeItem(at: directory) }
            let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
            for iteration in 1...2 {
                do {
                    _ = try await runtime.translate("fixture", targetTag: "de")
                    XCTFail("Untrained EOS-only graph cannot provide a translation")
                } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inferenceFailed) }
                let actual = await runtime.debugExecutionStatistics()
                XCTAssertEqual(actual.encoderCalls, iteration)
                XCTAssertEqual(actual.decoderCalls, iteration)
                XCTAssertEqual(actual.checkedBlockingCalls, iteration * 4)
                XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
                XCTAssertTrue(actual.resourcesLoaded)
                await runtime.releaseResources()
                await runtime.releaseResources()
                let released = await runtime.debugExecutionStatistics()
                XCTAssertFalse(released.resourcesLoaded)
            }
        }
    }

    func testUnsupportedLanguageAndInputBudgetNeverExecuteNativeGraph() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        for (text, tag, expected) in [
            ("fixture", "fr", FruitfolioTranslationError.unsupportedLanguage("fr")),
            (String(repeating: "fixture ", count: 100), "de", .inputTooLong)] {
            do { _ = try await runtime.translate(text, targetTag: tag); XCTFail("Expected rejection") }
            catch { XCTAssertEqual(error as? FruitfolioTranslationError, expected) }
        }
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 0)
        XCTAssertEqual(actual.decoderCalls, 0)
        XCTAssertEqual(actual.checkedBlockingCalls, 2)
        XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        await runtime.releaseResources()
    }

    @MainActor
    func testActualControlStateRejectsScientificLossAfterNativeOutput() async throws {
        let directory = try SyntheticT5Contract.write(gated: true, oneTokenThenEOS: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        let service = FruitfolioTranslationService(runtime: runtime)
        let state = FruitfolioControlTranslationState(service: service)
        let plain = FruitfolioControlTranslationState.Key(source: "confirm", language: .german)
        await state.resolve(plain, inferenceAllowed: true)
        XCTAssertEqual(state.presentation(for: plain).text, "fixture")
        XCTAssertEqual(state.presentation(for: plain).status, .machine)
        let scientific = FruitfolioControlTranslationState.Key(source: "LH 5.0 mIU/mL [1]", language: .german)
        await state.resolve(scientific, inferenceAllowed: true)
        XCTAssertEqual(state.presentation(for: scientific).text, scientific.source)
        XCTAssertEqual(state.presentation(for: scientific).status, .unavailable)
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 2)
        XCTAssertEqual(actual.decoderCalls, 4)
        XCTAssertEqual(actual.checkedBlockingCalls, 8)
        XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        await service.releaseResources()
    }

    func testActualNativeTokenOutputAndScientificEnvelopeRejection() async throws {
        let directory = try SyntheticT5Contract.write(gated: true, oneTokenThenEOS: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        // A hard-wired token followed by EOS tests output plumbing, NOT language.
        let output = try await runtime.translate("fixture", targetTag: "de")
        XCTAssertEqual(output, "fixture")
        let service = FruitfolioTranslationService(runtime: runtime)
        let source = "LH 5.0 mIU/mL; doi:10.1000/fixture [1]"
        do {
            _ = try await service.translateForDisplay(source, language: .german, preferCatalog: false)
            XCTFail("Native output that drops protected scientific/citation markers must be rejected")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
        let status = Prompt12AccountStatusText(identity: .init(provider: "Fixture **Provider**",
            email: "Fixture_Name@Example.invalid", username: "literal_name"))
        do {
            _ = try await service.translateForDisplay(status.source, language: .german,
                protectedLiterals: status.protectedLiterals, preferCatalog: false)
            XCTFail("Native output dropping identity fields must not be accepted")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 3)
        XCTAssertEqual(actual.decoderCalls, 6)
        await service.releaseResources()
        let released = await runtime.debugExecutionStatistics()
        XCTAssertFalse(released.resourcesLoaded)
    }

    func testActualDecoderBudgetRejectsPartialOutputAndClearsSequenceForRetry() async throws {
        let directory = try SyntheticT5Contract.write(gated: true, repeatToken: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        for iteration in 1...2 {
            do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Partial output is not success") }
            catch { XCTAssertEqual(error as? FruitfolioTranslationError, .truncatedOutput) }
            let actual = await runtime.debugExecutionStatistics()
            XCTAssertEqual(actual.encoderCalls, iteration)
            XCTAssertEqual(actual.decoderCalls, iteration * 8)
            XCTAssertEqual(actual.checkedBlockingCalls, 2 + iteration * 9)
            XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        }
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Cancelled loaded request") }
            catch { XCTAssertTrue(error is CancellationError) }
        }
        await task.value
        let unchanged = await runtime.debugExecutionStatistics()
        XCTAssertEqual(unchanged.encoderCalls, 2)
        XCTAssertEqual(unchanged.decoderCalls, 16)
        await runtime.releaseResources()
    }

    func testReloadReverifiesBytesRatherThanReusingReleasedModel() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Empty output") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inferenceFailed) }
        await runtime.releaseResources()
        let file = try FileHandle(forWritingTo: directory.appendingPathComponent("SYNTHETIC-UNTRAINED-NOT-MADLAD.gguf"))
        try file.seekToEnd()
        try file.write(contentsOf: Data([1]))
        try file.close()
        do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Mutated weights") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .checksumMismatch) }
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 1)
        XCTAssertEqual(actual.decoderCalls, 1)
        XCTAssertEqual(actual.checkedBlockingCalls, 4)
        XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        XCTAssertFalse(actual.resourcesLoaded)
    }

    func testCancellationBeforeLoadDoesNotAllocateOrExecuteNativeGraph() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Cancelled request") }
            catch { XCTAssertTrue(error is CancellationError) }
        }
        await task.value
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 0)
        XCTAssertEqual(actual.decoderCalls, 0)
        XCTAssertEqual(actual.checkedBlockingCalls, 0)
        XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        XCTAssertFalse(actual.resourcesLoaded)
    }
}

/// Self-contained GGUF v3 writer, confined to the test target and UUID temp dir.
/// The manifest's required repository/revision fields are FORMAT-CONTRACT INPUT,
/// not provenance: revision zeroes and explicit synthetic model name mark this
/// as NOT MADLAD. No fixture is shipped in app resources or used for localization.
private enum SyntheticT5Contract {
    static func integer(_ value: UInt64, bytes: Int = 8) -> Data {
        Data((0..<bytes).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) })
    }
    static func string(_ value: String) -> Data { integer(UInt64(value.utf8.count)) + Data(value.utf8) }
    static func floats(_ values: [Float]) -> Data {
        var data = Data()
        for value in values { data += integer(UInt64(value.bitPattern), bytes: 4) }
        return data
    }
    static func write(gated: Bool, repeatToken: Bool = false, oneTokenThenEOS: Bool = false) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("fruitfolio-SYNTHETIC-T5-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            let url = directory.appendingPathComponent("SYNTHETIC-UNTRAINED-NOT-MADLAD.gguf")
            try model(gated: gated, repeatToken: repeatToken, oneTokenThenEOS: oneTokenThenEOS).write(to: url)
            let file = try FileHandle(forReadingFrom: url)
            defer { try? file.close() }
            let hash = try FruitfolioModelChecksum.sha256(file: file)
            let manifest = FruitfolioMADLADManifest(modelFile: url.lastPathComponent, sha256: hash,
                sourceRepository: "google/madlad400-3b-mt", sourceRevision: String(repeating: "0", count: 40),
                architecture: "t5", tokenizer: "embedded-sentencepiece", supportedLanguageTags: ["de", "en"],
                contextLength: 64, maximumOutputTokens: 8)
            try JSONEncoder().encode(manifest).write(to: directory.appendingPathComponent("MADLAD400.manifest.json"))
            return directory
        } catch { try? FileManager.default.removeItem(at: directory); throw error }
    }
    static func model(gated: Bool, repeatToken: Bool, oneTokenThenEOS: Bool) -> Data {
        var metadata: [(String, UInt64, Data)] = []
        func text(_ key: String, _ value: String) { metadata.append((key, 8, string(value))) }
        func number(_ key: String, _ value: UInt64) { metadata.append((key, 4, integer(value, bytes: 4))) }
        text("general.architecture", "t5")
        text("general.name", "Fruitfolio SYNTHETIC UNTRAINED T5 CONTRACT - NOT MADLAD")
        number("general.file_type", 0)
        for (key, value) in [("context_length", 128), ("embedding_length", 32), ("block_count", 1),
                             ("decoder_block_count", 1), ("feed_forward_length", 64),
                             ("attention.head_count", 4), ("attention.head_count_kv", 4),
                             ("attention.key_length", 8), ("attention.value_length", 8),
                             ("attention.relative_buckets_count", 32), ("decoder_start_token_id", 0)] {
            number("t5." + key, UInt64(value))
        }
        metadata.append(("t5.attention.layer_norm_rms_epsilon", 6, floats([0.000001])))
        text("tokenizer.ggml.model", "t5")
        let tokens = ["<pad>", "</s>", "<unk>", "<2de>", "<2en>", "▁", "▁fixture"] +
            (0..<256).map { String(format: "<0x%02X>", $0) }
        var vocabulary = integer(8, bytes: 4) + integer(UInt64(tokens.count))
        for token in tokens { vocabulary += string(token) }
        metadata.append(("tokenizer.ggml.tokens", 9, vocabulary))
        metadata.append(("tokenizer.ggml.scores", 9,
                         integer(6, bytes: 4) + integer(UInt64(tokens.count)) + floats([Float](repeating: 0, count: tokens.count))))
        let types = [3, 3, 2, 4, 4, 1, 1] + [Int](repeating: 6, count: 256)
        var typeData = integer(5, bytes: 4) + integer(UInt64(types.count))
        for type in types { typeData += integer(UInt64(type), bytes: 4) }
        metadata.append(("tokenizer.ggml.token_type", 9, typeData))
        for (key, value) in [("eos_token_id", 1), ("padding_token_id", 0), ("unknown_token_id", 2)] {
            number("tokenizer.ggml." + key, UInt64(value))
        }
        for (key, value) in [("add_bos_token", false), ("add_eos_token", true), ("add_space_prefix", false)] {
            metadata.append(("tokenizer.ggml." + key, 7, Data([value ? 1 : 0])))
        }
        var tensors: [(String, [Int], [Float])] = []
        func tensor(_ name: String, _ dimensions: [Int], ones: Range<Int>? = nil, negatives: Range<Int>? = nil) {
            var values = [Float](repeating: 0, count: dimensions.reduce(1, *))
            if let ones { for index in ones { values[index] = 1 } }
            if let negatives { for index in negatives { values[index] = -1 } }
            tensors.append((name + ".weight", dimensions, values))
        }
        tensor("token_embd", [32, tokens.count], ones: repeatToken ? 0..<(32 * tokens.count) : 0..<32,
               negatives: oneTokenThenEOS ? 192..<224 : nil)
        // Either EOS or the same normal token wins deterministically. Neither
        // configuration contains learned linguistic knowledge or translations.
        tensor("output", [32, tokens.count], ones: (repeatToken || oneTokenThenEOS) ? 192..<224 : 32..<64,
               negatives: oneTokenThenEOS ? 32..<64 : nil)
        for side in ["enc", "dec"] {
            tensor(side + ".output_norm", [32], ones: 0..<32)
            let prefix = side + ".blk.0."
            tensor(prefix + "attn_norm", [32], ones: 0..<32)
            tensor(prefix + "attn_rel_b", [4, 32])
            for projection in ["q", "k", "v", "o"] { tensor(prefix + "attn_" + projection, [32, 32]) }
            if side == "dec" {
                tensor(prefix + "cross_attn_norm", [32], ones: 0..<32)
                for projection in ["q", "k", "v", "o"] { tensor(prefix + "cross_attn_" + projection, [32, 32]) }
            }
            tensor(prefix + "ffn_norm", [32], ones: 0..<32)
            tensor(prefix + "ffn_up", [32, 64])
            tensor(prefix + "ffn_down", [64, 32])
            if gated { tensor(prefix + "ffn_gate", [32, 64]) }
        }
        var data = Data("GGUF".utf8) + integer(3, bytes: 4) + integer(UInt64(tensors.count)) + integer(UInt64(metadata.count))
        for (key, type, value) in metadata { data += string(key) + integer(type, bytes: 4) + value }
        var payload = Data()
        for (name, dimensions, values) in tensors {
            data += string(name) + integer(UInt64(dimensions.count), bytes: 4)
            for dimension in dimensions { data += integer(UInt64(dimension)) }
            data += integer(0, bytes: 4) + integer(UInt64(payload.count)) // GGML F32.
            payload += floats(values)
            payload += Data(repeating: 0, count: (32 - payload.count % 32) % 32)
        }
        data += Data(repeating: 0, count: (32 - data.count % 32) % 32)
        return data + payload
    }
}
#endif
