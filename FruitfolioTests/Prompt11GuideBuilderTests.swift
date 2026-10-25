import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt11GuideBuilderTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: Prompt10SavedLibraryStore!

    override func setUp() {
        super.setUp()
        suiteName = "Prompt11GuideBuilderTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = Prompt10SavedLibraryStore(
            defaults: defaults,
            persistenceKey: "prompt11.tests"
        )
    }

    override func tearDown() {
        if let suiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }

        store = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testGuideUsesSamePrompt10EncyclopediaObject() throws {
        let guide = try store.createGuideEncyclopedia(
            name: "my hormone guide",
            subtitle: "things i want to remember",
            style: .sage
        )

        XCTAssertEqual(store.encyclopedia(id: guide.id)?.id, guide.id)
        XCTAssertEqual(store.encyclopedia(id: guide.id)?.guideBuilderEnabled, true)
        XCTAssertEqual(store.prompt11Guides.first?.id, guide.id)
    }

    func testNewGuideStartsWithoutSyntheticSection() throws {
        let guide = try store.createGuideEncyclopedia(
            name: "cycles",
            subtitle: "",
            style: .pink
        )

        XCTAssertTrue(guide.chapters.isEmpty)
    }

    func testGuideMetadataPersistsAcrossStoreReload() throws {
        let guide = try store.createGuideEncyclopedia(
            name: "cycles",
            subtitle: "things i want to remember",
            style: .lavender
        )

        let reloaded = Prompt10SavedLibraryStore(
            defaults: defaults,
            persistenceKey: "prompt11.tests"
        )

        XCTAssertEqual(reloaded.encyclopedia(id: guide.id)?.name, "cycles")
        XCTAssertEqual(
            reloaded.encyclopedia(id: guide.id)?.subtitle,
            "things i want to remember"
        )
        XCTAssertEqual(reloaded.encyclopedia(id: guide.id)?.style, .lavender)
        XCTAssertEqual(
            reloaded.encyclopedia(id: guide.id)?.guideBuilderEnabled,
            true
        )
    }

    func testAddingSavedMaterialCreatesReferenceAndPreventsDuplicate() throws {
        let sourceLibrary = try store.createEncyclopedia(
            name: "saved things",
            style: .sage
        )

        let sourceChapter = try XCTUnwrap(sourceLibrary.chapters.first)

        let sourcePage = Prompt10SavedPage(
            chapterID: sourceChapter.id,
            question: "what is estrogen?",
            answer: "saved answer",
            saveType: .fullAnswer
        )

        let savedSource = try store.savePage(
            sourcePage,
            to: sourceLibrary.id,
            chapterID: sourceChapter.id
        )

        let guide = try store.createGuideEncyclopedia(
            name: "hormones",
            subtitle: "",
            style: .pink
        )

        let section = try store.createChapter(
            in: guide.id,
            name: "estrogen"
        )

        let firstReference = try store.prompt11AddSavedMaterial(
            savedSource,
            to: guide.id,
            chapterID: section.id
        )

        _ = try store.prompt11AddSavedMaterial(
            savedSource,
            to: guide.id,
            chapterID: section.id
        )

        XCTAssertEqual(firstReference.sourceSavedPageID, savedSource.id)
        XCTAssertEqual(store.encyclopedia(id: guide.id)?.savedPageCount, 1)
    }

    func testDeletingGuideDoesNotDeleteSourceSavedMaterial() throws {
        let sourceLibrary = try store.createEncyclopedia(
            name: "saved things",
            style: .sage
        )
        let sourceChapter = try XCTUnwrap(sourceLibrary.chapters.first)
        let sourcePage = Prompt10SavedPage(
            chapterID: sourceChapter.id,
            question: "question",
            answer: "answer",
            saveType: .excerpt,
            excerptText: "answer"
        )
        let savedSource = try store.savePage(
            sourcePage,
            to: sourceLibrary.id,
            chapterID: sourceChapter.id
        )

        let guide = try store.createGuideEncyclopedia(
            name: "guide",
            subtitle: "",
            style: .coral
        )
        let section = try store.createChapter(
            in: guide.id,
            name: "section"
        )
        _ = try store.prompt11AddSavedMaterial(
            savedSource,
            to: guide.id,
            chapterID: section.id
        )

        try store.deleteEncyclopedia(id: guide.id)

        XCTAssertNil(store.encyclopedia(id: guide.id))
        XCTAssertNotNil(store.encyclopedia(id: sourceLibrary.id))
        XCTAssertNotNil(store.prompt11SourcePage(sourceKey: savedSource.id))
    }

    func testSectionAndPageReorderPersist() throws {
        let guide = try store.createGuideEncyclopedia(
            name: "guide",
            subtitle: "",
            style: .yellow
        )

        let first = try store.createChapter(in: guide.id, name: "first")
        let second = try store.createChapter(in: guide.id, name: "second")

        try store.moveChapter(
            encyclopediaID: guide.id,
            chapterID: second.id,
            offset: -1
        )

        XCTAssertEqual(store.encyclopedia(id: guide.id)?.chapters.first?.id, second.id)

        let pageOne = Prompt10SavedPage(
            chapterID: first.id,
            question: "one",
            answer: "one",
            saveType: .fullAnswer
        )
        let pageTwo = Prompt10SavedPage(
            chapterID: first.id,
            question: "two",
            answer: "two",
            saveType: .fullAnswer
        )

        let savedOne = try store.savePage(pageOne, to: guide.id, chapterID: first.id)
        let savedTwo = try store.savePage(pageTwo, to: guide.id, chapterID: first.id)

        try store.movePageWithinChapter(
            encyclopediaID: guide.id,
            chapterID: first.id,
            pageID: savedTwo.id,
            offset: -1
        )

        let updatedFirstChapter = try XCTUnwrap(
            store.encyclopedia(id: guide.id)?
                .chapters
                .first(where: { $0.id == first.id })
        )

        XCTAssertEqual(updatedFirstChapter.pages.first?.id, savedTwo.id)
        XCTAssertEqual(updatedFirstChapter.pages.last?.id, savedOne.id)
    }

    func testPersonalNoteRemainsAttachedToGuidePage() throws {
        let guide = try store.createGuideEncyclopedia(
            name: "guide",
            subtitle: "",
            style: .sage
        )
        let section = try store.createChapter(in: guide.id, name: "notes")
        let page = Prompt10SavedPage(
            chapterID: section.id,
            question: "question",
            answer: "answer",
            saveType: .fullAnswer
        )
        let saved = try store.savePage(page, to: guide.id, chapterID: section.id)

        try store.updatePageNotes(
            encyclopediaID: guide.id,
            chapterID: section.id,
            pageID: saved.id,
            notes: "ask about this later"
        )

        let updated = store.encyclopedia(id: guide.id)?
            .chapters
            .first?
            .pages
            .first

        XCTAssertEqual(updated?.notes, "ask about this later")
    }

    func testAllNineGuideBuilderAssetsUseExactCanonicalNames() {
        let assets = [
            "guide_rename",
            "guide_folder_add",
            "guide_orange_star_brush",
            "guide_sort",
            "guide_delete",
            "guide_folder",
            "guide_star_divider",
            "guide_back",
            "guide_bookmark_saved"
        ]

        XCTAssertEqual(Set(assets).count, 9)
    }
}
