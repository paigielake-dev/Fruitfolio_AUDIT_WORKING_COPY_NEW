import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt09AskTests: XCTestCase {
    func testEveryNewConversationStartsWithCanonicalGreeting() {
        let viewModel = Prompt09AskViewModel()
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.role, .fruitfolio)
        XCTAssertEqual(
            viewModel.messages.first?.text,
            "hi hi! ⟡ ݁ ₊ . what would you like to learn today?"
        )
    }

    func testCanonicalAskPresentationCopyRemainsExact() {
        XCTAssertEqual(Prompt09AskViewModel.sourcesHeading, "sources ˚ ☆ ‧ ₊")
        XCTAssertEqual(
            Prompt09AskViewModel.educationDisclaimer,
            "this is for education only, not medical advice."
        )
    }

    func testEducationalRouterRegistersAllFortyFourCanonicalAssets() {
        XCTAssertEqual(EducationalAssetRouter.canonicalDescriptors.count, 44)
        XCTAssertTrue(EducationalAssetRouter.canonicalDescriptors.allSatisfy(\.requiresResearchSupport))
    }

    func testEducationalVisualCannotBypassNoveltyBoundary() {
        let router = EducationalAssetRouter.shared
        let result = router.assets(
            for: ["ovulation", "follicle"],
            support: .genuinelyNovel
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testSupportedConceptSelectsSpecificEducationalVisual() {
        let router = EducationalAssetRouter.shared
        let result = router.assets(
            for: ["ovulation", "follicle"],
            support: .supported,
            maximumCount: 1
        )
        XCTAssertEqual(result.first?.assetID, .ovarian_cycle_follicle_development_stages)
    }

    func testPrompt09DevelopmentEngineDoesNotFabricateSources() async throws {
        let engine = Prompt09DevelopmentAskEngine()
        let answer = try await engine.answer(
            question: "test the Ask layout",
            conversation: []
        )

        XCTAssertTrue(answer.isDevelopmentPreview)
        XCTAssertTrue(answer.sources.isEmpty)
        XCTAssertTrue(answer.sourceIDs.isEmpty)
        XCTAssertEqual(answer.knowledgeBaseVersion, "prompt09-development-preview")
    }

    func testFullAnswerSavePreservesProvenanceFields() async throws {
        let store = Prompt09InMemorySaveStore()
        let answer = AskAnswer(
            originalQuestion: "layout test",
            answerText: "preview",
            support: .supported,
            sourceIDs: ["source-1"],
            sources: [
                AskSourceRecord(id: "source-1", title: "Fixture source", contentVersion: "3")
            ],
            knowledgeBaseVersion: "kb-3"
        )
        let conversationID = UUID()
        let request = AskSaveRequest(
            answer: answer,
            conversationID: conversationID,
            saveType: .fullAnswer,
            excerptText: nil,
            selectedCharacterRange: nil
        )

        try await store.save(request)
        let requests = await store.savedRequests()

        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.answer.sourceIDs, ["source-1"])
        XCTAssertEqual(requests.first?.answer.knowledgeBaseVersion, "kb-3")
        XCTAssertEqual(requests.first?.conversationID, conversationID)
    }
}
