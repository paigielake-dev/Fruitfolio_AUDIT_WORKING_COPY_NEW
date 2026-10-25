import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt06FruitPopupTests: XCTestCase {
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
