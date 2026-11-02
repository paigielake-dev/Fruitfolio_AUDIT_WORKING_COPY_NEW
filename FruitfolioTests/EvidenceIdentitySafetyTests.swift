import XCTest
@testable import Fruitfolio

/// Structural adversarial fixtures, not a claim of clinical evidence review.
final class EvidenceIdentitySafetyTests: XCTestCase {
    private let passage = "Temperature evidence at 2.500 units does not confirm ovulation."
    private func note(_ id: String) -> FruitfolioResearchNoteChunk {
        .init(chunkID: id, researchTopicID: "fixture", heading: "temperature evidence", subheading: nil,
              text: passage, sourceIDs: [], semanticTags: [], domainTags: [])
    }
    private func packet(notes: [FruitfolioResearchNoteChunk], extracts: [FruitfolioSourceChunk] = [],
                        claims: [FruitfolioClaimEvidence]? = nil,
                        sources: [FruitfolioResearchSource] = []) -> FruitfolioEvidencePacket {
        .init(normalizedQuestion: "temperature evidence", researchNoteChunks: notes, sourceChunks: extracts,
              claimEvidenceMap: claims ?? [.init(claim: .init(id: "claim", text: "temperature evidence"),
                                                noteChunkIDs: notes.map(\.chunkID), sourceChunkIDs: extracts.map(\.sourceChunkID))],
              sourceRecords: sources, safetyClassification: .init(level: .normal, matchedPatterns: []),
              permittedContext: nil, contentVersion: "structural-test-only")
    }

    func testValidIdentityStillRequiresCompleteVerbatimEvidenceIncludingNegationAndMeasurements() throws {
        let evidence = packet(notes: [note("note")])
        let draft = try FruitfolioSelectedEvidenceDraftBuilder.draft(selection: .init(evidenceIDs: ["note"]), evidence: evidence)
        XCTAssertEqual(draft.claims.first?.text, passage)
        XCTAssertNotNil(FruitfolioGeneratedDraftValidator.validatedDraft(draft: draft, evidence: evidence))
        for changed in ["Temperature evidence at 2.500 units confirms ovulation.",
                        "Temperature evidence at 2.5 units does not confirm ovulation.",
                        "Temperature evidence does not confirm ovulation."] {
            let altered = FruitfolioGeneratedDraft(bridge: nil, claims: [.init(text: changed, evidenceIDs: ["note"])], limitation: nil)
            XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedDraft(draft: altered, evidence: evidence))
        }
    }

    func testDuplicateNotesOrCrossNamespaceCollisionFailClosedBeforeDictionaryConstruction() {
        let duplicate = packet(notes: [note("same"), note("same")])
        let extract = FruitfolioSourceChunk(sourceChunkID: "same", sourceID: "fixture-source",
                                            section: nil, text: "Conflicting extract.", locationMetadata: nil, claimCategories: [])
        let collision = packet(notes: [note("same")], extracts: [extract])
        let duplicateExtracts = packet(notes: [], extracts: [extract, extract])
        for evidence in [duplicate, collision, duplicateExtracts] {
            XCTAssertFalse(evidence.hasUnambiguousEvidenceIdentity)
            XCTAssertThrowsError(try FruitfolioSelectedEvidenceDraftBuilder.draft(selection: .init(evidenceIDs: ["same"]), evidence: evidence))
            let draft = FruitfolioGeneratedDraft(bridge: nil, claims: [.init(text: passage, evidenceIDs: ["same"])], limitation: nil)
            XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedDraft(draft: draft, evidence: evidence))
        }
    }

    func testDuplicateClaimIdentifiersAndBlankEvidenceIdentifiersAreRejected() {
        let claim = FruitfolioClaimEvidence(claim: .init(id: "same-claim", text: "temperature evidence"),
                                           noteChunkIDs: ["note"], sourceChunkIDs: [])
        let source = FruitfolioResearchSource(sourceID: "source", title: "Fixture", authors: nil,
            organization: nil, publicationDate: nil, publicationType: nil, canonicalURL: nil, doi: nil,
            apa7Reference: "Fixture only.", verificationStatus: "verified", retrievalEligibility: true,
            sourceVersion: "v1", verifiedAt: nil, contentVersion: "v1")
        for evidence in [packet(notes: [note("note")], claims: [claim, claim]), packet(notes: [note(" ")]),
                         packet(notes: [note("note")], sources: [source, source])] {
            XCTAssertFalse(evidence.hasUnambiguousEvidenceIdentity)
            XCTAssertThrowsError(try FruitfolioSelectedEvidenceDraftBuilder.draft(selection: .init(evidenceIDs: ["note"]), evidence: evidence))
            let draft = FruitfolioGeneratedDraft(bridge: nil, claims: [.init(text: passage, evidenceIDs: ["note"])], limitation: nil)
            XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedDraft(draft: draft, evidence: evidence))
        }
    }
}
