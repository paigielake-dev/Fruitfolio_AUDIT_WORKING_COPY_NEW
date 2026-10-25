import XCTest
@testable import Fruitfolio

nonisolated final class Prompt15CycleTrackerTests: XCTestCase {
    func testPrimarySectionsRemainInCanonicalOrder() {
        XCTAssertEqual(
            Prompt15CycleSection.allCases.map(\.rawValue),
            ["today", "calendar", "body", "symptoms", "trends"]
        )
    }

    func testEveryPrimarySectionHasStableIdentity() {
        for section in Prompt15CycleSection.allCases {
            XCTAssertEqual(section.id, section.rawValue)
        }
    }

    func testSectionCountIsExactlyFive() {
        XCTAssertEqual(Prompt15CycleSection.allCases.count, 5)
    }
}
