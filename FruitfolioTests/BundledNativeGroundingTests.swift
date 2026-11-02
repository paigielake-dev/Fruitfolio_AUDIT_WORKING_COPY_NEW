import XCTest
@testable import Fruitfolio

final class BundledNativeGroundingTests: XCTestCase {
#if canImport(llama)
    @MainActor
    func testNativeAnswerUsesActualBundledResearchAndDocumentCitations() async throws {
        let model = RecordingNativeModel()
        let engine = FruitfolioResearchIntelligenceEngine(languageModel: model)
        let answer = try await engine.answer(
            question: "How does morning sunlight affect the body clock?", conversation: [])
        let result = await model.result()
        let attachment = XCTAttachment(data: result.data, uniformTypeIdentifier: "public.json")
        attachment.name = "ActualBundledResearchNativeDraft"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertTrue(result.accepted, "Retrieval fallback cannot satisfy this native integration test: \(String(decoding: result.data, as: UTF8.self))")
        XCTAssertFalse(answer.sources.isEmpty)
        XCTAssertTrue(answer.sourceIDs.allSatisfy { $0.hasPrefix("founder_corpus_") || $0.hasPrefix("founder_guide_") })
        XCTAssertFalse(answer.isDevelopmentPreview)
    }
#else
    func testNativeRuntimeRequired() { XCTFail("Native llama runtime must be linked") }
#endif
}

#if canImport(llama)
private actor RecordingNativeModel: FruitfolioLanguageModel {
    private var accepted = false
    private var data = Data()
    func availability() async -> FruitfolioLanguageModelAvailability {
        await LlamaFruitfolioLanguageModel.shared.availability()
    }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        let draft = try await LlamaFruitfolioLanguageModel.shared.generateDraft(question: question, evidence: evidence)
        data = try JSONEncoder().encode(draft)
        accepted = FruitfolioGeneratedDraftValidator.validatedDraft(draft: draft, evidence: evidence) != nil
        return draft
    }
    func result() -> (accepted: Bool, data: Data) { (accepted, data) }
}
#endif
