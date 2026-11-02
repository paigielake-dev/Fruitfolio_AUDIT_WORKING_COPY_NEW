import XCTest
@testable import Fruitfolio

@MainActor
final class CycleSetupEditingTests: XCTestCase {
    func testOpeningOneExistingAnswerDoesNotRestartOrClearCompletedSetup() async throws {
        var draft = Prompt14OnboardingDraft()
        draft.completedAt = Date(timeIntervalSince1970: 100)
        draft.step = .complete
        draft.regularityState = .supplied; draft.subjectiveRegularity = .variesALittle
        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft)
        let model = Prompt14CycleOnboardingViewModel(store: store)
        await model.load(); model.beginEditing(.subjectiveRegularity)
        XCTAssertTrue(model.draft.isCompleted)
        XCTAssertEqual(model.draft.subjectiveRegularity, .variesALittle)
        XCTAssertEqual(model.draft.step, .subjectiveRegularity)
        let persisted = try await store.snapshot()
        XCTAssertEqual(persisted, draft, "Opening a question alone must not rewrite stored answers")
    }

    func testRemovingLatestPeriodAlsoErasesItsDependentAnswersWithoutErasingOtherSetup() async throws {
        var draft = Prompt14OnboardingDraft()
        draft.completedAt = Date(timeIntervalSince1970: 100)
        draft.latestPeriodState = .supplied
        draft.latestPeriodStart = try Prompt13LocalDate(year: 2025, month: 1, day: 1)
        draft.currentPeriodState = .supplied; draft.currentPeriodAnswer = .no
        draft.periodEndState = .supplied; draft.periodEnd = try Prompt13LocalDate(year: 2025, month: 1, day: 5)
        draft.historicalPeriodStarts = [try Prompt13LocalDate(year: 2024, month: 12, day: 1)]
        draft.trackingPreferences = [.notes, .periods]
        let store = Prompt14CycleOnboardingStore.inMemory(draft: draft)
        let model = Prompt14CycleOnboardingViewModel(store: store)
        await model.load(); model.beginEditing(.latestPeriod); model.skipCurrentStep()
        await model.waitForPendingSaves()
        let saved = try await store.snapshot()
        XCTAssertNil(saved.latestPeriodStart); XCTAssertNil(saved.currentPeriodAnswer); XCTAssertNil(saved.periodEnd)
        XCTAssertEqual(saved.latestPeriodState, .skipped)
        XCTAssertEqual(saved.historicalPeriodStarts, draft.historicalPeriodStarts)
        XCTAssertEqual(saved.trackingPreferences, draft.trackingPreferences)
        XCTAssertEqual(saved.completedAt, draft.completedAt)
    }

    func testRapidEditsPersistTheLastAnswerWithoutStaleTaskOverwritingIt() async throws {
        let store = Prompt14CycleOnboardingStore.inMemory()
        let model = Prompt14CycleOnboardingViewModel(store: store)
        await model.load()
        for _ in 0..<12 { model.chooseRegularity(.variesALot); model.chooseRegularity(.prettyPredictable) }
        model.chooseRegularity(.variesALittle)
        await model.waitForPendingSaves()
        let saved = try await store.snapshot()
        XCTAssertEqual(saved.subjectiveRegularity, .variesALittle)
        XCTAssertEqual(saved.regularityState, model.draft.regularityState)
        XCTAssertEqual(saved.completedAt, model.draft.completedAt)
        XCTAssertEqual(saved.historicalPeriodStarts, model.draft.historicalPeriodStarts)
        // Store commits intentionally stamp their own updatedAt. Persistence
        // ordering concerns the last supplied answer, not equal clock samples.
    }

    func testRemovingReportedOnboardingContextRemovesItsSharedInfluenceWithoutInferringOtherStates() throws {
        let suite = "Fruitfolio.SetupEditing.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27AContextStore(defaults: defaults)
        var old = Prompt14OnboardingDraft()
        old.cycleContextState = .supplied; old.cycleAffectingContexts = [.hormonalBirthControl, .fertilityMedication]
        old.recentContextState = .supplied; old.recentContexts = [.postpartum, .breastfeeding]
        store.syncFromCycleOnboarding(old)
        XCTAssertEqual(store.context.contraceptionContext.value, .hormonalContraception)
        var removed = old
        removed.cycleContextState = .skipped; removed.cycleAffectingContexts = []
        removed.recentContextState = .skipped; removed.recentContexts = []
        store.syncFromCycleOnboarding(removed, previous: old)
        XCTAssertEqual(store.context.contraceptionContext.value, .unspecified)
        XCTAssertEqual(store.context.fertilityTreatmentContext.value, .unspecified)
        XCTAssertEqual(store.context.reproductiveStage.value, .unspecified)
        XCTAssertEqual(store.context.lactationContext.value, .unspecified)
        store.setReproductiveStage(.pregnant)
        store.syncFromCycleOnboarding(removed, previous: old)
        XCTAssertEqual(store.context.reproductiveStage.value, .pregnant, "An unrelated explicit current state must not be erased or inferred from an old removed answer")
    }
    func testRemovingNoneAndDeclinedOnboardingAnswersDoesNotRetainHiddenSharedValues() throws {
        for decline in [false, true] {
            let suite = "Fruitfolio.SetupRemoval.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
            let store = Prompt27AContextStore(defaults: defaults)
            var old = Prompt14OnboardingDraft()
            old.cycleContextState = .supplied; old.cycleAffectingContexts = decline ? [.preferNotToSay] : [.none]
            old.recentContextState = .supplied; old.recentContexts = decline ? [.preferNotToSay] : [.none]
            store.syncFromCycleOnboarding(old)
            var removed = old
            removed.cycleContextState = .skipped; removed.cycleAffectingContexts = []
            removed.recentContextState = .skipped; removed.recentContexts = []
            store.syncFromCycleOnboarding(removed, previous: old)
            XCTAssertEqual(store.context.contraceptionContext.value, .unspecified)
            XCTAssertEqual(store.context.fertilityTreatmentContext.value, .unspecified)
            XCTAssertEqual(store.context.lactationContext.value, .unspecified)
            XCTAssertEqual(store.context.reproductiveStage.value, .unspecified)
        }
    }

}
