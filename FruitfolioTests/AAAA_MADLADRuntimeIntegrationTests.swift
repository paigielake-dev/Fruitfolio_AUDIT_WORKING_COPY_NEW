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
            var usage = rusage(); getrusage(0, &usage)
            let report = "Actual Apple runtime / local official Q4: Spanish warning=\(warning); measurement=\(measurement); French uncertainty=\(uncertainty). Wall seconds=\(Date().timeIntervalSince(start)); process peak RSS bytes on Darwin=\(usage.ru_maxrss); reported host physical bytes=\(ProcessInfo.processInfo.physicalMemory). No inference network API. This is a bounded runtime test, not full language/medical/UI or physical-iPhone acceptance."
            let evidence = XCTAttachment(string: report); evidence.name = "MADLAD_ActualAppleRuntime"; evidence.lifetime = .keepAlways; add(evidence)
            await runtime.unload()
        } catch {
            await runtime.unload()
            throw error
        }
    }
}


extension AAAA_MADLADRuntimeIntegrationTests {
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
