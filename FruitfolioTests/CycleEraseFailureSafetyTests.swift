import XCTest
@testable import Fruitfolio

final class CycleEraseFailureSafetyTests: XCTestCase {
    func testFailedCycleErasePreservesExistingRecordedDataInMemoryAndPersistence() async throws {
        let persistence = EraseFailureCyclePersistence()
        let store = Prompt13CycleStore(persistence: persistence)
        _ = try await store.recordCycleStart(on: Prompt13LocalDate(year: 2025, month: 1, day: 1))
        let original = try await store.snapshot()
        XCTAssertEqual(original.cycleStarts.count, 1)
        do { try await store.eraseAllLocalCycleData(); XCTFail("Fixture erase must fail") }
        catch { }
        let after = try await store.snapshot(); let stored = try await persistence.load()
        XCTAssertEqual(after, original); XCTAssertEqual(stored, original)
    }
    func testFailedOnboardingEraseDoesNotDiscardTheVisiblePersistedAnswers() async throws {
        var draft = Prompt14OnboardingDraft(); draft.regularityState = .supplied
        draft.subjectiveRegularity = .variesALittle; draft.completedAt = Date(timeIntervalSince1970: 100)
        let persistence = EraseFailureOnboardingPersistence(draft: draft)
        let store = Prompt14CycleOnboardingStore(draft: draft, persistence: persistence, isLoaded: true)
        do { try await store.eraseOnboardingOnly(); XCTFail("Fixture erase must fail") }
        catch { }
        let after = try await store.snapshot(); let stored = try await persistence.load()
        XCTAssertEqual(after, draft); XCTAssertEqual(stored, draft)
    }
    func testSuccessfulEraseCannotReviveOldHealthDataWhenSavingEmptyEnvelopeFails() async throws {
        let fixture = Prompt13CycleStore.inMemory()
        _ = try await fixture.recordCycleStart(on: Prompt13LocalDate(year: 2025, month: 1, day: 1))
        let original = try await fixture.snapshot()
        let persistence = EraseSuccessSaveFailurePersistence(archive: original)
        let store = Prompt13CycleStore(archive: original, persistence: persistence, isLoaded: true)
        do { try await store.eraseAllLocalCycleData(); XCTFail("Fixture empty-envelope save must fail") }
        catch { }
        let after = try await store.snapshot(); let stored = try await persistence.load()
        XCTAssertTrue(after.cycleStarts.isEmpty); XCTAssertTrue(stored.cycleStarts.isEmpty)
        XCTAssertEqual(after.localProfileID, original.localProfileID)
        XCTAssertEqual(after.deviceID, original.deviceID)
    }
}

private enum EraseFixtureError: Error { case expected }
private actor EraseFailureCyclePersistence: Prompt13CyclePersistence {
    var archive = Prompt13CycleArchive()
    func load() async throws -> Prompt13CycleArchive { archive }
    func save(_ archive: Prompt13CycleArchive) async throws { self.archive = archive }
    func erase() async throws { throw EraseFixtureError.expected }
}
private actor EraseFailureOnboardingPersistence: Prompt14OnboardingPersistence {
    var draft: Prompt14OnboardingDraft
    init(draft: Prompt14OnboardingDraft) { self.draft = draft }
    func load() async throws -> Prompt14OnboardingDraft { draft }
    func save(_ draft: Prompt14OnboardingDraft) async throws { self.draft = draft }
    func erase() async throws { throw EraseFixtureError.expected }
}
private actor EraseSuccessSaveFailurePersistence: Prompt13CyclePersistence {
    var archive: Prompt13CycleArchive
    init(archive: Prompt13CycleArchive) { self.archive = archive }
    func load() async throws -> Prompt13CycleArchive { archive }
    func save(_ archive: Prompt13CycleArchive) async throws { throw EraseFixtureError.expected }
    func erase() async throws { archive = Prompt13CycleArchive() }
}
