import XCTest
@testable import Fruitfolio

final class Prompt1BAskPaperLayoutTests: XCTestCase {
    func testRequestTicketRequiresVisibleActiveOwnerAndSurvivesDuplicateActiveEvents() throws {
        var owner = Prompt09RequestInteraction()
        owner.setActive(true)
        XCTAssertNil(owner.ticket)
        owner.appear(active: true)
        let ticket = try XCTUnwrap(owner.ticket)
        owner.setActive(true)
        XCTAssertTrue(owner.accepts(ticket))
    }

    func testInactiveSendTicketCannotReviveAfterForegrounding() throws {
        var owner = Prompt09RequestInteraction()
        owner.appear(active: true)
        let old = try XCTUnwrap(owner.ticket)
        owner.setActive(false)
        XCTAssertNil(owner.ticket)
        XCTAssertFalse(owner.accepts(old))
        owner.setActive(false)
        owner.setActive(true)
        let current = try XCTUnwrap(owner.ticket)
        XCTAssertNotEqual(current, old)
        XCTAssertFalse(owner.accepts(old))
        XCTAssertTrue(owner.accepts(current))
    }

    func testDisappearedAndRemountedAskRejectsPriorQueuedSend() throws {
        var owner = Prompt09RequestInteraction()
        owner.appear(active: true)
        let old = try XCTUnwrap(owner.ticket)
        owner.disappear()
        owner.setActive(true)
        XCTAssertNil(owner.ticket)
        XCTAssertFalse(owner.accepts(old))
        owner.appear(active: true)
        XCTAssertFalse(owner.accepts(old))
        XCTAssertTrue(owner.accepts(try XCTUnwrap(owner.ticket)))
    }

    func testOnlyExactAppGreetingUsesControlledTranslation() {
        let source = Prompt09ControlledCopy.greeting
        XCTAssertTrue(Prompt09ControlledCopy.isGreeting(AskMessage(role: .fruitfolio, text: source)))
        XCTAssertFalse(Prompt09ControlledCopy.isGreeting(AskMessage(role: .user, text: source)))
        for unknown in [source + " ", source + " medical advice", "provider response", ""] {
            let message = AskMessage(role: .fruitfolio, text: unknown)
            XCTAssertFalse(Prompt09ControlledCopy.isGreeting(message))
            XCTAssertEqual(Array(message.text.utf8), Array(unknown.utf8))
        }
    }

    func testPaperAndTextStayCenteredAndBoundedAcrossSmallAndLongSessions() {
        for width: CGFloat in [240, 320, 393, 852] {
            for height: CGFloat in [180, 852, 10_000] {
                let metrics = Prompt09PaperLayout.metrics(viewport: CGSize(width: width, height: height))
                XCTAssertLessThanOrEqual(metrics.paperWidth, width - 16)
                XCTAssertLessThanOrEqual(metrics.paperWidth, 680)
                XCTAssertGreaterThan(metrics.textColumnWidth, 0)
                XCTAssertLessThan(metrics.textColumnWidth, metrics.paperWidth)
                XCTAssertGreaterThanOrEqual(metrics.sourceHeight * metrics.imageScale, height + Prompt09PaperLayout.bottomOverflow - 0.001)
                // Width depends only on runtime viewport width, never answer length.
                XCTAssertEqual(metrics.paperWidth, Prompt09PaperLayout.metrics(viewport: CGSize(width: width, height: 100)).paperWidth)
            }
        }
    }
    func testOpeningArtworkUsesVisiblePaintToCenterEachEqualColumn() {
        for art in Prompt09OpeningFruitArtwork.allCases {
            let box = CGSize(width: 70, height: 80)
            let scale = min(box.width / art.pixels.width, box.height / art.pixels.height)
            let offset = art.opticalOffset(box: box)
            XCTAssertEqual((box.width - art.pixels.width * scale) / 2 + art.paintedBounds.midX * scale + offset.width, box.width / 2, accuracy: 0.001)
            XCTAssertEqual((box.height - art.pixels.height * scale) / 2 + art.paintedBounds.midY * scale + offset.height, box.height / 2, accuracy: 0.001)
        }
    }
    func testCollapsedAndInvalidViewportsDoNotCreateNonfiniteGeometry() {
        for size in [CGSize.zero, CGSize(width: 12, height: 100), CGSize(width: CGFloat.infinity, height: 100)] {
            let metrics = Prompt09PaperLayout.metrics(viewport: size)
            XCTAssertEqual(metrics.paperWidth, 0)
            XCTAssertEqual(metrics.imageScale, 0)
            XCTAssertEqual(metrics.textColumnWidth, 0)
        }
    }
}

final class Prompt1BAskAnswerActionOwnershipTests: XCTestCase {
    private func answer(id: UUID = UUID(), text: String = "fixture answer") -> AskAnswer {
        AskAnswer(id: id, originalQuestion: "fixture question", answerText: text, support: .supported,
            knowledgeBaseVersion: "fixture", generationTimestamp: Date(timeIntervalSince1970: 99))
    }
    func testUniqueCurrentAnswerRequiresActiveOwner() {
        let record = answer(), conversation = UUID()
        let owner = Prompt09AnswerActionOwner(conversationID: conversation, answerID: record.id, language: .english)
        XCTAssertTrue(owner.accepts(answer: record, conversationID: conversation, language: .english,
                                    history: [record], isActive: true))
        XCTAssertFalse(owner.accepts(answer: record, conversationID: conversation, language: .english,
                                     history: [record], isActive: false))
    }
    func testConversationResetAndLanguageChangeInvalidateCapturedActions() {
        let record = answer(), conversation = UUID()
        let owner = Prompt09AnswerActionOwner(conversationID: conversation, answerID: record.id, language: .english)
        XCTAssertFalse(owner.accepts(answer: record, conversationID: UUID(), language: .english,
                                     history: [record], isActive: true))
        XCTAssertFalse(owner.accepts(answer: record, conversationID: conversation, language: .arabic,
                                     history: [record], isActive: true))
        XCTAssertFalse(owner.accepts(answer: record, conversationID: conversation, language: .english,
                                     history: [], isActive: true))
    }
    func testReplacedDuplicateOrUnownedAnswersCannotPrepareASave() {
        let record = answer(), conversation = UUID()
        let owner = Prompt09AnswerActionOwner(conversationID: conversation, answerID: record.id, language: .english)
        for history in [[answer(id: record.id, text: "new revision")], [record, record], [answer()]] {
            XCTAssertFalse(owner.accepts(answer: record, conversationID: conversation, language: .english,
                                         history: history, isActive: true))
        }
        let other = answer()
        XCTAssertFalse(owner.accepts(answer: other, conversationID: conversation, language: .english,
                                     history: [other], isActive: true))
    }
}
