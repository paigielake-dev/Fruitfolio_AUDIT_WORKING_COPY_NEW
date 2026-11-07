import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BLevelResetSessionTests: XCTestCase {
    func testResetDialogueEmphasizesActualLevelScopeWithoutChangingSavedDataPromise() async throws {
        let spans = Prompt28LevelResetSession.messageSpans
        let original = "start this topic’s game level over?\n\nthe catching will go back to the gentlest level. your learning topic, question difficulty, saved encyclopedia entries, and scores won’t disappear."
        XCTAssertEqual(Data(spans.map(\.text).joined().utf8), Data(original.utf8))
        XCTAssertEqual(spans.filter { $0.emphasis == .anchorBold }.map(\.text),
            ["start this topic’s game level over?", "gentlest level"])
        XCTAssertEqual(spans.filter { $0.emphasis == .symptomOrPracticalUnderline }.map(\.text), ["won’t disappear"])
        let coordinator = PopupCoordinator()
        let session = Prompt28LevelResetSession(coordinator: coordinator)
        session.present(context: context())
        let request = try XCTUnwrap(coordinator.currentPopup)
        XCTAssertTrue(request.message.contains("**gentlest level**"))
        XCTAssertTrue(request.message.contains("<u>won’t disappear</u>"))
        XCTAssertEqual(request.tone, .cautionary)
        XCTAssertEqual(request.surface, .tapedWhite)
        session.cancel()
    }

    private func context(_ topic: String = "fixture", id: UUID? = UUID(), origin: Prompt28ScreenState = .paused) -> Prompt28LevelResetContext {
        .init(normalizedTopic: topic, sessionID: id, origin: origin)
    }
    func testResetTargetRequiresTheSameNonemptyTopicSessionAndOrigin() async {
        let id = UUID(), original = context(id: UUID())
        XCTAssertTrue(original.matches(original))
        XCTAssertFalse(original.matches(context("other", id: original.sessionID)))
        XCTAssertFalse(original.matches(context(id: id)))
        XCTAssertFalse(original.matches(context(id: original.sessionID, origin: .basketReveal)))
        XCTAssertFalse(context("", id: id).isEligible)
        XCTAssertFalse(context(id: id, origin: .catchActive).isEligible)
        XCTAssertTrue(context(id: nil, origin: .basketReveal).isEligible)
    }
    func testFirstConfirmedIntentWaitsForDismissalAndCannotBeReplayedOrReplaced() async throws {
        let coordinator = PopupCoordinator()
        let owner = Prompt28LevelResetSession(coordinator: coordinator)
        let first = context(), later = context("later")
        owner.present(context: first)
        let request = try XCTUnwrap(coordinator.currentPopup)
        owner.present(context: later)
        XCTAssertEqual(owner.requestID, request.id)
        XCTAssertEqual(request.surface, .tapedWhite)
        XCTAssertFalse(request.message.contains(first.normalizedTopic))
        request.secondaryAction!.handler()
        request.primaryAction!.handler()
        XCTAssertNil(owner.takeCompletedChoice())
        coordinator.finishDismissal(expectedPopupID: request.id)
        guard case .reset(let frozen)? = owner.takeCompletedChoice() else { return XCTFail("Missing reset") }
        XCTAssertEqual(frozen, first)
        XCTAssertNil(owner.takeCompletedChoice())
        request.secondaryAction!.handler()
        XCTAssertNil(owner.takeCompletedChoice())
    }
    func testCancelAndAccessibilityEscapeNeverDeliverAReset() async throws {
        for escape in [false, true] {
            let coordinator = PopupCoordinator()
            let session = Prompt28LevelResetSession(coordinator: coordinator)
            session.present(context: context())
            let request = try XCTUnwrap(coordinator.currentPopup)
            if escape { XCTAssertTrue(coordinator.dismissUsingAccessibilityEscape(expectedPopupID: request.id)) }
            else { request.primaryAction!.handler() }
            request.secondaryAction!.handler()
            XCTAssertNil(session.takeCompletedChoice())
            coordinator.finishDismissal(expectedPopupID: request.id)
            if escape { XCTAssertNil(session.takeCompletedChoice()) }
            else if case .cancel? = session.takeCompletedChoice() {} else { XCTFail("Cancel changed meaning") }
        }
    }
    func testQueuedDepartureRemovesOnlyOwnedRequest() async throws {
        let coordinator = PopupCoordinator()
        let other = FruitPopupRequest(character: .blueberry, message: "unrelated", priority: .sensitive)
        coordinator.request(other)
        let session = Prompt28LevelResetSession(coordinator: coordinator)
        session.present(context: context())
        let queuedID = try XCTUnwrap(session.requestID)
        XCTAssertTrue(coordinator.containsRequest(id: queuedID))
        session.cancel()
        XCTAssertFalse(coordinator.containsRequest(id: queuedID))
        XCTAssertEqual(coordinator.currentPopup?.id, other.id)
        XCTAssertNotEqual(coordinator.presentationState, .dismissing)
        XCTAssertNil(session.takeCompletedChoice())
    }
    func testPendingResetWaitsForAnotherOwnersPopup() async throws {
        let coordinator = PopupCoordinator(), target = context()
        let session = Prompt28LevelResetSession(coordinator: coordinator)
        session.present(context: target)
        let request = try XCTUnwrap(coordinator.currentPopup)
        request.secondaryAction!.handler()
        let other = FruitPopupRequest(character: .blueberry, message: "unrelated")
        coordinator.request(other)
        coordinator.finishDismissal(expectedPopupID: request.id)
        XCTAssertEqual(coordinator.currentPopup?.id, other.id)
        XCTAssertNil(session.takeCompletedChoice())
        coordinator.dismissCurrent()
        coordinator.finishDismissal(expectedPopupID: other.id)
        guard case .reset(let frozen)? = session.takeCompletedChoice() else { return XCTFail("Deferred reset lost") }
        XCTAssertEqual(frozen, target)
    }
    func testDepartureDropsConfirmedChoiceAndStaleActionCannotAffectNewRequest() async throws {
        let coordinator = PopupCoordinator()
        let session = Prompt28LevelResetSession(coordinator: coordinator)
        session.present(context: context())
        let old = try XCTUnwrap(coordinator.currentPopup)
        old.secondaryAction!.handler()
        session.cancel()
        coordinator.finishDismissal(expectedPopupID: old.id)
        let newTarget = context("new")
        session.present(context: newTarget)
        let new = try XCTUnwrap(coordinator.currentPopup)
        old.secondaryAction!.handler()
        XCTAssertEqual(coordinator.currentPopup?.id, new.id)
        XCTAssertNotEqual(coordinator.presentationState, .dismissing)
        new.secondaryAction!.handler()
        coordinator.finishDismissal(expectedPopupID: new.id)
        guard case .reset(let frozen)? = session.takeCompletedChoice() else { return XCTFail("New reset missing") }
        XCTAssertEqual(frozen, newTarget)
    }
    func testIneligibleContextsNeverCreateAConfirmation() async {
        let coordinator = PopupCoordinator()
        let session = Prompt28LevelResetSession(coordinator: coordinator)
        for invalid in [context(""), context(origin: .home), context(origin: .catchActive)] {
            session.present(context: invalid)
            XCTAssertNil(session.requestID)
            XCTAssertNil(coordinator.currentPopup)
        }
    }
}
