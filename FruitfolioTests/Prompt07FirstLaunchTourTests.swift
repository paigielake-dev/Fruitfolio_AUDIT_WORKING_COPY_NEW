import XCTest
@testable import Fruitfolio

final class Prompt07FirstLaunchTourTests: XCTestCase {
    func testTourHasSixSteps() {
        XCTAssertEqual(Prompt07TourStep.allCases.count, 6)
        XCTAssertEqual(Prompt07TourStep.ask.progressText, "1 of 6")
        XCTAssertEqual(Prompt07TourStep.ready.progressText, "6 of 6")
    }

    func testTourNavigation() async {
        await MainActor.run {
            let tour = Prompt07TourController()
            tour.begin()
            XCTAssertEqual(tour.currentStep, .ask)
            tour.next()
            XCTAssertEqual(tour.currentStep, .library)
            tour.back()
            XCTAssertEqual(tour.currentStep, .ask)
            tour.end()
            XCTAssertFalse(tour.isTourActive)
        }
    }

    func testCanonicalCharacterAssignments() async {
        await MainActor.run {
            XCTAssertEqual(Prompt07TourStep.ask.character, .blueberry)
            XCTAssertEqual(Prompt07TourStep.cycle.character, .peach)
            XCTAssertEqual(Prompt07TourStep.fruitBasket.character, .strawberry)
            XCTAssertEqual(Prompt07TourStep.ready.character, .blueberry)
        }
    }
}
