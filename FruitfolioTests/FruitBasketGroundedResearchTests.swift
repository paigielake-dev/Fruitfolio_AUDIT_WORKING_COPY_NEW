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
                let prefix = "which word fills the blank in this research-library passage?\n\n"
                XCTAssertTrue(question.questionText.hasPrefix(prefix))
                let excerpt = String(question.questionText.dropFirst(prefix.count))
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

    func testSavingTheActualQuestionPreservesSourceSnapshotsRatherThanSubstitutingThePackageVersion() async throws {
        let suite = "Fruitfolio.GameSources.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let provider = Prompt28CanonicalResearchProvider()
        let question = try await provider.question(topic: "nutrition", normalizedTopic: "nutrition",
            difficulty: .easy, excludingQuestionIDs: [])
        let model = Prompt28FruitBasketViewModel(store: .init(defaults: defaults), researchProvider: provider)
        model.currentQuestion = question
        let pending = try XCTUnwrap(model.savePendingContent())
        let original = try XCTUnwrap(question.evidenceSnapshot)
        XCTAssertEqual(pending.sourceVersions, Dictionary(uniqueKeysWithValues: original.sources.map { ($0.sourceID, $0.contentVersion) }))
        XCTAssertEqual(pending.sourceSnapshots?.map(\.id), original.sources.map(\.sourceID))
        XCTAssertEqual(pending.sourceSnapshots?.map(\.sourceText), original.sources.map(\.apa7Reference))
        XCTAssertTrue(pending.answer.contains(original.originalPassage))
        XCTAssertFalse(pending.answer.contains("^_"))
        XCTAssertEqual(pending.knowledgeBaseVersion, original.packageVersion)
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

extension FruitBasketGroundedResearchTests {
    func testCompletedRoundKeepsActualApprovedExplanationAndSourceVersionsAfterResearchReplacementAndRestart() async throws {
        let suite = "Fruitfolio.CompletedRoundSnapshot.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let packages = FruitfolioResearchPackageStore()
        let originalPackage = try await packages.load()
        let provider = Prompt28CanonicalResearchProvider(packages: packages)
        let question = try await provider.question(topic: "nutrition", normalizedTopic: "nutrition", difficulty: .easy, excludingQuestionIDs: [])
        let originalEvidence = try XCTUnwrap(question.evidenceSnapshot)
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let record = Prompt28CompletedRound(id: UUID(), sessionID: UUID(), round: 1,
            completedAt: Date(timeIntervalSinceReferenceDate: 799999999.1234568), successful: true,
            question: question, collection: .init(goodFruit: [.apple, .pear], startingScore: 40),
            finalScore: 60, remainingStarPasses: 1, personalBest: false)
        // Persistence fixture only: actual registered full-round scoring has its
        // separate frame-driven test. Do not mistake this fixture for gameplay.
        store.recordCompletedRound(record)
        let storedBefore = try XCTUnwrap(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"))
        var replacement = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(originalPackage)) as? [String: Any])
        replacement["contentVersion"] = "test-only-successor-package"
        var sources = try XCTUnwrap(replacement["sources"] as? [[String: Any]])
        let usedIDs = Set(originalEvidence.sources.map(\.sourceID))
        for index in sources.indices where usedIDs.contains(sources[index]["sourceID"] as? String ?? "") {
            sources[index]["sourceVersion"] = "test-only-successor-source"
            sources[index]["contentVersion"] = "test-only-successor-package"
        }
        replacement["sources"] = sources
        let nextPackage = try JSONDecoder().decode(FruitfolioResearchPackage.self,
            from: JSONSerialization.data(withJSONObject: replacement))
        let nextProvider = Prompt28CanonicalResearchProvider(packages: .init(package: nextPackage))
        let nextQuestion = try await nextProvider.question(topic: "nutrition", normalizedTopic: "nutrition", difficulty: .easy, excludingQuestionIDs: [])
        XCTAssertEqual(nextQuestion.contentVersion, "test-only-successor-package")
        XCTAssertTrue(try XCTUnwrap(nextQuestion.evidenceSnapshot).sources.allSatisfy { $0.sourceVersion == "test-only-successor-source" })
        let restored = Prompt28FruitBasketStore(defaults: defaults)
        XCTAssertEqual(restored.completedRounds, [record])
        XCTAssertEqual(restored.completedRounds.first?.question.explanation, originalEvidence.originalPassage)
        XCTAssertEqual(restored.completedRounds.first?.question.evidenceSnapshot, originalEvidence)
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"), storedBefore,
                       "New retrieval must not rewrite the original completed-round bytes")
        let factRecord = XCTAttachment(data: try JSONEncoder().encode(record), uniformTypeIdentifier: "public.json")
        factRecord.name = "CompletedRound_OriginalGroundedFactAndSourceVersions"; factRecord.lifetime = .keepAlways; add(factRecord)
    }
}
