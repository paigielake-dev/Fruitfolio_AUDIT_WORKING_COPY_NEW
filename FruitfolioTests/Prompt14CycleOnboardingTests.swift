import XCTest
@testable import Fruitfolio

nonisolated final class Prompt14CycleOnboardingTests: XCTestCase {
    func testUnknownLatestPeriodDoesNotCreateDefaultDate() {
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .unknown
        XCTAssertNil(draft.latestPeriodStart)
        XCTAssertTrue(draft.allSuppliedCycleStarts.isEmpty)
    }

    func testNoneCycleContextClearsMedicationCategories() {
        var draft = Prompt14OnboardingDraft()
        draft.selectCycleContext(.hormonalBirthControl)
        draft.selectCycleContext(.fertilityMedication)
        draft.selectCycleContext(.none)
        XCTAssertEqual(draft.cycleAffectingContexts, [.none])
    }

    func testMedicationContextClearsNone() {
        var draft = Prompt14OnboardingDraft()
        draft.selectCycleContext(.none)
        draft.selectCycleContext(.hormonalBirthControl)
        XCTAssertEqual(draft.cycleAffectingContexts, [.hormonalBirthControl])
    }

    func testPostpartumAndBreastfeedingCanCoexist() {
        var draft = Prompt14OnboardingDraft()
        draft.selectRecentContext(.postpartum)
        draft.selectRecentContext(.breastfeeding)
        XCTAssertEqual(draft.recentContexts, [.postpartum, .breastfeeding])
    }

    func testRecentContextNoneClearsSubstantiveSelections() {
        var draft = Prompt14OnboardingDraft()
        draft.selectRecentContext(.postpartum)
        draft.selectRecentContext(.breastfeeding)
        draft.selectRecentContext(.none)
        XCTAssertEqual(draft.recentContexts, [.none])
    }

    func testSubjectiveRegularityIsIndependentValue() {
        var draft = Prompt14OnboardingDraft()
        draft.subjectiveRegularity = .prettyPredictable
        draft.regularityState = .supplied
        XCTAssertEqual(draft.subjectiveRegularity, .prettyPredictable)
        XCTAssertEqual(draft.regularityState, .supplied)
    }

    func testTrackingPreferenceIsMultiSelect() {
        var draft = Prompt14OnboardingDraft()
        draft.toggleTrackingPreference(.periods)
        draft.toggleTrackingPreference(.bbt)
        draft.toggleTrackingPreference(.cervicalFluid)
        XCTAssertEqual(draft.trackingPreferences, [.periods, .bbt, .cervicalFluid])
    }

    func testTrackingPreferenceCanBeDeselected() {
        var draft = Prompt14OnboardingDraft()
        draft.toggleTrackingPreference(.bbt)
        draft.toggleTrackingPreference(.bbt)
        XCTAssertFalse(draft.trackingPreferences.contains(.bbt))
    }

    func testSuppliedCycleStartsAreUniqueAndSorted() throws {
        let a = try Prompt13LocalDate(year: 2026, month: 6, day: 14)
        let b = try Prompt13LocalDate(year: 2026, month: 7, day: 12)
        let c = try Prompt13LocalDate(year: 2026, month: 8, day: 9)
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodStart = c
        draft.historicalPeriodStarts = [b, a, b]
        XCTAssertEqual(draft.allSuppliedCycleStarts, [a, b, c])
    }

    func testCompletingWithoutAnyPeriodDateStillSucceeds() async throws {
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .unknown
        draft.step = .complete
        let cycleStore = Prompt13CycleStore.inMemory()
        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft, cycleStore: cycleStore)

        let completed = try await store.complete(now: Date(timeIntervalSince1970: 1_788_739_200))
        XCTAssertTrue(completed.isCompleted)
        XCTAssertTrue(completed.didCommitCycleStarts)
        let cycleArchive = try await cycleStore.snapshot()
        XCTAssertTrue(cycleArchive.cycleStarts.isEmpty)
    }

    func testCompletionCommitsUserSuppliedStartsIntoPrompt13() async throws {
        let historical = try Prompt13LocalDate(year: 2026, month: 6, day: 14)
        let latest = try Prompt13LocalDate(year: 2026, month: 7, day: 12)
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied
        draft.latestPeriodStart = latest
        draft.previousHistoryState = .supplied
        draft.historicalPeriodStarts = [historical]
        draft.step = .complete

        let cycleStore = Prompt13CycleStore.inMemory()
        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft, cycleStore: cycleStore)
        _ = try await store.complete(now: Date(timeIntervalSince1970: 1_788_739_200))

        let archive = try await cycleStore.snapshot()
        let dates = Set(archive.cycleStarts.filter { !$0.metadata.isDeleted }.map(\.date))
        XCTAssertEqual(dates, [historical, latest])
    }

    func testCompletionRetryDoesNotDuplicateCycleStarts() async throws {
        let latest = try Prompt13LocalDate(year: 2026, month: 7, day: 12)
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied
        draft.latestPeriodStart = latest
        draft.step = .complete

        let cycleStore = Prompt13CycleStore.inMemory()
        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft, cycleStore: cycleStore)
        let now = Date(timeIntervalSince1970: 1_788_739_200)
        _ = try await store.complete(now: now)
        _ = try await store.complete(now: now)

        let archive = try await cycleStore.snapshot()
        XCTAssertEqual(archive.cycleStarts.filter { !$0.metadata.isDeleted }.count, 1)
    }

    func testBBTMeasurementTimePreferenceDoesNotCreateTemperatureObservation() async throws {
        var draft = Prompt14OnboardingDraft()
        draft.trackingPreferences = [.bbt]
        draft.trackingPreferencesState = .supplied
        draft.bbtTrackingChoice = .yes
        draft.bbtUnit = .fahrenheit
        draft.bbtUsualMeasurementMinutesAfterMidnight = 420
        draft.step = .complete

        let cycleStore = Prompt13CycleStore.inMemory()
        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft, cycleStore: cycleStore)
        _ = try await store.complete(now: Date(timeIntervalSince1970: 1_788_739_200))

        let archive = try await cycleStore.snapshot()
        XCTAssertTrue(archive.temperatureObservations.isEmpty)
    }

    func testFertilityPermissionRemainsPreferenceNotPrediction() async throws {
        var draft = Prompt14OnboardingDraft()
        draft.fertilityPreference = .showEstimates
        draft.step = .complete

        let cycleStore = Prompt13CycleStore.inMemory()
        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft, cycleStore: cycleStore)
        _ = try await store.complete(now: Date(timeIntervalSince1970: 1_788_739_200))

        let archive = try await cycleStore.snapshot()
        XCTAssertTrue(archive.predictionSnapshots.isEmpty)
    }
    func testEndCurrentPeriodPersistsExplicitEndWithoutChangingStart() async throws {
        let start = try Prompt13LocalDate(year: 2026, month: 9, day: 3)
        let end = try Prompt13LocalDate(year: 2026, month: 9, day: 8)
        let today = try Prompt13LocalDate(year: 2026, month: 9, day: 10)

        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied
        draft.latestPeriodStart = start
        draft.currentPeriodState = .supplied
        draft.currentPeriodAnswer = .yes
        draft.periodEndState = .skipped
        draft.periodEnd = nil

        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft)
        let updated = try await store.endCurrentPeriod(
            on: end,
            today: today
        )

        XCTAssertEqual(updated.latestPeriodStart, start)
        XCTAssertEqual(updated.currentPeriodState, .supplied)
        XCTAssertEqual(updated.currentPeriodAnswer, .no)
        XCTAssertEqual(updated.periodEndState, .supplied)
        XCTAssertEqual(updated.periodEnd, end)
    }

    func testEndCurrentPeriodRejectsDateBeforeRecordedStart() async throws {
        let start = try Prompt13LocalDate(year: 2026, month: 9, day: 3)
        let invalidEnd = try Prompt13LocalDate(year: 2026, month: 9, day: 2)
        let today = try Prompt13LocalDate(year: 2026, month: 9, day: 10)

        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied
        draft.latestPeriodStart = start
        draft.currentPeriodState = .supplied
        draft.currentPeriodAnswer = .yes

        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft)

        do {
            _ = try await store.endCurrentPeriod(
                on: invalidEnd,
                today: today
            )
            XCTFail("Expected endBeforeStart")
        } catch let error as Prompt14CurrentPeriodUpdateError {
            XCTAssertEqual(error, .endBeforeStart)
        }
    }

    func testEndCurrentPeriodRejectsFutureDate() async throws {
        let start = try Prompt13LocalDate(year: 2026, month: 9, day: 3)
        let today = try Prompt13LocalDate(year: 2026, month: 9, day: 10)
        let futureEnd = try Prompt13LocalDate(year: 2026, month: 9, day: 11)

        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied
        draft.latestPeriodStart = start
        draft.currentPeriodState = .supplied
        draft.currentPeriodAnswer = .yes

        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft)

        do {
            _ = try await store.endCurrentPeriod(
                on: futureEnd,
                today: today
            )
            XCTFail("Expected endInFuture")
        } catch let error as Prompt14CurrentPeriodUpdateError {
            XCTAssertEqual(error, .endInFuture)
        }
    }

}
