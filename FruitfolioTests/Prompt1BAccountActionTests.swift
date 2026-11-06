import Foundation
import XCTest
@testable import Fruitfolio

/// Only rejects the selected write; reads/normal writes retain real UserDefaults
/// suite persistence. This is an acknowledgment fault, not replacement storage.
private final class Prompt1BRejectingAccountDefaults: UserDefaults, @unchecked Sendable {
    var rejectSnapshotWrites = false
    private(set) var snapshotWriteAttempts = 0
    override func set(_ value: Any?, forKey defaultName: String) {
        if defaultName == "fixture" {
            snapshotWriteAttempts += 1
            if rejectSnapshotWrites { return }
        }
        super.set(value, forKey: defaultName)
    }
}

@MainActor
final class Prompt1BAccountActionTests: XCTestCase {
    func testExpectedSignOutKeepsPendingMarkerContainerAndActualCycleFile() async throws {
        let suite = "Fruitfolio.AccountSignOut." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: file))
        let day = try Prompt13LocalDate(year: 2026, month: 9, day: 7)
        _ = try await cycle.recordNote(on: day, text: "recorded fixture note", today: day)
        let bytes = try Data(contentsOf: file)
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        // Development identity is a local fixture, never real authentication.
        try store.signInForDevelopment(email: "fixture-a@example.invalid")
        store.markLocalChangePending()
        let expected = store.accountActionSnapshot
        try store.signOut(keepLocalData: true, expecting: expected)
        XCTAssertNil(store.account); XCTAssertEqual(store.authenticationState, .signedOut)
        XCTAssertEqual(store.syncState, .localOnly); XCTAssertTrue(store.pendingLocalChanges)
        XCTAssertEqual(store.localDataContainerID, expected.localDataContainerID)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let restored = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        XCTAssertNil(restored.account); XCTAssertTrue(restored.pendingLocalChanges)
        XCTAssertEqual(restored.localDataContainerID, expected.localDataContainerID)
    }

    func testStaleConfirmationCannotSignOutDeleteOrSyncDifferentIdentity() async throws {
        let suite = "Fruitfolio.AccountStaleIdentity." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        try store.signInForDevelopment(email: "fixture-a@example.invalid")
        let stale = store.accountActionSnapshot
        try store.signInForDevelopment(email: "fixture-b@example.invalid")
        let current = store.accountActionSnapshot, bytes = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try store.signOut(expecting: stale)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .accountChanged) }
        XCTAssertThrowsError(try store.deleteAccountAndAssociatedRemoteData(expecting: stale)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .accountChanged) }
        XCTAssertThrowsError(try store.attemptSyncNow(expecting: stale)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .accountChanged) }
        XCTAssertEqual(store.accountActionSnapshot, current)
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
    }

    func testNewPendingChangesInvalidateEarlierConfirmationWithoutClearingThem() async throws {
        let suite = "Fruitfolio.AccountPendingIntent." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        try store.signInForDevelopment(email: "fixture@example.invalid")
        let stale = store.accountActionSnapshot
        store.markLocalChangePending()
        let bytes = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try store.signOut(expecting: stale)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .accountChanged) }
        XCTAssertTrue(store.pendingLocalChanges); XCTAssertTrue(store.isSignedIn)
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
    }

    func testExplicitSyncAndDeletionFailuresKeepIdentityAndPendingInformation() async throws {
        let suite = "Fruitfolio.AccountUnavailableActions." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        try store.signInForDevelopment(email: "fixture@example.invalid")
        store.markLocalChangePending()
        let expected = store.accountActionSnapshot
        XCTAssertThrowsError(try store.attemptSyncNow(expecting: expected)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .serviceNotConfigured) }
        XCTAssertEqual(store.syncState, .unavailable)
        XCTAssertEqual(store.accountActionSnapshot, expected)
        let afterSync = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try store.deleteAccountAndAssociatedRemoteData(expecting: expected)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .remoteDeletionUnavailable) }
        XCTAssertEqual(defaults.data(forKey: "fixture"), afterSync)
        XCTAssertTrue(store.pendingLocalChanges)
    }

    func testSignOutCannotImplicitlySelectLocalDataDeletion() async throws {
        let suite = "Fruitfolio.AccountSeparateDeletion." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        try store.signInForDevelopment(email: "fixture@example.invalid")
        let before = store.accountActionSnapshot, bytes = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try store.signOut(keepLocalData: false, expecting: before)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .localDataDeletionRequiresReview) }
        XCTAssertEqual(store.accountActionSnapshot, before)
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
    }

    func testRejectedSignOutWriteRollsBackCacheAndReportsFailureAfterOneAttempt() async throws {
        let suite = "Fruitfolio.AccountRejectedWrite." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BRejectingAccountDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        try store.signInForDevelopment(email: "fixture@example.invalid")
        store.markLocalChangePending()
        let before = store.accountActionSnapshot, bytes = defaults.data(forKey: "fixture"), attempts = defaults.snapshotWriteAttempts
        defaults.rejectSnapshotWrites = true
        XCTAssertThrowsError(try store.signOut(expecting: before)) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .localRecordProtected) }
        XCTAssertEqual(defaults.snapshotWriteAttempts, attempts + 1)
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        XCTAssertEqual(store.accountActionSnapshot, before)
        XCTAssertFalse(store.canPersistAccountChanges)
    }

    func testExplicitNullAccountMetadataIsProtectedFromLossyRoundTrip() async throws {
        let suite = "Fruitfolio.AccountNullMetadata." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let seed = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "seed")
        seed.markLocalChangePending()
        let original = try XCTUnwrap(defaults.data(forKey: "seed"))
        for field in ["account", "lastExport"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
            object[field] = NSNull()
            let bytes = try JSONSerialization.data(withJSONObject: object)
            defaults.set(bytes, forKey: "fixture")
            let protected = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
            XCTAssertFalse(protected.canPersistAccountChanges)
            XCTAssertThrowsError(try protected.signOut()) { XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .localRecordProtected) }
            XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        }
    }
    func testRejectedPrivacyWriteRevertsToggleAndPreservesSavedRecord() async throws {
        let suite = "Fruitfolio.AccountRejectedPrivacy." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BRejectingAccountDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        try store.signInForDevelopment(email: "fixture@example.invalid")
        let before = store.usePrivacyModeOnLockScreen, bytes = defaults.data(forKey: "fixture")
        let attempts = defaults.snapshotWriteAttempts
        defaults.rejectSnapshotWrites = true
        store.usePrivacyModeOnLockScreen = !before
        XCTAssertEqual(store.usePrivacyModeOnLockScreen, before)
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        XCTAssertEqual(defaults.snapshotWriteAttempts, attempts + 1)
        XCTAssertFalse(store.canPersistAccountChanges)
    }

}

/// Explicit inference fixture preserves placeholders, never translates identities.
private actor AccountStatusTranslationFixture: FruitfolioLocalTranslationRuntime {
    private let dropMarkers: Bool
    private(set) var input: String?
    init(dropMarkers: Bool = false) { self.dropMarkers = dropMarkers }
    func translate(_ text: String, targetTag: String) async throws -> String {
        input = text
        return dropMarkers ? "fixture heading" : text.replacingOccurrences(of: "signed in with", with: "fixture heading")
    }
    func releaseResources() {}
}

final class Prompt1BAccountStatusTranslationTests: XCTestCase {
    private func identity() -> Prompt12AccountIdentity {
        .init(provider: "[**Fixture Provider**]", email: "Fixture_Name+tag@Example.invalid", username: "literal_name")
    }
    func testActualAccountStatusMasksAndRestoresEscapedIdentityFields() async throws {
        let account = identity()
        let status = Prompt12AccountStatusText(identity: account)
        XCTAssertTrue(status.source.contains(#"\[\*\*Fixture Provider\*\*\]"#))
        XCTAssertTrue(status.source.contains(#"Fixture\_Name+tag@Example.invalid"#))
        let runtime = AccountStatusTranslationFixture()
        let service = FruitfolioTranslationService(runtime: runtime)
        let result = try await service.translateForDisplay(status.source, language: .german,
            protectedLiterals: status.protectedLiterals, preferCatalog: false)
        XCTAssertEqual(result.text, status.source.replacingOccurrences(of: "signed in with", with: "fixture heading"))
        let captured = await runtime.input
        let input = try XCTUnwrap(captured)
        for literal in status.protectedLiterals { XCTAssertFalse(input.contains(literal)) }
        XCTAssertFalse(input.contains(account.email))
        XCTAssertFalse(input.contains(account.provider))
        XCTAssertTrue(input.contains("FFPROTECT_"))
    }
    func testActualAccountStatusRejectsOutputThatDropsIdentityFields() async throws {
        let status = Prompt12AccountStatusText(identity: identity())
        let service = FruitfolioTranslationService(runtime: AccountStatusTranslationFixture(dropMarkers: true))
        do {
            _ = try await service.translateForDisplay(status.source, language: .german,
                protectedLiterals: status.protectedLiterals, preferCatalog: false)
            XCTFail("Identity loss must not be presented as translated account status")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
    }
}
