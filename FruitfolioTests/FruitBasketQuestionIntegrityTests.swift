import XCTest
@testable import Fruitfolio

final class FruitBasketQuestionIntegrityTests: XCTestCase {
    private func original() async throws -> Prompt28Question {
        try await Prompt28CanonicalResearchProvider().question(topic: "nutrition", normalizedTopic: "nutrition",
                                                               difficulty: .easy, excludingQuestionIDs: [])
    }
    private func changed(_ question: Prompt28Question, _ edit: (inout [String: Any]) -> Void) throws -> Prompt28Question {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(question)) as? [String: Any])
        edit(&object)
        return try JSONDecoder().decode(Prompt28Question.self, from: JSONSerialization.data(withJSONObject: object))
    }

    func testMalformedStoredAnswerOptionsAndCitationIdentitiesCannotBecomePlayable() async throws {
        let valid = try await original()
        XCTAssertTrue(valid.isPlayable)
        let invalid: [(inout [String: Any]) -> Void] = [
            { $0["answerOptions"] = [["id": "a", "text": "one"], ["id": "a", "text": "two"]]; $0["correctAnswerID"] = "a" },
            { $0["answerOptions"] = [["id": "a", "text": "same"], ["id": "b", "text": "same"]]; $0["correctAnswerID"] = "a" },
            { $0["answerOptions"] = [["id": "", "text": "one"], ["id": "b", "text": "two"]]; $0["correctAnswerID"] = "b" },
            { $0["answerOptions"] = [["id": "a", "text": " "], ["id": "b", "text": "two"]]; $0["correctAnswerID"] = "b" },
            { $0["sourceIDs"] = ["same", "same"] },
            { $0["sourceIDs"] = [" "] }, { $0["explanation"] = " " },
            { $0["questionText"] = "\n" }, { $0["contentVersion"] = "" }
        ]
        for edit in invalid { XCTAssertFalse(try changed(valid, edit).isPlayable) }
    }

    func testEvidenceSnapshotMustMatchOriginalPassageVersionsAndApprovedSources() async throws {
        let valid = try await original()
        XCTAssertTrue(valid.hasVerifiedEvidenceSnapshot)
        let missing = try changed(valid) { $0.removeValue(forKey: "evidenceSnapshot") }
        XCTAssertFalse(missing.hasVerifiedEvidenceSnapshot)
        let altered = try changed(valid) { $0["explanation"] = "Changed unsupported explanation." }
        XCTAssertFalse(altered.hasVerifiedEvidenceSnapshot)
        let differentPackage = try changed(valid) { $0["contentVersion"] = "different-version" }
        XCTAssertFalse(differentPackage.hasVerifiedEvidenceSnapshot)
    }

    func testBridgeRejectsMissingEvidenceAndWrongTopicOrDifficultyWithoutFabricatingQuestions() async throws {
        let valid = try await original()
        let noSnapshot = try changed(valid) { $0.removeValue(forKey: "evidenceSnapshot") }
        let ungrounded = Prompt28ResearchLibraryBridge { _, _, _, _ in noSnapshot }
        do {
            _ = try await ungrounded.question(topic: "nutrition", normalizedTopic: "nutrition", difficulty: .easy, excludingQuestionIDs: [])
            XCTFail("Source identifiers alone cannot substitute for pinned approved evidence")
        } catch { XCTAssertEqual(error as? Prompt28ResearchError, .sourceValidationFailed) }
        let mismatched = Prompt28ResearchLibraryBridge { _, _, _, _ in valid }
        for request in [("hormones", Prompt28EducationalDifficulty.easy), ("nutrition", .medium)] {
            do {
                _ = try await mismatched.question(topic: request.0, normalizedTopic: request.0,
                                                  difficulty: request.1, excludingQuestionIDs: [])
                XCTFail("Question metadata must match the requested topic and difficulty")
            } catch { XCTAssertEqual(error as? Prompt28ResearchError, .invalidQuestion) }
        }
        let accepted = try await mismatched.question(topic: "nutrition", normalizedTopic: "nutrition",
                                                     difficulty: .easy, excludingQuestionIDs: [])
        XCTAssertEqual(accepted, valid)
    }
}
