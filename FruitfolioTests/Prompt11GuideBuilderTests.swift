import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt11GuideBuilderTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: Prompt10SavedLibraryStore!

    private func prepareGuideFixture() throws {
        suiteName = "Prompt11GuideBuilderTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        store = Prompt10SavedLibraryStore(
            defaults: defaults,
            persistenceKey: "prompt11.tests"
        )
    }

    private func removeGuideFixture() {
        if let suiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }

        store = nil
        defaults = nil
        suiteName = nil
    }

    func testGuideUsesSamePrompt10EncyclopediaObject() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
        let guide = try store.createGuideEncyclopedia(
            name: "my hormone guide",
            subtitle: "things i want to remember",
            style: .sage
        )

        XCTAssertEqual(store.encyclopedia(id: guide.id)?.id, guide.id)
        XCTAssertEqual(store.encyclopedia(id: guide.id)?.guideBuilderEnabled, true)
        XCTAssertEqual(store.prompt11Guides.first?.id, guide.id)
    }

    func testNewGuideStartsWithoutSyntheticSection() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
        let guide = try store.createGuideEncyclopedia(
            name: "cycles",
            subtitle: "",
            style: .pink
        )

        XCTAssertTrue(guide.chapters.isEmpty)
    }

    func testGuideMetadataPersistsAcrossStoreReload() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
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

    func testAddingSavedMaterialCreatesReferenceAndPreventsDuplicate() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
        let sourceLibrary = try store.createEncyclopedia(
            name: "saved things",
            style: .sage
        )

        let sourceChapter = try XCTUnwrap(sourceLibrary.chapters.first)

        let sourcePage = Prompt10SavedPage(
            chapterID: sourceChapter.id,
            question: "what is estrogen?",
            answer: "saved answer",
            saveType: .fullAnswer,
            importedImageIDs: ["shared-image"],
            sourceRecords: [.init(id: "source-1", title: "Original source title", doi: "10.1000/fixture")],
            educationalAssetIDs: [.ovarian_cycle_follicle_development_stages]
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

        XCTAssertEqual(firstReference.importedImageIDs, ["shared-image"])
        XCTAssertEqual(firstReference.sourceRecords, savedSource.sourceRecords)
        XCTAssertEqual(firstReference.educationalAssetIDs, savedSource.educationalAssetIDs)
        try store.setImportedImageIDs(encyclopediaID: sourceLibrary.id, chapterID: sourceChapter.id, pageID: savedSource.id, imageIDs: [])
        XCTAssertTrue(Prompt10MediaReferences.contains("shared-image", in: store.encyclopedias))
        XCTAssertEqual(firstReference.sourceSavedPageID, savedSource.id)
        XCTAssertEqual(store.encyclopedia(id: guide.id)?.savedPageCount, 1)
    }

    func testDeletingGuideDoesNotDeleteSourceSavedMaterial() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
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

    func testSectionAndPageReorderPersist() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
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

    func testPersonalNoteRemainsAttachedToGuidePage() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
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

    func testAllNineGuideBuilderAssetsUseExactCanonicalNames() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
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
    func testGuideDescriptionSaveIsAcknowledgedByIndependentReloadWithoutChangingPages() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
        let guide = try store.createGuideEncyclopedia(name: "QA guide", subtitle: "original", style: .sage)
        let section = try store.createChapter(in: guide.id, name: "QA section")
        let page = Prompt10SavedPage(chapterID: section.id, question: "nonclinical fixture",
            answer: "source content remains unchanged", saveType: .fullAnswer,
            sourceRecords: [.init(id: "qa-source", title: "Synthetic fixture, not research")])
        _ = try store.savePage(page, to: guide.id, chapterID: section.id)
        let before = try XCTUnwrap(store.encyclopedia(id: guide.id))
        try store.updateEncyclopediaDescription(id: guide.id, description: "QA updated description")
        let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "prompt11.tests")
        let saved = try XCTUnwrap(reloaded.encyclopedia(id: guide.id))
        XCTAssertEqual(saved.subtitle, "QA updated description")
        XCTAssertEqual(saved.name, before.name)
        XCTAssertEqual(saved.style, before.style)
        XCTAssertEqual(saved.chapters, before.chapters)
        XCTAssertEqual(saved.guideBuilderEnabled, true)
        XCTAssertNil(reloaded.storageProtectionReason)
    }
    func testFailedGuideDescriptionSavePreservesExternalBytesAndCommittedMemory() async throws {
        try prepareGuideFixture()
        defer { removeGuideFixture() }
        let guide = try store.createGuideEncyclopedia(name: "QA guide", subtitle: "original", style: .sage)
        let original = try XCTUnwrap(store.encyclopedia(id: guide.id))
        let external = Data(#"{"futureSchema":3,"preserve":{"field":null}}"#.utf8)
        defaults.set(external, forKey: "prompt11.tests")
        XCTAssertThrowsError(try store.updateEncyclopediaDescription(id: guide.id, description: "unsaved draft"))
        XCTAssertEqual(store.encyclopedia(id: guide.id), original)
        XCTAssertEqual(defaults.data(forKey: "prompt11.tests"), external)
        XCTAssertNotNil(store.storageProtectionReason)
        let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "prompt11.tests")
        XCTAssertNotNil(reloaded.storageProtectionReason)
        XCTAssertEqual(defaults.data(forKey: "prompt11.tests"), external)
    }

}

final class Prompt1BGuideLocalizedCopyTests: XCTestCase {
    func testNativeGuideCountsRemainProtectedAcrossLocalesAndSingularPlural() throws {
        for language in [FruitfolioLanguage.english, .french, .arabic, .hindi, .japanese] {
            for values in [(1, 1), (1234, 5678), (0, 0)] {
                let copy = Prompt11GuideCountCopy(sections: values.0, pages: values.1, language: language)
                let envelope = try FruitfolioScientificTranslationEnvelope(copy.progressSource, protectedLiterals: copy.progressLiterals)
                XCTAssertEqual(try envelope.restore(envelope.prepared), copy.progressSource)
                for number in copy.progressLiterals {
                    XCTAssertThrowsError(try envelope.validateCatalogCandidate(copy.progressSource.replacingOccurrences(of: number, with: "999999")))
                }
                XCTAssertTrue(copy.savedPagesSource.hasSuffix(values.1 == 1 ? "saved page" : "saved pages"))
                if language == .arabic && values.1 == 1 { XCTAssertEqual(copy.pageCountLiteral, "١") }
            }
        }
    }
    func testGuideTileEscapesAndProtectsExactAuthoredNameAlongsideNativeCount() throws {
        let name = "[cafe\u{301}] **12,50 µg/L**"
        let copy = Prompt11GuideTileCopy(name: name, sections: 1, pages: 1234, language: .arabic)
        let literalName = FruitfolioSemanticMarkup.markdown([.init(text: name)])
        XCTAssertTrue(copy.accessibilityProtectedLiterals.contains(literalName))
        let envelope = try FruitfolioScientificTranslationEnvelope(copy.accessibilitySource,
            protectedLiterals: copy.accessibilityProtectedLiterals)
        XCTAssertFalse(envelope.prepared.contains("cafe\u{301}"))
        XCTAssertFalse(envelope.prepared.contains(copy.counts.pageCountLiteral))
        XCTAssertEqual(Data(try envelope.restore(envelope.prepared).utf8), Data(copy.accessibilitySource.utf8))
        XCTAssertThrowsError(try envelope.validateCatalogCandidate(copy.accessibilitySource.replacingOccurrences(of: literalName, with: "rewritten name")))
    }
}
