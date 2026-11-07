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

    func testActualT5DummyPrefixAndLanguageTagTypesAcceptUnicodeInput() async throws {
        for prefix in [false, true] {
            for tagType in [3, 4] { // Actual GGUF CONTROL / USER_DEFINED vocabulary types.
                let directory = try SyntheticT5Contract.write(gated: true, oneTokenThenEOS: true,
                    addSpacePrefix: prefix, languageTagType: tagType)
                defer { try? FileManager.default.removeItem(at: directory) }
                let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
                let result = try await runtime.translate("  épreuve 中\n\tfixture  ", targetTag: "de")
                XCTAssertEqual(result, "fixture", "Deterministic token plumbing, not a translation")
                let actual = await runtime.debugExecutionStatistics()
                XCTAssertEqual(actual.encoderCalls, 1)
                XCTAssertEqual(actual.decoderCalls, 2)
                XCTAssertEqual(actual.checkedBlockingCalls, 5)
                XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
                await runtime.releaseResources()
            }
        }
    }

    func testManifestUnsupportedLanguageAvoidsNativeAllocation() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        do { _ = try await runtime.translate("fixture", targetTag: "fr"); XCTFail("Unsupported tag") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .unsupportedLanguage("fr")) }
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 0)
        XCTAssertEqual(actual.decoderCalls, 0)
        XCTAssertEqual(actual.checkedBlockingCalls, 0)
        XCTAssertFalse(actual.resourcesLoaded)
        await runtime.releaseResources()
    }

    func testInputBudgetRejectsBeforeEncoderDecoderExecution() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        do {
            _ = try await runtime.translate(String(repeating: "fixture ", count: 100), targetTag: "de")
            XCTFail("Over-budget input")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inputTooLong) }
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 0)
        XCTAssertEqual(actual.decoderCalls, 0)
        XCTAssertEqual(actual.checkedBlockingCalls, 1)
        XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        XCTAssertTrue(actual.modelLoaded)
        XCTAssertFalse(actual.resourcesLoaded)
        do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Empty synthetic output") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inferenceFailed) }
        let retried = await runtime.debugExecutionStatistics()
        XCTAssertEqual(retried.encoderCalls, 1)
        XCTAssertEqual(retried.decoderCalls, 1)
        XCTAssertEqual(retried.checkedBlockingCalls, 4, "The already loaded model must be reused")
        XCTAssertTrue(retried.resourcesLoaded)
        await runtime.releaseResources()
        let released = await runtime.debugExecutionStatistics()
        XCTAssertFalse(released.modelLoaded)
        XCTAssertFalse(released.resourcesLoaded)
    }

    func testReleaseOwnsUnsharedQueuedAndBetweenParagraphNativeWork() async throws {
        for holdAfterNative in [false, true] {
            let directory = try SyntheticT5Contract.write(gated: false, oneTokenThenEOS: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
            if !holdAfterNative {
                let warmed = try await runtime.translate("fixture", targetTag: "de")
                XCTAssertEqual(warmed, "fixture")
            }
            let gate = Prompt1BNativeTranslationGate(runtime: runtime, holdAfterNative: holdAfterNative)
            let service = FruitfolioTranslationService(runtime: gate)
            let source = "fixture\n\nfixture"
            let protection = Array(repeating: "brand", count: 65) // Unshared metadata-overflow path.
            let pending = Task { try await service.translate(source, language: .german,
                protectedLiterals: protection, preferCatalog: false) }
            let deadline = ContinuousClock.now.advanced(by: .seconds(3))
            var ready = false
            while ContinuousClock.now < deadline {
                let active = await service.debugInFlightStatistics()
                let native = await runtime.debugExecutionStatistics()
                if active.unshared == 1, await gate.callCount() == 1, native.encoderCalls == 1 {
                    ready = true; break
                }
                try? await Task.sleep(for: .milliseconds(1))
            }
            XCTAssertTrue(ready)
            await service.releaseResources()
            let released = await runtime.debugExecutionStatistics()
            XCTAssertFalse(released.modelLoaded)
            XCTAssertFalse(released.resourcesLoaded)
            await gate.unblockAll()
            do { _ = try await pending.value; XCTFail("Released unshared operation") }
            catch { XCTAssertTrue(error is CancellationError) }
            let stopped = await runtime.debugExecutionStatistics()
            XCTAssertEqual(stopped.encoderCalls, 1, "No cancelled queued reload or second-paragraph decode")
            XCTAssertFalse(stopped.modelLoaded)
            let fresh = try await service.translate(source, language: .german,
                protectedLiterals: protection, preferCatalog: false)
            XCTAssertEqual(fresh, source)
            let actual = await runtime.debugExecutionStatistics()
            XCTAssertEqual(actual.encoderCalls, 3)
            XCTAssertEqual(actual.decoderCalls, 6)
            XCTAssertEqual(actual.checkedBlockingCalls, 13)
            XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
            let finished = await service.debugInFlightStatistics()
            XCTAssertEqual(finished.unshared, 0)
            await service.releaseResources()
        }
    }

    func testSharedRequestsUseOneActualNativeDecodeAndReleaseCancelsQueuedReload() async throws {
        let directory = try SyntheticT5Contract.write(gated: false, oneTokenThenEOS: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        let gate = Prompt1BNativeTranslationGate(runtime: runtime)
        let service = FruitfolioTranslationService(runtime: gate)
        func waitFor(_ waiters: Int, calls: Int) async {
            let deadline = ContinuousClock.now.advanced(by: .seconds(3))
            while ContinuousClock.now < deadline {
                let active = await service.debugInFlightStatistics()
                if active.requests == 1, active.waiters == waiters, await gate.callCount() == calls { return }
                try? await Task.sleep(for: .milliseconds(1))
            }
            XCTFail("Timed out waiting for queued native request owners")
            await gate.unblockAll()
        }
        let first = (0..<8).map { _ in Task {
            try await service.translateForDisplay("fixture", language: .german, preferCatalog: false)
        } }
        await waitFor(8, calls: 1)
        await gate.unblockAll()
        for task in first {
            let result = try await task.value
            XCTAssertEqual(result.text, "fixture")
            XCTAssertEqual(result.origin, .machine)
        }
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 1)
        XCTAssertEqual(actual.decoderCalls, 2)
        XCTAssertTrue(actual.resourcesLoaded)
        await gate.rearm()
        let pending = (0..<2).map { _ in Task {
            try await service.translate("fixture", language: .german, preferCatalog: false)
        } }
        await waitFor(2, calls: 2)
        await service.releaseResources()
        let released = await runtime.debugExecutionStatistics()
        XCTAssertFalse(released.modelLoaded)
        XCTAssertFalse(released.resourcesLoaded)
        await gate.unblockAll()
        for task in pending {
            do { _ = try await task.value; XCTFail("Release cancelled queued shared inference") }
            catch { XCTAssertTrue(error is CancellationError) }
        }
        let cancelled = await runtime.debugExecutionStatistics()
        XCTAssertEqual(cancelled.encoderCalls, 1, "Cancelled queued work must not reload or decode")
        XCTAssertFalse(cancelled.modelLoaded)
        let next = try await service.translate("fixture", language: .german, preferCatalog: false)
        XCTAssertEqual(next, "fixture")
        let retried = await runtime.debugExecutionStatistics()
        XCTAssertEqual(retried.encoderCalls, 2)
        XCTAssertEqual(retried.decoderCalls, 4)
        XCTAssertEqual(retried.checkedBlockingCalls, 10)
        XCTAssertEqual(retried.mainThreadBlockingCalls, 0)
        await service.releaseResources()
    }

    func testT5ReleaseAndReloadPreserveSeparateLoadedAskModelDuringConcurrentRequests() async throws {
        let modelURL = try XCTUnwrap(ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_MODEL_PATH"]
            .map { URL(fileURLWithPath: $0) } ?? Bundle.main.url(forResource: "FruitfolioAI", withExtension: "gguf"))
        let ask = LlamaFruitfolioLanguageModel(modelURL: modelURL)
        // Explicitly synthetic source text: this is a resource-ownership test,
        // not a clinical evidence package or a translation-quality assessment.
        let text = "This is a synthetic runtime ownership fixture, not medical evidence."
        let question = "what does the runtime ownership fixture say?"
        let note = FruitfolioResearchNoteChunk(chunkID: "ownership_note", researchTopicID: "ownership_fixture",
            heading: "runtime ownership fixture", subheading: nil, text: text,
            sourceIDs: [], semanticTags: [], domainTags: [])
        let evidence = FruitfolioEvidencePacket(normalizedQuestion: question,
            researchNoteChunks: [note], sourceChunks: [],
            claimEvidenceMap: [.init(claim: .init(id: "ownership_claim", text: question),
                                     noteChunkIDs: [note.chunkID], sourceChunkIDs: [])],
            sourceRecords: [], safetyClassification: .init(level: .normal, matchedPatterns: []),
            permittedContext: nil, contentVersion: "synthetic-resource-ownership-only")
        let warmed = try await ask.generateDraft(question: question, evidence: evidence)
        XCTAssertNotNil(FruitfolioGeneratedDraftValidator.validatedText(draft: warmed, evidence: evidence))
        let directory = try SyntheticT5Contract.write(gated: false, oneTokenThenEOS: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let translation = FruitfolioMADLADRuntime(resourceDirectory: directory)
        async let draft = ask.generateDraft(question: question, evidence: evidence)
        async let outputs: [String] = {
            var results: [String] = []
            for _ in 0..<8 {
                results.append(try await translation.translate("fixture", targetTag: "de"))
                await translation.releaseResources()
            }
            return results
        }()
        let (concurrent, translated) = try await (draft, outputs)
        XCTAssertEqual(concurrent, warmed)
        XCTAssertEqual(translated, Array(repeating: "fixture", count: 8))
        XCTAssertNotNil(FruitfolioGeneratedDraftValidator.validatedText(draft: concurrent, evidence: evidence))
        // Ask's model/context existed before every translation resource release.
        // A further actual decode must remain valid after all eight releases.
        let afterRelease = try await ask.generateDraft(question: question, evidence: evidence)
        XCTAssertEqual(afterRelease, warmed)
        await ask.releaseResources()
        let afterAskRelease = try await translation.translate("fixture", targetTag: "de")
        XCTAssertEqual(afterAskRelease, "fixture")
        let actual = await translation.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 9)
        XCTAssertEqual(actual.decoderCalls, 18)
        XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        await translation.releaseResources()
    }

    func testOversizedInputRejectsBeforeAllocatingItsTokenBufferAndCanRetry() async throws {
        let directory = try SyntheticT5Contract.write(gated: false, oneTokenThenEOS: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        for text in [String(repeating: "fixture ", count: 4096),
                     String(repeating: "🧬漢字 ", count: 4096)] {
            do { _ = try await runtime.translate(text, targetTag: "de"); XCTFail("Oversized input") }
            catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inputTooLong) }
            let rejected = await runtime.debugExecutionStatistics()
            XCTAssertEqual(rejected.largestTokenBuffer, 1, "Only the target-tag buffer may have been allocated")
            XCTAssertEqual(rejected.encoderCalls, 0)
            XCTAssertEqual(rejected.decoderCalls, 0)
            XCTAssertEqual(rejected.checkedBlockingCalls, 1)
            XCTAssertTrue(rejected.modelLoaded)
            XCTAssertFalse(rejected.resourcesLoaded)
        }
        let result = try await runtime.translate("fixture", targetTag: "de")
        XCTAssertEqual(result, "fixture")
        let retried = await runtime.debugExecutionStatistics()
        XCTAssertGreaterThan(retried.largestTokenBuffer, 1)
        XCTAssertLessThan(retried.largestTokenBuffer, 64)
        XCTAssertEqual(retried.encoderCalls, 1)
        XCTAssertEqual(retried.decoderCalls, 2)
        XCTAssertEqual(retried.mainThreadBlockingCalls, 0)
        await runtime.releaseResources()
    }

    func testModelOnlyReleaseRevalidatesChangedBytesBeforeReload() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        do {
            _ = try await runtime.translate(String(repeating: "fixture ", count: 100), targetTag: "de")
            XCTFail("Over-budget input")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inputTooLong) }
        let partial = await runtime.debugExecutionStatistics()
        XCTAssertTrue(partial.modelLoaded); XCTAssertFalse(partial.resourcesLoaded)
        await runtime.releaseResources()
        let released = await runtime.debugExecutionStatistics()
        XCTAssertFalse(released.modelLoaded); XCTAssertFalse(released.resourcesLoaded)
        let file = try FileHandle(forWritingTo: directory.appendingPathComponent("SYNTHETIC-UNTRAINED-NOT-MADLAD.gguf"))
        try file.seekToEnd(); try file.write(contentsOf: Data([1])); try file.close()
        do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Changed weights") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .checksumMismatch) }
        let rejected = await runtime.debugExecutionStatistics()
        XCTAssertEqual(rejected.checkedBlockingCalls, 1)
        XCTAssertFalse(rejected.modelLoaded); XCTAssertFalse(rejected.resourcesLoaded)
    }

    func testRejectedVocabularyTagCacheIsBoundedToResourceReleaseEpoch() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manifestURL = directory.appendingPathComponent("MADLAD400.manifest.json")
        var manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any])
        manifest["supportedLanguageTags"] = ["de", "en", "fr"]
        try JSONSerialization.data(withJSONObject: manifest).write(to: manifestURL)
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        for _ in 0..<2 {
            do { _ = try await runtime.translate("fixture", targetTag: "fr"); XCTFail("Missing actual vocabulary tag") }
            catch { XCTAssertEqual(error as? FruitfolioTranslationError, .unsupportedLanguage("fr")) }
        }
        let cached = await runtime.debugExecutionStatistics()
        XCTAssertEqual(cached.vocabularyPreflightCalls, 1)
        XCTAssertEqual(cached.successfulResourceVerifications, 1)
        XCTAssertEqual(cached.activeVocabularyOnlyModels, 0)
        XCTAssertEqual(cached.vocabularyPreflightMainThreadCalls, 0)
        XCTAssertEqual(cached.checkedBlockingCalls, 0)
        XCTAssertFalse(cached.modelLoaded); XCTAssertFalse(cached.resourcesLoaded)
        await runtime.releaseResources()
        do { _ = try await runtime.translate("fixture", targetTag: "fr"); XCTFail("Missing actual vocabulary tag") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .unsupportedLanguage("fr")) }
        let retried = await runtime.debugExecutionStatistics()
        XCTAssertEqual(retried.vocabularyPreflightCalls, 2)
        XCTAssertEqual(retried.successfulResourceVerifications, 2)
        XCTAssertEqual(retried.activeVocabularyOnlyModels, 0)
        XCTAssertEqual(retried.vocabularyPreflightMainThreadCalls, 0)
        XCTAssertFalse(retried.modelLoaded)
        await runtime.releaseResources()
    }

    func testMissingLanguageTagCanBeRejectedFromVocabularyOnlyGGUFWithoutAnyTensors() async throws {
        let directory = try SyntheticT5Contract.write(gated: false, vocabularyOnly: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manifestURL = directory.appendingPathComponent("MADLAD400.manifest.json")
        var manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any])
        manifest["supportedLanguageTags"] = ["de", "en", "fr"]
        try JSONSerialization.data(withJSONObject: manifest).write(to: manifestURL)
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        do { _ = try await runtime.translate("fixture", targetTag: "fr"); XCTFail("Missing actual vocabulary tag") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .unsupportedLanguage("fr")) }
        let stats = await runtime.debugExecutionStatistics()
        XCTAssertEqual(stats.checkedBlockingCalls, 0)
        XCTAssertEqual(stats.vocabularyPreflightCalls, 1)
        XCTAssertEqual(stats.vocabularyPreflightMainThreadCalls, 0)
        XCTAssertEqual(stats.activeVocabularyOnlyModels, 0)
        XCTAssertFalse(stats.modelLoaded); XCTAssertFalse(stats.resourcesLoaded)
        XCTAssertEqual(stats.encoderCalls, 0); XCTAssertEqual(stats.decoderCalls, 0)
        await runtime.releaseResources()
    }

    func testDeclaredButMissingVocabularyTagNeverLoadsTensorsOrContext() async throws {
        let directory = try SyntheticT5Contract.write(gated: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manifestURL = directory.appendingPathComponent("MADLAD400.manifest.json")
        var manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any])
        manifest["supportedLanguageTags"] = ["de", "en", "fr"]
        try JSONSerialization.data(withJSONObject: manifest).write(to: manifestURL)
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        do { _ = try await runtime.translate("fixture", targetTag: "fr"); XCTFail("Manifest cannot invent a vocabulary tag") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .unsupportedLanguage("fr")) }
        let rejected = await runtime.debugExecutionStatistics()
        XCTAssertEqual(rejected.checkedBlockingCalls, 0)
        XCTAssertFalse(rejected.modelLoaded); XCTAssertFalse(rejected.resourcesLoaded)
        XCTAssertEqual(rejected.encoderCalls, 0); XCTAssertEqual(rejected.decoderCalls, 0)
        do { _ = try await runtime.translate("fixture", targetTag: "de"); XCTFail("Empty synthetic output") }
        catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inferenceFailed) }
        let valid = await runtime.debugExecutionStatistics()
        XCTAssertEqual(valid.checkedBlockingCalls, 4)
        XCTAssertEqual(valid.successfulResourceVerifications, 1, "The verified resource epoch need not hash the same weights twice")
        XCTAssertEqual(valid.vocabularyPreflightCalls, 2)
        XCTAssertEqual(valid.activeVocabularyOnlyModels, 0)
        XCTAssertEqual(valid.encoderCalls, 1); XCTAssertEqual(valid.decoderCalls, 1)
        await runtime.releaseResources()
    }

    func testConcurrentNativeRequestsAndReleaseReuseRespectActorOwnership() async throws {
        let directory = try SyntheticT5Contract.write(gated: true, oneTokenThenEOS: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: directory)
        var completed = 0
        try await withThrowingTaskGroup(of: [String].self) { group in
            for index in 0..<8 {
                group.addTask {
                    let first = try await runtime.translate("fixture", targetTag: index.isMultiple(of: 2) ? "de" : "en")
                    await runtime.releaseResources()
                    let second = try await runtime.translate("fixture", targetTag: index.isMultiple(of: 2) ? "en" : "de")
                    return [first, second]
                }
            }
            for try await pair in group {
                XCTAssertEqual(pair, ["fixture", "fixture"], "Synthetic token output only, not linguistic translation")
                completed += pair.count
            }
        }
        XCTAssertEqual(completed, 16)
        let actual = await runtime.debugExecutionStatistics()
        XCTAssertEqual(actual.encoderCalls, 16)
        XCTAssertEqual(actual.decoderCalls, 32)
        XCTAssertGreaterThanOrEqual(actual.checkedBlockingCalls, 52)
        XCTAssertEqual(actual.mainThreadBlockingCalls, 0)
        await runtime.releaseResources()
        let released = await runtime.debugExecutionStatistics()
        XCTAssertFalse(released.modelLoaded); XCTAssertFalse(released.resourcesLoaded)
        let final = try await runtime.translate("fixture", targetTag: "de")
        XCTAssertEqual(final, "fixture")
        let reloaded = await runtime.debugExecutionStatistics()
        XCTAssertEqual(reloaded.encoderCalls, 17)
        XCTAssertEqual(reloaded.decoderCalls, 34)
        XCTAssertEqual(reloaded.checkedBlockingCalls, actual.checkedBlockingCalls + 5)
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
    static func write(gated: Bool, repeatToken: Bool = false, oneTokenThenEOS: Bool = false,
                      addSpacePrefix: Bool = false, languageTagType: Int = 4, vocabularyOnly: Bool = false) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("fruitfolio-SYNTHETIC-T5-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            let url = directory.appendingPathComponent("SYNTHETIC-UNTRAINED-NOT-MADLAD.gguf")
            try model(gated: gated, repeatToken: repeatToken, oneTokenThenEOS: oneTokenThenEOS,
                addSpacePrefix: addSpacePrefix, languageTagType: languageTagType, vocabularyOnly: vocabularyOnly).write(to: url)
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
    static func model(gated: Bool, repeatToken: Bool, oneTokenThenEOS: Bool,
                      addSpacePrefix: Bool, languageTagType: Int, vocabularyOnly: Bool = false) -> Data {
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
        let types = [3, 3, 2, languageTagType, languageTagType, 1, 1] + [Int](repeating: 6, count: 256)
        var typeData = integer(5, bytes: 4) + integer(UInt64(types.count))
        for type in types { typeData += integer(UInt64(type), bytes: 4) }
        metadata.append(("tokenizer.ggml.token_type", 9, typeData))
        for (key, value) in [("eos_token_id", 1), ("padding_token_id", 0), ("unknown_token_id", 2)] {
            number("tokenizer.ggml." + key, UInt64(value))
        }
        for (key, value) in [("add_bos_token", false), ("add_eos_token", true), ("add_space_prefix", addSpacePrefix)] {
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
        if vocabularyOnly { tensors.removeAll() } // Deliberately no executable tensor payload.
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
/// Schedules entry to the actual native runtime; it never implements a C API
/// or supplies model output. Every unblocked request calls the real actor.
private actor Prompt1BNativeTranslationGate: FruitfolioLocalTranslationRuntime {
    private let runtime: FruitfolioMADLADRuntime
    private var calls = 0
    private var open = false
    private var gates: [CheckedContinuation<Void, Never>] = []
    private let holdAfterNative: Bool
    init(runtime: FruitfolioMADLADRuntime, holdAfterNative: Bool = false) {
        self.runtime = runtime
        self.holdAfterNative = holdAfterNative
    }
    func translate(_ text: String, targetTag: String) async throws -> String {
        calls += 1
        if !holdAfterNative { try await pauseIfNeeded() }
        let result = try await runtime.translate(text, targetTag: targetTag)
        if holdAfterNative { try await pauseIfNeeded() }
        return result
    }
    private func pauseIfNeeded() async throws {
        if !open { await withCheckedContinuation { gates.append($0) } }
        try Task.checkCancellation()
    }
    func releaseResources() async { await runtime.releaseResources() }
    func callCount() -> Int { calls }
    func rearm() { open = false }
    func unblockAll() {
        open = true
        let pending = gates
        gates.removeAll()
        for gate in pending { gate.resume() }
    }
}
#endif
