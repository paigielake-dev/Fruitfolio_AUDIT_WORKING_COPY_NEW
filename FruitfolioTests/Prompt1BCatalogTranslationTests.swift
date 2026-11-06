import Foundation
import XCTest
@testable import Fruitfolio

private actor CatalogFallbackRuntime: FruitfolioLocalTranslationRuntime {
    private var calls = 0
    func releaseResources() async {} // Contract fixture allocates no model resources.
    func translate(_ text: String, targetTag: String) async throws -> String { calls += 1; return text }
    func callCount() -> Int { calls }
}

final class Prompt1BCatalogTranslationTests: XCTestCase {
    private func fixture(_ table: [String: String], language: String = "es") throws -> (Bundle, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        let folder = root.appendingPathComponent(language + ".lproj")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": "fixture." + UUID().uuidString,
                "CFBundleDevelopmentRegion": "en"], format: .xml, options: 0).write(to: root.appendingPathComponent("Info.plist"))
            try PropertyListSerialization.data(fromPropertyList: table, format: .binary, options: 0)
                .write(to: folder.appendingPathComponent("Localizable.strings"))
            return (try XCTUnwrap(Bundle(url: root)), root)
        } catch { try? FileManager.default.removeItem(at: root); throw error }
    }

    func testActualCatalogBypassesInferenceEvenWhenMemoryPressurePausesTheModel() async throws {
        let (bundle, root) = try fixture(["my context": "mi contexto", "DNA": "DNA"])
        defer { try? FileManager.default.removeItem(at: root) }
        let runtime = CatalogFallbackRuntime()
        let service = FruitfolioTranslationService(runtime: runtime)
        let result = try await service.translateForDisplay("my context", language: .spanish, inferenceAllowed: false, bundle: bundle)
        XCTAssertEqual(result, .init(text: "mi contexto", origin: .catalog))
        let sameLabel = try await service.translateForDisplay("DNA", language: .spanish, inferenceAllowed: false, bundle: bundle)
        XCTAssertEqual(sameLabel, .init(text: "DNA", origin: .catalog))
        XCTAssertEqual(FruitfolioLocalization.localized("DNA", language: .spanish, fallback: "wrong fallback", bundle: bundle), "DNA")
        let calls = await runtime.callCount()
        XCTAssertEqual(calls, 0)
        // Real Foundation bundle lookup/service control flow, not clinical translation review or T5 output.
    }

    func testRepeatedMissingOrEmptyCatalogKeysNeverBecomeSentinelTranslations() throws {
        let (bundle, root) = try fixture(["empty": "  \n"])
        defer { try? FileManager.default.removeItem(at: root) }
        for _ in 0..<8 {
            XCTAssertNil(FruitfolioLocalization.catalogValue("missing", language: .spanish, bundle: bundle))
            XCTAssertNil(FruitfolioLocalization.catalogValue("empty", language: .spanish, bundle: bundle))
            XCTAssertEqual(FruitfolioLocalization.localized("missing", language: .spanish, fallback: "original", bundle: bundle), "original")
        }
    }

    func testBlankSourceIsNotFalselyLabeledAsModelInferenceWhilePaused() async throws {
        let runtime = CatalogFallbackRuntime()
        let service = FruitfolioTranslationService(runtime: runtime)
        let source = "  \n\n\t"
        let result = try await service.translateForDisplay(source, language: .spanish, inferenceAllowed: false)
        XCTAssertEqual(result, .init(text: source, origin: .source))
        let calls = await runtime.callCount()
        XCTAssertEqual(calls, 0)
    }

    func testMissingOrInvalidCatalogNeverBypassesMemoryPauseOrScientificProtection() async throws {
        let source = "FSH 12.50 mIU/mL [A]"
        let (bundle, root) = try fixture([source: "FSH 13.50 mIU/mL [A]"])
        defer { try? FileManager.default.removeItem(at: root) }
        let runtime = CatalogFallbackRuntime()
        let service = FruitfolioTranslationService(runtime: runtime)
        for text in [source, "not in catalog"] {
            do {
                _ = try await service.translateForDisplay(text, language: .spanish, protectedLiterals: ["A"], inferenceAllowed: false, bundle: bundle)
                XCTFail("Unsafe/missing catalog unexpectedly displayed")
            } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .pausedForMemoryPressure) }
        }
        let calls = await runtime.callCount()
        XCTAssertEqual(calls, 0)
        let fallback = try await service.translateForDisplay(source, language: .spanish, bundle: bundle)
        XCTAssertEqual(fallback.origin, .machine)
        XCTAssertEqual(fallback.text, source)
        let fallbackCalls = await runtime.callCount()
        XCTAssertEqual(fallbackCalls, 1)
        // Identity contract fixture proves fallback invocation, not translation quality.
    }

    func testCatalogWithInventedIdentifierCannotDisplayWhileModelIsPaused() async throws {
        let source = "my context"
        let (bundle, root) = try fixture([source: "mi contexto AMH"])
        defer { try? FileManager.default.removeItem(at: root) }
        let runtime = CatalogFallbackRuntime()
        let service = FruitfolioTranslationService(runtime: runtime)
        do {
            _ = try await service.translateForDisplay(source, language: .spanish, inferenceAllowed: false, bundle: bundle)
            XCTFail("Invented catalog identifier must not bypass validation")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .pausedForMemoryPressure) }
        let calls = await runtime.callCount()
        XCTAssertEqual(calls, 0)
        let fallback = try await service.translateForDisplay(source, language: .spanish, bundle: bundle)
        XCTAssertEqual(fallback.text, source)
        XCTAssertEqual(fallback.origin, .machine)
        let fallbackCalls = await runtime.callCount()
        XCTAssertEqual(fallbackCalls, 1)
    }

    func testCatalogCannotAlterBareDOISuffixWhileKeepingItsNumericalPrefix() async throws {
        let source = "source 10.1234/original"
        let (bundle, root) = try fixture([source: "fuente 10.1234/changed"])
        defer { try? FileManager.default.removeItem(at: root) }
        let runtime = CatalogFallbackRuntime()
        let service = FruitfolioTranslationService(runtime: runtime)
        do {
            _ = try await service.translateForDisplay(source, language: .spanish, inferenceAllowed: false, bundle: bundle)
            XCTFail("Changed identifier cannot display as an accepted catalog translation")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .pausedForMemoryPressure) }
        let result = try await service.translateForDisplay(source, language: .spanish, bundle: bundle)
        XCTAssertEqual(result.text, source)
        XCTAssertEqual(result.origin, .machine)
        let calls = await runtime.callCount()
        XCTAssertEqual(calls, 1)
    }

    func testScientificLiteralsAndFullAttributionMustRemainExactInCatalogText() throws {
        let citation = "Doe, A. (2024). Original source title. DOI:10.1000/example."
        let source = "recorded FSH 12.50 mIU/mL [A]\n\n" + citation
        let envelope = try FruitfolioScientificTranslationEnvelope(source, protectedLiterals: [citation, "A"])
        XCTAssertNoThrow(try envelope.validateCatalogCandidate(source.replacingOccurrences(of: "recorded", with: "registrado")))
        XCTAssertThrowsError(try envelope.validateCatalogCandidate(source.replacingOccurrences(of: "Doe, A.", with: "Other Author")))
        XCTAssertThrowsError(try envelope.validateCatalogCandidate(source.replacingOccurrences(of: "mIU/mL", with: "IU/L")))
        XCTAssertThrowsError(try envelope.validateCatalogCandidate(source + " (Invented, n.d.)"))
        XCTAssertThrowsError(try envelope.validateCatalogCandidate(source + " ٩٩"))
        XCTAssertThrowsError(try envelope.validateCatalogCandidate(source + " १२"))
        let ordinary = try FruitfolioScientificTranslationEnvelope("my context")
        XCTAssertEqual(try ordinary.validateCatalogCandidate("min kontekst"), "min kontekst")
    }

    func testCatalogCanBeExplicitlyBypassedForActualModelDraftJobs() async throws {
        let (bundle, root) = try fixture(["my context": "mi contexto"])
        defer { try? FileManager.default.removeItem(at: root) }
        let runtime = CatalogFallbackRuntime()
        let result = try await FruitfolioTranslationService(runtime: runtime).translateForDisplay("my context",
            language: .spanish, preferCatalog: false, bundle: bundle)
        XCTAssertEqual(result.origin, .machine)
        let calls = await runtime.callCount()
        XCTAssertEqual(calls, 1)
    }

    func testRecordedNonEnglishOriginalIsNotMistakenForAnEnglishCatalogKey() async throws {
        let (bundle, root) = try fixture(["my context": "mi contexto"])
        defer { try? FileManager.default.removeItem(at: root) }
        let runtime = CatalogFallbackRuntime()
        let result = try await FruitfolioTranslationService(runtime: runtime).translateForDisplay("my context",
            language: .spanish, sourceLanguage: "fr", bundle: bundle)
        XCTAssertEqual(result.origin, .machine)
        let calls = await runtime.callCount()
        XCTAssertEqual(calls, 1)
    }

    func testNoDateAPACitationIsProtectedAndCannotBeInventedByInference() throws {
        let source = "uncertainty remains (Original Author, n.d.)."
        let envelope = try FruitfolioScientificTranslationEnvelope(source)
        XCTAssertFalse(envelope.prepared.contains("n.d."))
        XCTAssertEqual(try envelope.restore(envelope.prepared), source)
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " (Invented Author, N. D.)"))
        XCTAssertThrowsError(try FruitfolioScientificTranslationEnvelope("source prose").restore("translated prose (Invented, n.d.)"))
        XCTAssertThrowsError(try FruitfolioScientificTranslationEnvelope("source prose").restore("translated prose （Invented, n.d.）"))
        XCTAssertThrowsError(try FruitfolioScientificTranslationEnvelope("source prose").restore("translated prose ［InventedSource］"))
        let fullWidthOriginal = "source details （Original Author, n.d.） ［original-source］"
        let fullWidthEnvelope = try FruitfolioScientificTranslationEnvelope(fullWidthOriginal)
        XCTAssertEqual(try fullWidthEnvelope.restore(fullWidthEnvelope.prepared), fullWidthOriginal)
    }
}
