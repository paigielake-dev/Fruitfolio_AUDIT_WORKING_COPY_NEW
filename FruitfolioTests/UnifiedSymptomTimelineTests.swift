import XCTest
@testable import Fruitfolio

final class UnifiedSymptomTimelineTests: XCTestCase {
    func testInitialGraphShowsAllAndOnlyActuallyLoggedSymptomsAndRespectsExplicitHideAll() {
        let available: Set<Prompt20SymptomID> = [.headache, .fatigue]
        XCTAssertEqual(Prompt24SymptomChartData.selection(nil, available: available), available)
        XCTAssertEqual(Prompt24SymptomChartData.selection([], available: available), [])
        XCTAssertEqual(Prompt24SymptomChartData.selection([.headache, .cramps], available: available), [.headache])
    }
    func testUnknownCycleDayStillPlotsTheActualDatedObservationWithoutInventingAnAssignment() {
        let first = Prompt24SymptomOccurrence(symptomID: .headache, date: Date(timeIntervalSince1970: 100), cycleDay: nil, completedCycleIndex: nil)
        let middle = Prompt24SymptomOccurrence(symptomID: .fatigue, date: Date(timeIntervalSince1970: 150), cycleDay: 4, completedCycleIndex: 0)
        let last = Prompt24SymptomOccurrence(symptomID: .headache, date: Date(timeIntervalSince1970: 200), cycleDay: 10, completedCycleIndex: 1)
        let data = Prompt24SymptomChartData(occurrences: [last, first, middle], selected: [.headache, .fatigue])
        XCTAssertEqual(data.occurrences, [first, middle, last])
        XCTAssertNil(data.occurrences.first?.cycleDay)
        XCTAssertEqual(data.dateFraction(first), 0)
        XCTAssertEqual(data.dateFraction(middle), 0.5)
        XCTAssertEqual(data.dateFraction(last), 1)
        XCTAssertEqual(data.symptoms.count, 2)
    }
    func testFilteringNeverCreatesMissingObservationsAndSingleDateRemainsARecordedPoint() {
        let only = Prompt24SymptomOccurrence(symptomID: .fatigue, date: Date(timeIntervalSince1970: 100), cycleDay: nil, completedCycleIndex: nil)
        let data = Prompt24SymptomChartData(occurrences: [only], selected: [.fatigue, .cramps])
        XCTAssertEqual(data.occurrences, [only]); XCTAssertEqual(data.symptoms, [.fatigue])
        XCTAssertEqual(data.dateFraction(only), 0.5)
        XCTAssertTrue(Prompt24SymptomChartData(occurrences: [only], selected: []).occurrences.isEmpty)
    }
}
