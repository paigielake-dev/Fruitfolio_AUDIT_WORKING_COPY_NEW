import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BPredictionPopupTests: XCTestCase {
    func testProductionFactoryPreservesAllExistingCopyAndUsesMeasuredOwnedSurface() async {
        let coordinator = PopupCoordinator()
        let actualOwner = FruitfolioOwnedPopupSession(coordinator: coordinator)
        let info = Prompt16PredictionLearningInfo(title: "still learning ♡",
            body: "one period start is saved.", progress: "log your next period start to unlock your first cycle estimate.")
        let scope = UUID()
        var accepted = 0
        actualOwner.present { id in
            Prompt16PredictionPopupRequest.make(info: info, id: id, scope: scope) {
                if actualOwner.consumeAction(for: id) { accepted += 1 }
            }
        }
        let request = coordinator.currentPopup!
        XCTAssertEqual(request.surface, .woodenSign)
        XCTAssertEqual(request.dismissBehavior, .explicitActionOnly)
        XCTAssertTrue(request.message.contains(info.title))
        XCTAssertTrue(request.message.contains(info.body))
        XCTAssertTrue(request.message.contains(info.progress))
        XCTAssertEqual(request.source, "cycle-prediction-info")
        XCTAssertNil(request.secondaryAction); XCTAssertNil(request.tertiaryAction)
        request.primaryAction!.handler()
        request.primaryAction!.handler()
        XCTAssertEqual(accepted, 1, "Repeated close cannot consume the same request twice")
        coordinator.finishDismissal(expectedPopupID: request.id)
        actualOwner.observeDismissal()
        XCTAssertNil(actualOwner.requestID)
    }

    func testQueuedAndDepartedPredictionActionsCannotDismissAnotherModal() async {
        let coordinator = PopupCoordinator()
        let blocker = FruitPopupRequest(character: .blueberry, message: "other active modal", dismissBehavior: .persistentUntilAcknowledged)
        coordinator.request(blocker)
        let owner = FruitfolioOwnedPopupSession(coordinator: coordinator)
        var accepted = false
        var queued: FruitPopupRequest?
        owner.present { id in
            let request = Prompt16PredictionPopupRequest.make(info: .init(title: "fixture", body: "original body", progress: "original progress"), id: id, scope: UUID()) {
                if owner.consumeAction(for: id) { accepted = true }
            }
            queued = request
            return request
        }
        queued!.primaryAction!.handler()
        XCTAssertFalse(accepted)
        XCTAssertEqual(coordinator.currentPopup?.id, blocker.id)
        owner.cancel()
        queued!.primaryAction!.handler()
        XCTAssertFalse(accepted)
        XCTAssertEqual(coordinator.currentPopup?.id, blocker.id)
    }

    func testPredictionEscapeRemainsIdentityGuardedAcrossReplacement() async {
        let coordinator = PopupCoordinator()
        let original = Prompt16PredictionPopupRequest.make(info: .init(title: "fixture", body: "original body", progress: "original progress"), id: UUID(), scope: UUID(), onClose: {})
        coordinator.request(original)
        XCTAssertTrue(coordinator.dismissUsingAccessibilityEscape(expectedPopupID: original.id))
        coordinator.finishDismissal(expectedPopupID: original.id)
        let replacement = FruitPopupRequest(character: .blueberry, message: "new unrelated modal")
        coordinator.request(replacement)
        XCTAssertFalse(coordinator.dismissUsingAccessibilityEscape(expectedPopupID: original.id))
        XCTAssertEqual(coordinator.currentPopup?.id, replacement.id)
    }
}
