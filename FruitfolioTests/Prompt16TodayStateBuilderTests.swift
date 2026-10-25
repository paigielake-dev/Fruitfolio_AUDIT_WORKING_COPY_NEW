import XCTest
@testable import Fruitfolio

nonisolated final class Prompt16TodayStateBuilderTests: XCTestCase {
    func testNoHistoryDoesNotInventCycleDayOrPhase() throws {
        let today = try Prompt13LocalDate(year: 2026, month: 9, day: 7)
        let derived = Prompt13DerivedState(
            generatedAt: Date(timeIntervalSince1970: 1_788_739_200),
            cycles: [],
            statistics: Prompt13CycleStatistics(
                completedCycleLengths: [],
                mean: nil,
                median: nil,
                medianAbsoluteDeviation: nil,
                minimum: nil,
                maximum: nil,
                variation: .insufficientData
            ),
            currentCycleDay: nil,
            currentCycleID: nil,
            currentDate: today,
            activePredictions: [],
            patternInsights: [],
            needsReviewCycleStartIDs: []
        )

        let state = Prompt16TodayStateBuilder().makeState(
            archive: Prompt13CycleArchive(),
            derivedState: derived,
            onboarding: Prompt14OnboardingDraft()
        )

        XCTAssertNil(state.cycleDay)
        XCTAssertEqual(state.context, .insufficientData)
        XCTAssertFalse(state.bbtShortcutEnabled)
    }

    func testCurrentPeriodAnswerProducesMenstruationContextWithoutPrediction() throws {
        let today = try Prompt13LocalDate(year: 2026, month: 9, day: 7)
        let derived = Prompt13DerivedState(
            generatedAt: Date(timeIntervalSince1970: 1_788_739_200),
            cycles: [],
            statistics: Prompt13CycleStatistics(
                completedCycleLengths: [],
                mean: nil,
                median: nil,
                medianAbsoluteDeviation: nil,
                minimum: nil,
                maximum: nil,
                variation: .insufficientData
            ),
            currentCycleDay: 3,
            currentCycleID: nil,
            currentDate: today,
            activePredictions: [],
            patternInsights: [],
            needsReviewCycleStartIDs: []
        )

        var onboarding = Prompt14OnboardingDraft()
        onboarding.latestPeriodStart = try Prompt13LocalDate(year: 2026, month: 9, day: 5)
        onboarding.latestPeriodState = .supplied
        onboarding.currentPeriodAnswer = .yes
        onboarding.currentPeriodState = .supplied

        let state = Prompt16TodayStateBuilder().makeState(
            archive: Prompt13CycleArchive(),
            derivedState: derived,
            onboarding: onboarding
        )

        XCTAssertEqual(state.cycleDay, 3)
        XCTAssertEqual(state.context, .menstruation)
    }

    func testBBTShortcutRequiresBothTrackingPreferenceAndSetupChoice() {
        var onboarding = Prompt14OnboardingDraft()
        onboarding.trackingPreferences = [.bbt]
        onboarding.bbtTrackingChoice = .yes
        onboarding.bbtUnit = .fahrenheit

        let derived = Prompt13DerivedState(
            generatedAt: Date(),
            cycles: [],
            statistics: Prompt13CycleStatistics(
                completedCycleLengths: [],
                mean: nil,
                median: nil,
                medianAbsoluteDeviation: nil,
                minimum: nil,
                maximum: nil,
                variation: .insufficientData
            ),
            currentCycleDay: nil,
            currentCycleID: nil,
            currentDate: try! Prompt13LocalDate(year: 2026, month: 9, day: 7),
            activePredictions: [],
            patternInsights: [],
            needsReviewCycleStartIDs: []
        )

        let state = Prompt16TodayStateBuilder().makeState(
            archive: Prompt13CycleArchive(),
            derivedState: derived,
            onboarding: onboarding
        )

        XCTAssertTrue(state.bbtShortcutEnabled)
        XCTAssertEqual(state.bbtUnit, .fahrenheit)
    }
}
