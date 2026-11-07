import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BAccountDraftExitTests: XCTestCase {
    func testContextualDraftEmphasisRetainsEveryOriginalVisibleByteAndAction() async {
        let contexts: [(Bool, Bool, Bool, String, String)] = [
            (true, true, false, "unsaved account edits\n\nthe saved username record is protected. keep the drafts to review it, or discard only these unsaved edits and leave. your saved information stays in place.",
             "saved username record is protected"),
            (true, true, true, "unsaved account edits\n\nyour username edit and sign-in email are not saved. saving the username only saves that name on this device; it does not submit or save the email. leaving will discard the email draft.",
             "does not submit or save the email"),
            (true, false, true, "unsaved username\n\nyour username edit has not been saved. save it on this device, discard only this edit, or keep editing. other saved information is separate.",
             "on this device"),
            (false, true, true, "unsaved sign-in email\n\nyou have not submitted this email. keep editing, or discard this draft and leave. leaving does not sign in or change your account.",
             "does not sign in or change your account")
        ]
        for (username, email, writable, original, qualification) in contexts {
            let spans = FruitfolioAccountDraftExitRequest.messageSpans(hasUsernameDraft: username,
                hasEmailDraft: email, canSaveUsername: writable)
            XCTAssertEqual(Data(spans.map(\.text).joined().utf8), Data(original.utf8))
            XCTAssertEqual(spans.filter { $0.emphasis == .symptomOrPracticalUnderline }.map(\.text), [qualification])
            XCTAssertEqual(spans.filter { $0.emphasis == .anchorBold }.count, 1)
            var kept = 0
            let request = FruitfolioAccountDraftExitRequest.make(id: UUID(), scope: UUID(),
                hasUsernameDraft: username, hasEmailDraft: email, canSaveUsername: writable,
                onKeep: { kept += 1 }, onSaveUsername: {}, onDiscard: {})
            XCTAssertTrue(request.message.contains("<u>" + qualification + "</u>"))
            XCTAssertEqual(request.tone, .cautionary)
            request.primaryAction?.handler()
            XCTAssertEqual(kept, 1)
            XCTAssertFalse(spans.contains { [.spokenItalic, .anchorBoldSpokenItalic, .rareItalicUnderline, .absoluteBoldItalicUnderline].contains($0.emphasis) })
        }
    }

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
