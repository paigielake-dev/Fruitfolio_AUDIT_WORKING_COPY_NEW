import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BAccountDraftExitTests: XCTestCase {
    func testEmailOnlyNeverOffersOrCallsUsernameSave() async {
        var kept = 0, saved = 0, discarded = 0
        let request = FruitfolioAccountDraftExitRequest.make(id: UUID(), scope: UUID(),
            hasUsernameDraft: false, hasEmailDraft: true, canSaveUsername: true,
            onKeep: { kept += 1 }, onSaveUsername: { saved += 1 }, onDiscard: { discarded += 1 })
        XCTAssertEqual(request.surface, .tapedWhite)
        XCTAssertEqual(request.dismissBehavior, .explicitActionOnly)
        XCTAssertEqual(request.secondaryAction?.label, "discard drafts + leave")
        XCTAssertNil(request.tertiaryAction)
        request.primaryAction!.handler(); request.secondaryAction!.handler()
        XCTAssertEqual(kept, 1); XCTAssertEqual(discarded, 1); XCTAssertEqual(saved, 0)
        XCTAssertTrue(request.message.contains("does not sign in"))
    }
    func testMixedDraftsDiscloseThatSavingUsernameDoesNotSaveEmail() async {
        for writable in [false, true] {
            var saved = 0, discarded = 0
            let request = FruitfolioAccountDraftExitRequest.make(id: UUID(), scope: UUID(),
                hasUsernameDraft: true, hasEmailDraft: true, canSaveUsername: writable,
                onKeep: {}, onSaveUsername: { saved += 1 }, onDiscard: { discarded += 1 })
            request.secondaryAction!.handler()
            XCTAssertEqual(saved, writable ? 1 : 0)
            XCTAssertEqual(discarded, writable ? 0 : 1)
            if writable {
                XCTAssertEqual(request.secondaryAction?.label, "save username + leave")
                XCTAssertNotNil(request.tertiaryAction)
                XCTAssertTrue(request.message.contains("does not submit or save the email"))
            } else { XCTAssertNil(request.tertiaryAction) }
        }
    }
    func testFrozenIntentRetainsAccountIdentityExclusionsBeforeAnyWrite() async throws {
        let suite = "Fruitfolio.AccountDraftIdentity." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        let key = FruitfolioUsernamePersistence.recordKey(for: "username")
        let bytes = defaults.data(forKey: key)
        let intent = FruitfolioUsernameSaveIntent(raw: "new_berry", confirmedNonIdentifying: true,
            expected: store.snapshot, identifyingText: ["new_berry@example.invalid"])
        XCTAssertNotNil(intent.commit(to: store))
        XCTAssertEqual(defaults.data(forKey: key), bytes)
        XCTAssertEqual(store.username, "old_berry")
    }
}
