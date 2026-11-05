import XCTest
@testable import Fruitfolio

final class Prompt1BTodaySnapshotTests: XCTestCase {
    func testArchiveAndDerivedStateRemainCoherentWhenLaterRecordsChange() async throws {
        let store = Prompt13CycleStore.inMemory()
        let today = try Prompt13LocalDate(year: 2026, month: 9, day: 7)
        let first = try Prompt13LocalDate(year: 2026, month: 9, day: 1)
        _ = try await store.recordCycleStart(on: first, today: today)
        let captured = try await store.snapshotWithDerivedState(on: today)
        _ = try await store.recordCycleStart(on: .init(year: 2026, month: 9, day: 6), today: today)
        let current = try await store.snapshotWithDerivedState(on: today)
        XCTAssertEqual(captured.archive.cycleStarts.filter { !$0.metadata.isDeleted }.count, 1)
        XCTAssertEqual(captured.derivedState.currentCycleDay, 7)
        XCTAssertEqual(current.archive.cycleStarts.filter { !$0.metadata.isDeleted }.count, 2)
        XCTAssertEqual(current.derivedState.currentCycleDay, 2)
    }
    func testTodayUsesTheSameCapturedInputsForStateAndPredictionBridge() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12)))
        let cycle = Prompt13CycleStore.inMemory()
        let start = try Prompt13LocalDate(year: 2026, month: 9, day: 1)
        _ = try await cycle.recordCycleStart(on: start, today: .init(year: 2026, month: 9, day: 7))
        var draft = Prompt14OnboardingDraft()
        draft.currentPeriodState = .supplied; draft.currentPeriodAnswer = .yes; draft.latestPeriodStart = start
        let onboarding = Prompt14CycleOnboardingStore.inMemory(draft: draft, cycleStore: cycle)
        let loader = Prompt16TodayLoader(cycleStore: cycle, onboardingStore: onboarding, calendar: calendar)
        let result = try await loader.loadSnapshot(now: now)
        XCTAssertEqual(result.asOfDate, now)
        XCTAssertEqual(result.state.cycleDay, result.derivedState.currentCycleDay)
        XCTAssertEqual(result.state.context, .menstruation)
        XCTAssertFalse(result.state.hasRecordedBleedingToday, "An onboarding report must not become a new recorded bleeding observation")
        XCTAssertEqual(result.onboarding, draft)
        XCTAssertEqual(result.archive.cycleStarts.count, 1)
    }

    func testActualCalendarLoaderSuppressesInapplicablePredictionAndKeepsRecordedMetadata() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let first = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12)))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 12)))
        let today = try Prompt13LocalDate(now, calendar: calendar)
        let cycle = Prompt13CycleStore.inMemory()
        var starts: [Prompt13LocalDate] = []
        for index in 0..<5 {
            let date = try XCTUnwrap(calendar.date(byAdding: .day, value: 28 * index, to: first))
            let local = try Prompt13LocalDate(date, calendar: calendar)
            starts.append(local)
            _ = try await cycle.recordCycleStart(on: local, now: now, today: today)
        }
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied; draft.latestPeriodStart = starts.last
        draft.currentPeriodAnswer = .no; draft.periodEndState = .supplied
        draft.periodEnd = try Prompt13LocalDate(year: 2026, month: 4, day: 27)
        let onboarding = Prompt14CycleOnboardingStore.inMemory(draft: draft, cycleStore: cycle)
        let todayLoader = Prompt16TodayLoader(cycleStore: cycle, onboardingStore: onboarding, calendar: calendar)
        let key = Prompt19CalendarDateKey(year: 2026, month: 5, day: 8)
        let supplemental = Prompt19CalendarSupplementalProvider { _, _ in
            [.init(key: key, bbtRecorded: true, noteAdded: true, temperatureDisplay: "36.50 °C", noteText: "recorded fixture note")]
        }
        let normal = try await Prompt19CalendarLoader(todayLoader: todayLoader, supplementalProvider: supplemental)
            .load(month: .init(year: 2026, month: 5), now: now)
        XCTAssertTrue(normal.annotations.values.contains { $0.predictedPeriod })
        XCTAssertFalse(normal.annotations.values.contains { $0.ovulationEstimated || $0.fertileEstimated })
        let restricted = try await Prompt19CalendarLoader(todayLoader: todayLoader, supplementalProvider: supplemental,
            contextPolicy: Prompt27AContextPolicyEngine().policy(for: .init(reproductiveStage: .pregnant)))
            .load(month: .init(year: 2026, month: 5), now: now)
        XCTAssertFalse(restricted.annotations.values.contains { $0.predictedPeriod || $0.ovulationEstimated || $0.fertileEstimated })
        XCTAssertEqual(restricted.annotations[key]?.temperatureDisplay, "36.50 °C")
        XCTAssertEqual(restricted.annotations[key]?.noteText, "recorded fixture note")
    }

}
