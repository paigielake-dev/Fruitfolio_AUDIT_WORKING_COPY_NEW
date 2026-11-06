import XCTest
@testable import Fruitfolio

private final class Prompt1BLibraryWriteFaultDefaults: UserDefaults, @unchecked Sendable {
    enum Fault { case accept, drop, replace(Data), wrongType }
    var fault: Fault = .accept
    private(set) var attempts = 0
    override func set(_ value: Any?, forKey key: String) {
        guard key == "library" else { super.set(value, forKey: key); return }
        attempts += 1
        switch fault {
        case .accept: super.set(value, forKey: key)
        case .drop: break
        case .replace(let bytes): super.set(bytes, forKey: key)
        case .wrongType: super.set("external replacement", forKey: key)
        }
    }
}

@MainActor
final class Prompt1BLibraryPersistenceTests: XCTestCase {
    func testFailedEncodingPreservesCommittedSnapshotAndStoredBytes() async throws {
        let suite = "Prompt1BPersistence.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "library"
        var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: key)
        let original = Prompt10Encyclopedia(name: "original", style: .sage)
        try persistence.commit([original])
        let bytes = try XCTUnwrap(defaults.data(forKey: key))
        let invalid = Prompt10Encyclopedia(name: "invalid", style: .pink, createdAt: Date(timeIntervalSinceReferenceDate: .infinity))
        XCTAssertThrowsError(try persistence.commit([original, invalid]))
        XCTAssertEqual(persistence.committed, [original])
        XCTAssertEqual(defaults.data(forKey: key), bytes)
        XCTAssertEqual(Prompt10SavedLibraryPersistence(defaults: defaults, key: key).committed, [original])
    }
    func testUnreadableAndWrongTypeOriginalsCannotBeOverwritten() async throws {
        let suite = "Prompt1BCorruptLibrary.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let data = Data("unreadable original".utf8)
        defaults.set(data, forKey: "library")
        var corrupt = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
        XCTAssertTrue(corrupt.storageUnreadable)
        XCTAssertThrowsError(try corrupt.commit([])) { XCTAssertEqual($0 as? Prompt10LibraryError, .unreadableStorage) }
        XCTAssertEqual(defaults.data(forKey: "library"), data)
        defaults.set("wrong stored type", forKey: "other")
        var wrongType = Prompt10SavedLibraryPersistence(defaults: defaults, key: "other")
        XCTAssertTrue(wrongType.storageUnreadable)
        XCTAssertThrowsError(try wrongType.commit([]))
        XCTAssertEqual(defaults.string(forKey: "other"), "wrong stored type")
    }
    func testDroppedFirstWriteCannotAdvanceCommittedSnapshot() async throws {
        let suite = "Fruitfolio.library-first-drop." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
        defaults.fault = .drop
        XCTAssertThrowsError(try persistence.commit([.init(name: "QA first", style: .sage)]))
        XCTAssertEqual(persistence.committed, [])
        XCTAssertNil(defaults.object(forKey: "library"))
        XCTAssertEqual(persistence.protectionReason, .persistenceFailure)
    }
    func testDroppedReplacementBlocksUntilReloadWithoutLosingLastAcknowledgment() async throws {
        let suite = "Fruitfolio.library-replace-drop." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
        let original = Prompt10Encyclopedia(name: "QA original", style: .sage)
        let next = Prompt10Encyclopedia(name: "QA next", style: .pink)
        try persistence.commit([original])
        let bytes = try XCTUnwrap(defaults.data(forKey: "library"))
        defaults.fault = .drop
        XCTAssertThrowsError(try persistence.commit([next]))
        XCTAssertEqual(persistence.committed, [original])
        XCTAssertEqual(defaults.data(forKey: "library"), bytes)
        XCTAssertEqual(persistence.protectionReason, .persistenceFailure)
        defaults.fault = .accept
        let attempts = defaults.attempts
        XCTAssertThrowsError(try persistence.commit([next])) { XCTAssertEqual($0 as? Prompt10LibraryError, .persistenceFailure) }
        XCTAssertEqual(defaults.attempts, attempts)
        persistence.reload()
        XCTAssertNil(persistence.protectionReason)
        XCTAssertEqual(persistence.committed, [original])
        try persistence.commit([next])
        XCTAssertEqual(Prompt10SavedLibraryPersistence(defaults: defaults, key: "library").committed, [next])
    }
    func testPostWriteForeignDataOrWrongTypeIsNeverRolledBack() async throws {
        for wrongType in [false, true] {
            let suite = "Fruitfolio.library-substitute." + UUID().uuidString
            let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
            let original = Prompt10Encyclopedia(name: "QA original", style: .sage)
            try persistence.commit([original])
            let foreign = try JSONEncoder().encode([Prompt10Encyclopedia(name: "QA external", style: .pink)])
            defaults.fault = wrongType ? .wrongType : .replace(foreign)
            XCTAssertThrowsError(try persistence.commit([]))
            XCTAssertEqual(persistence.committed, [original])
            XCTAssertEqual(persistence.protectionReason, .persistenceFailure)
            XCTAssertEqual(defaults.attempts, 2, "No rollback may overwrite an observed replacement")
            if wrongType { XCTAssertEqual(defaults.string(forKey: "library"), "external replacement") }
            else { XCTAssertEqual(defaults.data(forKey: "library"), foreign) }
        }
    }
    func testRealStoreRejectsDroppedGuideDescriptionAndCreationWithoutFalseMemorySuccess() async throws {
        let suite = "Fruitfolio.library-store-drop." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let original = try store.createGuideEncyclopedia(name: "QA guide", subtitle: "original", style: .sage)
        let bytes = try XCTUnwrap(defaults.data(forKey: "library"))
        defaults.fault = .drop
        XCTAssertThrowsError(try store.updateEncyclopediaDescription(id: original.id, description: "unacknowledged draft"))
        XCTAssertEqual(store.encyclopedia(id: original.id), original)
        XCTAssertEqual(store.storageProtectionReason, .persistenceFailure)
        XCTAssertEqual(defaults.data(forKey: "library"), bytes)
        store.reloadSavedLibrary()
        XCTAssertNil(store.storageProtectionReason)
        XCTAssertThrowsError(try store.createGuideEncyclopedia(name: "unacknowledged guide", subtitle: "draft", style: .pink))
        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(store.storageProtectionReason, .persistenceFailure)
        XCTAssertEqual(defaults.data(forKey: "library"), bytes)
    }

    private func batchFixture() throws -> (String, Prompt1BLibraryWriteFaultDefaults, Prompt10SavedLibraryStore, UUID, UUID, [Prompt10SavedPage]) {
        let suite = "Fruitfolio.guide-batch." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let source = try store.createEncyclopedia(name: "QA source", style: .sage)
        let sourceChapter = try XCTUnwrap(source.chapters.first)
        let pages = try (0..<2).map { index in
            try store.savePage(Prompt10SavedPage(chapterID: sourceChapter.id,
                question: "QA question \(index)", answer: "QA answer \(index)", saveType: .excerpt,
                excerptText: "QA excerpt \(index)", originalAnswerID: "answer-\(index)",
                originalConversationID: "conversation-\(index)", sourceIDs: ["source-\(index)"],
                sourceVersions: ["source-\(index)": "v1"], knowledgeBaseVersion: "qa-v1",
                generationTimestamp: Date(timeIntervalSince1970: 100), notes: "private source note",
                importedImageIDs: ["qa-image-\(index)"],
                excerptSemanticSpans: [.init(text: "QA excerpt \(index)", emphasis: .anchorBold)], excerptSelectionLocation: 0,
                excerptSelectionLength: 10, excerptLanguage: "en",
                sourceRecords: [.init(id: "source-\(index)", title: "QA source", doi: "10.1000/fixture")],
                educationalAssetIDs: [.ovarian_cycle_follicle_development_stages],
                userMaterial: index == 1 ? .init(sourceURL: "https://example.com/qa", addedAt: Date(timeIntervalSince1970: 10), editedAt: Date(timeIntervalSince1970: 20)) : nil),
                to: source.id, chapterID: sourceChapter.id)
        }
        let guide = try store.createGuideEncyclopedia(name: "QA guide", subtitle: "QA description", style: .pink)
        let section = try store.createChapter(in: guide.id, name: "QA destination")
        return (suite, defaults, store, guide.id, section.id, pages)
    }

    func testGuideBatchAcknowledgesOneWriteAndPreservesSourceFields() async throws {
        let (suite, defaults, store, guide, chapter, pages) = try batchFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let sourceSnapshot = store.encyclopedias.filter { $0.id != guide }
        let attempts = defaults.attempts
        let added = try store.prompt11AddSavedMaterials(pages, to: guide, chapterID: chapter)
        XCTAssertEqual(defaults.attempts, attempts + 1)
        XCTAssertEqual(added.count, 2)
        XCTAssertEqual(added.map(\.order), [0, 1])
        for (reference, source) in zip(added, pages) {
            var expected = source
            // Only identity, placement, timestamps, reference and ordinary private notes change.
            expected = Prompt10SavedPage(id: reference.id, chapterID: chapter,
                question: source.question, answer: source.answer, saveType: source.saveType,
                excerptText: source.excerptText, originalAnswerID: source.originalAnswerID,
                originalConversationID: source.originalConversationID, sourceIDs: source.sourceIDs,
                sourceVersions: source.sourceVersions, knowledgeBaseVersion: source.knowledgeBaseVersion,
                generationTimestamp: source.generationTimestamp, savedAt: reference.savedAt,
                updatedAt: reference.updatedAt, notes: source.userMaterial == nil ? "" : source.notes, order: reference.order,
                sourceSavedPageID: source.id, importedImageIDs: source.importedImageIDs,
                excerptSemanticSpans: source.excerptSemanticSpans,
                excerptSelectionLocation: source.excerptSelectionLocation,
                excerptSelectionLength: source.excerptSelectionLength, excerptLanguage: source.excerptLanguage,
                sourceRecords: source.sourceRecords, educationalAssetIDs: source.educationalAssetIDs,
                userMaterial: source.userMaterial)
            XCTAssertEqual(reference, expected)
        }
        let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        XCTAssertEqual(reloaded.encyclopedia(id: guide)?.chapters.first?.pages, added)
        XCTAssertEqual(reloaded.encyclopedias.filter { $0.id != guide }, sourceSnapshot)
    }

    func testGuideBatchDroppedWriteLeavesNoPartialSelection() async throws {
        let (suite, defaults, store, guide, chapter, pages) = try batchFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let before = store.encyclopedias
        let bytes = defaults.data(forKey: "library")
        let attempts = defaults.attempts
        defaults.fault = .drop
        XCTAssertThrowsError(try store.prompt11AddSavedMaterials(pages, to: guide, chapterID: chapter))
        XCTAssertEqual(defaults.attempts, attempts + 1)
        XCTAssertEqual(store.encyclopedias, before)
        XCTAssertEqual(defaults.data(forKey: "library"), bytes)
        XCTAssertEqual(store.storageProtectionReason, .persistenceFailure)
        XCTAssertEqual(Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library").encyclopedias, before)
    }

    func testGuideBatchDeduplicatesAcrossChaptersAndDoesNotWriteEmptySelection() async throws {
        let (suite, defaults, store, guide, chapter, pages) = try batchFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let second = try store.createChapter(in: guide, name: "QA second")
        let original = try store.prompt11AddSavedMaterial(pages[0], to: guide, chapterID: chapter)
        let attempts = defaults.attempts
        XCTAssertEqual(try store.prompt11AddSavedMaterials([], to: guide, chapterID: second.id), [])
        XCTAssertEqual(try store.prompt11AddSavedMaterials([pages[0], pages[0]], to: guide, chapterID: second.id), [])
        XCTAssertEqual(defaults.attempts, attempts)
        let added = try store.prompt11AddSavedMaterials([pages[0], pages[1], pages[1]], to: guide, chapterID: second.id)
        XCTAssertEqual(added.count, 1)
        XCTAssertEqual(added.first?.sourceSavedPageID, pages[1].id)
        XCTAssertEqual(defaults.attempts, attempts + 1)
        XCTAssertEqual(try store.prompt11AddSavedMaterial(pages[0], to: guide, chapterID: second.id), original)
        XCTAssertEqual(store.encyclopedia(id: guide)?.savedPageCount, 2)
    }

    func testGuideBatchInvalidDestinationCannotMutateOrWrite() async throws {
        let (suite, defaults, store, guide, chapter, pages) = try batchFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let before = store.encyclopedias
        let attempts = defaults.attempts
        XCTAssertThrowsError(try store.prompt11AddSavedMaterials(pages, to: guide, chapterID: UUID()))
        XCTAssertThrowsError(try store.prompt11AddSavedMaterials(pages, to: UUID(), chapterID: chapter))
        XCTAssertEqual(defaults.attempts, attempts)
        XCTAssertEqual(store.encyclopedias, before)
    }

    func testGuideBatchPreservesPreAndPostWriteExternalReplacement() async throws {
        for postWrite in [false, true] {
            let (suite, defaults, store, guide, chapter, pages) = try batchFixture()
            defer { defaults.removePersistentDomain(forName: suite) }
            let before = store.encyclopedias
            let foreign = Data("{\"futureSchema\":3,\"preserve\":null}".utf8)
            if postWrite { defaults.fault = .replace(foreign) }
            else { defaults.set(foreign, forKey: "library") }
            let attempts = defaults.attempts
            XCTAssertThrowsError(try store.prompt11AddSavedMaterials(pages, to: guide, chapterID: chapter))
            XCTAssertEqual(defaults.attempts, attempts + (postWrite ? 1 : 0))
            XCTAssertEqual(defaults.data(forKey: "library"), foreign)
            XCTAssertEqual(store.encyclopedias, before)
            XCTAssertNotNil(store.storageProtectionReason)
        }
    }

    func testGuideKeySelectionResolvesWholeCatalogAndRejectsMissingSourceWithoutSubsetWrite() async throws {
        let (suite, defaults, store, guide, chapter, pages) = try batchFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let before = store.encyclopedias
        let attempts = defaults.attempts
        XCTAssertThrowsError(try store.prompt11AddSavedMaterialSelection(
            sourceKeys: [pages[0].id, UUID()], to: guide, chapterID: chapter)) {
            XCTAssertEqual($0 as? Prompt10LibraryError, .contentChanged)
        }
        XCTAssertEqual(defaults.attempts, attempts)
        XCTAssertEqual(store.encyclopedias, before)
        let added = try store.prompt11AddSavedMaterialSelection(
            sourceKeys: Set(pages.map(\.id)), to: guide, chapterID: chapter)
        XCTAssertEqual(Set(added.compactMap(\.sourceSavedPageID)), Set(pages.map(\.id)))
        XCTAssertEqual(defaults.attempts, attempts + 1)
    }

}
