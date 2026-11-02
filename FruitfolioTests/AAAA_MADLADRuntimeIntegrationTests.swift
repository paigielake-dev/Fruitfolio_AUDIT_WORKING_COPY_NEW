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
                if target == "ja" {
                    XCTAssertEqual(candidate.retainedOriginalMedicalTerms, ["estimate", "ovulation"])
                    XCTAssertTrue(candidate.textForVerification.contains("estimate"))
                    XCTAssertTrue(candidate.textForVerification.contains("ovulation"))
                    XCTAssertFalse(candidate.translationLimitations.isEmpty)
                    XCTAssertFalse(candidate.textForVerification.contains("なかった"))
                }
                if target == "hi" {
                    XCTAssertTrue(candidate.textForVerification.contains("ovulation"), "The exact original concept must remain when its medical translation is unsafe")
                    XCTAssertEqual(candidate.retainedOriginalMedicalTerms, ["ovulation"])
                    XCTAssertFalse(candidate.translationLimitations.isEmpty, "Original-English term retention must be explicit, not presented as complete localization")
                    XCTAssertFalse(candidate.textForVerification.contains("अंडाशय"), "Ovary is not ovulation")
                    XCTAssertFalse(candidate.textForVerification.contains("घनत्व"),
                        "The actual prior Hindi density hallucination must not pass the corrected medical fixture")
                    XCTAssertFalse(candidate.textForVerification.contains("ग्राम/सेमी"),
                        "The original ng/mL result must not become grams per cubic centimetre")
                }
                reports.append(["target": target, "output": candidate.textForVerification,
                    "actualSentenceEvidence": String(decoding: try JSONEncoder().encode(candidate.sentenceEvidence), as: UTF8.self),
                    "retainedOriginalMedicalTerms": candidate.retainedOriginalMedicalTerms.joined(separator: ", "),
                    "translationLimitations": candidate.translationLimitations.joined(separator: " | "),
                    "preservation": "PASS", "semanticReview": "NOT VERIFIED — requires review of this actual output"])
            } catch {
                var report = ["target": target, "error": String(describing: error), "preservation": "FAIL"]
                if let rejected = error as? FruitfolioTranslationRejectedCandidate {
                    report["rejectedSourceSentence"] = rejected.sourceSentence
                    report["actualModelInput"] = rejected.actualModelInput
                    report["actualRejectedRawOutput"] = rejected.rawOutput
                    report["strictReason"] = String(describing: rejected.reason)
                }
                reports.append(report)
                XCTFail("Official local candidate failed strict preservation for \(target): \(error)")
            }
            // These are exclusively the hard-coded synthetic fixture values,
            // not user data. Preserve each actual result even if a later test
            // times out before Xcode can finalize the result bundle.
            if let report = reports.last {
                let bytes = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
                print("MADLAD_SYNTHETIC_FIXTURE_RESULT " + String(decoding: bytes, as: UTF8.self))
            }
        }
        let evidence = XCTAttachment(data: try JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys]),
                                     uniformTypeIdentifier: "public.json")
        evidence.name = "MADLAD_ActualMultilingualMedicalCandidates"
        evidence.lifetime = .keepAlways; add(evidence)
        await runtime.unload()
    }

    func testMultilingualEdgeQuantitiesExecuteWithoutChangingRecordedValuesOrWarnings() async throws {
        let directory = try XCTUnwrap(Bundle.main.url(forResource: "MADLAD", withExtension: nil))
        let runtime = FruitfolioMADLADLocalRuntime()
        let translator = FruitfolioMADLADDocumentTranslator(runtime: runtime)
        let original = "These are recorded values, not medical advice: -2.50–-1.00 ng/mL; 12.5%; 37.0 °C; 4.20e-3 mol/L; 1.2 ×10⁻³ kg·m⁻²; ١٢٫٥٪ [source-1]."
        let originalNumbers = FruitfolioTranslationPreservation.numbers(original)
        let quantities = ["-2.50–-1.00 ng/mL", "12.5%", "37.0 °C", "4.20e-3 mol/L", "1.2 ×10⁻³ kg·m⁻²", "١٢٫٥٪"]
        var reports: [[String: String]] = []
        for target in ["es", "fr", "de", "pt", "it", "zh", "zh_Hant", "ja", "ko", "ar", "hi"] {
            do {
                let candidate = try await translator.candidate(source: original, sourceIdentifiers: ["source-1"],
                    target: target, immutableTerms: [], directory: directory)
                XCTAssertEqual(candidate.originalText, original)
                XCTAssertEqual(candidate.citationMarkers, ["[source-1]"])
                XCTAssertEqual(FruitfolioTranslationPreservation.numbers(candidate.textForVerification), originalNumbers)
                for quantity in quantities { XCTAssertTrue(candidate.textForVerification.contains(quantity)) }
                XCTAssertFalse(candidate.medicalMeaningVerified, "Exact values alone do not validate translated medical meaning")
                reports.append(["target": target, "output": candidate.textForVerification,
                    "actualSentenceEvidence": String(decoding: try JSONEncoder().encode(candidate.sentenceEvidence), as: UTF8.self),
                    "retainedOriginalMedicalTerms": candidate.retainedOriginalMedicalTerms.joined(separator: ", "),
                    "translationLimitations": candidate.translationLimitations.joined(separator: " | "),
                    "preservation": "PASS", "semanticReview": "NOT VERIFIED — review the actual warning and surrounding wording"])
            } catch {
                var report = ["target": target, "error": String(describing: error), "preservation": "FAIL"]
                if let rejected = error as? FruitfolioTranslationRejectedCandidate {
                    report["rejectedSourceSentence"] = rejected.sourceSentence
                    report["actualModelInput"] = rejected.actualModelInput
                    report["actualRejectedRawOutput"] = rejected.rawOutput
                    report["strictReason"] = String(describing: rejected.reason)
                }
                reports.append(report)
                XCTFail("Official local edge fixture failed strict preservation for \(target): \(error)")
            }
            let bytes = try JSONSerialization.data(withJSONObject: reports.last!, options: [.sortedKeys])
            print("MADLAD_SYNTHETIC_EDGE_FIXTURE_RESULT " + String(decoding: bytes, as: UTF8.self))
        }
        let evidence = XCTAttachment(data: try JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys]),
            uniformTypeIdentifier: "public.json")
        evidence.name = "MADLAD_ActualMultilingualEdgeQuantities"; evidence.lifetime = .keepAlways; add(evidence)
        await runtime.unload()
    }

    func testFifteenExpandedTargetsExecuteMedicalWarningPreservationWithoutClaimingMeaningApproval() async throws {
        let directory = try XCTUnwrap(Bundle.main.url(forResource: "MADLAD", withExtension: nil))
        let runtime = FruitfolioMADLADLocalRuntime()
        let translator = FruitfolioMADLADDocumentTranslator(runtime: runtime)
        let source = "Do not stop taking prescribed medication.\n\nThese recorded values do not confirm a diagnosis: -2.50–-1.00 ng/mL; 12.5%; 37.0 °C; 4.20e-3 mol/L [source-1]."
        let targets = ["th", "mn", "id", "ru", "pl", "nl", "sv", "uk", "tr", "ku", "ckb", "he", "qu", "gn", "ay"]
        var reports: [[String: String]] = []
        for target in targets {
            do {
                let candidate = try await translator.candidate(source: source, sourceIdentifiers: ["source-1"],
                    target: target, immutableTerms: [], directory: directory)
                XCTAssertEqual(candidate.originalText, source)
                XCTAssertEqual(candidate.sourceIdentifiers, ["source-1"])
                XCTAssertEqual(candidate.citationMarkers, ["[source-1]"])
                XCTAssertEqual(FruitfolioTranslationPreservation.numbers(candidate.textForVerification),
                               FruitfolioTranslationPreservation.numbers(source))
                for quantity in ["-2.50–-1.00 ng/mL", "12.5%", "37.0 °C", "4.20e-3 mol/L"] {
                    XCTAssertTrue(candidate.textForVerification.contains(quantity))
                }
                XCTAssertTrue(candidate.textForVerification.contains("\n\n"))
                XCTAssertFalse(candidate.medicalMeaningVerified,
                    "Preservation cannot approve the medication warning, diagnosis negation, language identity, or clinical terminology")
                reports.append(["target": target, "source": source, "output": candidate.textForVerification,
                    "actualSentenceEvidence": String(decoding: try JSONEncoder().encode(candidate.sentenceEvidence), as: UTF8.self),
                    "preservation": "PASS", "medicalMeaning": "NOT VERIFIED — actual warning, negation, terminology and language require review"])
            } catch {
                var report = ["target": target, "source": source, "preservation": "FAIL", "error": String(describing: error)]
                if let rejected = error as? FruitfolioTranslationRejectedCandidate {
                    report["actualModelInput"] = rejected.actualModelInput
                    report["actualRejectedRawOutput"] = rejected.rawOutput
                    report["strictReason"] = String(describing: rejected.reason)
                }
                reports.append(report)
                XCTFail("Expanded official target failed strict preservation for \(target): \(error)")
            }
            print("MADLAD_SYNTHETIC_EXPANDED_MEDICAL_RESULT " + String(decoding:
                try JSONSerialization.data(withJSONObject: reports.last!, options: [.sortedKeys]), as: UTF8.self))
        }
        XCTAssertEqual(reports.count, 15, "No expanded target may be excluded")
        let evidence = XCTAttachment(data: try JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys]),
            uniformTypeIdentifier: "public.json")
        evidence.name = "MADLAD_ActualFifteenExpandedMedicalPreservation"
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

extension AAAA_MADLADRuntimeIntegrationTests {
    func testEveryRequestedLanguageExecutesOrReportsExactOfficialTagAbsenceWithoutSubstitution() async throws {
        let directory = try XCTUnwrap(Bundle.main.url(forResource: "MADLAD", withExtension: nil))
        let tokenizer = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("tokenizer.json"))) as? [String: Any])
        let model = try XCTUnwrap(tokenizer["model"] as? [String: Any])
        let vocabulary = try XCTUnwrap(model["vocab"] as? [[Any]])
        let tags = Set(vocabulary.compactMap { $0.first as? String }.filter { $0.hasPrefix("<2") && $0.hasSuffix(">") })
        let actuallyAbsent = FruitfolioLanguage.allCases.filter { !tags.contains("<2" + $0.madladTargetCode + ">") }
        XCTAssertEqual(Set(actuallyAbsent.map(\.rawValue)), Set(["tpi", "ty", "rar", "niu", "gil"]),
            "The official tokenizer, not a guessed alias, determines unsupported selections")
        let runtime = FruitfolioMADLADLocalRuntime()
        var reports: [[String: String]] = []
        for language in FruitfolioLanguage.allCases {
            let start = Date()
            let absent = !tags.contains("<2" + language.madladTargetCode + ">")
            do {
                let output = try await runtime.translateRawSentence("Please select a language.",
                    target: language.madladTargetCode, directory: directory)
                XCTAssertFalse(absent, "An absent exact target must never be silently substituted")
                XCTAssertFalse(output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if language == .chineseSimplified { XCTAssertTrue(output.contains("选") || output.contains("语")) }
                if language == .chineseTraditional {
                    XCTAssertTrue(output.contains("選") || output.contains("語"))
                    XCTAssertFalse(output.contains("选") || output.contains("语"))
                }
                reports.append(["language": language.rawValue, "target": language.madladTargetCode,
                    "source": "Please select a language.", "actualRawOutput": output,
                    "runtimeExecution": "PASS", "languageQuality": "NOT VERIFIED — one nonmedical fixture is not full localization or clinical acceptance",
                    "wallSeconds": String(Date().timeIntervalSince(start))])
            } catch {
                if absent, case FruitfolioMADLADError.inferenceFailed = error {
                    reports.append(["language": language.rawValue, "target": language.madladTargetCode,
                        "runtimeExecution": "REJECTED — exact official tokenizer target absent",
                        "languageSupport": "BLOCKED", "substitution": "NONE"])
                } else {
                    reports.append(["language": language.rawValue, "target": language.madladTargetCode,
                                    "runtimeExecution": "FAIL", "error": String(describing: error)])
                    XCTFail("Actual local requested-language execution failed for \(language.rawValue): \(error)")
                }
            }
            let data = try JSONSerialization.data(withJSONObject: reports.last!, options: [.sortedKeys])
            print("MADLAD_SYNTHETIC_REQUESTED_LANGUAGE_RESULT " + String(decoding: data, as: UTF8.self))
        }
        XCTAssertEqual(reports.count, FruitfolioLanguage.allCases.count)
        let evidence = XCTAttachment(data: try JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys]),
            uniformTypeIdentifier: "public.json")
        evidence.name = "MADLAD_ActualAllRequestedLanguageTargets"; evidence.lifetime = .keepAlways; add(evidence)
        await runtime.unload()
    }
}
