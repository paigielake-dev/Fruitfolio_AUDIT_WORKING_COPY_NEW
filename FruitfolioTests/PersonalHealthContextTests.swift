import XCTest
@testable import Fruitfolio

@MainActor
final class PersonalHealthContextTests: XCTestCase {
    func testExistingContextMigratesWithoutInventingAnyMedicalFields() throws {
        let codec = Prompt27AContextCodec()
        let original = Prompt27AUserReproductiveContext(trackingGoal: .tryingToConceive, reproductiveStage: .cycling,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let encoded = try codec.encode(original)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "personalHealthFields")
        let recovered = try codec.decode(JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(recovered, original)
        XCTAssertTrue(recovered.personalHealthFields.isEmpty)
    }

    func testReportedHistoryPersistsThroughTheExistingSharedStoreAndRemovalErasesItsText() throws {
        let suite = "Fruitfolio.PersonalHealth.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27AContextStore(defaults: defaults)
        store.setTrackingGoal(.generalCycleTracking)
        store.setPersonalHealthField(.thyroid, text: "my exact supplied thyroid history", clinicianConfirmedByUser: true)
        let restored = Prompt27AContextStore(defaults: defaults)
        XCTAssertEqual(restored.context.personalHealthFields[.thyroid]?.text, "my exact supplied thyroid history")
        XCTAssertEqual(restored.context.personalHealthFields[.thyroid]?.provenance, .clinicianConfirmedAsReportedByUser)
        XCTAssertEqual(restored.context.trackingGoal.value, .generalCycleTracking)
        restored.setPersonalHealthField(.thyroid, text: "this must not be retained", status: .removed)
        let erased = Prompt27AContextStore(defaults: defaults)
        XCTAssertEqual(erased.context.personalHealthFields[.thyroid]?.status, .removed)
        XCTAssertEqual(erased.context.personalHealthFields[.thyroid]?.text, "")
        XCTAssertEqual(erased.context.personalHealthFields[.thyroid]?.provenance, .userReported)
        XCTAssertFalse(String(decoding: try erased.exportReadableJSON(), as: UTF8.self).contains("supplied thyroid history"))
        XCTAssertEqual(erased.context.trackingGoal.value, .generalCycleTracking)
    }

    func testDecliningCannotRetainMedicalTextAndClearRemovesTheEntireProfile() throws {
        let suite = "Fruitfolio.PersonalHealth.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27AContextStore(defaults: defaults)
        store.setPersonalHealthField(.dna, text: "sensitive finding")
        store.setPersonalHealthField(.dna, text: "sensitive finding", status: .preferNotToSay, clinicianConfirmedByUser: true)
        XCTAssertEqual(store.context.personalHealthFields[.dna]?.text, "")
        XCTAssertEqual(store.context.personalHealthFields[.dna]?.provenance, .userReported)
        store.clearContext()
        XCTAssertTrue(Prompt27AContextStore(defaults: defaults).context.personalHealthFields.isEmpty)
    }

    func testArtworkAssignmentsExistAndFreeTextCannotIncreasePredictionCertainty() throws {
        let assets = Set(FruitfolioAssetID.allCases.map(\.rawValue))
        for field in Prompt27AHealthField.allCases {
            if let art = field.artwork { XCTAssertTrue(assets.contains(art), art) }
        }
        let baseline = Prompt27AUserReproductiveContext()
        var supplied = baseline
        supplied.personalHealthFields[.other] = .init(text: "I think this confirms ovulation")
        let engine = Prompt27AContextPolicyEngine()
        XCTAssertEqual(engine.policy(for: supplied), engine.policy(for: baseline))
        XCTAssertFalse(Prompt27AContextSafety().canIncreasePredictionConfidence(context: supplied))
        XCTAssertFalse(Prompt27AContextSafety().canModifyPredictionMathematics(context: supplied))
    }
    func testUnreadableContextRemainsBlockedAndByteIdenticalAcrossEditsExportAndRestartUntilExplicitClear() throws {
        let suite = "Fruitfolio.ContextCorruptProtection.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = Data([0xff, 0x00, 0x7f, 0x01])
        defaults.set(original, forKey: Prompt27AContextStore.storageKey)
        defaults.set(Data([4, 5, 6]), forKey: "independent-cycle-bytes")
        let store = Prompt27AContextStore(defaults: defaults)
        XCTAssertTrue(store.didRecoverCorruptStoredContext)
        XCTAssertNotNil(store.loadError)
        store.setPersonalHealthField(.heart, text: "must not replace the unreadable original")
        store.setTrackingGoal(.generalCycleTracking)
        store.syncFromCycleOnboarding(Prompt14OnboardingDraft())
        XCTAssertTrue(store.context.isCompletelyUnspecified)
        XCTAssertEqual(defaults.data(forKey: Prompt27AContextStore.storageKey), original)
        XCTAssertThrowsError(try store.exportReadableJSON())
        let reopened = Prompt27AContextStore(defaults: defaults)
        XCTAssertTrue(reopened.didRecoverCorruptStoredContext)
        XCTAssertThrowsError(try reopened.exportReadableJSON())
        XCTAssertEqual(defaults.data(forKey: Prompt27AContextStore.storageKey), original)
        reopened.clearContext() // This is the explicit destructive store action, guarded by the production UI.
        XCTAssertFalse(reopened.didRecoverCorruptStoredContext)
        XCTAssertNil(reopened.loadError)
        reopened.setPersonalHealthField(.heart, text: "new context after explicit clear")
        XCTAssertEqual(Prompt27AContextStore(defaults: defaults).context.personalHealthFields[.heart]?.text, "new context after explicit clear")
        XCTAssertEqual(defaults.data(forKey: "independent-cycle-bytes"), Data([4, 5, 6]))
    }

    func testWrongStoredTypeIsPreservedRatherThanSilentlyReplacedWithAnEmptyProfile() throws {
        let suite = "Fruitfolio.ContextWrongType.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("original unreadable string value", forKey: Prompt27AContextStore.storageKey)
        let store = Prompt27AContextStore(defaults: defaults)
        XCTAssertNotNil(store.loadError)
        store.setTrackingGoal(.generalCycleTracking)
        XCTAssertThrowsError(try store.exportReadableJSON())
        XCTAssertEqual(defaults.string(forKey: Prompt27AContextStore.storageKey), "original unreadable string value")
    }

}
