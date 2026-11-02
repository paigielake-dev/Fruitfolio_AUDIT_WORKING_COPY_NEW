import XCTest
@testable import Fruitfolio

/// Synthetic nonmedical answer for a real in-memory Ask session; this test
/// verifies export privacy, not native inference or scientific grounding.
private struct PersonalExportSessionFixtureEngine: AskKnowledgeServing {
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        AskAnswer(originalQuestion: question, answerText: "PRIVATE_UNSAVED_ASK_ANSWER_FIXTURE",
            support: .supported, knowledgeBaseVersion: "synthetic-export-privacy-fixture")
    }
}

@MainActor
final class PersonalDataExportTests: XCTestCase {
    func testActualDomainSnapshotsKeepExactMedicalTextAndOriginalSavedSourceReferencesWithoutMutatingStores() async throws {
        let suite = "Fruitfolio.Export.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("must never be exported", forKey: "unrelated.credential.fixture")
        // A deterministic fractional-reference timestamp exercises real
        // record fidelity rather than hiding precision loss with whole seconds.
        let fixed = Date(timeIntervalSinceReferenceDate: 799_999_999.1234568)
        let bookID = UUID(); let chapterID = UUID()
        let reference = AskSourceRecord(id: "synthetic-reference", title: "Synthetic fixture", sourceText: "Exact synthetic APA reference.", contentVersion: "v1")
        let page = Prompt10SavedPage(chapterID: chapterID, question: "My saved question", answer: "Original quoted words, 2.500 ng/mL [synthetic-reference].", saveType: .fullAnswer,
            sourceIDs: [reference.id], sourceVersions: [reference.id: "v1"], sourceSnapshots: [reference], knowledgeBaseVersion: "fixture-v1", savedAt: fixed, updatedAt: fixed)
        let chapter = Prompt10Chapter(id: chapterID, encyclopediaID: bookID, name: "saved", order: 0, pages: [page])
        let book = Prompt10Encyclopedia(id: bookID, name: "My own material", style: .coral,
            createdAt: fixed, updatedAt: fixed, chapters: [chapter])
        defaults.set(try JSONEncoder().encode([book]), forKey: "library")
        let library = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let context = Prompt27AContextStore(defaults: defaults)
        context.setPersonalHealthField(.thyroid, text: "my exact reported history; not a confirmed diagnosis")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let hormones = HormoneMeasurementStore(fileURL: directory.appendingPathComponent("hormones.json"))
        var measurement = HormoneMeasurement(); measurement.result = "2.500"; measurement.unit = "ng/mL"
        measurement.testDateWasProvided = true; measurement.notes = "my exact original note"
        try hormones.save(measurement)
        let settings = SettingsStore(defaults: defaults); settings.musicVolume = 0.23
        let cycle = Prompt13CycleStore.inMemory()
        let onboarding = Prompt14CycleOnboardingStore.inMemory(cycleStore: cycle)
        let originalBooks = library.encyclopedias; let originalContext = context.context
        let originalHormones = hormones.measurements
        let ask = Prompt09AskViewModel(engine: PersonalExportSessionFixtureEngine())
        ask.inputText = "PRIVATE_UNSAVED_ASK_QUESTION_FIXTURE"
        await ask.submitCurrentQuestion(reduceMotion: true)
        XCTAssertFalse(ask.sessionAnswers.isEmpty)
        let originalSession = ask.messages
        let game = Prompt28FruitBasketStore(defaults: defaults)
        var progress = game.ensureProgress(for: "nutrition")
        progress.totalFruitCaught = 37; progress.totalStarsEarned = 12
        progress.totalRoundsCompleted = 3; progress.currentGameLevel = 2
        game.updateProgress(progress)
        game.recordQuestion("exact-original-evidence-question", topic: "nutrition")
        let originalGameBytes = defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1")
        let originalGame = game.topicProgress
        let originalHistory = game.questionHistory
        let bytes = try await FruitfolioPersonalDataExport.capture(account: nil, username: "peach_qa", settings: settings,
            library: library, context: context, hormones: hormones, cycle: cycle, onboarding: onboarding,
            fruitBasket: game, now: fixed)
        // Exercise the same regular FileWrapper supplied to the system exporter,
        // writing and reopening an actual JSON file, then inspect real domains.
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("FruitfolioActualExport-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: destination) }
        let document = FruitfolioPersonalDataDocument(data: bytes)
        try document.makeFileWrapper().write(to: destination, options: .atomic, originalContentsURL: nil)
        try FruitfolioPersonalDataDocument.verifySavedFile(at: destination, expected: bytes)
        let savedBytes = try Data(contentsOf: destination)
        XCTAssertEqual(savedBytes, bytes, "Actual written file must retain all prepared bytes")
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: savedBytes))
        let exported = try FruitfolioPersonalDataExport.decodeDocument(savedBytes)
        XCTAssertEqual(exported.schemaVersion, 2)
        XCTAssertTrue(try XCTUnwrap(exported.dateRepresentation).contains("2001-01-01"))
        let evidence = XCTAttachment(data: savedBytes, uniformTypeIdentifier: "public.json")
        evidence.name = "ActualReopenedPersonalDataExport_SyntheticFixture"
        evidence.lifetime = .keepAlways; add(evidence)
        XCTAssertEqual(exported.createdAt, fixed)
        XCTAssertEqual(exported.encyclopediasAndGuides, originalBooks)
        XCTAssertEqual(exported.encyclopediasAndGuides.first?.chapters.first?.pages.first?.sourceSnapshots, [reference])
        XCTAssertEqual(exported.reportedContext.personalHealthFields[.thyroid]?.text, originalContext.personalHealthFields[.thyroid]?.text)
        XCTAssertEqual(exported.hormoneMeasurements.first?.result, "2.500")
        XCTAssertEqual(exported.hormoneMeasurements.first?.unit, "ng/mL")
        XCTAssertEqual(exported.hormoneMeasurements.first?.notes, "my exact original note")
        XCTAssertEqual(exported.hormoneMeasurements, originalHormones, "Reopened exports must preserve whole original records, including dates and timestamps")
        XCTAssertEqual(exported.reportedContext, originalContext)
        XCTAssertEqual(exported.fruitBasketProgress, originalGame)
        // Existing schema1 files remain readable. Their already converted date
        // values cannot recover old discarded bits; do not claim otherwise.
        let legacyEncoder = JSONEncoder(); legacyEncoder.dateEncodingStrategy = .millisecondsSince1970
        var legacyObject = try XCTUnwrap(JSONSerialization.jsonObject(with: legacyEncoder.encode(exported)) as? [String: Any])
        legacyObject["schemaVersion"] = 1; legacyObject.removeValue(forKey: "dateRepresentation")
        let legacyBytes = try JSONSerialization.data(withJSONObject: legacyObject)
        let legacy = try FruitfolioPersonalDataExport.decodeDocument(legacyBytes)
        XCTAssertEqual(legacy.schemaVersion, 1)
        XCTAssertNil(legacy.dateRepresentation)
        XCTAssertEqual(legacy.publicUsername, exported.publicUsername)
        XCTAssertEqual(legacy.encyclopediasAndGuides.first?.chapters.first?.pages.first?.sourceSnapshots,
                       exported.encyclopediasAndGuides.first?.chapters.first?.pages.first?.sourceSnapshots)
        var unknownObject = legacyObject; unknownObject["schemaVersion"] = 999
        XCTAssertThrowsError(try FruitfolioPersonalDataExport.decodeDocument(JSONSerialization.data(withJSONObject: unknownObject)))
        XCTAssertEqual(exported.settings.musicVolume, 0.23)
        XCTAssertEqual(exported.publicUsername, "peach_qa")
        let exportedGame = try XCTUnwrap(exported.fruitBasketProgress["nutrition"])
        XCTAssertEqual(exportedGame.totalFruitCaught, 37)
        XCTAssertEqual(exportedGame.totalStarsEarned, 12)
        XCTAssertEqual(exportedGame.totalRoundsCompleted, 3)
        XCTAssertEqual(exportedGame.currentGameLevel, 2)
        XCTAssertEqual(exportedGame.lastPlayedAt.timeIntervalSince1970,
            try XCTUnwrap(originalGame["nutrition"]).lastPlayedAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(exported.fruitBasketQuestionHistory["nutrition"], ["exact-original-evidence-question"])
        XCTAssertEqual(game.topicProgress, originalGame)
        XCTAssertEqual(game.questionHistory, originalHistory)
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"), originalGameBytes)
        XCTAssertTrue(exported.limitations.contains { $0.contains("not a complete media backup") })
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains("must never be exported"))
        XCTAssertFalse(String(decoding: savedBytes, as: UTF8.self).contains("PRIVATE_UNSAVED_ASK_QUESTION_FIXTURE"))
        XCTAssertFalse(String(decoding: savedBytes, as: UTF8.self).contains("PRIVATE_UNSAVED_ASK_ANSWER_FIXTURE"))
        XCTAssertEqual(ask.messages, originalSession, "Export must neither persist nor clear the active unsaved Ask visit")
        XCTAssertFalse(ask.sessionAnswers.isEmpty)
        XCTAssertEqual(library.encyclopedias, originalBooks)
        XCTAssertEqual(context.context, originalContext)
        XCTAssertEqual(hormones.measurements, originalHormones)
    }

    func testUnreadableGameStorageBlocksMisleadingExportAndCannotBeOverwrittenByGameActions() async throws {
        let suite = "Fruitfolio.GameExportCorruption.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "fruitfolio.prompt28.fruitBasket.v1"
        let original = Data([0xff, 0x00, 0x7f])
        defaults.set(original, forKey: key)
        let game = Prompt28FruitBasketStore(defaults: defaults)
        XCTAssertNotNil(game.loadError)
        game.recordQuestion("must-not-replace-corrupt-history", topic: "nutrition")
        game.completeTour()
        _ = game.ensureProgress(for: "nutrition")
        XCTAssertEqual(defaults.data(forKey: key), original)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("empty-hormones-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        do {
            _ = try await FruitfolioPersonalDataExport.capture(account: nil, username: "test_pear",
                settings: SettingsStore(defaults: defaults), library: Prompt10SavedLibraryStore(defaults: defaults),
                context: Prompt27AContextStore(defaults: defaults), hormones: HormoneMeasurementStore(fileURL: file),
                cycle: .inMemory(), onboarding: .inMemory(cycleStore: .inMemory()), fruitBasket: game)
            XCTFail("Unreadable game progress must not be represented as a successful empty export")
        } catch { XCTAssertEqual(error as? Prompt12AccountPrivacyError, .exportFailed) }
        XCTAssertEqual(defaults.data(forKey: key), original)
        let model = Prompt28FruitBasketViewModel(store: game, researchProvider: Prompt28CanonicalResearchProvider())
        model.openSetup(); XCTAssertEqual(model.screen, .error)
        XCTAssertEqual(model.message, game.loadError)
    }

    func testUnreadableHealthStoragePreventsASuccessfulPartialExportAndPreservesOriginalBytes() async throws {
        let suite = "Fruitfolio.ExportCorrupt.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        let original = Data([0xff, 0x00, 0x7f]); try original.write(to: file); defer { try? FileManager.default.removeItem(at: file) }
        let hormones = HormoneMeasurementStore(fileURL: file)
        XCTAssertNotNil(hormones.loadError)
        do {
            _ = try await FruitfolioPersonalDataExport.capture(account: nil, username: "", settings: SettingsStore(defaults: defaults),
                library: Prompt10SavedLibraryStore(defaults: defaults), context: Prompt27AContextStore(defaults: defaults), hormones: hormones,
                cycle: .inMemory(), onboarding: .inMemory(), fruitBasket: Prompt28FruitBasketStore(defaults: defaults))
            XCTFail("An incomplete unreadable domain must not be reported as a successful export")
        } catch { XCTAssertEqual(try Data(contentsOf: file), original) }
    }

    func testReadBackRejectsChangedUnreadableOrInvalidJSONWithoutModifyingTheFile() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let bytes = Data("{\"recordedValue\":\"2.500 ng/mL\"}".utf8)
        try bytes.write(to: file)
        XCTAssertThrowsError(try FruitfolioPersonalDataDocument.verifySavedFile(at: file, expected: Data("{}".utf8)))
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let invalid = Data("not JSON".utf8); try invalid.write(to: file)
        XCTAssertThrowsError(try FruitfolioPersonalDataDocument.verifySavedFile(at: file, expected: invalid))
        XCTAssertEqual(try Data(contentsOf: file), invalid)
        try FileManager.default.removeItem(at: file)
        XCTAssertThrowsError(try FruitfolioPersonalDataDocument.verifySavedFile(at: file, expected: bytes))
    }

    func testReadableDocumentRetainsTheExactPreparedBytesAndJSONContentType() throws {
        let data = Data("{\"sensitive_fixture\":\"original\"}".utf8)
        let document = FruitfolioPersonalDataDocument(data: data)
        XCTAssertEqual(document.data, data)
        XCTAssertEqual(FruitfolioPersonalDataDocument.readableContentTypes.map(\.identifier), ["public.json"])
    }
}
