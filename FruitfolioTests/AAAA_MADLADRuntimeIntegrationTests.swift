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
