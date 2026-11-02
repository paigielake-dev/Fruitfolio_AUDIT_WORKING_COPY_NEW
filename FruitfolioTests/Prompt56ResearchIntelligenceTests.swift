import XCTest
@testable import Fruitfolio

final class Prompt56ResearchIntelligenceTests: XCTestCase {
#if canImport(llama)
    /// Directly exercises the native GGUF path, never the research fallback.
    /// Run separately: loading a ~469 MB model may take time and memory.
    func testNativeGGUFProducesStructuredDraftWithoutFallback() async throws {
        let model = LlamaFruitfolioLanguageModel.shared
        let availability = await model.availability()
        XCTAssertEqual(availability, .available, "Bundled GGUF must be available")
        guard availability == .available else { return }

        let claim = FruitfolioClaimNeed(
            id: "claim_0", text: "progesterone and basal body temperature"
        )
        let note = FruitfolioResearchNoteChunk(
            chunkID: "note_1",
            researchTopicID: "topic_1",
            heading: "progesterone and temperature",
            subheading: nil,
            text: "Progesterone is associated with a post-ovulatory rise in basal body temperature.",
            sourceIDs: [],
            semanticTags: [],
            domainTags: []
        )
        let evidence = FruitfolioEvidencePacket(
            normalizedQuestion: "how does progesterone affect basal body temperature?",
            researchNoteChunks: [note],
            sourceChunks: [],
            claimEvidenceMap: [
                FruitfolioClaimEvidence(
                    claim: claim,
                    noteChunkIDs: ["note_1"],
                    sourceChunkIDs: []
                )
            ],
            sourceRecords: [],
            safetyClassification: Prompt34SafetyClassification(
                level: .normal, matchedPatterns: []
            ),
            permittedContext: nil,
            contentVersion: "native-inference-smoke-test"
        )

        let negativeNote = FruitfolioResearchNoteChunk(
            chunkID: "negative_note_2", researchTopicID: "topic_2",
            heading: "temperature and ovulation", subheading: nil,
            text: "A single temperature rise does not confirm ovulation.",
            sourceIDs: [], semanticTags: [], domainTags: []
        )
        let negativePacket = FruitfolioEvidencePacket(
            normalizedQuestion: "does a single temperature rise confirm ovulation?",
            researchNoteChunks: [negativeNote], sourceChunks: [],
            claimEvidenceMap: [FruitfolioClaimEvidence(
                claim: FruitfolioClaimNeed(id: "claim_1", text: "temperature rise confirm ovulation"),
                noteChunkIDs: [negativeNote.chunkID], sourceChunkIDs: []
            )],
            sourceRecords: [],
            safetyClassification: Prompt34SafetyClassification(level: .normal, matchedPatterns: []),
            permittedContext: nil, contentVersion: "native-negation-fixture"
        )
        // Direct native calls cannot be satisfied by a mock or retrieval fallback.
        // The second request changes evidence IDs and tests a critical negation.
        let requests = [
            ("How does progesterone affect basal body temperature?", evidence),
            ("Does a single temperature rise confirm ovulation?", negativePacket)
        ]
        for (index, request) in requests.enumerated() {
            let attempt = index + 1
            let draft = try await model.generateDraft(question: request.0, evidence: request.1)
            let encodedDraft = try JSONEncoder().encode(draft)
            let attachment = XCTAttachment(data: encodedDraft, uniformTypeIdentifier: "public.json")
            attachment.name = "NativeDraft_Request_\(attempt)"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTAssertFalse(draft.claims.isEmpty, "Native draft must contain a claim on request \(attempt)")
            XCTAssertNotNil(
                FruitfolioGeneratedDraftValidator.validatedText(draft: draft, evidence: request.1),
                "Native draft must retain the supplied evidence and identifier on request \(attempt): \(String(decoding: encodedDraft, as: UTF8.self))"
            )
        }
    }
#else
    func testNativeRuntimeMustBeLinkedForAIValidation() {
        XCTFail("The llama module is unavailable. Native inference must not be reported as verified by conditionally omitting its test.")
    }
#endif

    func testQueryNormalizationHandlesCommonCycleLanguage() {
        let normalized = FruitfolioQueryNormalizer.normalize("Why did my temp change during my period?")
        XCTAssertTrue(normalized.contains("temperature"))
        XCTAssertTrue(normalized.contains("menstruation"))
    }

    func testQuestionDecompositionPreservesMultipleClaimNeeds() {
        let claims = FruitfolioQuestionDecomposer.claims(from: "can pcos affect cycles and does one temperature rise confirm ovulation")
        XCTAssertGreaterThanOrEqual(claims.count, 2)
    }

    func testZeroMeteredAIClientsInvariant() {
        XCTAssertTrue(Prompt56ArchitectureAudit.hasZeroMeteredAIClients)
        XCTAssertTrue(Prompt56ArchitectureAudit.productionNetworkAIClients.isEmpty)
    }

    func testBoundedTrackerContextContainsNoRawHistoryFields() throws {
        let context = FruitfolioBoundedTrackerContext(
            predictionConfidence: "limited",
            reasonCode: "insufficientCompletedCycles",
            trackingGoal: "TTC",
            reproductiveStage: nil,
            cycleHealthContext: "PCOS"
        )
        let data = try JSONEncoder().encode(context)
        let text = String(decoding: data, as: UTF8.self).lowercased()
        XCTAssertFalse(text.contains("temperaturehistory"))
        XCTAssertFalse(text.contains("medicationhistory"))
        XCTAssertFalse(text.contains("sexual"))
    }

    func testResearchRetrieverCanRunWithoutGeneration() {
        let note = FruitfolioResearchNoteChunk(
            chunkID: "n1", researchTopicID: "t1", heading: "progesterone and temperature", subheading: nil,
            text: "Progesterone is associated with a post-ovulatory rise in basal body temperature in the approved note.",
            sourceIDs: [], semanticTags: [], domainTags: []
        )
        let package = FruitfolioResearchPackage(
            schemaVersion: 1, contentVersion: "test", generatedFrom: "fixture", generationNote: "fixture",
            researchNoteChunks: [note], sources: [], sourceChunks: []
        )
        let retriever = FruitfolioLocalResearchRetriever(package: package)
        let results = retriever.searchNotes(question: "why does progesterone change temperature")
        XCTAssertEqual(results.first?.chunk.chunkID, "n1")
    }

    func testUnsupportedEvidenceRemainsUnsupported() {
        let package = FruitfolioResearchPackage(
            schemaVersion: 1, contentVersion: "test", generatedFrom: "fixture", generationNote: "fixture",
            researchNoteChunks: [], sources: [], sourceChunks: []
        )
        let retriever = FruitfolioLocalResearchRetriever(package: package)
        let claims = FruitfolioQuestionDecomposer.claims(from: "unrepresented topic")
        let coverage = retriever.coverage(claims: claims, notes: [])
        XCTAssertFalse(coverage.hasAnySupport)
        XCTAssertFalse(coverage.isSufficient)
    }

    func testGeneratedDraftRejectsInventedEvidenceID() {
        let claim = FruitfolioClaimNeed(id: "claim_0", text: "progesterone temperature")
        let note = FruitfolioResearchNoteChunk(
            chunkID: "note_1",
            researchTopicID: "topic_1",
            heading: "progesterone and temperature",
            subheading: nil,
            text: "Progesterone is associated with a post-ovulatory basal body temperature rise.",
            sourceIDs: ["source_1"],
            semanticTags: [],
            domainTags: []
        )
        let packet = FruitfolioEvidencePacket(
            normalizedQuestion: "progesterone temperature",
            researchNoteChunks: [note],
            sourceChunks: [],
            claimEvidenceMap: [
                FruitfolioClaimEvidence(
                    claim: claim,
                    noteChunkIDs: ["note_1"],
                    sourceChunkIDs: []
                )
            ],
            sourceRecords: [],
            safetyClassification: Prompt34SafetyClassification(level: .normal, matchedPatterns: []),
            permittedContext: nil,
            contentVersion: "test"
        )
        let draft = FruitfolioGeneratedDraft(
            bridge: nil,
            claims: [
                FruitfolioGeneratedClaim(
                    text: "Progesterone can affect temperature.",
                    evidenceIDs: ["invented_id"]
                )
            ],
            limitation: nil
        )

        XCTAssertNil(
            FruitfolioGeneratedDraftValidator.validatedText(
                draft: draft,
                evidence: packet
            )
        )
    }

    func testGeneratedDraftKeepsEvidenceLinkedClaim() {
        let claim = FruitfolioClaimNeed(id: "claim_0", text: "progesterone temperature")
        let note = FruitfolioResearchNoteChunk(
            chunkID: "note_1",
            researchTopicID: "topic_1",
            heading: "progesterone and temperature",
            subheading: nil,
            text: "Progesterone is associated with a post-ovulatory basal body temperature rise.",
            sourceIDs: ["source_1"],
            semanticTags: [],
            domainTags: []
        )
        let packet = FruitfolioEvidencePacket(
            normalizedQuestion: "progesterone temperature",
            researchNoteChunks: [note],
            sourceChunks: [],
            claimEvidenceMap: [
                FruitfolioClaimEvidence(
                    claim: claim,
                    noteChunkIDs: ["note_1"],
                    sourceChunkIDs: []
                )
            ],
            sourceRecords: [],
            safetyClassification: Prompt34SafetyClassification(level: .normal, matchedPatterns: []),
            permittedContext: nil,
            contentVersion: "test"
        )
        let draft = FruitfolioGeneratedDraft(
            bridge: "here’s the evidence-bounded version:",
            claims: [
                FruitfolioGeneratedClaim(
                    text: "Progesterone is associated with a post-ovulatory basal body temperature rise.",
                    evidenceIDs: ["note_1"]
                )
            ],
            limitation: nil
        )

        let text = FruitfolioGeneratedDraftValidator.validatedText(
            draft: draft,
            evidence: packet
        )
        XCTAssertNotNil(text)
        XCTAssertTrue(text?.contains("Progesterone") == true)
        XCTAssertFalse(text?.contains("here’s the evidence-bounded version") == true)
        let unsupported = FruitfolioGeneratedDraft(
            bridge: nil,
            claims: [FruitfolioGeneratedClaim(text: "Progesterone cures cancer.", evidenceIDs: ["note_1"])],
            limitation: nil
        )
        XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedText(draft: unsupported, evidence: packet))
        let changedNegation = FruitfolioGeneratedDraft(
            bridge: nil,
            claims: [FruitfolioGeneratedClaim(text: "Progesterone is not associated with a post-ovulatory basal body temperature rise.", evidenceIDs: ["note_1"])],
            limitation: nil
        )
        XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedText(draft: changedNegation, evidence: packet))
    }
}
