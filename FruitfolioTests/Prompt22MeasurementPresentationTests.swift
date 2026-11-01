import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt22MeasurementPresentationTests: XCTestCase {
    func testOptInCannotCreateAnAdjustedCurveWithoutApprovedCalibration() {
        let value = HormoneMeasurement()
        XCTAssertEqual(Prompt22MeasurementPresentationPolicy.assessment(requested: false, measurements: [value]), .notRequested)
        XCTAssertEqual(Prompt22MeasurementPresentationPolicy.assessment(requested: true, measurements: []), .noRecordedMeasurements)
        XCTAssertEqual(Prompt22MeasurementPresentationPolicy.assessment(requested: true, measurements: [value]), .approvedCalibrationUnavailable)
        XCTAssertEqual(Prompt22MeasurementPresentationPolicy.insufficientTitle, "a little note! ☆")
        XCTAssertEqual(Prompt22MeasurementPresentationPolicy.insufficientMessage,
            "your measurement has been saved, but there isn’t enough information to adjust this illustration reliably. you can still explore the typical hormone rhythm and view your actual result in my measurements.")
    }

    func testReferencePresentationDoesNotInventValuesOrRewriteStoredMeasurements() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("measurements.json")
        let store = HormoneMeasurementStore(fileURL: file)
        var early = HormoneMeasurement()
        early.testDateWasProvided = true
        early.testDate = Date(timeIntervalSince1970: 1_700_000_000)
        early.result = "2,500"; early.unit = " user-unit "
        var later = early
        later.id = UUID(); later.hormone = .progesterone
        later.testDate = early.testDate.addingTimeInterval(86_400 * 9)
        later.result = "3.1250"; later.notes = "unaltered note"
        try store.save(later); try store.save(early)
        let bytesBefore = try Data(contentsOf: file)
        let baseline = Prompt22HormoneRhythmEngine().presentation(for: .neutral)
        let recordsBefore = store.measurements
        XCTAssertEqual(Prompt22MeasurementPresentationPolicy.assessment(requested: true,
            measurements: store.measurements), .approvedCalibrationUnavailable)
        let references = Prompt22MeasurementPresentationPolicy.orderedReferences(store.measurements)
        XCTAssertEqual(references.map(\.id), [early.id, later.id])
        XCTAssertEqual(references.map(\.result), ["2,500", "3.1250"])
        XCTAssertEqual(references.map(\.unit), [" user-unit ", " user-unit "])
        XCTAssertEqual(references.count, 2, "Only actual measurements may be presented; no interpolated laboratory results")
        XCTAssertEqual(store.measurements, recordsBefore)
        XCTAssertEqual(try Data(contentsOf: file), bytesBefore)
        XCTAssertEqual(HormoneMeasurementStore(fileURL: file).measurements, recordsBefore)
        XCTAssertEqual(Prompt22HormoneRhythmEngine().presentation(for: .neutral), baseline,
            "Requesting an unsupported adjustment must leave the existing educational illustration and its confidence markers unchanged")
    }
}
