import Foundation
import XCTest
@testable import Fruitfolio

private actor ExcerptReadingAidFixtureRuntime: FruitfolioLocalTranslationRuntime {
    enum Output { case preserve, dropBlank, insertAnswer(String) }
    let output: Output
    private(set) var inputs: [String] = []
    init(output: Output = .preserve) { self.output = output }
    func translate(_ text: String, targetTag: String) async throws -> String {
        inputs.append(text)
        switch output {
        case .preserve: return text.replacingOccurrences(of: "the ", with: "le ")
        case .dropBlank: return "lecture sans marqueur"
        case .insertAnswer(let answer): return text + " " + answer
        }
    }
    func releaseResources() async {}
}

final class Prompt1BGameSavedSourceTests: XCTestCase {
    private func question(records: [AskSourceRecord]? = nil,
                          text: String = "which word matches the exact test excerpt?",
                          category: String = "source-excerpt practice",
                          explanation: String = "test-only original field x_y = 2–4; not a medical claim",
                          sourceIDs: [String]? = nil, version: String = "package-v2",
                          review: String = "test-only", createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)) -> Prompt28Question {
        Prompt28Question(id: "fixture", topicQuery: "test", normalizedTopic: "test", category: category,
            educationalDifficulty: .easy, questionText: text,
            answerOptions: [.init(id: "a", text: "first"), .init(id: "b", text: "second")], correctAnswerID: "a",
            explanation: explanation, sourceIDs: sourceIDs ?? (records?.map(\.id) ?? ["legacy"]),
            sourceTitles: records?.map(\.title) ?? ["Legacy attribution"], catchConceptID: "visual-starred-fruit", catchRule: "starred fruit",
            goodFruitIDs: [.pear], badFruitIDs: [.lemon], contentVersion: version, reviewStatus: review,
            createdAt: createdAt, sourceRecords: records)
    }
    func testBlankProvenanceOrExplanationAndNonfiniteDatesCannotBecomeSavedResearch() {
        let invalid = [question(explanation: " \n"), question(sourceIDs: [" "]), question(version: " "),
            question(review: " "), question(createdAt: Date(timeIntervalSinceReferenceDate: .nan)),
            question(createdAt: Date(timeIntervalSinceReferenceDate: .infinity))]
        for (index, q) in invalid.enumerated() {
            XCTAssertFalse(q.isPlayable, "Malformed scalar metadata case \(index)")
            // Compare only the Boolean: printing a nonfinite Date is not part of this contract.
            XCTAssertTrue(Prompt28SavedResearchCopy.pending(question: q) == nil,
                "Malformed metadata must not reach saved research: \(index)")
        }
    }

    func testPresentBlankSourceVersionCannotProduceEmptySavedProvenance() {
        for version in ["", " \n"] {
            let record = AskSourceRecord(id: "paper", title: "Original fixture attribution",
                sourceText: "Original APA fixture x_y = 2–4", contentVersion: version)
            let q = question(records: [record])
            XCTAssertFalse(q.isPlayable)
            XCTAssertTrue(Prompt28SavedResearchCopy.pending(question: q) == nil)
        }
    }

    func testAbsentLegacySourceVersionKeepsPackageFallbackAndOriginalCitation() throws {
        let record = AskSourceRecord(id: "paper", title: "Original fixture attribution",
            sourceText: "  Original APA fixture x_y = 2–4 cafe\u{301}\n", doi: "10.1000/fixture")
        XCTAssertNil(record.contentVersion)
        let q = question(records: [record])
        let saved = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: q))
        XCTAssertEqual(saved.sourceVersions, ["paper": "package-v2"])
        XCTAssertEqual(saved.sourceRecords, [record])
        XCTAssertEqual(saved.answer, q.explanation)
        XCTAssertEqual(saved.knowledgeBaseVersion, q.contentVersion)
        XCTAssertEqual(saved.generationTimestamp, q.createdAt)
    }

    func testReadingAidMasksBlankAndAnswerChoicesWhilePreservingSourceAndSavedContract() async throws {
        let record = AskSourceRecord(id: "paper", title: "Original fixture attribution", sourceText: "Original APA fixture",
            doi: "10.1234/fixture", contentVersion: "paper-v7")
        let q = question(records: [record], text: Prompt28ExcerptQuestionPresentation.prefix + "the [blank] fixture has FSH 2.5 IU/L. DOI:10.1234/fixture")
        let excerpt = try XCTUnwrap(Prompt28ExcerptQuestionPresentation(question: q))
        let before = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: q))
        let runtime = ExcerptReadingAidFixtureRuntime()
        let service = FruitfolioTranslationService(runtime: runtime)
        let translated = try await service.translate(excerpt.literalExcerpt, language: .french,
            protectedLiterals: FruitfolioCitationProtection.literals(ids: excerpt.readingAidProtectedLiterals, records: q.sourceRecords ?? []),
            preferCatalog: false)
        XCTAssertTrue(translated.hasPrefix("le [blank]"))
        XCTAssertTrue(translated.contains("FSH 2.5 IU/L")); XCTAssertTrue(translated.contains("10.1234/fixture"))
        let inputs = await runtime.inputs
        XCTAssertEqual(inputs.count, 1)
        let input = try XCTUnwrap(inputs.first)
        for literal in ["[blank]", "first", "second", "FSH", "2.5", "10.1234/fixture"] { XCTAssertFalse(input.contains(literal)) }
        let after = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: q))
        XCTAssertEqual(after.question, before.question); XCTAssertEqual(after.answer, before.answer)
        XCTAssertEqual(after.sourceIDs, before.sourceIDs); XCTAssertEqual(after.sourceVersions, before.sourceVersions)
        XCTAssertEqual(after.sourceRecords, before.sourceRecords); XCTAssertEqual(after.generationTimestamp, before.generationTimestamp)
        XCTAssertEqual(q.answerOptions.map(\.text), ["first", "second"]); XCTAssertEqual(q.correctAnswerID, "a")
    }

    func testReadingAidRejectsDroppedBlank() async throws {
        let q = question(text: Prompt28ExcerptQuestionPresentation.prefix + "the [blank] fixture")
        let excerpt = try XCTUnwrap(Prompt28ExcerptQuestionPresentation(question: q))
        let service = FruitfolioTranslationService(runtime: ExcerptReadingAidFixtureRuntime(output: .dropBlank))
        do {
            _ = try await service.translate(excerpt.literalExcerpt, language: .french,
                protectedLiterals: excerpt.readingAidProtectedLiterals, preferCatalog: false)
            XCTFail("A reading aid without the original cloze marker must not be displayed")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
    }

    func testReadingAidRejectsIntroducedOmittedAnswerOrDistractor() async throws {
        let q = question(text: Prompt28ExcerptQuestionPresentation.prefix + "the [blank] fixture")
        let excerpt = try XCTUnwrap(Prompt28ExcerptQuestionPresentation(question: q))
        for answer in q.answerOptions {
            let service = FruitfolioTranslationService(runtime: ExcerptReadingAidFixtureRuntime(output: .insertAnswer(answer.text)))
            do {
                _ = try await service.translate(excerpt.literalExcerpt, language: .french,
                    protectedLiterals: excerpt.readingAidProtectedLiterals, preferCatalog: false)
                XCTFail("An absent answer choice must not be introduced into the reading aid")
            } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
        }
    }

    func testKnownExcerptPresentationPreservesLiteralBytesAndSavedOriginal() throws {
        let literal = "  synthetic [blank]; x_y; FSH ≤ −2.5 IU/L. DOI:10.1234/fixture cafe\u{301}\n\n  "
        let original = Prompt28ExcerptQuestionPresentation.prefix + literal
        let q = question(text: original)
        let presentation = try XCTUnwrap(Prompt28ExcerptQuestionPresentation(question: q))
        XCTAssertEqual(Data(presentation.literalExcerpt.utf8), Data(literal.utf8))
        let saved = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: q))
        XCTAssertEqual(Data(saved.question.utf8), Data(original.utf8))
        XCTAssertEqual(saved.answer, q.explanation)
        XCTAssertEqual(saved.sourceIDs, q.sourceIDs)
        XCTAssertEqual(q.answerOptions.map(\.text), ["first", "second"])
        XCTAssertEqual(q.correctAnswerID, "a")
    }

    func testUnknownLegacyOrEmptyExcerptTemplateDoesNotDropQuestionText() {
        for q in [question(), question(text: Prompt28ExcerptQuestionPresentation.prefix),
                  question(text: " " + Prompt28ExcerptQuestionPresentation.prefix + "literal"),
                  question(text: Prompt28ExcerptQuestionPresentation.prefix + "literal", category: "other")] {
            XCTAssertNil(Prompt28ExcerptQuestionPresentation(question: q))
            XCTAssertFalse(q.questionText.isEmpty)
        }
    }

    func testSavedLessonRetainsOriginalSourceVersionAndCitationMetadata() throws {
        let source = AskSourceRecord(id: "paper", title: "Original fixture attribution", sourceText: "Original APA fixture",
            urlString: "https://example.test/paper", doi: "10.1000/fixture", publicationData: "2026", contentVersion: "paper-v7")
        let q = question(records: [source])
        let saved = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: q))
        XCTAssertEqual(saved.sourceVersions["paper"], "paper-v7")
        XCTAssertEqual(saved.knowledgeBaseVersion, "package-v2")
        XCTAssertEqual(saved.sourceRecords, [source])
        XCTAssertEqual(saved.question, q.questionText)
        XCTAssertEqual(saved.answer, q.explanation)
        XCTAssertEqual(saved.generationTimestamp, q.createdAt)
        XCTAssertEqual(saved.originalAnswerID, "fruitbasket:fixture")
    }
    func testLegacyQuestionUsesItsKnownPackageVersionWithoutInventingSourceRecords() throws {
        let saved = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: question()))
        XCTAssertEqual(saved.sourceVersions, ["legacy": "package-v2"])
        XCTAssertNil(saved.sourceRecords)
    }
    func testInvalidDuplicateSourceIdentityCannotCrashOrSaveAFalseTrail() {
        let source = AskSourceRecord(id: "same", title: "Fixture")
        XCTAssertNil(Prompt28SavedResearchCopy.pending(question: question(records: [source, source])))
    }
}
