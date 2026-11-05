import XCTest
@testable import Fruitfolio

final class Prompt1BExcerptIdentityTests: XCTestCase {
    func testIdenticalTextAtDifferentOccurrencesDoesNotShareSaveBadge() throws {
        let answer = UUID()
        let first = try XCTUnwrap(Prompt09ExcerptIdentity(answerID: answer, renderedRange: NSRange(location: 0, length: 6)))
        let repeated = try XCTUnwrap(Prompt09ExcerptIdentity(answerID: answer, renderedRange: NSRange(location: 20, length: 6)))
        let differentAnswer = try XCTUnwrap(Prompt09ExcerptIdentity(answerID: UUID(), renderedRange: NSRange(location: 0, length: 6)))
        XCTAssertNotEqual(first, repeated)
        XCTAssertNotEqual(first, differentAnswer)
        XCTAssertEqual(Set([first, repeated, differentAnswer]).count, 3)
    }

    func testOptionalIllustrationSelectionHasItsOwnSaveBadge() throws {
        let answer = UUID(), range = NSRange(location: 0, length: 4)
        let text = try XCTUnwrap(Prompt09ExcerptIdentity(answerID: answer, renderedRange: range))
        let illustrated = try XCTUnwrap(Prompt09ExcerptIdentity(answerID: answer, renderedRange: range,
            educationalAssetIDs: [.ovarian_cycle_follicle_development_stages]))
        XCTAssertNotEqual(text, illustrated)
    }

    func testEmptyAndInvalidSelectionsCannotReceiveSaveBadge() {
        XCTAssertNil(Prompt09ExcerptIdentity(answerID: UUID(), renderedRange: nil))
        XCTAssertNil(Prompt09ExcerptIdentity(answerID: UUID(), renderedRange: NSRange(location: NSNotFound, length: 1)))
        XCTAssertNil(Prompt09ExcerptIdentity(answerID: UUID(), renderedRange: NSRange(location: 0, length: 0)))
    }
}
