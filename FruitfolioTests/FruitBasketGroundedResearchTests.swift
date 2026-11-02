import XCTest
@testable import Fruitfolio

@MainActor
final class FruitBasketGroundedResearchTests: XCTestCase {
    func testActualBundledResearchProvidesAllFiveMenuTopicsAtEveryDifficultyWithoutModelOrNetwork() async throws {
        let packages = FruitfolioResearchPackageStore()
        let provider = Prompt28CanonicalResearchProvider(packages: packages)
        let package = try await packages.load()
        for topic in ["reproductive health", "hormones", "nutrition", "surrogacy", "women’s wellness"] {
            for difficulty in Prompt28EducationalDifficulty.allCases {
                let question = try await provider.question(topic: topic, normalizedTopic: topic,
                    difficulty: difficulty, excludingQuestionIDs: [])
                let snapshot = try XCTUnwrap(question.evidenceSnapshot)
                XCTAssertTrue(question.isPlayable)
                XCTAssertEqual(snapshot.originalPassage, question.explanation)
                XCTAssertEqual(snapshot.packageVersion, package.contentVersion)
                XCTAssertEqual(Set(question.sourceIDs), Set(snapshot.sources.map(\.sourceID)))
                XCTAssertTrue(snapshot.sources.allSatisfy(\.isApprovedForDisplay))
                XCTAssertEqual(question.answerOptions.filter { $0.id == question.correctAnswerID }.count, 1)
                let correct = try XCTUnwrap(question.answerOptions.first { $0.id == question.correctAnswerID })
                let excerpt = String(question.questionText.split(separator: "\n", maxSplits: 1).last ?? "")
                    .trimmingCharacters(in: .newlines)
                XCTAssertEqual(excerpt.replacingOccurrences(of: "_____", with: correct.text), snapshot.originalPassage)
                XCTAssertTrue(package.researchNoteChunks.contains { $0.chunkID == snapshot.evidenceID && $0.text == question.explanation }
                    || package.sourceChunks.contains { $0.sourceChunkID == snapshot.evidenceID && $0.text == question.explanation })
                let decoded = try JSONDecoder().decode(Prompt28Question.self, from: JSONEncoder().encode(question))
                XCTAssertEqual(decoded, question, "Stored question preserves its original passage and exact approved source versions")
                let report = XCTAttachment(data: try JSONEncoder().encode(question), uniformTypeIdentifier: "public.json")
                report.name = "ActualFruitBasketResearch_\(topic)_\(difficulty.rawValue)"
                report.lifetime = .keepAlways; add(report)
            }
        }
    }

    func testUnapprovedSourcesAndUnsupportedQueriesCannotBecomePlayableQuestions() async throws {
        let original = try await FruitfolioResearchPackageStore().load()
        let blocked = FruitfolioResearchPackage(schemaVersion: original.schemaVersion,
            contentVersion: original.contentVersion, generatedFrom: original.generatedFrom,
            generationNote: original.generationNote, researchNoteChunks: original.researchNoteChunks,
            sources: [], sourceChunks: original.sourceChunks)
        let provider = Prompt28CanonicalResearchProvider(packages: .init(package: blocked))
        do {
            _ = try await provider.question(topic: "hormones", normalizedTopic: "hormones", difficulty: .easy, excludingQuestionIDs: [])
            XCTFail("Missing approved source records must fail closed")
        } catch { XCTAssertEqual(error as? Prompt28ResearchError, .unsupportedTopic) }
        let live = Prompt28CanonicalResearchProvider()
        do {
            _ = try await live.question(topic: "zzzxqvvzz", normalizedTopic: "zzzxqvvzz", difficulty: .easy, excludingQuestionIDs: [])
            XCTFail("No model-memory or arbitrary-topic quiz may replace missing evidence")
        } catch { XCTAssertEqual(error as? Prompt28ResearchError, .unsupportedTopic) }
    }

    func testExclusionUsesStableEvidenceIdentityAndDoesNotRepeatTheSameQuestion() async throws {
        let provider = Prompt28CanonicalResearchProvider()
        let first = try await provider.question(topic: "hormones", normalizedTopic: "hormones", difficulty: .easy, excludingQuestionIDs: [])
        let second = try await provider.question(topic: "hormones", normalizedTopic: "hormones", difficulty: .easy, excludingQuestionIDs: [first.id])
        XCTAssertNotEqual(first.id, second.id)
        let repeated = try await provider.question(topic: "hormones", normalizedTopic: "hormones", difficulty: .easy, excludingQuestionIDs: [])
        XCTAssertEqual(repeated.id, first.id)
    }
}
