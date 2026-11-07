import XCTest
@testable import Fruitfolio

final class Prompt1BScientificTranslationTests: XCTestCase {
    func testIntroducedScientificIdentifiersRejectBothInferenceAndCatalogCandidates() throws {
        let source = "my context"
        let envelope = try FruitfolioScientificTranslationEnvelope(source)
        for identifier in ["AMH", "FSH", "LH", "TSH", "pH", "hCG", "HCG", "DHEA-S", "HbA1c", "rs123", "HLA-DQB1*06:02"] {
            XCTAssertThrowsError(try envelope.restore(envelope.prepared + " " + identifier), identifier)
            XCTAssertThrowsError(try envelope.validateCatalogCandidate("mi contexto " + identifier), identifier)
        }
        XCTAssertEqual(try envelope.restore("min kontekst"), "min kontekst")
        XCTAssertEqual(try envelope.validateCatalogCandidate("min kontekst"), "min kontekst")
    }

    func testScientificIdentifierOrderMultiplicityAndCaseRemainExact() throws {
        let source = "FSH and AMH; FSH again"
        let envelope = try FruitfolioScientificTranslationEnvelope(source)
        XCTAssertEqual(try envelope.restore(envelope.prepared), source)
        XCTAssertEqual(try envelope.validateCatalogCandidate("FSH y AMH; FSH otra vez"), "FSH y AMH; FSH otra vez")
        for candidate in ["FSH y AMH", "AMH y FSH; FSH otra vez", "FSH y AMH; FSH FSH", "fsh y AMH; FSH"] {
            XCTAssertThrowsError(try envelope.validateCatalogCandidate(candidate))
        }
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " AMH"))
    }

    func testExplicitProtectedLiteralCannotBeIntroducedWhenAbsentFromSource() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("my library", protectedLiterals: ["Fruitfolio", "FruitsofLife.xo"])
        XCTAssertEqual(try envelope.validateCatalogCandidate("mi biblioteca"), "mi biblioteca")
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " Fruitfolio"))
        XCTAssertThrowsError(try envelope.validateCatalogCandidate("biblioteca de FruitsofLife.xo"))
        let present = try FruitfolioScientificTranslationEnvelope("Fruitfolio library", protectedLiterals: ["Fruitfolio"])
        XCTAssertEqual(try present.restore(present.prepared), "Fruitfolio library")
        XCTAssertThrowsError(try present.restore(present.prepared + " Fruitfolio"))
        XCTAssertThrowsError(try present.validateCatalogCandidate("Fruitfolio biblioteca Fruitfolio"))
    }

    func testBareBibliographicIdentifiersAreProtectedWholeBeforeTheirNumericPrefixes() throws {
        let sources = ["HCG and hCG", "HCG ≤ 2.5 IU/L", "PMID: 12345678", "PMID 12345678",
                       "PMCID: PMC1234567", "10.1234/original", "doi: 10.1234/original", "DOI:10.1234/αβ"]
        for source in sources {
            let envelope = try FruitfolioScientificTranslationEnvelope(source)
            XCTAssertEqual(try envelope.restore(envelope.prepared), source)
            XCTAssertNoThrow(try envelope.validateCatalogCandidate(source))
            for literal in ["HCG", "hCG", "PMID", "PMCID", "10.1234", "original", "αβ"] {
                if source.contains(literal) { XCTAssertFalse(envelope.prepared.contains(literal), source) }
            }
        }
        for source in ["10.1234/original", "DOI:10.1234/original"] {
            let envelope = try FruitfolioScientificTranslationEnvelope(source)
            XCTAssertThrowsError(try envelope.validateCatalogCandidate(source.replacingOccurrences(of: "original", with: "changed")))
        }
        let identifier = try FruitfolioScientificTranslationEnvelope("PMID: 12345678")
        XCTAssertThrowsError(try identifier.validateCatalogCandidate("PMCID: 12345678"))
    }

    func testRoundTripProtectsNumbersUnitsCitationsURLsAndFormatting() throws {
        let source = "**estradiol** 12.5 pg/mL [source-7] (Author, 2020). https://example.org/12"
        let envelope = try FruitfolioScientificTranslationEnvelope(source, protectedLiterals: ["source-7"])
        XCTAssertFalse(envelope.prepared.contains("12.5 pg/mL"))
        XCTAssertEqual(try envelope.restore(envelope.prepared), source)
    }
    func testClinicalSignsComparisonsAndExtendedUnitsCannotBeAlteredOutsidePlaceholders() throws {
        let source = "FSH ≤ −2.5 ng/dL; change -0.2 °C; 1.2×10^-3 µIU/mL; ratio 1:2; 2.5±0.3 pg/mL; HbA1c=5.2 %."
        let envelope = try FruitfolioScientificTranslationEnvelope(source)
        for literal in ["≤", "−", "-0.2", "ng/dL", "µIU/mL", "±", "HbA1c"] {
            XCTAssertFalse(envelope.prepared.contains(literal), "Unprotected scientific token: \(literal)")
        }
        let tampered = envelope.prepared.replacingOccurrences(of: "−", with: "")
            .replacingOccurrences(of: "≤", with: "").replacingOccurrences(of: "ng/dL", with: "mg/dL")
        XCTAssertEqual(try envelope.restore(tampered), source)
    }
    func testEscapedComparatorsGroupingAndScientificPowersRemainExact() throws {
        let sources = ["E2 < -2.5 ng/dL", "1 000 IU/L", "1.2 * 10^-3 mIU/mL", "10^−3 mol/L", "2 mg–3 mg", "−.5 ng/dL"]
        for source in sources {
            let canonical = FruitfolioSemanticMarkup.markdown([.init(text: source)])
            let envelope = try FruitfolioScientificTranslationEnvelope(canonical)
            XCTAssertEqual(try envelope.restore(envelope.prepared), canonical)
            XCTAssertFalse(envelope.prepared.contains("ng/dL"))
            XCTAssertFalse(envelope.prepared.contains("^−3"))
        }
    }
    func testIntroducedUnitsOrReferencesRejectOutputEvenWithoutNewDigits() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("recorded value 20")
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " mg"))
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " [invented-source]"))
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " https://invented.example/paper"))
    }
    func testOrdinaryTranslatedContractionsAreNotMisreadAsBareUnits() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("my context")
        XCTAssertEqual(try envelope.restore("min kontekst"), "min kontekst")
        XCTAssertEqual(try envelope.restore("m’a aidé"), "m’a aidé")
    }

    func testMissingProtectedTokensRejectsOutput() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("level 12 pg/mL [source-1]")
        XCTAssertThrowsError(try envelope.restore("translated prose with no protected tokens"))
    }
    func testIntroducedNumericalClaimIsRejected() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("source prose with no numeric claim")
        XCTAssertThrowsError(try envelope.restore("source prose now claims 99 percent"))
    }
}

/// Deliberately corrupt contract fixture; never presented as native T5 output.
private actor Prompt1BIdentifierInjectionFixture: FruitfolioLocalTranslationRuntime {
    let suffix: String
    private var calls = 0
    init(suffix: String) { self.suffix = suffix }
    func releaseResources() {}
    func translate(_ text: String, targetTag: String) async throws -> String {
        calls += 1
        return calls == 2 ? text + suffix : text
    }
    func callCount() -> Int { calls }
}

private actor Prompt1BIdentityTranslationFixture: FruitfolioLocalTranslationRuntime {
    private var tags: [String] = []
    private var releases = 0
    func releaseResources() { releases += 1 }
    func releaseCount() -> Int { releases }
    func translate(_ text: String, targetTag: String) async throws -> String {
        tags.append(targetTag)
        return text
    }
    func requestedTags() -> [String] { tags }
}

final class Prompt1BTranslationPipelineTests: XCTestCase {
    func testLateIdentifierOrProtectedBrandInjectionRejectsWholePassage() async throws {
        for suffix in [" AMH", " HCG", " PMID: 12345678", " Fruitfolio"] {
            let runtime = Prompt1BIdentifierInjectionFixture(suffix: suffix)
            let service = FruitfolioTranslationService(runtime: runtime)
            let source = "first paragraph\n\nsecond paragraph"
            do {
                _ = try await service.translateForDisplay(source, language: .spanish,
                    protectedLiterals: ["Fruitfolio"], preferCatalog: false)
                XCTFail("An invalid second paragraph must not return a partial translation")
            } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
            let calls = await runtime.callCount()
            XCTAssertEqual(calls, 2)
            XCTAssertEqual(source, "first paragraph\n\nsecond paragraph")
        }
    }

    func testNewFounderSelectorsForwardDistinctModelTagsWithoutClaimingSupport() async throws {
        let fixture = Prompt1BIdentityTranslationFixture()
        let service = FruitfolioTranslationService(runtime: fixture)
        let languages: [FruitfolioLanguage] = [.thai, .mongolian, .indonesian, .russian, .polish,
            .dutch, .swedish, .ukrainian, .turkish, .kurdishKurmanji, .kurdishSorani, .hebrew]
        for language in languages {
            _ = try await service.translate("source text", language: language)
        }
        let tags = await fixture.requestedTags()
        XCTAssertEqual(tags, ["th", "mn", "id", "ru", "pl", "nl", "sv", "uk", "tr", "ku", "ckb", "he"])
        // This records the real service's requests, not real tokenizer support or output.
    }

    func testServiceForwardsExplicitResourceReleaseWithoutChangingSourceText() async throws {
        let fixture = Prompt1BIdentityTranslationFixture()
        let service = FruitfolioTranslationService(runtime: fixture)
        await service.releaseResources()
        await service.releaseResources()
        let count = await fixture.releaseCount()
        XCTAssertEqual(count, 2)
        let original = "source 12 pg/mL [A]"
        let translated = try await service.translate(original, language: .spanish)
        XCTAssertEqual(translated, original)
        // Contract fixture only; actual T5 allocation release requires the model.
    }

    func testNonEnglishSavedContentCanRequestEnglishTranslation() async throws {
        let fixture = Prompt1BIdentityTranslationFixture()
        let service = FruitfolioTranslationService(runtime: fixture)
        _ = try await service.translate("texto original", language: .english, sourceLanguage: "es")
        let tags = await fixture.requestedTags()
        XCTAssertEqual(tags, ["en"])
    }

    func testParagraphAndStructuredReferencePreservationWithFixtureRuntime() async throws {
        let service = FruitfolioTranslationService(runtime: Prompt1BIdentityTranslationFixture())
        let original = "value 3.2 ng/mL [A]\n\nuncertainty remains."
        let result = try await service.translate(original, language: .spanish, protectedLiterals: ["A"])
        XCTAssertEqual(result, original)
        // This checks the protection pipeline, not actual model inference or translation quality.
    }
}

#if DEBUG
/// Protocol scheduling fixture only: identity text is NOT native/model output.
private actor Prompt1BSharedTranslationGate: FruitfolioLocalTranslationRuntime {
    private var calls = 0
    private var cancelled = 0
    private var open = false
    private var gates: [Int: CheckedContinuation<Void, Never>] = [:]
    private let corruptFirst: Bool
    init(corruptFirst: Bool = false) { self.corruptFirst = corruptFirst }
    func translate(_ text: String, targetTag: String) async throws -> String {
        calls += 1
        let index = calls
        if !open { await withCheckedContinuation { gates[index] = $0 } }
        do { try Task.checkCancellation() }
        catch { cancelled += 1; throw error }
        return corruptFirst && index == 1 ? text + " 99 mg" : text
    }
    func releaseResources() {}
    func counts() -> (calls: Int, cancelled: Int) { (calls, cancelled) }
    func unblockFirst() { gates.removeValue(forKey: 1)?.resume() }
    func unblockAll() {
        open = true
        let pending = Array(gates.values)
        gates.removeAll()
        for gate in pending { gate.resume() }
    }
}

final class Prompt1BSharedTranslationTests: XCTestCase {
    private func wait(_ service: FruitfolioTranslationService, runtime: Prompt1BSharedTranslationGate,
                      requests: Int, waiters: Int, calls: Int,
                      file: StaticString = #filePath, line: UInt = #line) async {
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while ContinuousClock.now < deadline {
            let active = await service.debugInFlightStatistics()
            let actual = await runtime.counts()
            if active.requests == requests, active.waiters == waiters, actual.calls == calls { return }
            try? await Task.sleep(for: .milliseconds(1))
        }
        XCTFail("Timed out waiting for actual shared-request ownership", file: file, line: line)
        await runtime.unblockAll()
    }

    func testExcessiveSourceAndProtectionBudgetsRejectBeforeCallingRuntime() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let cases: [(String, [String], String)] = [
            (String(repeating: "a", count: 1024 * 1024 + 1), [], "en"),
            (String(repeating: "é", count: 512 * 1024 + 1), [], "en"),
            ("original", Array(repeating: "", count: 1025), "en"),
            ("original", [String(repeating: "b", count: 64 * 1024 + 1)], "en"),
            ("original", Array(repeating: String(repeating: "b", count: 32769), count: 2), "en"),
            ("original", [], String(repeating: "x", count: 65))
        ]
        for (source, protection, sourceLanguage) in cases {
            do {
                _ = try await service.translate(source, language: .german,
                    protectedLiterals: protection, sourceLanguage: sourceLanguage, preferCatalog: false)
                XCTFail("Excessive work must retain original rather than enqueue inference")
            } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inputTooLong) }
        }
        let calls = await runtime.counts()
        XCTAssertEqual(calls.calls, 0)
        let active = await service.debugInFlightStatistics()
        XCTAssertEqual(active.requests, 0)
        XCTAssertEqual(active.unshared, 0)
    }

    func testExactInputBudgetsAndSameLanguageOriginalRemainIntact() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        await runtime.unblockAll()
        let service = FruitfolioTranslationService(runtime: runtime)
        let source = String(repeating: "é", count: 512 * 1024)
        let translated = try await service.translate(source, language: .german,
            protectedLiterals: Array(repeating: "", count: 1024), preferCatalog: false)
        XCTAssertEqual(Data(translated.utf8), Data(source.utf8))
        let metadataBoundary = try await service.translate("original", language: .german,
            protectedLiterals: [String(repeating: "b", count: 64 * 1024)], preferCatalog: false)
        XCTAssertEqual(metadataBoundary, "original")
        let oversizedOriginal = source + "extra"
        let display = try await service.translateForDisplay(oversizedOriginal, language: .english)
        XCTAssertEqual(display.origin, .source)
        XCTAssertEqual(Data(display.text.utf8), Data(oversizedOriginal.utf8))
        let calls = await runtime.counts()
        XCTAssertEqual(calls.calls, 2, "Same-language display must bypass inference")
    }

    func testIndependentAdmissionIsBoundedWithoutBlockingSharedOwnersAndRecoversAfterRelease() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let protection = Array(repeating: "brand", count: 65) // real uncached path
        let tasks = (0..<64).map { _ in Task {
            try await service.translate("original passage", language: .german,
                protectedLiterals: protection, preferCatalog: false)
        } }
        await wait(service, runtime: runtime, requests: 0, waiters: 0, calls: 64)
        let full = await service.debugInFlightStatistics()
        XCTAssertEqual(full.unshared, 64)
        do {
            _ = try await service.translate("overflow must stay original", language: .german,
                protectedLiterals: protection, preferCatalog: false)
            XCTFail("Overflow admission must fail before retaining another inference job")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .inferenceCapacityReached) }
        let afterRejection = await runtime.counts()
        XCTAssertEqual(afterRejection.calls, 64)
        let shared = (0..<2).map { _ in Task {
            try await service.translate("shared owner", language: .french, preferCatalog: false)
        } }
        await wait(service, runtime: runtime, requests: 1, waiters: 2, calls: 65)
        await service.releaseResources()
        await runtime.unblockAll()
        for task in tasks + shared {
            do { _ = try await task.value; XCTFail("Released owner returned a translation") }
            catch { XCTAssertTrue(error is CancellationError) }
        }
        let cleared = await service.debugInFlightStatistics()
        XCTAssertEqual(cleared.requests, 0)
        XCTAssertEqual(cleared.waiters, 0)
        XCTAssertEqual(cleared.unshared, 0)
        let retry = try await service.translate("original passage", language: .german,
            protectedLiterals: protection, preferCatalog: false)
        XCTAssertEqual(retry, "original passage")
    }

    func testIdenticalConcurrentRequestsShareValidatedResultWithoutCachingCompletedText() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let source = "FSH ≤ 12.5 IU/L [source-1] DOI:10.1234/fixture"
        let tasks = (0..<8).map { _ in Task {
            try await service.translateForDisplay(source, language: .german,
                protectedLiterals: ["source-1"], preferCatalog: false)
        } }
        await wait(service, runtime: runtime, requests: 1, waiters: 8, calls: 1)
        await runtime.unblockAll()
        for task in tasks {
            let result = try await task.value
            XCTAssertEqual(result.text, source)
            XCTAssertEqual(result.origin, .machine)
        }
        let finished = await service.debugInFlightStatistics()
        XCTAssertEqual(finished.requests, 0)
        XCTAssertEqual(finished.waiters, 0)
        let again = try await service.translate(source, language: .german,
            protectedLiterals: ["source-1"], preferCatalog: false)
        XCTAssertEqual(again, source)
        let actual = await runtime.counts()
        XCTAssertEqual(actual.calls, 2, "Completed text must not remain in a service result cache")
    }

    func testOneCancelledWaiterDoesNotCancelAnotherOwnersSharedWork() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let first = Task { try await service.translate("fixture", language: .german, preferCatalog: false) }
        let second = Task { try await service.translate("fixture", language: .german, preferCatalog: false) }
        await wait(service, runtime: runtime, requests: 1, waiters: 2, calls: 1)
        first.cancel()
        await wait(service, runtime: runtime, requests: 1, waiters: 1, calls: 1)
        await runtime.unblockAll()
        do { _ = try await first.value; XCTFail("Cancelled owner") }
        catch { XCTAssertTrue(error is CancellationError) }
        let kept = try await second.value
        XCTAssertEqual(kept, "fixture")
        let actual = await runtime.counts()
        XCTAssertEqual(actual.cancelled, 0)
    }

    func testLastCancellationAndStaleCompletionCannotRemoveANewSameSourceFlight() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let old = (0..<2).map { _ in Task {
            try await service.translate("fixture", language: .german, preferCatalog: false)
        } }
        await wait(service, runtime: runtime, requests: 1, waiters: 2, calls: 1)
        for task in old { task.cancel() }
        await wait(service, runtime: runtime, requests: 0, waiters: 0, calls: 1)
        let fresh = Task { try await service.translate("fixture", language: .german, preferCatalog: false) }
        await wait(service, runtime: runtime, requests: 1, waiters: 1, calls: 2)
        await runtime.unblockFirst()
        for task in old {
            do { _ = try await task.value; XCTFail("Cancelled owners") }
            catch { XCTAssertTrue(error is CancellationError) }
        }
        let joining = Task { try await service.translate("fixture", language: .german, preferCatalog: false) }
        await wait(service, runtime: runtime, requests: 1, waiters: 2, calls: 2)
        await runtime.unblockAll()
        let first = try await fresh.value
        let second = try await joining.value
        XCTAssertEqual(first, "fixture")
        XCTAssertEqual(second, "fixture")
        let actual = await runtime.counts()
        XCTAssertEqual(actual.cancelled, 1)
    }

    func testRejectedSharedOutputIsNotAcceptedOrCached() async throws {
        let runtime = Prompt1BSharedTranslationGate(corruptFirst: true)
        let service = FruitfolioTranslationService(runtime: runtime)
        let tasks = (0..<2).map { _ in Task {
            try await service.translate("fixture", language: .german, preferCatalog: false)
        } }
        await wait(service, runtime: runtime, requests: 1, waiters: 2, calls: 1)
        await runtime.unblockAll()
        for task in tasks {
            do { _ = try await task.value; XCTFail("Invented quantity") }
            catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
        }
        let retry = try await service.translate("fixture", language: .german, preferCatalog: false)
        XCTAssertEqual(retry, "fixture")
        let actual = await runtime.counts()
        XCTAssertEqual(actual.calls, 2)
    }

    func testByteDifferentUnicodeAndDifferentProtectionOrLanguageNeverShare() async throws {
        let cases: [(String, String, [String], [String], FruitfolioLanguage, FruitfolioLanguage, String, String)] = [
            ("café", "cafe\u{301}", [], [], .german, .german, "en", "en"),
            ("Blue flower", "Blue flower", ["Blue"], ["flower"], .german, .german, "en", "en"),
            ("fixture", "fixture", [], [], .german, .french, "en", "en"),
            ("fixture", "fixture", [], [], .german, .german, "en", "fr")
        ]
        for (left, right, leftProtection, rightProtection, leftLanguage, rightLanguage, leftSource, rightSource) in cases {
            let runtime = Prompt1BSharedTranslationGate()
            let service = FruitfolioTranslationService(runtime: runtime)
            let first = Task { try await service.translate(left, language: leftLanguage,
                protectedLiterals: leftProtection, sourceLanguage: leftSource, preferCatalog: false) }
            let second = Task { try await service.translate(right, language: rightLanguage,
                protectedLiterals: rightProtection, sourceLanguage: rightSource, preferCatalog: false) }
            await wait(service, runtime: runtime, requests: 2, waiters: 2, calls: 2)
            await runtime.unblockAll()
            let firstText = try await first.value
            let secondText = try await second.value
            XCTAssertEqual(Data(firstText.utf8), Data(left.utf8))
            XCTAssertEqual(Data(secondText.utf8), Data(right.utf8))
        }
    }

    func testPausedCallerCannotJoinAnAlreadyRunningInference() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let active = Task { try await service.translate("fixture", language: .german, preferCatalog: false) }
        await wait(service, runtime: runtime, requests: 1, waiters: 1, calls: 1)
        do {
            _ = try await service.translateForDisplay("fixture", language: .german,
                preferCatalog: false, inferenceAllowed: false)
            XCTFail("Paused caller must not join inference")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .pausedForMemoryPressure) }
        await wait(service, runtime: runtime, requests: 1, waiters: 1, calls: 1)
        await runtime.unblockAll()
        let result = try await active.value
        XCTAssertEqual(result, "fixture")
    }

    func testReleaseCancelsUnsharedMultiParagraphWorkBeforeTheNextParagraph() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let source = "fixture\n\nsecond paragraph"
        let task = Task { try await service.translate(source, language: .german,
            protectedLiterals: Array(repeating: "brand", count: 65), preferCatalog: false) }
        await wait(service, runtime: runtime, requests: 0, waiters: 0, calls: 1)
        let pending = await service.debugInFlightStatistics()
        XCTAssertEqual(pending.unshared, 1)
        await service.releaseResources()
        await runtime.unblockAll()
        do { _ = try await task.value; XCTFail("Released unshared work") }
        catch { XCTAssertTrue(error is CancellationError) }
        let actual = await runtime.counts()
        XCTAssertEqual(actual.calls, 1, "Second paragraph must not run after release")
        let cleared = await service.debugInFlightStatistics()
        XCTAssertEqual(cleared.unshared, 0)
        let fresh = try await service.translate(source, language: .german,
            protectedLiterals: Array(repeating: "brand", count: 65), preferCatalog: false)
        XCTAssertEqual(fresh, source)
    }

    func testCancellingUnsharedCallerPreservesOtherOwnerUntilExplicitRelease() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let protection = Array(repeating: "brand", count: 65)
        let first = Task { try await service.translate("fixture", language: .german,
            protectedLiterals: protection, preferCatalog: false) }
        await wait(service, runtime: runtime, requests: 0, waiters: 0, calls: 1)
        let second = Task { try await service.translate("fixture", language: .german,
            protectedLiterals: protection, preferCatalog: false) }
        await wait(service, runtime: runtime, requests: 0, waiters: 0, calls: 2)
        first.cancel()
        await runtime.unblockFirst()
        do { _ = try await first.value; XCTFail("Cancelled independent owner") }
        catch { XCTAssertTrue(error is CancellationError) }
        let retained = await service.debugInFlightStatistics()
        XCTAssertEqual(retained.unshared, 1)
        let beforeRelease = await runtime.counts()
        XCTAssertEqual(beforeRelease.cancelled, 1)
        await service.releaseResources()
        await runtime.unblockAll()
        do { _ = try await second.value; XCTFail("Released remaining independent owner") }
        catch { XCTAssertTrue(error is CancellationError) }
        let cleared = await service.debugInFlightStatistics()
        XCTAssertEqual(cleared.unshared, 0)
    }

    func testSharingWaiterLimitBypassesInsteadOfGrowingUnboundedMetadata() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let tasks = (0..<65).map { _ in Task {
            try await service.translate("fixture", language: .german, preferCatalog: false)
        } }
        await wait(service, runtime: runtime, requests: 1, waiters: 64, calls: 2)
        await runtime.unblockAll()
        for task in tasks {
            let result = try await task.value
            XCTAssertEqual(result, "fixture")
        }
        let active = await service.debugInFlightStatistics()
        XCTAssertEqual(active.requests, 0)
    }

    func testLargeSourceOrProtectionMetadataRetainsTheOriginalUncachedPath() async throws {
        for (source, protection) in [
            (String(repeating: "a", count: 16 * 1024 + 1), [String]()),
            ("fixture", Array(repeating: "brand", count: 65)),
            ("fixture", [String(repeating: "b", count: 4097)])
        ] {
            let runtime = Prompt1BSharedTranslationGate()
            let service = FruitfolioTranslationService(runtime: runtime)
            let task = Task { try await service.translate(source, language: .german,
                protectedLiterals: protection, preferCatalog: false) }
            await wait(service, runtime: runtime, requests: 0, waiters: 0, calls: 1)
            await runtime.unblockAll()
            let result = try await task.value
            XCTAssertEqual(Data(result.utf8), Data(source.utf8))
        }
    }

    func testSharingMetadataBudgetsBypassWithoutClippingOrRejectingWork() async throws {
        let runtime = Prompt1BSharedTranslationGate()
        let service = FruitfolioTranslationService(runtime: runtime)
        let tasks = (0..<33).map { index in Task {
            try await service.translate("fixture \(index)", language: .german, preferCatalog: false)
        } }
        await wait(service, runtime: runtime, requests: 32, waiters: 32, calls: 33)
        await runtime.unblockAll()
        for (index, task) in tasks.enumerated() {
            let result = try await task.value
            XCTAssertEqual(result, "fixture \(index)")
        }
        let large = String(repeating: "a", count: 16 * 1024 + 1)
        let result = try await service.translate(large, language: .german, preferCatalog: false)
        XCTAssertEqual(result, large)
        let finished = await service.debugInFlightStatistics()
        XCTAssertEqual(finished.requests, 0)
        XCTAssertEqual(finished.waiters, 0)
    }
}
#endif
