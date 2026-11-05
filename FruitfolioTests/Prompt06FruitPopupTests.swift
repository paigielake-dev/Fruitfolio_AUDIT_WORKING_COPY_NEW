import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt06FruitPopupTests: XCTestCase {
    func testStaleDismissalCannotClearNewerDismissingPopup() {
        let coordinator = PopupCoordinator()
        let first = FruitPopupRequest(character: .blueberry, message: "first")
        let second = FruitPopupRequest(character: .peach, message: "second")
        coordinator.request(first)
        coordinator.request(second)
        coordinator.dismissCurrent()
        coordinator.finishDismissal(expectedPopupID: first.id)
        XCTAssertEqual(coordinator.currentPopup?.id, second.id)
        coordinator.dismissCurrent()
        // Simulate the old host task arriving after the replacement begins closing.
        coordinator.finishDismissal(expectedPopupID: first.id)
        XCTAssertEqual(coordinator.currentPopup?.id, second.id)
        XCTAssertEqual(coordinator.presentationState, .dismissing)
        coordinator.finishDismissal(expectedPopupID: second.id)
        XCTAssertNil(coordinator.currentPopup)
        XCTAssertEqual(coordinator.presentationState, .idle)
    }

    func testDismissalCompletionRequiresDismissalState() {
        let coordinator = PopupCoordinator()
        let popup = FruitPopupRequest(character: .blueberry, message: "still visible")
        coordinator.request(popup)
        coordinator.markPresented()
        coordinator.finishDismissal(expectedPopupID: popup.id)
        XCTAssertEqual(coordinator.currentPopup?.id, popup.id)
        XCTAssertEqual(coordinator.presentationState, .visible)
    }

    func testCanonicalCharacterAssetMapping() {
        XCTAssertEqual(FruitPopupCharacter.strawberry.assetID, .fruit_strawberry_silly)
        XCTAssertEqual(FruitPopupCharacter.blueberry.assetID, .fruit_blueberry_friendly)
        XCTAssertEqual(FruitPopupCharacter.peach.assetID, .fruit_peach_soft)
    }
    func testCoordinatorShowsOnlyOnePopup() async {
        await MainActor.run {
            let coordinator = PopupCoordinator()
            
            coordinator.request(
                .init(
                    character: .blueberry,
                    message: "one",
                    priority: .educational
                )
            )
            
            coordinator.request(
                .init(
                    character: .strawberry,
                    message: "two",
                    priority: .success
                )
            )
            
            XCTAssertEqual(
                coordinator.currentPopup?.message,
                "one"
            )
        }
    }
    
    func testHigherPriorityReplacesLowerPriority() async {
        await MainActor.run {
            let coordinator = PopupCoordinator()
            
            coordinator.request(
                .init(
                    character: .strawberry,
                    message: "success",
                    priority: .success
                )
            )
            
            coordinator.request(
                .init(
                    character: .peach,
                    message: "sensitive",
                    priority: .sensitive
                )
            )
            
            XCTAssertEqual(
                coordinator.presentationState,
                .dismissing
            )
        }
    }
    
    func testDeduplicationPreventsRepeatedReactiveRequest() async {
        await MainActor.run {
            let coordinator = PopupCoordinator()
            
            coordinator.request(
                .init(
                    character: .blueberry,
                    message: "same",
                    deduplicationKey: "prediction-help"
                )
            )
            
            coordinator.request(
                .init(
                    character: .blueberry,
                    message: "same",
                    deduplicationKey: "prediction-help"
                )
            )
            
            XCTAssertEqual(
                coordinator.currentPopup?.deduplicationKey,
                "prediction-help"
            )
        }
    }
}
