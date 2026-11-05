import XCTest
@testable import Fruitfolio

final class Prompt1BAskScrollTests: XCTestCase {
    func testReadingOlderContentDoesNotQualifyForAutomaticFollow() {
        XCTAssertFalse(Prompt09ScrollFollowPolicy.isNearBottom(bottom: 1400, viewportHeight: 600))
        XCTAssertTrue(Prompt09ScrollFollowPolicy.isNearBottom(bottom: 660, viewportHeight: 600))
        XCTAssertTrue(Prompt09ScrollFollowPolicy.isNearBottom(bottom: 400, viewportHeight: 600))
        XCTAssertFalse(Prompt09ScrollFollowPolicy.isNearBottom(bottom: 10, viewportHeight: 0))
    }
}

