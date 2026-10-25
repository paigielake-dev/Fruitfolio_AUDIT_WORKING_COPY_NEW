import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt20CoreTests: XCTestCase {
    private func calendar(_ timeZoneID: String = "America/New_York") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 12,
        calendar: Calendar? = nil
    ) -> Date {
        let calendar = calendar ?? self.calendar()
        return calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Prompt20LocalDay {
        Prompt20LocalDay(year: year, month: month, day: day)
    }

    func testLocalDayRoundTripUsesCalendarDay() {
        let cal = calendar()
        let source = date(2026, 9, 7, hour: 23, calendar: cal)
        let local = Prompt20LocalDay(date: source, calendar: cal)
        XCTAssertEqual(local, day(2026, 9, 7))
        XCTAssertEqual(Prompt20LocalDay(date: local.date(in: cal)!, calendar: cal), local)
    }

    func testLocalDaySurvivesDSTBoundary() {
        let cal = calendar()
        let local = day(2026, 3, 8)
        let restored = local.date(in: cal)!
        XCTAssertEqual(Prompt20LocalDay(date: restored, calendar: cal), local)
    }

    func testFutureDateRuleUsesLocalCalendarDayNotElapsedHours() {
        let cal = calendar()
        let now = date(2026, 9, 7, hour: 23, calendar: cal)
        XCTAssertFalse(Prompt20DailyLogRules.isFuture(day(2026, 9, 7), relativeTo: now, calendar: cal))
        XCTAssertTrue(Prompt20DailyLogRules.isFuture(day(2026, 9, 8), relativeTo: now, calendar: cal))
    }

    func testPartialBleedingOnlyLogIsValid() throws {
        var draft = Prompt20DailyLogDraft()
        draft.bleedingLevel = .spotting
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.bleeding?.level, .spotting)
        XCTAssertNil(log.symptoms)
        XCTAssertNil(log.temperature)
        XCTAssertTrue(log.hasRecordedContent)
    }

    func testBleedingObservationDoesNotDeclarePeriodInCalendarBridge() throws {
        var draft = Prompt20DailyLogDraft()
        draft.bleedingLevel = .heavy
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotations = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: Prompt19CalendarMonth(year: 2026, month: 9),
            calendar: calendar()
        )
        XCTAssertEqual(annotations.count, 1)
        XCTAssertFalse(annotations[0].recordedPeriod)
        XCTAssertFalse(annotations[0].predictedPeriod)
        XCTAssertFalse(annotations[0].fertileEstimated)
        XCTAssertFalse(annotations[0].ovulationEstimated)
    }

    func testSymptomsRemainStructuredAndNoteSeparate() throws {
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps, .bloating, .headache]
        draft.symptomNote = "after lunch"
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.symptoms?.selectedIDs, [.cramps, .bloating, .headache])
        XCTAssertEqual(log.symptoms?.note, "after lunch")
    }

    func testSymptomSummaryDoesNotInventSeverity() throws {
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps]
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let summary = Prompt20DailyLogRules.summary(for: log)
        XCTAssertEqual(summary.symptomNames, ["cramps"])
        XCTAssertFalse(summary.symptomNames.contains { $0.contains("mild") || $0.contains("severe") })
    }

    func testFahrenheitConvertsToCanonicalCelsius() {
        let value = Prompt20TemperatureObservation(
            originalValue: 98.6,
            originalUnit: .fahrenheit,
            readingType: .general
        )
        XCTAssertEqual(value.canonicalCelsius, 37.0, accuracy: 0.0001)
        XCTAssertEqual(value.value(in: .fahrenheit), 98.6, accuracy: 0.0001)
    }

    func testCelsiusConvertsToFahrenheit() {
        let value = Prompt20TemperatureObservation(
            originalValue: 36.5,
            originalUnit: .celsius,
            readingType: .basalWaking
        )
        XCTAssertEqual(value.value(in: .fahrenheit), 97.7, accuracy: 0.0001)
    }

    func testTemperatureValidationRejectsNonnumericInputWithoutDiscardingDraft() {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "ninety seven"
        let result = Prompt20DailyLogRules.validate(draft)
        XCTAssertEqual(result.issues, [.invalidTemperatureFormat])
        XCTAssertEqual(draft.temperatureText, "ninety seven")
    }

    func testTemperatureValidationRejectsObviousUnitTypo() {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "986"
        draft.temperatureUnit = .fahrenheit
        XCTAssertEqual(Prompt20DailyLogRules.validate(draft).issues, [.implausibleTemperature])
    }

    func testTemperatureValidationAcceptsReasonableGeneralInput() {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "98.6"
        draft.temperatureUnit = .fahrenheit
        XCTAssertTrue(Prompt20DailyLogRules.validate(draft).isValid)
    }

    func testGeneralTemperatureDoesNotBecomeBBTCalendarMarker() throws {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "98.6"
        draft.temperatureUnit = .fahrenheit
        draft.temperatureReadingType = .general
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertFalse(annotation.bbtRecorded)
        XCTAssertNil(annotation.temperatureDisplay)
    }

    func testBasalTemperatureBecomesBBTCalendarMarker() throws {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "97.8"
        draft.temperatureUnit = .fahrenheit
        draft.temperatureReadingType = .basalWaking
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertTrue(annotation.bbtRecorded)
        XCTAssertEqual(annotation.temperatureDisplay, "97.8°F · basal / waking")
    }

    func testCervicalFluidStaysObservationOnly() throws {
        var draft = Prompt20DailyLogDraft()
        draft.cervicalFluidCategory = .eggWhiteStretchy
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.cervicalFluid?.category, .eggWhiteStretchy)
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertFalse(annotation.fertileEstimated)
        XCTAssertFalse(annotation.ovulationEstimated)
    }

    func testMedicationRequiresNameWhenOtherFieldsContainContent() {
        var draft = Prompt20DailyLogDraft()
        draft.medications = [Prompt20MedicationEntry(dose: "10 mg")]
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.medicationNameRequired(index: 0)]
        )
    }

    func testMultipleMedicationsRemainSeparateRows() throws {
        var draft = Prompt20DailyLogDraft()
        draft.medications = [
            Prompt20MedicationEntry(name: "Medication A", dose: "10 mg"),
            Prompt20MedicationEntry(name: "Supplement B", time: "8:00 am")
        ]
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.medications.count, 2)
        XCTAssertEqual(log.medications.map(\.name), ["Medication A", "Supplement B"])
    }

    func testGeneralNoteIsSensitiveDataFieldNotCalendarPrimaryState() throws {
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "private note"
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.generalNote?.text, "private note")
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertTrue(annotation.noteAdded)
        XCTAssertEqual(annotation.noteText, "private note")
        XCTAssertEqual(annotation.primaryState, .none)
    }

    func testEditPreservesStableIDAndCreatedAtAndIncrementsRevision() throws {
        var firstDraft = Prompt20DailyLogDraft()
        firstDraft.selectedSymptoms = [.cramps]
        let created = date(2026, 9, 7, hour: 10)
        let first = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: firstDraft,
            existing: nil,
            now: created
        )

        var editedDraft = firstDraft
        editedDraft.selectedSymptoms.insert(.bloating)
        let editedAt = date(2026, 9, 7, hour: 11)
        let edited = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: editedDraft,
            existing: first,
            now: editedAt
        )

        XCTAssertEqual(edited.id, first.id)
        XCTAssertEqual(edited.createdAt, first.createdAt)
        XCTAssertEqual(edited.revision, first.revision + 1)
        XCTAssertEqual(edited.updatedAt, editedAt)
    }

    func testInMemoryRepositoryEnforcesOneCanonicalLogPerOwnerAndDate() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        let target = day(2026, 9, 7)
        let now = date(2026, 9, 7, calendar: cal)

        var firstDraft = Prompt20DailyLogDraft()
        firstDraft.generalNote = "first"
        let first = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: firstDraft,
            now: now,
            requestID: UUID()
        )!

        var secondDraft = firstDraft
        secondDraft.generalNote = "edited"
        let second = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: secondDraft,
            now: now.addingTimeInterval(60),
            requestID: UUID()
        )!

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(second.generalNote?.text, "edited")
        let activeLogs = try await repo.allActiveLogs(ownerID: .localDevice)
        XCTAssertEqual(activeLogs.count, 1)
    }

    func testRepeatedRequestIDIsIdempotent() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        let target = day(2026, 9, 7)
        let now = date(2026, 9, 7, calendar: cal)
        let requestID = UUID()
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "once"

        let first = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: draft,
            now: now,
            requestID: requestID
        )!
        let second = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: draft,
            now: now.addingTimeInterval(90),
            requestID: requestID
        )!

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.revision, second.revision)
        XCTAssertEqual(first.updatedAt, second.updatedAt)
    }

    func testIntentionallyClearingExistingLogRemovesActiveLog() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        let target = day(2026, 9, 7)
        let now = date(2026, 9, 7, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "delete me"
        _ = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: draft,
            now: now,
            requestID: UUID()
        )
        let cleared = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: Prompt20DailyLogDraft(),
            now: now.addingTimeInterval(60),
            requestID: UUID()
        )
        XCTAssertNil(cleared)
        let loadedAfterClear = try await repo.load(ownerID: .localDevice, date: target)
        XCTAssertNil(loadedAfterClear)
    }

    func testRepositoryRejectsFutureObservationSaveEvenIfUICheckIsBypassed() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "future body observation"
        do {
            _ = try await repo.save(
                ownerID: .localDevice,
                date: day(2026, 9, 8),
                draft: draft,
                now: date(2026, 9, 7, calendar: cal),
                requestID: UUID()
            )
            XCTFail("Future observation save should have failed")
        } catch let error as Prompt20DailyLogDomainError {
            XCTAssertEqual(error, .futureDate)
        }
    }

    func testFileStorePersistsAndReloadsCanonicalLog() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps, .headache]
        draft.generalNote = "persisted"
        let now = date(2026, 9, 7, calendar: cal)
        let saved = try await firstStore.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now,
            requestID: UUID()
        )!

        let reloadedStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let loaded = try await reloadedStore.load(
            ownerID: .localDevice,
            date: day(2026, 9, 7)
        )
        XCTAssertEqual(loaded, saved)
    }

    func testFileStorePersistsDeletionTombstoneAsInactive() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.bleedingLevel = .light
        let now = date(2026, 9, 7, calendar: cal)
        _ = try await store.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now,
            requestID: UUID()
        )
        _ = try await store.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: Prompt20DailyLogDraft(),
            now: now.addingTimeInterval(60),
            requestID: UUID()
        )

        let reloaded = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let loadedAfterReload = try await reloaded.load(ownerID: .localDevice, date: day(2026, 9, 7))
        let activeAfterReload = try await reloaded.allActiveLogs(ownerID: .localDevice)
        XCTAssertNil(loadedAfterReload)
        XCTAssertTrue(activeAfterReload.isEmpty)
    }

    func testCalendarBridgeFiltersToDisplayedMonth() throws {
        var septemberDraft = Prompt20DailyLogDraft()
        septemberDraft.selectedSymptoms = [.cramps]
        let september = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: septemberDraft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        var octoberDraft = Prompt20DailyLogDraft()
        octoberDraft.generalNote = "october"
        let october = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 10, 1),
            draft: octoberDraft,
            existing: nil,
            now: date(2026, 10, 1)
        )
        let annotations = Prompt20CalendarIntegration.annotations(
            for: [september, october],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        )
        XCTAssertEqual(annotations.map(\.key), [Prompt19CalendarDateKey(year: 2026, month: 9, day: 7)])
    }

    func testCalendarMetadataRespectsPrompt19TwoIndicatorPriority() throws {
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps]
        draft.temperatureText = "97.8"
        draft.temperatureUnit = .fahrenheit
        draft.temperatureReadingType = .basalWaking
        draft.generalNote = "note"
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertEqual(annotation.visibleMetadata, [.bbt, .symptom])
        XCTAssertTrue(annotation.noteAdded)
    }

    func testEmptyDraftProducesNoRecordedObservations() throws {
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: Prompt20DailyLogDraft(),
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertFalse(log.hasRecordedContent)
        XCTAssertNil(log.bleeding)
        XCTAssertNil(log.symptoms)
        XCTAssertNil(log.temperature)
        XCTAssertNil(log.cervicalFluid)
        XCTAssertTrue(log.medications.isEmpty)
        XCTAssertNil(log.generalNote)
    }

    func testFailedFileWriteRollsBackInMemoryMutation() async throws {
        let cal = calendar()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let blockingFile = root.appendingPathComponent("not-a-directory")
        try Data("block".utf8).write(to: blockingFile)
        let impossibleURL = blockingFile.appendingPathComponent("daily-logs.json")
        let store = Prompt20CycleDailyLogStore(fileURL: impossibleURL, calendar: cal)

        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "must not survive a failed write"

        do {
            _ = try await store.save(
                ownerID: .localDevice,
                date: day(2026, 9, 7),
                draft: draft,
                now: date(2026, 9, 7, calendar: cal),
                requestID: UUID()
            )
            XCTFail("Write should fail when the parent path is a regular file")
        } catch let error as Prompt20DailyLogDomainError {
            XCTAssertEqual(error, .persistenceUnavailable)
        }

        let loaded = try await store.load(ownerID: .localDevice, date: day(2026, 9, 7))
        XCTAssertNil(loaded)
    }

    func testCorruptPersistenceNeverSilentlyTurnsIntoEmptyStore() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not valid json".utf8).write(to: fileURL)

        let store = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        for _ in 0..<2 {
            do {
                _ = try await store.load(ownerID: .localDevice, date: day(2026, 9, 7))
                XCTFail("Corrupt persistence must not be treated as an empty archive")
            } catch let error as Prompt20DailyLogDomainError {
                XCTAssertEqual(error, .corruptPersistence)
            }
        }
    }

    func testPersistedRequestIDRemainsIdempotentAfterStoreReload() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let requestID = UUID()
        let now = date(2026, 9, 7, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "only once"

        let firstStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let first = try await firstStore.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now,
            requestID: requestID
        )!

        let reloadedStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let second = try await reloadedStore.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now.addingTimeInterval(120),
            requestID: requestID
        )!

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.revision, first.revision)
        XCTAssertEqual(second.updatedAt, first.updatedAt)
    }

    func testBleedingNoteWithoutLevelIsRejectedRatherThanSilentlyDropped() {
        var draft = Prompt20DailyLogDraft()
        draft.bleedingNote = "important detail"
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.bleedingLevelRequiredForNote]
        )
    }

    func testTemperatureContextWithoutValueIsRejectedRatherThanSilentlyDropped() {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureReadingType = .basalWaking
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.temperatureValueRequired]
        )
    }

    func testTemperatureNoteWithoutValueIsRejectedRatherThanSilentlyDropped() {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureNote = "slept poorly"
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.temperatureValueRequired]
        )
    }

    func testCervicalNoteWithoutCategoryIsRejectedRatherThanSilentlyDropped() {
        var draft = Prompt20DailyLogDraft()
        draft.cervicalFluidNote = "hard to categorize"
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.cervicalCategoryRequiredForNote]
        )
    }

    func testPersistencePreservesSubsecondRevisionTimestamps() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let preciseNow = Date(timeIntervalSince1970: 1_788_800_000.731)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "timestamp precision"

        let store = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let saved = try await store.save(
            ownerID: .localDevice,
            date: Prompt20LocalDay(date: preciseNow, calendar: cal),
            draft: draft,
            now: preciseNow,
            requestID: UUID()
        )!

        let reloaded = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let loaded = try await reloaded.load(ownerID: .localDevice, date: saved.date)!
        XCTAssertEqual(loaded.createdAt, preciseNow)
        XCTAssertEqual(loaded.updatedAt, preciseNow)
    }
}
