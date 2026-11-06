import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BSymptomTimelineTests: XCTestCase {
    @MainActor
    func testActualRepositoryAndTrendsLoaderPreserveObservationsAcrossTimelineFilters() async throws {
        let calendar = calendar()
        let repository = Prompt20InMemoryDailyLogRepository(calendar: calendar)
        let owner = Prompt20DailyLogOwnerID(rawValue: "isolated-timeline-regression")
        let cycle = Prompt13CycleStore.inMemory()
        let loader = Prompt24TrendsLoader(todayLoader: .init(cycleStore: cycle,
            onboardingStore: .inMemory(cycleStore: cycle), calendar: calendar),
            dailyLogRepository: repository, ownerID: owner)
        for day in [7, 9] {
            var draft = Prompt20DailyLogDraft(); draft.selectedSymptoms = [.cramps, .fatigue]
            let date = date(3, day)
            _ = try await repository.save(ownerID: owner, date: .init(date: date, calendar: calendar),
                draft: draft, now: date, requestID: UUID())
        }
        let original = try await repository.allActiveLogs(ownerID: owner).sorted { $0.id.uuidString < $1.id.uuidString }
        let snapshot = try await loader.load(now: date(3, 10))
        XCTAssertEqual(snapshot.symptomOccurrences.count, 4)
        XCTAssertTrue(snapshot.symptomOccurrences.allSatisfy { $0.cycleDay == nil && $0.completedCycleIndex == nil })
        let all = Prompt24SymptomTimeline(occurrences: snapshot.symptomOccurrences, selected: [.cramps, .fatigue], calendar: calendar)
        XCTAssertEqual(all.points.map(\.dayOffset), [0, 0, 2, 2])
        XCTAssertEqual(all.spanDays, 2)
        let hidden = Prompt24SymptomTimeline(occurrences: snapshot.symptomOccurrences, selected: [], calendar: calendar)
        XCTAssertTrue(hidden.points.isEmpty)
        let one = Prompt24SymptomTimeline(occurrences: snapshot.symptomOccurrences, selected: [.fatigue], calendar: calendar)
        XCTAssertEqual(one.points.count, 2)
        XCTAssertTrue(one.points.allSatisfy { $0.occurrence.symptomID == .fatigue })
        XCTAssertEqual(Prompt24SymptomTimeline(occurrences: snapshot.symptomOccurrences, selected: [.cramps, .fatigue], calendar: calendar), all)
        let actual = try await repository.allActiveLogs(ownerID: owner).sorted { $0.id.uuidString < $1.id.uuidString }
        XCTAssertEqual(actual, original)
        XCTAssertEqual(actual.count, 2)
        XCTAssertNil(snapshot.predictionMarker)
    }

    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }
    private func date(_ month: Int, _ day: Int) -> Date {
        calendar().date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
    private func occurrence(_ date: Date, symptom: Prompt20SymptomID = .cramps, cycleDay: Int? = nil) -> Prompt24SymptomOccurrence {
        .init(symptomID: symptom, date: date, cycleDay: cycleDay, completedCycleIndex: nil)
    }
    func testSameCycleDayInDifferentMonthsIsNotOverlaid() {
        let observations = [occurrence(date(2, 5), cycleDay: 5), occurrence(date(1, 5), cycleDay: 5)]
        let timeline = Prompt24SymptomTimeline(occurrences: observations, selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.map(\.dayOffset), [0, 31])
        XCTAssertEqual(timeline.spanDays, 31)
        XCTAssertEqual(timeline.points.map { $0.occurrence.date }, [date(1, 5), date(2, 5)])
    }
    func testObservationWithoutCycleAssignmentIsRetained() {
        let observation = occurrence(date(1, 5))
        let timeline = Prompt24SymptomTimeline(occurrences: [observation], selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.count, 1)
        XCTAssertEqual(timeline.points.first?.occurrence, observation)
        XCTAssertNil(timeline.points.first?.occurrence.cycleDay)
        XCTAssertEqual(timeline.omittedInvalidDateCount, 0)
    }
    func testDSTUsesCivilDaySpacingRatherThanElapsedHours() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(date(3, 7)), occurrence(date(3, 9))], selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.map(\.dayOffset), [0, 2])
        XCTAssertEqual(timeline.spanDays, 2)
    }
    func testSelectionFiltersOnlyExplicitlyHiddenSymptoms() {
        let observations = [occurrence(date(1, 5)), occurrence(date(1, 5), symptom: .fatigue)]
        let timeline = Prompt24SymptomTimeline(occurrences: observations, selected: [.fatigue], calendar: calendar())
        XCTAssertEqual(timeline.symptoms, [.fatigue])
        XCTAssertEqual(timeline.points.map { $0.occurrence.symptomID }, [.fatigue])
        XCTAssertEqual(timeline.points.map(\.row), [0])
    }
    func testUnloggedDaysAreNeverSynthesizedAsAbsentSymptoms() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(date(1, 1)), occurrence(date(1, 31))], selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.count, 2)
        XCTAssertEqual(timeline.spanDays, 30)
    }
    func testEmptySelectionDoesNotInventDomainOrPoints() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(date(1, 1))], selected: [], calendar: calendar())
        XCTAssertTrue(timeline.points.isEmpty)
        XCTAssertNil(timeline.firstDate)
        XCTAssertNil(timeline.lastDate)
    }
    func testInvalidDateIsCountedWithoutBeingReplaced() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(Date(timeIntervalSinceReferenceDate: .nan))], selected: [.cramps], calendar: calendar())
        XCTAssertTrue(timeline.points.isEmpty)
        XCTAssertNil(timeline.firstDate)
        XCTAssertEqual(timeline.omittedInvalidDateCount, 1)
    }
}
