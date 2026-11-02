import XCTest
@testable import Fruitfolio

@MainActor
final class HormoneMeasurementHistoryTests: XCTestCase {
    private func record(_ value: String, unit: String = "ng/mL", sample: String = "serum", hormone: RecordedHormone = .progesterone, date: Double = 100) -> HormoneMeasurement {
        var r = HormoneMeasurement(); r.result = value; r.unit = unit; r.sampleType = sample
        r.hormone = hormone; r.testDate = Date(timeIntervalSince1970: date); r.testDateWasProvided = true
        return r
    }
    func testOnlyActualPointsAreReturnedInDateOrderWithoutInterpolationOrMutation() {
        let records = [record("3.1250", date: 300), record("2,500", date: 100)]
        let groups = HormoneMeasurementSeries.groups(records)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].records.map(\.id), [records[1].id, records[0].id])
        XCTAssertEqual(groups[0].records.map(\.result), ["2,500", "3.1250"])
        XCTAssertEqual(groups[0].records.count, 2)
        XCTAssertEqual(HormoneMeasurementSeries.coordinate(records[1]), 2.5)
        XCTAssertEqual(records[1].result, "2,500")
    }
    func testDifferentExactUnitsHormonesAndSamplesAreNeverCombinedOrConverted() {
        let records = [record("1"), record("2", unit: "nmol/L"), record("3", sample: "saliva"),
                       record("4", hormone: .estradiol), record("5", unit: " ng/mL ")]
        let groups = HormoneMeasurementSeries.groups(records)
        XCTAssertEqual(groups.count, 5)
        XCTAssertEqual(Set(groups.flatMap(\.records).map(\.id)), Set(records.map(\.id)))
    }
    func testOtherHormonesRemainDistinctAndMissingOrInvalidValuesAreNotInvented() {
        var a = record("1", hormone: .other); a.otherHormoneName = "reported hormone A"
        var b = record("2", hormone: .other); b.otherHormoneName = "reported hormone B"
        var undated = record("3"); undated.testDateWasProvided = false
        let groups = HormoneMeasurementSeries.groups([a, b, undated, record("NaN"), record("")])
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(Set(groups.flatMap(\.records).map(\.id)), Set([a.id, b.id]))
        XCTAssertTrue(HormoneMeasurementSeries.groups([]).isEmpty)
    }
}
