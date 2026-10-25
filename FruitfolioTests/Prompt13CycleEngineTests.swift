import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt13CycleEngineTests: XCTestCase {
    private let engine = Prompt13CycleLogicEngine()

    private func date(_ month: Int, _ day: Int, year: Int = 2026) throws -> Prompt13LocalDate {
        try Prompt13LocalDate(year: year, month: month, day: day)
    }

    private func metadata(
        profileID: UUID = UUID(),
        deviceID: UUID = UUID(),
        at now: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> Prompt13RecordMetadata {
        Prompt13RecordMetadata(
            createdAt: now,
            updatedAt: now,
            localProfileID: profileID,
            deviceID: deviceID
        )
    }

    private func archiveWithStarts(_ dates: [Prompt13LocalDate]) -> Prompt13CycleArchive {
        let profile = UUID()
        let device = UUID()
        let starts = dates.map {
            CycleStart(
                date: $0,
                metadata: metadata(profileID: profile, deviceID: device)
            )
        }
        return Prompt13CycleArchive(
            localProfileID: profile,
            deviceID: device,
            cycleStarts: starts
        )
    }

    func testFirstEverCycleStartCreatesOpenCycleAndDayOne() throws {
        let start = try date(8, 4)
        let archive = archiveWithStarts([start])
        let state = try engine.rebuildDerivedState(from: archive, currentDate: start)
        XCTAssertEqual(state.cycles.count, 1)
        XCTAssertEqual(state.cycles[0].status, .open)
        XCTAssertEqual(state.currentCycleDay, 1)
    }

    func testTwoConsecutiveStartsCalculateLength() throws {
        let archive = archiveWithStarts([try date(8, 4), try date(9, 3)])
        let state = try engine.rebuildDerivedState(from: archive, currentDate: try date(9, 3))
        XCTAssertEqual(state.cycles[0].observedLength, 30)
        XCTAssertEqual(state.cycles[0].status, .complete)
        XCTAssertEqual(state.cycles[1].status, .open)
    }

    func testHistoricalCycleDayCalculation() throws {
        let archive = archiveWithStarts([try date(8, 4), try date(9, 3)])
        XCTAssertEqual(try engine.cycleDay(on: try date(8, 16), from: archive), 13)
    }

    func testIrregularHistoryIsPreservedIndividually() throws {
        let archive = archiveWithStarts([
            try date(1, 1),
            try date(1, 27),
            try date(2, 23),
            try date(3, 27),
            try date(4, 25)
        ])
        let state = try engine.rebuildDerivedState(from: archive, currentDate: try date(4, 25))
        XCTAssertEqual(state.statistics.completedCycleLengths, [26, 27, 32, 29])
        XCTAssertNotEqual(state.statistics.mean, 28)
    }

    func testMissingBleedingDaysDoNotBecomeExactPeriodDuration() throws {
        let profile = UUID()
        let cycleID = UUID()
        let logID = UUID()
        let bleeding = [1, 2, 3].map { day -> BleedingObservation in
            BleedingObservation(
                dailyLogID: logID,
                cycleID: cycleID,
                date: try! Prompt13LocalDate(year: 2026, month: 8, day: day),
                flowLevel: .medium,
                metadata: metadata(profileID: profile)
            )
        }
        let archive = Prompt13CycleArchive(localProfileID: profile, bleedingObservations: bleeding)
        let summary = engine.recordedBleedingSummary(cycleID: cycleID, archive: archive)
        XCTAssertEqual(summary.recordedBleedingDays, 3)
        XCTAssertFalse(summary.isComplete)
    }

    func testSpottingDoesNotCreateCycleStart() async throws {
        let store = Prompt13CycleStore.inMemory()
        _ = try await store.recordBleeding(on: try date(8, 4), flowLevel: .spotting)
        let snapshot = try await store.snapshot()
        XCTAssertTrue(snapshot.cycleStarts.isEmpty)
        XCTAssertEqual(snapshot.bleedingObservations.count, 1)
    }

    func testRetroactiveCycleStartPreservesCreationTimestamp() async throws {
        let store = Prompt13CycleStore.inMemory()
        let created = Date(timeIntervalSince1970: 1_800_000_000)
        let start = try await store.recordCycleStart(on: try date(8, 22), now: created)
        XCTAssertEqual(start.date, try date(8, 22))
        XCTAssertEqual(start.metadata.createdAt, created)
    }

    func testEditedCycleStartRecalculatesLength() async throws {
        let store = Prompt13CycleStore.inMemory()
        let first = try await store.recordCycleStart(on: try date(8, 4))
        _ = try await store.recordCycleStart(on: try date(9, 3))
        var state = try await store.derivedState(on: try date(9, 3))
        XCTAssertEqual(state.cycles[0].observedLength, 30)

        _ = try await store.editCycleStart(id: first.id, newDate: try date(8, 5))
        state = try await store.derivedState(on: try date(9, 3))
        XCTAssertEqual(state.cycles[0].observedLength, 29)
    }

    func testDeletedCycleStartIsExcludedFromCalculations() async throws {
        let store = Prompt13CycleStore.inMemory()
        let first = try await store.recordCycleStart(on: try date(8, 4))
        _ = try await store.recordCycleStart(on: try date(9, 3))
        try await store.deleteCycleStart(id: first.id, referenceDate: try date(9, 3))
        let state = try await store.derivedState(on: try date(9, 3))
        XCTAssertEqual(state.cycles.count, 1)
        XCTAssertNil(state.statistics.mean)
    }

    func testPredictionInvalidatesAfterHistoricalEdit() async throws {
        let store = Prompt13CycleStore.inMemory()
        let d1 = try await store.recordCycleStart(on: try date(1, 1))
        _ = try await store.recordCycleStart(on: try date(1, 31))
        _ = try await store.recordCycleStart(on: try date(3, 2))
        _ = try await store.recordCycleStart(on: try date(4, 1))
        let beforeState = try await store.derivedState(on: try date(4, 1))
        let before = beforeState.nextPeriodPrediction
        XCTAssertNotNil(before)
        XCTAssertEqual(beforeState.statistics.completedCycleLengths, [30, 30, 30])

        _ = try await store.editCycleStart(id: d1.id, newDate: try date(1, 3))
        let afterState = try await store.derivedState(on: try date(4, 1))
        let after = afterState.nextPeriodPrediction

        XCTAssertNotEqual(before?.id, after?.id)
        XCTAssertEqual(afterState.statistics.completedCycleLengths, [28, 30, 30])
    }

    func testPredictionNeverBecomesRecordedHistory() throws {
        let archive = archiveWithStarts([try date(1, 1), try date(1, 31), try date(3, 2)])
        let state = try engine.rebuildDerivedState(from: archive, currentDate: try date(3, 2))
        XCTAssertFalse(state.activePredictions.isEmpty)
        XCTAssertTrue(state.activePredictions.allSatisfy { $0.informationType == .estimated })
        XCTAssertEqual(archive.cycleStarts.count, 3)
    }

    func testSymptomMissingDiffersFromExplicitNone() async throws {
        let store = Prompt13CycleStore.inMemory()
        let initial = try await store.snapshot()
        XCTAssertTrue(initial.symptomObservations.isEmpty)
        _ = try await store.recordSymptom(on: try date(8, 4), type: .cramps, severity: .none)
        let after = try await store.snapshot()
        XCTAssertEqual(after.symptomObservations.count, 1)
        XCTAssertEqual(after.symptomObservations[0].severity, .none)
    }

    func testTemperatureConversionPreservesOriginal() throws {
        let observation = try TemperatureObservation(
            date: try date(8, 4),
            value: 98.6,
            unit: .fahrenheit,
            metadata: metadata()
        )
        XCTAssertEqual(observation.originalValue, 98.6, accuracy: 0.0001)
        XCTAssertEqual(observation.originalUnit, .fahrenheit)
        XCTAssertEqual(observation.canonicalCelsius, 37.0, accuracy: 0.0001)
        XCTAssertEqual(observation.displayValue(in: .fahrenheit), 98.6, accuracy: 0.0001)
    }

    func testDSTBoundaryUsesCalendarDatesNotHours() throws {
        let before = try date(3, 8)
        let after = try before.addingDays(1)
        XCTAssertEqual(after, try date(3, 9))
        XCTAssertEqual(try before.days(to: after), 1)
    }

    func testTimezoneChangeDoesNotMutateStoredLocalDate() throws {
        let stored = try date(11, 2)
        let encoded = try JSONEncoder().encode(stored)
        let decoded = try JSONDecoder().decode(Prompt13LocalDate.self, from: encoded)
        XCTAssertEqual(decoded, stored)
    }

    func testOfflineLogCreationPersistsInMemory() async throws {
        let store = Prompt13CycleStore.inMemory()
        _ = try await store.recordNote(on: try date(8, 4), text: "offline note")
        let snapshot = try await store.snapshot()
        XCTAssertEqual(snapshot.notes.first?.text, "offline note")
    }

    func testSyncConflictDetectedForSameIDSameRevisionDifferentContent() throws {
        let profile = UUID()
        let id = UUID()
        var localStart = CycleStart(id: id, date: try date(8, 4), metadata: metadata(profileID: profile))
        var remoteStart = localStart
        remoteStart.date = try date(8, 5)
        localStart.metadata.revision = 2
        remoteStart.metadata.revision = 2
        let local = Prompt13CycleArchive(localProfileID: profile, cycleStarts: [localStart])
        let remote = Prompt13CycleArchive(localProfileID: profile, cycleStarts: [remoteStart])
        let conflicts = Prompt13SyncConflictDetector().conflicts(local: local, remote: remote)
        XCTAssertTrue(conflicts.contains { $0.kind == .sameRecordSameRevisionDifferentContent })
    }

    func testDuplicateCycleStartDetection() async throws {
        let store = Prompt13CycleStore.inMemory()
        _ = try await store.recordCycleStart(on: try date(8, 4))
        do {
            _ = try await store.recordCycleStart(on: try date(8, 4))
            XCTFail("Expected duplicate rejection")
        } catch let error as Prompt13CycleError {
            XCTAssertEqual(error, .duplicateCycleStartDate(try date(8, 4)))
        }
    }

    func testInsufficientPredictionDataProducesNoPrediction() throws {
        let archive = archiveWithStarts([try date(8, 4), try date(9, 3)])
        let state = try engine.rebuildDerivedState(from: archive, currentDate: try date(9, 3))
        XCTAssertTrue(state.activePredictions.isEmpty)
    }

    func testConfidenceChangesAsHistoryGrows() throws {
        let developingArchive = archiveWithStarts([
            try date(1, 1), try date(1, 31), try date(3, 2)
        ])
        let developing = try engine.rebuildDerivedState(from: developingArchive, currentDate: try date(3, 2))
        XCTAssertEqual(developing.nextPeriodPrediction?.confidence, .developing)

        let strongArchive = archiveWithStarts([
            try date(1, 1), try date(1, 31), try date(3, 2), try date(4, 1), try date(5, 1)
        ])
        let strong = try engine.rebuildDerivedState(from: strongArchive, currentDate: try date(5, 1))
        XCTAssertEqual(strong.nextPeriodPrediction?.confidence, .strong)
    }

    func testPatternInsightRequiresMinimumEvidence() throws {
        let twoCycles = archiveWithStarts([try date(1, 1), try date(1, 31), try date(3, 2)])
        let state = try engine.rebuildDerivedState(from: twoCycles, currentDate: try date(3, 2))
        XCTAssertFalse(state.patternInsights.contains { $0.insightType == .cycleLengthRange })

        let threeCycles = archiveWithStarts([try date(1, 1), try date(1, 31), try date(3, 2), try date(4, 1)])
        let state2 = try engine.rebuildDerivedState(from: threeCycles, currentDate: try date(4, 1))
        XCTAssertTrue(state2.patternInsights.contains { $0.insightType == .cycleLengthRange })
    }

    func testDeletedObservationDisappearsFromInsights() async throws {
        let store = Prompt13CycleStore.inMemory()
        _ = try await store.recordCycleStart(on: try date(1, 1))
        _ = try await store.recordCycleStart(on: try date(1, 31))
        _ = try await store.recordCycleStart(on: try date(3, 2))
        _ = try await store.recordCycleStart(on: try date(4, 1))

        let a = try await store.recordSymptom(on: try date(1, 2), type: .cramps, severity: .moderate)
        _ = try await store.recordSymptom(on: try date(2, 1), type: .cramps, severity: .moderate)
        _ = try await store.recordSymptom(on: try date(3, 3), type: .cramps, severity: .moderate)

        var state = try await store.derivedState(on: try date(4, 1))
        XCTAssertTrue(state.patternInsights.contains { $0.insightType == .symptomNearCycleStart })

        try await store.deleteObservation(id: a.id, referenceDate: try date(4, 1))
        state = try await store.derivedState(on: try date(4, 1))
        XCTAssertFalse(state.patternInsights.contains { $0.insightType == .symptomNearCycleStart })
    }

    func testEducationalDataNeverBecomesRecorded() throws {
        let snapshot = PredictionSnapshot(
            generatedAt: Date(),
            predictionType: .phase,
            confidence: .limited,
            inputCycleIDs: [],
            methodVersion: "test",
            validFrom: Date()
        )
        XCTAssertEqual(snapshot.informationType, .estimated)
        XCTAssertNotEqual(snapshot.informationType, .recorded)
    }

    func testNoDay14OvulationFallbackAndNoFertileFallback() throws {
        let archive = archiveWithStarts([
            try date(1, 1), try date(1, 31), try date(3, 2), try date(4, 1), try date(5, 1)
        ])
        let state = try engine.rebuildDerivedState(from: archive, currentDate: try date(5, 14))
        XCTAssertFalse(state.activePredictions.contains { $0.predictionType == .ovulation })
        XCTAssertFalse(state.activePredictions.contains { $0.predictionType == .fertileWindow })
    }

    func testNo28DayFallback() throws {
        let archive = archiveWithStarts([try date(8, 4)])
        let state = try engine.rebuildDerivedState(from: archive, currentDate: try date(8, 20))
        XCTAssertNil(state.statistics.mean)
        XCTAssertTrue(state.activePredictions.isEmpty)
    }

    func testFutureRecordedObservationCanBeRejectedExplicitly() async throws {
        let store = Prompt13CycleStore.inMemory()
        do {
            _ = try await store.recordSymptom(
                on: try date(9, 8),
                type: .headache,
                severity: .mild,
                today: try date(9, 7)
            )
            XCTFail("Expected future observation rejection")
        } catch let error as Prompt13CycleError {
            XCTAssertEqual(error, .futureObservationNotAllowed)
        }
    }

    func testArchiveRoundTripRegeneratesDerivedState() throws {
        let archive = archiveWithStarts([
            try date(1, 1), try date(1, 31), try date(3, 2), try date(4, 1)
        ])
        let encoded = try JSONEncoder().encode(archive)
        let decoded = try JSONDecoder().decode(Prompt13CycleArchive.self, from: encoded)
        let state = try engine.rebuildDerivedState(from: decoded, currentDate: try date(4, 1))
        XCTAssertEqual(state.statistics.completedCycleLengths, [30, 30, 30])
        XCTAssertNotNil(state.nextPeriodPrediction)
    }

    func testEraseAllLocalCycleDataClearsSensitiveRecords() async throws {
        let store = Prompt13CycleStore.inMemory()
        _ = try await store.recordCycleStart(on: try date(8, 4))
        _ = try await store.recordNote(on: try date(8, 4), text: "sensitive")
        try await store.eraseAllLocalCycleData()
        let snapshot = try await store.snapshot()
        XCTAssertTrue(snapshot.cycleStarts.isEmpty)
        XCTAssertTrue(snapshot.notes.isEmpty)
        XCTAssertTrue(snapshot.predictionSnapshots.isEmpty)
    }

    func testPregnancyTestObservationDoesNotCreatePregnancyState() async throws {
        let store = Prompt13CycleStore.inMemory()
        let test = try await store.recordPregnancyTest(on: try date(8, 4), result: .positive)
        let snapshot = try await store.snapshot()
        XCTAssertEqual(test.result, .positive)
        XCTAssertEqual(test.informationType, .recorded)
        XCTAssertTrue(snapshot.cycleStarts.isEmpty)
    }
}
