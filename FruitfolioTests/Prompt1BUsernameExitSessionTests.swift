import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BUsernameExitSessionTests: XCTestCase {
    private func intent(name: String = "new_berry") -> FruitfolioUsernameSaveIntent {
        .init(raw: name, confirmedNonIdentifying: true,
              expected: .init(username: "old_berry", confirmedNonIdentifying: true))
    }
    func testSaveChoiceWaitsForActualDismissalAndCommitsFrozenIntentOnlyOnce() async throws {
        let suite = "Fruitfolio.UsernameExit." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        let coordinator = PopupCoordinator()
        let session = FruitfolioUsernameExitSession(coordinator: coordinator)
        session.present(intent: intent(), canSave: true)
        let request = try XCTUnwrap(coordinator.currentPopup)
        XCTAssertEqual(request.surface, .tapedWhite)
        XCTAssertEqual(request.dismissBehavior, .explicitActionOnly)
        XCTAssertFalse(request.message.contains("new_berry"))
        XCTAssertFalse(request.message.contains("old_berry"))
        request.secondaryAction!.handler()
        request.tertiaryAction!.handler() // A replay during closing cannot change Save into Discard.
        XCTAssertNil(session.takeCompletedChoice())
        XCTAssertEqual(store.username, "old_berry")
        coordinator.finishDismissal(expectedPopupID: request.id)
        guard case .save(let frozen)? = session.takeCompletedChoice() else { return XCTFail("Save choice missing") }
        XCTAssertNil(frozen.commit(to: store))
        XCTAssertEqual(store.username, "new_berry"); XCTAssertTrue(store.confirmedNonIdentifying)
        XCTAssertNil(session.takeCompletedChoice())
    }
    func testFirstRapidRequestAndLateSaveCannotReplaceAnotherConfirmedName() async throws {
        let suite = "Fruitfolio.UsernameExitStale." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        let coordinator = PopupCoordinator()
        let session = FruitfolioUsernameExitSession(coordinator: coordinator)
        session.present(intent: intent(), canSave: true)
        let request = try XCTUnwrap(coordinator.currentPopup)
        session.present(intent: intent(name: "later_berry"), canSave: true)
        XCTAssertEqual(session.requestID, request.id)
        XCTAssertNil(store.setUsername("other_berry", confirmedNonIdentifying: true))
        let bytes = defaults.data(forKey: FruitfolioUsernamePersistence.recordKey(for: "username"))
        request.secondaryAction!.handler()
        coordinator.finishDismissal(expectedPopupID: request.id)
        guard case .save(let frozen)? = session.takeCompletedChoice() else { return XCTFail("Save missing") }
        XCTAssertEqual(frozen.raw, "new_berry")
        XCTAssertNotNil(frozen.commit(to: store))
        XCTAssertEqual(defaults.data(forKey: FruitfolioUsernamePersistence.recordKey(for: "username")), bytes)
        XCTAssertEqual(store.username, "other_berry")
    }
    func testProtectedRecordOffersReviewAndNeverDeliversSave() async throws {
        let coordinator = PopupCoordinator()
        let session = FruitfolioUsernameExitSession(coordinator: coordinator)
        session.present(intent: intent(), canSave: false)
        let request = try XCTUnwrap(coordinator.currentPopup)
        XCTAssertEqual(request.secondaryAction?.label, "review saved username")
        request.secondaryAction!.handler()
        coordinator.finishDismissal(expectedPopupID: request.id)
        guard case .review? = session.takeCompletedChoice() else { return XCTFail("Protected record must offer review") }
    }
    func testKeepDiscardAndEscapeRemainDistinctWithoutExecutingNameWrites() async throws {
        for selection in ["keep", "discard", "escape"] {
            let coordinator = PopupCoordinator()
            let session = FruitfolioUsernameExitSession(coordinator: coordinator)
            session.present(intent: intent(), canSave: true)
            let request = try XCTUnwrap(coordinator.currentPopup)
            switch selection {
            case "keep": request.primaryAction!.handler()
            case "discard": request.tertiaryAction!.handler()
            default: XCTAssertTrue(coordinator.dismissUsingAccessibilityEscape(expectedPopupID: request.id))
            }
            XCTAssertNil(session.takeCompletedChoice())
            coordinator.finishDismissal(expectedPopupID: request.id)
            switch (selection, session.takeCompletedChoice()) {
            case ("keep", .keepEditing?), ("discard", .discard?), ("escape", nil): break
            default: XCTFail("Exit choice changed meaning")
            }
            XCTAssertNil(session.takeCompletedChoice())
        }
    }
    func testCompletedChoiceWaitsForAnotherOwnersQueuedPopup() async throws {
        let coordinator = PopupCoordinator()
        let session = FruitfolioUsernameExitSession(coordinator: coordinator)
        session.present(intent: intent(), canSave: true)
        let request = try XCTUnwrap(coordinator.currentPopup)
        request.secondaryAction!.handler()
        let other = FruitPopupRequest(character: .blueberry, message: "other queued fixture",
            dismissBehavior: .persistentUntilAcknowledged)
        coordinator.request(other)
        coordinator.finishDismissal(expectedPopupID: request.id)
        XCTAssertEqual(coordinator.currentPopup?.id, other.id)
        XCTAssertNil(session.takeCompletedChoice())
        coordinator.dismissCurrent()
        coordinator.finishDismissal(expectedPopupID: other.id)
        guard case .save? = session.takeCompletedChoice() else { return XCTFail("Deferred choice lost") }
        XCTAssertNil(session.takeCompletedChoice())
    }

    func testDepartureCancelsPendingWorkAndPreservesAnotherOwnersPopup() async throws {
        let coordinator = PopupCoordinator()
        let session = FruitfolioUsernameExitSession(coordinator: coordinator)
        session.present(intent: intent(), canSave: true)
        let request = try XCTUnwrap(coordinator.currentPopup)
        request.secondaryAction!.handler()
        session.cancel()
        coordinator.finishDismissal(expectedPopupID: request.id)
        let unrelated = FruitPopupRequest(character: .blueberry, message: "unrelated fixture")
        coordinator.request(unrelated)
        request.secondaryAction!.handler()
        XCTAssertNil(session.takeCompletedChoice())
        XCTAssertEqual(coordinator.currentPopup?.id, unrelated.id)
        session.cancel()
        XCTAssertEqual(coordinator.currentPopup?.id, unrelated.id)
    }
}
