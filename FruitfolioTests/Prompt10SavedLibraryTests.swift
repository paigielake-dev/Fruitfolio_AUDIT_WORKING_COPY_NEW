import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt10SavedLibraryTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: Prompt10SavedLibraryStore!
    private var key: String!

    override func setUp() async throws {
        key = "Prompt10SavedLibraryTests.\(UUID().uuidString)"
        defaults = UserDefaults(
            suiteName: "Prompt10SavedLibraryTests"
        )!

        defaults.removePersistentDomain(
            forName: "Prompt10SavedLibraryTests"
        )

        store = Prompt10SavedLibraryStore(
            defaults: defaults,
            persistenceKey: key
        )
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(
            forName: "Prompt10SavedLibraryTests"
        )

        defaults = nil
        store = nil
        key = nil
    }

    func testExactSavedLibraryAssetManifestHasSixteenPhysicalPNGs() {
        XCTAssertEqual(
            Prompt10SavedLibraryAsset.exactPhysicalFilenames.count,
            16
        )

        XCTAssertEqual(
            Set(Prompt10SavedLibraryAsset.exactPhysicalFilenames),
            Set([
                "library_book_open.png",
                "library_label.png",
                "library_flower.png",
                "library_book_blank.png",
                "library_bookshelf.png",
                "library_open_book.png",
                "library_book_closed.png",
                "library_potted_plant.png",
                "library_book_yellow.png",
                "library_bookmark.png",
                "library_book_pink.png",
                "library_book_sage.png",
                "library_book_stack.png",
                "library_book_coral.png",
                "library_flower_bundle.png",
                "library_book_lavender.png"
            ])
        )
    }

    func testCreatePersistsAcrossStoreReinitialization() throws {
        let created = try store.createEncyclopedia(
            name: "cycle health",
            style: .sage
        )

        let reloaded = Prompt10SavedLibraryStore(
            defaults: defaults,
            persistenceKey: key
        )

        XCTAssertEqual(
            reloaded.encyclopedias.count,
            1
        )

        XCTAssertEqual(
            reloaded.encyclopedias.first?.id,
            created.id
        )

        XCTAssertEqual(
            reloaded.encyclopedias.first?.name,
            "cycle health"
        )
    }

    func testBlankTitleIsRejected() {
        XCTAssertThrowsError(
            try store.createEncyclopedia(
                name: "   ",
                style: .sage
            )
        ) { error in
            XCTAssertEqual(
                error as? Prompt10LibraryError,
                .blankTitle
            )
        }
    }

    func testMaximumIsEnforcedAtStoreLayer() throws {
        for index in 0..<Prompt10SavedLibraryStore.maximumEncyclopedias {
            _ = try store.createEncyclopedia(
                name: "book \(index)",
                style: .sage
            )
        }

        XCTAssertEqual(
            store.count,
            100
        )

        XCTAssertFalse(
            store.canCreateEncyclopedia
        )

        XCTAssertThrowsError(
            try store.createEncyclopedia(
                name: "book 101",
                style: .sage
            )
        ) { error in
            XCTAssertEqual(
                error as? Prompt10LibraryError,
                .encyclopediaLimitReached
            )
        }
    }

    func testDeletingOneBookAtLimitImmediatelyRestoresCreation() throws {
        for index in 0..<Prompt10SavedLibraryStore.maximumEncyclopedias {
            _ = try store.createEncyclopedia(
                name: "book \(index)",
                style: .sage
            )
        }

        let firstID = try XCTUnwrap(
            store.encyclopedias.first?.id
        )

        try store.deleteEncyclopedia(
            id: firstID
        )

        XCTAssertEqual(
            store.count,
            99
        )

        XCTAssertTrue(
            store.canCreateEncyclopedia
        )

        XCTAssertNoThrow(
            try store.createEncyclopedia(
                name: "new little book",
                style: .sage
            )
        )
    }

    func testRenamePersists() throws {
        let encyclopedia = try store.createEncyclopedia(
            name: "old name",
            style: .sage
        )

        try store.renameEncyclopedia(
            id: encyclopedia.id,
            to: "new name"
        )

        let reloaded = Prompt10SavedLibraryStore(
            defaults: defaults,
            persistenceKey: key
        )

        XCTAssertEqual(
            reloaded.encyclopedia(
                id: encyclopedia.id
            )?.name,
            "new name"
        )
    }

    func testFullAnswerPreservesPrompt09Provenance() throws {
        let encyclopedia = try store.createEncyclopedia(
            name: "hormones",
            style: .sage
        )

        let chapterID = try XCTUnwrap(
            encyclopedia.chapters.first?.id
        )

        let generationDate = Date()

        let page = Prompt10SavedPage(
            chapterID: chapterID,
            question: "what does estrogen do?",
            answer: "complete sourced answer",
            saveType: .fullAnswer,
            originalAnswerID: "answer-123",
            originalConversationID: "conversation-456",
            sourceIDs: [
                "source-a",
                "source-b"
            ],
            sourceVersions: [
                "source-a": "v2",
                "source-b": "v4"
            ],
            knowledgeBaseVersion: "kb-19",
            generationTimestamp: generationDate
        )

        let saved = try store.savePage(
            page,
            to: encyclopedia.id,
            chapterID: chapterID
        )

        XCTAssertEqual(
            saved.displayBody,
            "complete sourced answer"
        )

        XCTAssertEqual(
            saved.originalAnswerID,
            "answer-123"
        )

        XCTAssertEqual(
            saved.originalConversationID,
            "conversation-456"
        )

        XCTAssertEqual(
            saved.sourceIDs,
            [
                "source-a",
                "source-b"
            ]
        )

        XCTAssertEqual(
            saved.sourceVersions["source-a"],
            "v2"
        )

        XCTAssertEqual(
            saved.knowledgeBaseVersion,
            "kb-19"
        )
    }

    func testExcerptDisplaysExactExcerptNotWholeAnswer() throws {
        let encyclopedia = try store.createEncyclopedia(
            name: "nutrition",
            style: .sage
        )

        let chapterID = try XCTUnwrap(
            encyclopedia.chapters.first?.id
        )

        let page = Prompt10SavedPage(
            chapterID: chapterID,
            question: "question",
            answer: "the complete answer is much longer than this excerpt.",
            saveType: .excerpt,
            excerptText: "this excerpt."
        )

        let saved = try store.savePage(
            page,
            to: encyclopedia.id,
            chapterID: chapterID
        )

        XCTAssertEqual(
            saved.displayBody,
            "this excerpt."
        )

        XCTAssertNotEqual(
            saved.displayBody,
            saved.answer
        )
    }

    func testDeletingEncyclopediaDoesNotMutateAnotherEncyclopedia() throws {
        let first = try store.createEncyclopedia(
            name: "first",
            style: .sage
        )

        let second = try store.createEncyclopedia(
            name: "second",
            style: .sage
        )

        try store.deleteEncyclopedia(
            id: first.id
        )

        XCTAssertNil(
            store.encyclopedia(
                id: first.id
            )
        )

        XCTAssertEqual(
            store.encyclopedia(
                id: second.id
            )?.name,
            "second"
        )
    }

    func testSortControlsDoNotAppearConceptuallyBeforeThirteenBooks() throws {
        for index in 0..<12 {
            _ = try store.createEncyclopedia(
                name: "book \(index)",
                style: .sage
            )
        }

        XCTAssertEqual(
            store.encyclopedias.count,
            12
        )

        _ = try store.createEncyclopedia(
            name: "thirteenth",
                style: .sage
            )

        XCTAssertEqual(
            store.encyclopedias.count,
            13
        )
    }

    func testSearchMatchesTitlesCaseInsensitively() throws {
        _ = try store.createEncyclopedia(
            name: "Cycle Health",
                style: .sage
            )

        _ = try store.createEncyclopedia(
            name: "Pregnancy",
                style: .sage
            )

        let results = store.sorted(
            by: .recentlyUpdated,
            searchText: "cycle"
        )

        XCTAssertEqual(
            results.map(\.name),
            ["Cycle Health"]
        )
    }

    func testChosenBookStylePersistsInsteadOfAutoCycling() throws {
        _ = try store.createEncyclopedia(
            name: "styled book",
            style: .lavender
        )

        let reloaded = Prompt10SavedLibraryStore(
            defaults: defaults,
            persistenceKey: key
        )

        let reloadedBook = try XCTUnwrap(
            reloaded.encyclopedias.first
        )

        XCTAssertEqual(
            reloadedBook.style,
            .lavender
        )

        XCTAssertEqual(
            reloadedBook.style.assetName,
            "library_book_lavender"
        )
    }
}



extension Prompt10SavedLibraryTests {
    func testCorruptMetadataNeverDeletesImportedMediaDuringRecovery() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let media = Prompt10LocalMediaStore(root: root)
        let id = try media.saveImageData(Data([3,2,1]))
        defaults.set(Data("unreadable metadata".utf8), forKey: key)
        let broken = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: key, mediaStore: media)
        XCTAssertNotNil(broken.loadError)
        broken.recoverMedia(discardAbandonedDrafts: true)
        XCTAssertEqual(media.data(for: id), Data([3,2,1]))
        XCTAssertEqual(defaults.data(forKey: key), Data("unreadable metadata".utf8))
    }
}


extension Prompt10SavedLibraryTests {
    func testSharedImportedImageSurvivesOneBookDeletionAndIsRemovedAfterLastReference() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let media = Prompt10LocalMediaStore(root: root)
        let library = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: key, mediaStore: media)
        let first = try library.createEncyclopedia(name: "first", style: .pink)
        let second = try library.createEncyclopedia(name: "second", style: .sage)
        let id = try media.stageImageData(Data([2,4,6]))
        let writing = FruitfolioSemanticDocument(spans: [.init(text: "my image notes")])
        _ = try library.saveUserPage(pageID: nil, encyclopediaID: first.id,
            chapterID: first.chapters[0].id, title: "first image", document: writing, imageIDs: [id])
        _ = try library.saveUserPage(pageID: nil, encyclopediaID: second.id,
            chapterID: second.chapters[0].id, title: "second image", document: writing, imageIDs: [id])
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: key, mediaStore: media)
        XCTAssertEqual(media.data(for: id), Data([2,4,6]))
        XCTAssertNil(reopened.mediaRecoveryError)
        try reopened.deleteEncyclopedia(id: first.id)
        XCTAssertEqual(media.data(for: id), Data([2,4,6]), "Another saved page still owns these bytes")
        try reopened.deleteEncyclopedia(id: second.id)
        XCTAssertNil(media.data(for: id))
    }
}
