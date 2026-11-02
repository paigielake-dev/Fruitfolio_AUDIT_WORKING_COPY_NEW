import XCTest
import Darwin
@testable import Fruitfolio

@MainActor
final class AAAA_MADLADRuntimeIntegrationTests: XCTestCase {
    func testOfficialModelExecutesLocallyThroughTheLinkedAppleRuntime() async throws {
        let directory = try XCTUnwrap(Bundle.main.url(forResource: "MADLAD", withExtension: nil),
            "Actual model resources must be bundled; no synthetic translation can satisfy this test")
        let runtime = FruitfolioMADLADLocalRuntime()
        let start = Date()
        do {
            let warning = try await runtime.translateRawSentence("This is educational information, not medical advice.", target: "es", directory: directory)
            XCTAssertEqual(warning, "Esta es información educativa, no consejo médico.")
            let measurement = try await runtime.translateRawSentence("The result is 2.5 ng/mL.", target: "es", directory: directory)
            XCTAssertEqual(measurement, "El resultado es 2.5 ng/mL.")
            let uncertainty = try await runtime.translateRawSentence("This estimate does not confirm ovulation.", target: "fr", directory: directory)
            XCTAssertEqual(uncertainty, "Cette estimation ne confirme pas l'ovulation.")
            do {
                _ = try await runtime.translateRawSentence("This is educational information.", target: "zzz", directory: directory)
                XCTFail("An unknown language tag must be rejected rather than interpreted as ordinary input text")
            } catch FruitfolioMADLADError.inferenceFailed { /* exact tokenizer tag rejection */ }
            let documentTranslator = FruitfolioMADLADDocumentTranslator(runtime: runtime)
            let originalFixture = "This is educational information, not medical advice. The result is 2.5 ng/mL [source-1]."
            let candidate = try await documentTranslator.candidate(source: originalFixture,
                sourceIdentifiers: ["source-1"], target: "es", immutableTerms: ["ng/mL"], directory: directory)
            XCTAssertEqual(candidate.textForVerification,
                "Esta es información educativa, no consejo médico. El resultado es 2.5 ng/mL [source-1].")
            XCTAssertEqual(candidate.originalText, originalFixture)
            XCTAssertEqual(candidate.sourceIdentifiers, ["source-1"])
            XCTAssertEqual(candidate.citationMarkers, ["[source-1]"])
            XCTAssertFalse(candidate.medicalMeaningVerified, "Preservation fixture success is not general clinical translation approval")
            let french = try await documentTranslator.candidate(source: "The result is 2.5 ng/mL.",
                sourceIdentifiers: [], target: "fr", immutableTerms: ["ng/mL"], directory: directory)
            XCTAssertTrue(french.textForVerification.contains("2.5 ng/mL"))
            let repaired = XCTAttachment(string: "Actual official local model; original failed combined medical fixture through sentence/citation boundary preservation: \(candidate.textForVerification)\nFrench exact original numeric spelling: \(french.textForVerification)\nClinical/general-language approval remains NOT VERIFIED.")
            repaired.name = "MADLAD_ActualMedicalFixtureBoundaryRepair"; repaired.lifetime = .keepAlways; add(repaired)
            let simplified = try await runtime.translateRawSentence("Please select a language.", target: FruitfolioLanguage.chineseSimplified.madladTargetCode, directory: directory)
            let traditional = try await runtime.translateRawSentence("Please select a language.", target: FruitfolioLanguage.chineseTraditional.madladTargetCode, directory: directory)
            XCTAssertTrue(simplified.contains("选") || simplified.contains("语"), "Actual Simplified Chinese fixture must use its requested script")
            XCTAssertTrue(traditional.contains("選") || traditional.contains("語"), "Actual Traditional Chinese fixture must use the official zh_Hant target")
            XCTAssertFalse(traditional.contains("选") || traditional.contains("语"), "The Traditional selection must not silently reuse Simplified Chinese")
            let scriptEvidence = XCTAttachment(string: "Actual official local MADLAD. Source: Please select a language.\nzh: \(simplified)\nzh_Hant: \(traditional)\nBounded script fixture only; general Chinese clinical translation is NOT VERIFIED.")
            scriptEvidence.name = "MADLAD_ActualChineseScriptSelection"; scriptEvidence.lifetime = .keepAlways; add(scriptEvidence)
            let executedOnMainThread = await runtime.lastInferenceWasOnMainThread
            XCTAssertEqual(executedOnMainThread, false, "Actual C ABI encoder-decoder execution must leave the main UI thread")
            var usage = rusage(); getrusage(0, &usage)
            let report = "Actual Apple runtime / local official Q4: Spanish warning=\(warning); measurement=\(measurement); French uncertainty=\(uncertainty). Wall seconds=\(Date().timeIntervalSince(start)); process peak RSS bytes on Darwin=\(usage.ru_maxrss); reported host physical bytes=\(ProcessInfo.processInfo.physicalMemory). Actual inference used main thread=\(String(describing: executedOnMainThread)). No inference network API. This is a bounded runtime test, not full language/medical/UI or physical-iPhone acceptance."
            let evidence = XCTAttachment(string: report); evidence.name = "MADLAD_ActualAppleRuntime"; evidence.lifetime = .keepAlways; add(evidence)
            await runtime.unload()
        } catch {
            await runtime.unload()
            throw error
        }
    }
}


extension AAAA_MADLADRuntimeIntegrationTests {
    func testMultilingualCandidatesExecuteWithOriginalMeasurementsCitationsAndParagraphLayout() async throws {
        let directory = try XCTUnwrap(Bundle.main.url(forResource: "MADLAD", withExtension: nil))
        let runtime = FruitfolioMADLADLocalRuntime()
        let translator = FruitfolioMADLADDocumentTranslator(runtime: runtime)
        let original = "This estimate does not confirm ovulation.\n\nThe result is 2.5 ng/mL [source-1]."
        var reports: [[String: String]] = []
        for target in ["es", "fr", "de", "pt", "it", "zh", "zh_Hant", "ja", "ko", "ar", "hi"] {
            do {
                let candidate = try await translator.candidate(source: original, sourceIdentifiers: ["source-1"],
                    target: target, immutableTerms: ["ng/mL"], directory: directory)
                XCTAssertEqual(candidate.originalText, original)
                XCTAssertEqual(candidate.citationMarkers, ["[source-1]"])
                XCTAssertEqual(candidate.sourceIdentifiers, ["source-1"])
                XCTAssertTrue(candidate.textForVerification.contains("\n\n"), "Paragraph structure must survive actual generation")
                XCTAssertTrue(candidate.textForVerification.contains("2.5 ng/mL"))
                XCTAssertFalse(candidate.medicalMeaningVerified)
                reports.append(["target": target, "output": candidate.textForVerification,
                    "preservation": "PASS", "semanticReview": "NOT VERIFIED — requires review of this actual output"])
            } catch {
                reports.append(["target": target, "error": String(describing: error), "preservation": "FAIL"])
                XCTFail("Official local candidate failed strict preservation for \(target): \(error)")
            }
        }
        let evidence = XCTAttachment(data: try JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys]),
                                     uniformTypeIdentifier: "public.json")
        evidence.name = "MADLAD_ActualMultilingualMedicalCandidates"
        evidence.lifetime = .keepAlways; add(evidence)
        await runtime.unload()
    }

    func testCorruptTokenizerIsRejectedBeforeAnyModelInference() async throws {
        let bundled = try XCTUnwrap(Bundle.main.url(forResource: "MADLAD", withExtension: nil))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for name in ["added_tokens.json", "config.json", "generation_config.json", "special_tokens_map.json",
                     "spiece.model", "tokenizer_config.json"] {
            try FileManager.default.copyItem(at: bundled.appendingPathComponent(name), to: directory.appendingPathComponent(name))
        }
        try Data("corrupt tokenizer".utf8).write(to: directory.appendingPathComponent("tokenizer.json"))
        let runtime = FruitfolioMADLADLocalRuntime()
        do {
            _ = try await runtime.translateRawSentence("Do not stop taking prescribed medication.", target: "es", directory: directory)
            XCTFail("Corrupt tokenization resources must never reach model inference")
        } catch FruitfolioMADLADError.modelIntegrity { /* strict official checksum mismatch */ }
        await runtime.unload()
    }
}
