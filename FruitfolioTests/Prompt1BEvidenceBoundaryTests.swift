import XCTest
@testable import Fruitfolio

final class Prompt1BEvidenceBoundaryTests: XCTestCase {
    private let original = "Progesterone is associated with a temperature rise after ovulation; one reading does not confirm ovulation."
    private func packet() -> FruitfolioEvidencePacket {
        let note = FruitfolioResearchNoteChunk(chunkID: "note-1", researchTopicID: "topic", heading: "progesterone temperature",
            subheading: nil, text: original, sourceIDs: ["source-1"], semanticTags: [], domainTags: [])
        return .init(normalizedQuestion: "progesterone temperature", researchNoteChunks: [note], sourceChunks: [],
                     claimEvidenceMap: [.init(claim: .init(id: "claim-1", text: "progesterone temperature"), noteChunkIDs: ["note-1"], sourceChunkIDs: [])],
                     sourceRecords: [], safetyClassification: .init(level: .normal, matchedPatterns: []), permittedContext: nil, contentVersion: "fixture")
    }
    func testKeywordOverlapCannotApproveReversedRelationshipOrDroppedQualifier() {
        for unsupported in ["Progesterone causes a temperature decrease after ovulation.",
                            "Progesterone is associated with a temperature rise after ovulation.",
                            "Progesterone confirms ovulation."] {
            let draft = FruitfolioGeneratedDraft(bridge: nil, claims: [.init(text: unsupported, evidenceIDs: ["note-1"])], limitation: nil)
            XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedText(draft: draft, evidence: packet()))
        }
    }
    func testFreeFormBridgeAndLimitationCannotSmuggleMedicalClaimsPastEvidenceCheck() throws {
        let draft = FruitfolioGeneratedDraft(bridge: "you are definitely pregnant", claims: [.init(text: original, evidenceIDs: ["note-1"])], limitation: "take an unsupported treatment")
        let result = try XCTUnwrap(FruitfolioGeneratedDraftValidator.validatedText(draft: draft, evidence: packet()))
        XCTAssertTrue(result.contains(original))
        XCTAssertFalse(result.contains("definitely pregnant"))
        XCTAssertFalse(result.contains("unsupported treatment"))
        XCTAssertTrue(result.contains("☆"))
    }
    func testScientificQuantitiesCaseAndLiteralOperatorsArePreserved() throws {
        XCTAssertFalse(FruitfolioEvidenceCopyPolicy.matchesCompleteEvidence("E2 200 pg/mL", original: "E2 20 pg/mL"))
        XCTAssertFalse(FruitfolioEvidenceCopyPolicy.matchesCompleteEvidence("1 mm", original: "1 mM"))
        let presentation = try XCTUnwrap(FruitfolioEvidenceCopyPolicy.validatedPresentation("2 * 3 * 4", original: "2 * 3 * 4"))
        XCTAssertEqual(presentation, "2 \\* 3 \\* 4")
        XCTAssertTrue(FruitfolioEvidenceCopyPolicy.matchesCompleteEvidence("**E2** 20 pg/mL", original: "E2 20 pg/mL"))
    }
    func testSelectionRejectsUnknownUnpermittedAndExcessiveIDs() throws {
        for json in [#"{"evidenceIDs":["invented"]}"#, #"{"evidenceIDs":["note-1","note-1","note-1","note-1"]}"#] {
            XCTAssertThrowsError(try FruitfolioEvidenceSelectionDecoder.draft(from: Data(json.utf8), evidence: packet(), maximumClaims: 3))
        }
        var evidence = packet()
        evidence = .init(normalizedQuestion: evidence.normalizedQuestion, researchNoteChunks: evidence.researchNoteChunks,
            sourceChunks: [], claimEvidenceMap: [], sourceRecords: [], safetyClassification: evidence.safetyClassification,
            permittedContext: nil, contentVersion: "fixture")
        XCTAssertThrowsError(try FruitfolioEvidenceSelectionDecoder.draft(from: Data(#"{"evidenceIDs":["note-1"]}"#.utf8), evidence: evidence, maximumClaims: 3))
    }

    func testSelectionReconstructsOnlyOriginalEvidenceAndRecordsActualAttribution() throws {
        let data = Data(#"{"evidenceIDs":["note-1","note-1"],"text":"invented treatment"}"#.utf8)
        let draft = try FruitfolioEvidenceSelectionDecoder.draft(from: data, evidence: packet(), maximumClaims: 3)
        XCTAssertEqual(draft.claims.count, 1)
        XCTAssertEqual(draft.claims.first?.text, original)
        let answer = try XCTUnwrap(FruitfolioGeneratedDraftValidator.validatedAnswer(draft: draft, evidence: packet()))
        XCTAssertEqual(answer.usedEvidenceIDs, ["note-1"])
        XCTAssertFalse(answer.text.contains("invented treatment"))
    }
    #if canImport(llama)
    func testNativeEvidenceSelectionPreservesQuotedUnicodeSourceAndExactEvidenceID() async throws {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_MODEL_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioAI", withExtension: "gguf"))
        let model = LlamaFruitfolioLanguageModel(modelURL: url)
        let text = "The laboratory supplied the label \"E2\" and the recorded value 20 pg/mL; this is not a diagnosis. μg"
        let id = "note_μ/1"
        let note = FruitfolioResearchNoteChunk(chunkID: id, researchTopicID: "fixture", heading: "laboratory label", subheading: nil,
            text: text, sourceIDs: [], semanticTags: [], domainTags: [])
        let evidence = FruitfolioEvidencePacket(normalizedQuestion: "laboratory label", researchNoteChunks: [note], sourceChunks: [],
            claimEvidenceMap: [.init(claim: .init(id: "claim-1", text: "laboratory label"), noteChunkIDs: [id], sourceChunkIDs: [])],
            sourceRecords: [], safetyClassification: .init(level: .normal, matchedPatterns: []), permittedContext: nil, contentVersion: "fixture")
        let draft = try await model.generateDraft(question: "What is the exact recorded laboratory label and value?", evidence: evidence)
        XCTAssertEqual(draft.claims.first?.text, text)
        XCTAssertEqual(draft.claims.first?.evidenceIDs, [id])
        XCTAssertNotNil(FruitfolioGeneratedDraftValidator.validatedText(draft: draft, evidence: evidence))
    }
    #endif

    func testSeriousFramingDoesNotInventAnEmergencyAndKaomojiMaximumMatchesFounderRule() {
        let sensitive = FruitfolioCanonicalAnswerVoice.compose(excerpts: ["exact approved evidence"], hasUnansweredParts: false,
            safety: .init(level: .sensitive, matchedPatterns: []))
        XCTAssertFalse(sensitive.contains("urgent medical"))
        XCTAssertFalse(sensitive.contains("♡"))
        XCTAssertEqual(Prompt54CanonicalVoicePolicy.maximumKaomojiPerAnswer, 3)
        XCTAssertEqual(Prompt54CanonicalVoicePolicy.preferredKaomojiRange, 0...1)
    }
}
