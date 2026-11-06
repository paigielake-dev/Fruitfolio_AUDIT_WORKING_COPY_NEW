import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BRecoveredCycleLoaderTests: XCTestCase {
    private struct Fixture {
        let cycleURL: URL
        let onboardingURL: URL
        let cycle: Prompt13CycleStore
        let onboarding: Prompt14CycleOnboardingStore
        let boundary: OnboardingWriteBoundary
        let calendar: Calendar
        let now: Date
        var todayLoader: Prompt16TodayLoader {
            Prompt16TodayLoader(cycleStore: cycle, onboardingStore: onboarding, calendar: calendar)
        }
        func removeFiles() {
            try? FileManager.default.removeItem(at: cycleURL)
            try? FileManager.default.removeItem(at: onboardingURL)
        }
    }

    private func fixture() async throws -> Fixture {
        let directory = FileManager.default.temporaryDirectory
        let cycleURL = directory.appendingPathComponent(UUID().uuidString + ".json")
        let onboardingURL = directory.appendingPathComponent(UUID().uuidString + ".json")
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = try Prompt13LocalDate(year: 2026, month: 9, day: 7)
        let now = try today.foundationDate(in: calendar)
        let first = try Prompt13LocalDate(year: 2026, month: 8, day: 1)
        let oldLatest = try Prompt13LocalDate(year: 2026, month: 9, day: 1)
        let replacement = try Prompt13LocalDate(year: 2026, month: 9, day: 5)
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        try await cycle.reconcileOnboardingCycleStarts(dates: [first, oldLatest], replacingCommittedHistory: false, now: now, today: today)
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied; draft.latestPeriodStart = replacement
        draft.historicalPeriodStarts = [first]
        draft.currentPeriodState = .supplied; draft.currentPeriodAnswer = .yes
        draft.didCommitCycleStarts = true
        draft.pendingCycleCommit = Prompt14PendingCycleCommit(dates: [first, replacement], replacingCommittedHistory: true, completionRequestedAt: now, requestedAt: now, today: today)
        try await Prompt14FileOnboardingPersistence(fileURL: onboardingURL).save(draft)
        let boundary = OnboardingWriteBoundary(onboardingURL)
        await boundary.hold()
        let onboarding = Prompt14CycleOnboardingStore(persistence: boundary, cycleStore: cycle)
        return Fixture(cycleURL: cycleURL, onboardingURL: onboardingURL, cycle: cycle, onboarding: onboarding, boundary: boundary, calendar: calendar, now: now)
    }

    func testTodayCapturesArchiveAfterHeldJournalRecoveryAcknowledges() async throws {
        let fixture = try await fixture(); defer { fixture.removeFiles() }
        let task = Task { try await fixture.todayLoader.loadSnapshot(now: fixture.now) }
        await fixture.boundary.waitUntilHeld()
        let physicallyCommitted = try await Prompt13FileCyclePersistence(fileURL: fixture.cycleURL).load()
        XCTAssertTrue(physicallyCommitted.cycleStarts.contains { $0.date.day == 5 && !$0.metadata.isDeleted })
        await fixture.boundary.release()
        let snapshot = try await task.value
        XCTAssertEqual(snapshot.state.cycleDay, 3)
        XCTAssertEqual(snapshot.derivedState.currentCycleDay, 3)
        XCTAssertEqual(snapshot.onboarding.latestPeriodStart?.day, 5)
        XCTAssertEqual(snapshot.archive.cycleStarts.filter { !$0.metadata.isDeleted }.map(\.id), physicallyCommitted.cycleStarts.filter { !$0.metadata.isDeleted }.map(\.id))
    }

    func testCalendarUsesRecoveredStartsWithoutOldRecordedStartMarker() async throws {
        let fixture = try await fixture(); defer { fixture.removeFiles() }
        let loader = Prompt19CalendarLoader(todayLoader: fixture.todayLoader)
        let task = Task { try await loader.load(month: .init(year: 2026, month: 9), now: fixture.now) }
        await fixture.boundary.waitUntilHeld(); await fixture.boundary.release()
        let snapshot = try await task.value
        let old = Prompt19CalendarDateKey(year: 2026, month: 9, day: 1)
        let replacement = Prompt19CalendarDateKey(year: 2026, month: 9, day: 5)
        XCTAssertFalse(snapshot.annotations[old]?.recordedPeriod ?? false)
        XCTAssertTrue(snapshot.annotations[replacement]?.recordedPeriod ?? false)
    }

    func testTrendsUsesRecoveredThirtyFiveDayIntervalRatherThanOldThirtyOneDays() async throws {
        let fixture = try await fixture(); defer { fixture.removeFiles() }
        let loader = Prompt24TrendsLoader(todayLoader: fixture.todayLoader, dailyLogRepository: Prompt20InMemoryDailyLogRepository(calendar: fixture.calendar))
        let task = Task { try await loader.load(now: fixture.now) }
        await fixture.boundary.waitUntilHeld(); await fixture.boundary.release()
        let snapshot = try await task.value
        XCTAssertEqual(snapshot.cycleLengths.map(\.days), [35])
        XCTAssertEqual(snapshot.cycleMedianDays, 35)
        XCTAssertTrue(snapshot.bbtPoints.isEmpty, "No temperature was recorded by recovery")
    }

    func testHormoneRhythmUsesOneRecoveredTodaySnapshotForContextAndPrediction() async throws {
        let fixture = try await fixture(); defer { fixture.removeFiles() }
        let loader = Prompt22HormoneRhythmLoader(bodyBiologyLoader: Prompt21BodyBiologyLoader(todayLoader: fixture.todayLoader))
        let task = Task { try await loader.load(now: fixture.now) }
        await fixture.boundary.waitUntilHeld(); await fixture.boundary.release()
        let input = try await task.value
        XCTAssertEqual(input.cycleDay, 3)
        XCTAssertFalse(input.measuredHormoneDataAvailable, "Recovery must not invent laboratory measurements")
    }
}
