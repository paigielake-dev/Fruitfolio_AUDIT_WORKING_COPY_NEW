import XCTest
@testable import Fruitfolio

@MainActor
final class PersonalDataExportTests: XCTestCase {
    func testActualDomainSnapshotsKeepExactMedicalTextAndOriginalSavedSourceReferencesWithoutMutatingStores() async throws {
        let suite = "Fruitfolio.Export.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("must never be exported", forKey: "unrelated.credential.fixture")
        let library = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let book = try library.createEncyclopedia(name: "My own material", style: .coral)
        let chapter = try XCTUnwrap(book.chapters.first)
        let reference = AskSourceRecord(id: "synthetic-reference", title: "Synthetic fixture", sourceText: "Exact synthetic APA reference.", contentVersion: "v1")
        let page = Prompt10SavedPage(chapterID: chapter.id, question: "My saved question", answer: "Original quoted words, 2.500 ng/mL [synthetic-reference].", saveType: .fullAnswer,
            sourceIDs: [reference.id], sourceVersions: [reference.id: "v1"], sourceSnapshots: [reference], knowledgeBaseVersion: "fixture-v1")
        _ = try library.savePage(page, to: book.id, chapterID: chapter.id)
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
        let bytes = try await FruitfolioPersonalDataExport.capture(account: nil, username: "peach_qa", settings: settings,
            library: library, context: context, hormones: hormones, cycle: cycle, onboarding: onboarding,
            fruitBasket: Prompt28FruitBasketStore(defaults: defaults), now: Date(timeIntervalSince1970: 1_700_000_000))
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .millisecondsSince1970
        let exported = try decoder.decode(FruitfolioPersonalDataExport.self, from: bytes)
        XCTAssertEqual(exported.encyclopediasAndGuides, originalBooks)
        XCTAssertEqual(exported.encyclopediasAndGuides.first?.chapters.first?.pages.first?.sourceSnapshots, [reference])
        XCTAssertEqual(exported.reportedContext.personalHealthFields[.thyroid]?.text, originalContext.personalHealthFields[.thyroid]?.text)
        XCTAssertEqual(exported.hormoneMeasurements.first?.result, "2.500")
        XCTAssertEqual(exported.hormoneMeasurements.first?.unit, "ng/mL")
        XCTAssertEqual(exported.hormoneMeasurements.first?.notes, "my exact original note")
        XCTAssertEqual(exported.settings.musicVolume, 0.23)
        XCTAssertEqual(exported.publicUsername, "peach_qa")
        XCTAssertTrue(exported.limitations.contains { $0.contains("not a complete media backup") })
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains("must never be exported"))
        XCTAssertEqual(library.encyclopedias, originalBooks)
        XCTAssertEqual(context.context, originalContext)
        XCTAssertEqual(hormones.measurements, originalHormones)
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

    func testReadableDocumentRetainsTheExactPreparedBytesWithoutWritingAnAutomaticTemporaryFile() throws {
        let data = Data("{\"sensitive_fixture\":\"original\"}".utf8)
        let document = FruitfolioPersonalDataDocument(data: data)
        XCTAssertEqual(document.data, data)
        XCTAssertEqual(FruitfolioPersonalDataDocument.readableContentTypes.map(\.identifier), ["public.json"])
    }
}
