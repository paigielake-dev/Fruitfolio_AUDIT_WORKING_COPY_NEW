import XCTest
@testable import Fruitfolio

final class Prompt1BHormoneAdjustmentTests: XCTestCase {
    @MainActor
    func testRealMeasurementWritesCannotAlterExistingPredictionConfidenceCurvesOrCycleArchive() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let first = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)))
        let today = try Prompt13LocalDate(now, calendar: calendar)
        let cycle = Prompt13CycleStore.inMemory()
        for index in 0..<7 {
            let date = try XCTUnwrap(calendar.date(byAdding: .day, value: index * 28, to: first))
            _ = try await cycle.recordCycleStart(on: Prompt13LocalDate(date, calendar: calendar), now: now, today: today)
        }
        let onboarding = Prompt14CycleOnboardingStore.inMemory(cycleStore: cycle)
        let todayLoader = Prompt16TodayLoader(cycleStore: cycle, onboardingStore: onboarding, calendar: calendar)
        let loader = Prompt22HormoneRhythmLoader(bodyBiologyLoader: .init(todayLoader: todayLoader))
        let beforeInput = try await loader.load(now: now)
        XCTAssertNotEqual(beforeInput.confidence, .unavailable, "Test a real existing prediction, not an empty baseline")
        let beforeArchive = try await cycle.snapshot()
        let original = Prompt22HormoneRhythmEngine().presentation(for: beforeInput)
        let suite = "RhythmMeasurementIsolation." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let measurements = FruitfolioHormoneMeasurementStore(defaults: defaults)
        for hormone in [FruitfolioMeasuredHormone.estradiol, .progesterone] {
            var measurement = FruitfolioHormoneMeasurement()
            measurement.hormone = hormone
            measurement.result = hormone == .estradiol ? "12,50" : "2,500"
            measurement.unit = hormone == .estradiol ? "pg/mL" : "ng/mL"
            measurement.notes = "actual isolated test input, not clinical interpretation"
            try measurements.save(measurement, locale: Locale(identifier: "fr_FR"))
        }
        let bytes = defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        let records = measurements.records
        for requested in [true, false] {
            let decision = FruitfolioHormoneAdjustmentPolicy.decision(requested: requested,
                measurementCount: measurements.records.count, storageUnreadable: measurements.storageUnreadable)
            let afterInput = try await loader.load(now: now)
            XCTAssertEqual(afterInput, beforeInput)
            XCTAssertEqual(afterInput.confidence, beforeInput.confidence)
            XCTAssertFalse(afterInput.measuredHormoneDataAvailable)
            XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.presentation(
                preserving: Prompt22HormoneRhythmEngine().presentation(for: afterInput), decision: decision), original)
            XCTAssertEqual(measurements.records, records)
            XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), bytes)
        }
        let afterArchive = try await cycle.snapshot()
        XCTAssertEqual(afterArchive, beforeArchive)
    }

    func testOptInCannotTurnMeasurementsIntoAnUnreviewedCurve() {
        let original = Prompt22HormoneRhythmEngine().presentation(for: .neutral)
        for requested in [false, true] {
            for count in [0, 1, 20] {
                for unreadable in [false, true] {
                    let decision = FruitfolioHormoneAdjustmentPolicy.decision(requested: requested,
                        measurementCount: count, storageUnreadable: unreadable)
                    XCTAssertFalse(decision.appliesAdjustment)
                    XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.presentation(preserving: original, decision: decision), original)
                }
            }
        }
    }
    func testMissingMeasurementsCorruptStorageAndMissingClinicalMethodStayDistinct() {
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: false, measurementCount: 1, storageUnreadable: false), .original)
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: true, measurementCount: 0, storageUnreadable: false), .noMeasurements)
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: true, measurementCount: 1, storageUnreadable: true), .measurementsUnavailable)
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: true, measurementCount: 20, storageUnreadable: false), .reviewedMethodUnavailable)
    }
}
