import XCTest
@testable import Fruitfolio

final class Prompt1BCalendarPresentationPolicyTests: XCTestCase {
    @MainActor
    func testCancelledCalendarLoadDoesNotStartSupplementalWork() async throws {
        let gate = CalendarCancellationProbe()
        let cycle = Prompt13CycleStore.inMemory()
        let loader = Prompt19CalendarLoader(todayLoader: .init(cycleStore: cycle,
            onboardingStore: .inMemory(cycleStore: cycle)), supplementalProvider: .init { _, _ in await gate.record(); return [] })
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await loader.load(month: .init(year: 2026, month: 11))
        }
        do { _ = try await task.value; XCTFail("Cancelled load must throw") }
        catch { XCTAssertTrue(error is CancellationError) }
        let calls = await gate.calls
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testCancellationWhileSupplementalProviderIsHeldRejectsReturnedSnapshot() async throws {
        let gate = CalendarCancellationProbe()
        let cycle = Prompt13CycleStore.inMemory()
        let loader = Prompt19CalendarLoader(todayLoader: .init(cycleStore: cycle,
            onboardingStore: .inMemory(cycleStore: cycle)), supplementalProvider: .init { _, _ in await gate.hold(); return [] })
        let task = Task { try await loader.load(month: .init(year: 2026, month: 11)) }
        await gate.waitUntilHeld()
        task.cancel()
        await gate.release()
        do { _ = try await task.value; XCTFail("Late supplemental result must not return a cancelled snapshot") }
        catch { XCTAssertTrue(error is CancellationError) }
        let calls = await gate.calls
        XCTAssertEqual(calls, 1)
    }

    @MainActor
    func testSameMonthAndContextResultFromBeforeReactivationCannotReplaceCurrentPresentation() async throws {
        let gate = CalendarCancellationProbe()
        let cycle = Prompt13CycleStore.inMemory()
        let month = Prompt19CalendarMonth(year: 2026, month: 11)
        let loader = Prompt19CalendarLoader(todayLoader: .init(cycleStore: cycle,
            onboardingStore: .inMemory(cycleStore: cycle)), supplementalProvider: .init { _, _ in await gate.hold(); return [] })
        let beforeBackground = Prompt19CalendarLoadIdentity(month: month, context: .init(), presentationEpoch: UUID())
        let task = Task { try await loader.load(month: month) }
        await gate.waitUntilHeld()
        let afterReactivation = Prompt19CalendarLoadIdentity(month: month, context: .init(), presentationEpoch: UUID())
        // Deliberately do not cancel: SwiftUI task cancellation may arrive after
        // reactivation. A same-month/context result still belongs to its epoch.
        await gate.release()
        let oldSnapshot = try await task.value
        XCTAssertEqual(oldSnapshot.month, month)
        XCTAssertFalse(beforeBackground.accepts(oldSnapshot, current: afterReactivation))
        XCTAssertTrue(afterReactivation.accepts(oldSnapshot, current: afterReactivation))
    }

    func testContextChangeHidesOnlyInapplicableEstimatesWithoutChangingRecordedData() {
        let key = Prompt19CalendarDateKey(year: 2026, month: 11, day: 5)
        let original = Prompt19CalendarDayAnnotation(key: key, cycleDay: 7, recordedPeriod: true, predictedPeriod: true,
            fertileEstimated: true, ovulationEstimated: true, symptomsLogged: true, bbtRecorded: true, noteAdded: true,
            symptomSummary: ["recorded symptom"], temperatureDisplay: "36.50 °C", noteText: "user note")
        let policy = Prompt27AContextPolicyEngine().policy(for: .init(reproductiveStage: .pregnant))
        let shown = Prompt19CalendarPresentationPolicy.annotations([key: original], context: policy)[key]!
        XCTAssertFalse(shown.predictedPeriod); XCTAssertFalse(shown.fertileEstimated); XCTAssertFalse(shown.ovulationEstimated)
        XCTAssertTrue(shown.recordedPeriod); XCTAssertTrue(shown.bbtRecorded); XCTAssertTrue(shown.noteAdded)
        XCTAssertEqual(shown.cycleDay, original.cycleDay)
        XCTAssertEqual(shown.temperatureDisplay, original.temperatureDisplay)
        XCTAssertEqual(shown.noteText, original.noteText)
        XCTAssertEqual(shown.symptomSummary, original.symptomSummary)
        let restored = Prompt19CalendarPresentationPolicy.annotations([key: original], context: .init())[key]
        XCTAssertEqual(restored, original)
    }
    func testOlderMonthOrContextResultCannotWinARequestRace() {
        let month = Prompt19CalendarMonth(year: 2026, month: 11)
        let old = Prompt19CalendarLoadIdentity(month: month, context: .init())
        let changedContext = Prompt19CalendarLoadIdentity(month: month,
            context: Prompt27AContextPolicyEngine().policy(for: .init(reproductiveStage: .pregnant)))
        XCTAssertTrue(old.accepts(.empty(month: month), current: old))
        XCTAssertFalse(old.accepts(.empty(month: month), current: changedContext))
        XCTAssertFalse(old.accepts(.empty(month: .init(year: 2026, month: 12)), current: old))
    }
}

private actor CalendarCancellationProbe {
    private(set) var calls = 0
    private var continuation: CheckedContinuation<Void, Never>?
    private var waiters: [CheckedContinuation<Void, Never>] = []
    func record() { calls += 1 }
    func hold() async {
        calls += 1
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            let ready = waiters; waiters.removeAll()
            for waiter in ready { waiter.resume() }
        }
    }
    func waitUntilHeld() async {
        if continuation != nil { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func release() { continuation?.resume(); continuation = nil }
}
