import XCTest
@testable import Fruitfolio

final class Prompt1BIntroCheckpointTests: XCTestCase {
    func testEarlyFirstLaunchKeepsBlankCoverReadyForUnseenLogoReveal() {
        for stage: Prompt04IntroStage in [.initialStillness, .blankBookArriving, .blankBookSettled] {
            XCTAssertEqual(Prompt04IntroCheckpoint.resolve(stage: stage, firstLaunch: true), .blankBook)
        }
        XCTAssertEqual(Prompt04IntroCheckpoint.resolve(stage: .logoRevealing, firstLaunch: true), .brandedBook)
        XCTAssertEqual(Prompt04IntroCheckpoint.resolve(stage: .slightlyOpening, firstLaunch: true), .slightlyOpenBook)
        XCTAssertEqual(Prompt04IntroCheckpoint.resolve(stage: .rightPageFocusing, firstLaunch: true), .fullyOpenBook)
    }

    func testReturningLaunchNeverAcquiresFirstLaunchBlankLogoBeat() {
        for stage: Prompt04IntroStage in [.initialStillness, .blankBookArriving, .blankBookSettled] {
            XCTAssertEqual(Prompt04IntroCheckpoint.resolve(stage: stage, firstLaunch: false), .brandedBook)
        }
        for first in [true, false] {
            XCTAssertEqual(Prompt04IntroCheckpoint.resolve(stage: .standalonePaperResolving, firstLaunch: first), .hubPaper)
            XCTAssertEqual(Prompt04IntroCheckpoint.resolve(stage: .introComplete, firstLaunch: first), .complete)
        }
    }
}
