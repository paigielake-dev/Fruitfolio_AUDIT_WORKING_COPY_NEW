import XCTest
@testable import Fruitfolio

private actor Prompt1BContextCapturingSynthesis: FruitfolioLanguageModel {
    private(set) var captured: FruitfolioEvidencePacket?
    func availability() async -> FruitfolioLanguageModelAvailability { .packageNotLinked }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        captured = evidence
        throw FruitfolioLanguageModelError.unavailable(.packageNotLinked)
    }
}

final class Prompt1BAskUserContextTests: XCTestCase {
    func testOnlyTypedContextFailuresQualifyAsFixedTranslationCopy() {
        let controlled = FruitfolioAskContextNotice(error: FruitfolioAskUserContext.Failure.tooLarge)
        XCTAssertEqual(controlled, .tooLarge)
        XCTAssertEqual(controlled.fixedSource, FruitfolioAskUserContext.Failure.tooLarge.errorDescription)
        let spoof = NSError(domain: "untrusted-provider", code: 1,
            userInfo: [NSLocalizedDescriptionKey: controlled.text])
        let external = FruitfolioAskContextNotice(error: spoof)
        XCTAssertNil(external.fixedSource, "Identical error text must not establish trusted copy")
        XCTAssertEqual(external.text, controlled.text)
    }

    func testUnknownErrorRetainsExactOriginalBytesAndIsNeverFixedCopy() {
        let original = "cafe\u{301} [source-A] **private** 12,50 µg/L"
        let notice = FruitfolioAskContextNotice(error: NSError(domain: "fixture", code: 2,
            userInfo: [NSLocalizedDescriptionKey: original]))
        XCTAssertNil(notice.fixedSource)
        XCTAssertEqual(Array(notice.text.utf8), Array(original.utf8))
    }

    func testNativeSelectionCountIsProtectedAndCannotRewritePatientSnapshot() throws {
        let record = measurement()
        let snapshot = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [record.id],
            personalCategories: [], measurements: [record], context: .unspecified))
        let originalJSON = try snapshot.promptJSON()
        for locale in ["en_US", "fr_FR", "ar", "hi_IN", "ja_JP"] {
            let copy = FruitfolioAskContextSelectionCopy(count: 1234, locale: Locale(identifier: locale))
            let number = try XCTUnwrap(copy.protectedLiterals.first)
            let envelope = try FruitfolioScientificTranslationEnvelope(copy.source, protectedLiterals: copy.protectedLiterals)
            XCTAssertFalse(envelope.prepared.contains(number))
            XCTAssertEqual(try envelope.restore(envelope.prepared), copy.source)
            XCTAssertThrowsError(try envelope.validateCatalogCandidate(copy.source.replacingOccurrences(of: number, with: "999")))
        }
        XCTAssertEqual(try snapshot.promptJSON(), originalJSON)
        XCTAssertEqual(snapshot.records.first?.fields["result_exactly_as_entered"], "12,50")
        XCTAssertEqual(snapshot.records.first?.fields["unit_exactly_as_entered"], "µg/L")
    }

    private func measurement() -> FruitfolioHormoneMeasurement {
        var record = FruitfolioHormoneMeasurement()
        record.hormone = .progesterone; record.result = "12,50"; record.unit = "µg/L"
        record.resultLocaleIdentifier = "de_DE"; record.notes = "private-marker-not-output"
        return record
    }
    func testNothingIsSharedWithoutExplicitSelectionAndDeletedItemsCannotBeResolved() throws {
        var context = Prompt27AUserReproductiveContext()
        try context.setPersonalHealth(.dna, text: "private finding")
        let record = measurement()
        XCTAssertNil(try FruitfolioAskUserContext.selected(measurementIDs: [], personalCategories: [], measurements: [record], context: context))
        try context.setPersonalHealth(.dna, text: "", status: .removed)
        XCTAssertNil(try FruitfolioAskUserContext.selected(measurementIDs: [record.id], personalCategories: [.dna], measurements: [], context: context))
    }
    func testOnlyChosenRecordsRetainExactUnitsValuesAndExplicitProvenance() throws {
        var context = Prompt27AUserReproductiveContext()
        try context.setPersonalHealth(.thyroid, text: "my own reported context", provenance: .userReportsClinicianConfirmed)
        try context.setPersonalHealth(.dna, text: "must not share this unselected finding")
        let chosen = measurement()
        let snapshot = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [chosen.id], personalCategories: [.thyroid],
            measurements: [chosen, measurement()], context: context))
        XCTAssertEqual(snapshot.records.count, 2)
        let json = try snapshot.promptJSON()
        XCTAssertTrue(json.contains("12,50")); XCTAssertTrue(json.contains("µg/L"))
        XCTAssertTrue(json.contains("clinician_confirmation_reported_by_user_not_verified_by_fruitfolio"))
        XCTAssertFalse(json.contains("must not share"))
    }
    func testLargeContextFailsInsteadOfSilentlyClippingMedicalDetails() throws {
        var record = measurement(); record.notes = String(repeating: "x", count: 7000)
        XCTAssertThrowsError(try FruitfolioAskUserContext.selected(measurementIDs: [record.id], personalCategories: [],
            measurements: [record], context: .unspecified))
        XCTAssertEqual(record.notes.count, 7000)
    }
    @MainActor
    func testActualEngineKeepsUserContextOutsideEvidenceCitationsAndAnswerQuestion() async throws {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        let synthesis = Prompt1BContextCapturingSynthesis()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: .init(resourceURL: url), languageModel: synthesis)
        let record = measurement()
        let context = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [record.id], personalCategories: [],
            measurements: [record], context: .unspecified))
        let question = "how does progesterone affect temperature?"
        let answer = try await engine.answer(question: question, conversation: [], trackerContext: nil, userContext: context, progress: nil)
        let captured = await synthesis.captured
        let packet = try XCTUnwrap(captured)
        XCTAssertEqual(packet.userProvidedContext, context)
        XCTAssertEqual(packet.safetyClassification.level, .sensitive)
        XCTAssertEqual(answer.originalQuestion, question)
        XCTAssertFalse(answer.answerText.contains("private-marker-not-output"))
        XCTAssertFalse(answer.sources.contains { $0.id == record.id.uuidString })
        XCTAssertEqual(answer.answerPath, .retrievalFallback)
        let support = Prompt09SavedAnswerSupport(answer: answer)
        for metadata in [support, support.restricted(to: .excerpt)] {
            let encoded = String(decoding: try JSONEncoder().encode(metadata), as: UTF8.self)
            XCTAssertFalse(encoded.contains("private-marker-not-output"))
            XCTAssertFalse(encoded.contains(record.id.uuidString))
            XCTAssertFalse(encoded.contains("12,50"))
        }
        let prompt = FruitfolioEvidencePromptBuilder.selectionPrompt(question: question, evidence: packet)
        XCTAssertTrue(prompt.contains("UNTRUSTED DATA"))
        XCTAssertTrue(prompt.contains("12,50"))
        XCTAssertFalse(try FruitfolioEvidenceDecodingGrammar.make(evidence: packet).contains("private-marker-not-output"))
        let note = try XCTUnwrap(packet.researchNoteChunks.first)
        let invented = FruitfolioGeneratedDraft(bridge: nil, claims: [.init(text: record.notes, evidenceIDs: [note.chunkID])], limitation: nil)
        XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedText(draft: invented, evidence: packet))
    }

    #if canImport(llama)
    @MainActor
    func testActualNativeModelUsesSelectedContextWithoutEmittingItsPrivateDetails() async throws {
        let researchURL = try XCTUnwrap(ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
            ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        let modelURL = try XCTUnwrap(ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_MODEL_PATH"].map { URL(fileURLWithPath: $0) }
            ?? Bundle.main.url(forResource: "FruitfolioAI", withExtension: "gguf"))
        let record = measurement()
        let context = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [record.id], personalCategories: [],
            measurements: [record], context: .unspecified))
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: .init(resourceURL: researchURL),
            languageModel: LlamaFruitfolioLanguageModel(modelURL: modelURL))
        let question = "how does progesterone affect temperature?"
        let answer = try await engine.answer(question: question, conversation: [], trackerContext: nil, userContext: context, progress: nil)
        XCTAssertEqual(answer.answerPath, .generated)
        XCTAssertEqual(answer.originalQuestion, question)
        XCTAssertFalse(answer.answerText.contains("private-marker-not-output"))
        XCTAssertFalse(answer.sources.contains { $0.id == record.id.uuidString })
        XCTAssertFalse(answer.sourceIDs.isEmpty)
    }
    #endif

}

#if DEBUG
@MainActor
final class Prompt1BAskContextFixtureIsolationTests: XCTestCase {
    func testMissingPrivatePreferencesFailsWithoutCreatingAStore() async {
        let fixture = FruitfolioAskContextRegressionFixture(defaults: nil)
        XCTAssertNil(fixture.measurements)
        XCTAssertNotNil(fixture.failureMessage)
    }

    func testRemountLoadsExactExistingFixtureWithoutAppendingOrRewriting() async throws {
        let owner = FruitfolioRegressionPreferenceSuite()
        defer { owner.cleanUp() }
        let defaults = try XCTUnwrap(owner.defaults)
        let first = FruitfolioAskContextRegressionFixture(defaults: defaults)
        let original = try XCTUnwrap(first.measurements?.records.first)
        XCTAssertEqual(first.measurements?.records.count, 1)
        let bytes = try XCTUnwrap(defaults.data(forKey: FruitfolioAskContextRegressionFixture.storageKey))
        let second = FruitfolioAskContextRegressionFixture(defaults: defaults)
        XCTAssertNil(second.failureMessage)
        XCTAssertEqual(second.measurements?.records.count, 1)
        XCTAssertEqual(second.measurements?.records.first?.id, original.id)
        XCTAssertEqual(second.measurements?.records.first?.result, "12.50")
        XCTAssertEqual(second.measurements?.records.first?.unit, "ng/mL")
        XCTAssertEqual(defaults.data(forKey: FruitfolioAskContextRegressionFixture.storageKey), bytes)
    }

    func testDeletedFixtureRemainsDeletedAfterRemount() async throws {
        let owner = FruitfolioRegressionPreferenceSuite()
        defer { owner.cleanUp() }
        let defaults = try XCTUnwrap(owner.defaults)
        let first = FruitfolioAskContextRegressionFixture(defaults: defaults)
        let store = try XCTUnwrap(first.measurements)
        let id = try XCTUnwrap(store.records.first?.id)
        try store.delete(id: id)
        let bytes = try XCTUnwrap(defaults.data(forKey: FruitfolioAskContextRegressionFixture.storageKey))
        let remounted = FruitfolioAskContextRegressionFixture(defaults: defaults)
        XCTAssertNil(remounted.failureMessage)
        XCTAssertEqual(remounted.measurements?.records.count, 0)
        XCTAssertEqual(defaults.data(forKey: FruitfolioAskContextRegressionFixture.storageKey), bytes)
    }

    func testProtectedPrivateObjectsFailWithoutReplacement() async throws {
        let owner = FruitfolioRegressionPreferenceSuite()
        defer { owner.cleanUp() }
        let defaults = try XCTUnwrap(owner.defaults)
        let key = FruitfolioAskContextRegressionFixture.storageKey
        let seeded = FruitfolioAskContextRegressionFixture(defaults: defaults)
        XCTAssertNotNil(seeded.measurements)
        var future = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(defaults.data(forKey: key))) as? [[String: Any]])
        future[0]["futureField"] = NSNull()
        let futureData = try JSONSerialization.data(withJSONObject: future, options: .sortedKeys)
        for data in [futureData, Data("{\"futureSchema\":99,\"retain\":null}".utf8)] {
            defaults.set(data, forKey: key)
            let protected = FruitfolioAskContextRegressionFixture(defaults: defaults)
            XCTAssertNil(protected.measurements)
            XCTAssertNotNil(protected.failureMessage)
            XCTAssertEqual(defaults.data(forKey: key), data)
        }
        defaults.set("foreign non-data object", forKey: key)
        XCTAssertNil(FruitfolioAskContextRegressionFixture(defaults: defaults).measurements)
        XCTAssertEqual(defaults.string(forKey: key), "foreign non-data object")
    }
}
#endif
