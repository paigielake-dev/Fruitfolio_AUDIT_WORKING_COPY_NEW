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


extension Prompt1BAskScrollTests {
    func testLargeStreamedBatchKeepsFollowIntentInsteadOfPretendingReaderScrolledAway() {
        var session = Prompt09ScrollFollowSession()
        XCTAssertFalse(session.observe(.init(bottom: 600, contentHeight: 600), viewportHeight: 600, permitted: true))
        XCTAssertFalse(Prompt09ScrollFollowPolicy.isNearBottom(bottom: 1500, viewportHeight: 600),
            "The old bottom-only observation cannot distinguish this content growth from user scrolling")
        XCTAssertTrue(session.observe(.init(bottom: 1500, contentHeight: 1500), viewportHeight: 600, permitted: true))
        XCTAssertTrue(session.shouldFollow)
        XCTAssertFalse(session.observe(.init(bottom: 600, contentHeight: 1500), viewportHeight: 600, permitted: true))
        XCTAssertTrue(session.observe(.init(bottom: 1300, contentHeight: 2200), viewportHeight: 600, permitted: true))
    }

    func testReadingOlderContentStaysPutAcrossGrowthAndResumesOnlyWhenReaderReturnsNearBottom() {
        var session = Prompt09ScrollFollowSession()
        _ = session.observe(.init(bottom: 600, contentHeight: 1500), viewportHeight: 600, permitted: true)
        // Slow subpoint movement must not be mistaken for stationary content.
        // A1-point per-observation threshold would never detect this reader.
        for bottom in stride(from: 600.25, through: 1200, by: 0.25) {
            XCTAssertFalse(session.observe(.init(bottom: bottom, contentHeight: 1500), viewportHeight: 600, permitted: true))
        }
        XCTAssertFalse(session.shouldFollow)
        XCTAssertFalse(session.observe(.init(bottom: 1900, contentHeight: 2200), viewportHeight: 600, permitted: true))
        XCTAssertFalse(session.shouldFollow)
        XCTAssertFalse(session.observe(.init(bottom: 600, contentHeight: 2200), viewportHeight: 600, permitted: true))
        XCTAssertTrue(session.shouldFollow)
        XCTAssertTrue(session.observe(.init(bottom: 800, contentHeight: 2400), viewportHeight: 600, permitted: true))
    }

    func testInactiveOrCoveredGrowthCannotRequestScrollOrReplayOnResume() {
        var session = Prompt09ScrollFollowSession()
        _ = session.observe(.init(bottom: 600, contentHeight: 600), viewportHeight: 600, permitted: true)
        XCTAssertFalse(session.observe(.init(bottom: 1500, contentHeight: 1500), viewportHeight: 600, permitted: false))
        XCTAssertTrue(session.shouldFollow)
        XCTAssertFalse(session.observe(.init(bottom: 1500, contentHeight: 1500), viewportHeight: 600, permitted: true))
        XCTAssertTrue(session.observe(.init(bottom: 1800, contentHeight: 1800), viewportHeight: 600, permitted: true))
    }

    func testInvalidLayoutCannotChangeReadingIntentOrInventFollowRequest() {
        var session = Prompt09ScrollFollowSession()
        _ = session.observe(.init(bottom: 600, contentHeight: 1800), viewportHeight: 600, permitted: true)
        _ = session.observe(.init(bottom: 1300, contentHeight: 1800), viewportHeight: 600, permitted: true)
        XCTAssertFalse(session.shouldFollow)
        for metrics in [Prompt09ConversationScrollMetrics(bottom: .nan, contentHeight: 1800),
                        .init(bottom: 600, contentHeight: .infinity), .init(bottom: 600, contentHeight: 0)] {
            XCTAssertFalse(session.observe(metrics, viewportHeight: 600, permitted: true))
            XCTAssertFalse(session.shouldFollow)
        }
        XCTAssertFalse(session.observe(.init(bottom: 600, contentHeight: 1800), viewportHeight: 0, permitted: true))
        XCTAssertFalse(session.shouldFollow)
        session = Prompt09ScrollFollowSession()
        XCTAssertTrue(session.shouldFollow)
    }
}
