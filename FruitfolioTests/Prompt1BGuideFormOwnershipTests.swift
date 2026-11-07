import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BGuideFormOwnershipTests: XCTestCase {
    func testOnePresentationOwnsOneOpenCloseAndRepeatedRequestsKeepItsTicket() async throws {
        let session = Prompt11GuideFormSession()
        XCTAssertFalse(session.isCurrent(nil))
        XCTAssertEqual(session.transition(to: .createGuide), [.open])
        let ticket = try XCTUnwrap(session.ticket)
        XCTAssertTrue(session.isCurrent(ticket))
        XCTAssertEqual(session.transition(to: .createGuide), [])
        XCTAssertEqual(session.ticket, ticket)
        XCTAssertEqual(session.transition(to: nil), [.close])
        XCTAssertFalse(session.isCurrent(ticket))
        XCTAssertEqual(session.transition(to: nil), [])
    }
    func testReplacementAndForeignOwnerRejectEarlierCallbacks() async throws {
        let session = Prompt11GuideFormSession(), other = Prompt11GuideFormSession()
        _ = session.transition(to: .createGuide)
        _ = other.transition(to: .createGuide)
        let first = try XCTUnwrap(session.ticket), foreign = try XCTUnwrap(other.ticket)
        XCTAssertFalse(session.isCurrent(foreign))
        let guide = UUID()
        XCTAssertEqual(session.transition(to: .editDescription(guide, "original")), [.close, .open])
        XCTAssertFalse(session.isCurrent(first))
        let current = try XCTUnwrap(session.ticket)
        XCTAssertTrue(session.isCurrent(current))
        XCTAssertEqual(session.current, .editDescription(guide, "original"))
    }
    func testBackgroundRetainsFormButInvalidatesCallbacksUntilFreshVisibleTicket() async throws {
        let session = Prompt11GuideFormSession(), guide = UUID()
        let form = Prompt11Overlay.editDescription(guide, "original")
        _ = session.transition(to: form)
        let old = try XCTUnwrap(session.ticket)
        session.suspend(); session.suspend()
        XCTAssertEqual(session.current, form)
        XCTAssertNil(session.ticket)
        XCTAssertFalse(session.isCurrent(old))
        XCTAssertEqual(session.transition(to: .createGuide), [])
        XCTAssertEqual(session.current, form)
        session.resume()
        let resumed = try XCTUnwrap(session.ticket)
        XCTAssertNotEqual(old, resumed)
        XCTAssertFalse(session.isCurrent(old))
        XCTAssertTrue(session.isCurrent(resumed))
        session.resume()
        XCTAssertEqual(session.ticket, resumed)
        XCTAssertEqual(session.transition(to: nil), [.close])
    }
    func testCancelledAndReplayedActionsCannotCreateRealGuidesAndFailureRetainsRetry() async throws {
        let suite = "Fruitfolio.guide-form-ownership." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let session = Prompt11GuideFormSession()
        _ = session.transition(to: .createGuide)
        let cancelled = try XCTUnwrap(session.ticket)
        func save(_ ticket: Prompt11GuideFormTicket, name: String) throws {
            guard session.isCurrent(ticket) else { return }
            _ = try store.createGuideEncyclopedia(name: name, subtitle: "fixture only", style: .sage)
            _ = session.transition(to: nil)
        }
        _ = session.transition(to: nil)
        try save(cancelled, name: "cancelled callback")
        XCTAssertEqual(store.count, 0)
        XCTAssertNil(defaults.object(forKey: "fixture"))
        _ = session.transition(to: .createGuide)
        let current = try XCTUnwrap(session.ticket)
        try save(cancelled, name: "stale callback")
        XCTAssertEqual(store.count, 0)
        XCTAssertThrowsError(try save(current, name: ""))
        XCTAssertTrue(session.isCurrent(current), "A failed validation must retain the same editable form")
        try save(current, name: "QA guide")
        try save(current, name: "replayed callback")
        let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        XCTAssertEqual(reloaded.count, 1)
        XCTAssertEqual(reloaded.encyclopedias.first?.name, "QA guide")
        XCTAssertFalse(session.isCurrent(current))
    }
}

private final class Prompt1BGuideReorderTrackingDefaults: UserDefaults, @unchecked Sendable {
    private(set) var libraryWrites = 0
    override func set(_ value: Any?, forKey key: String) {
        if key == "guide-owned" { libraryWrites += 1 }
        super.set(value, forKey: key)
    }
}

@MainActor
final class Prompt1BGuideReorderOwnerTests: XCTestCase {
    private func fixture() throws -> (Prompt1BGuideReorderTrackingDefaults, String, Prompt10SavedLibraryStore, UUID, UUID, UUID, [Prompt10SavedPage]) {
        let suite = "fruitfolio.guide.reorder-owner." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGuideReorderTrackingDefaults(suiteName: suite))
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "guide-owned")
        let guide = try store.createGuideEncyclopedia(name: "QA owner", subtitle: "original", style: .sage)
        let first = try store.createChapter(in: guide.id, name: "first")
        let second = try store.createChapter(in: guide.id, name: "second")
        let pages = try store.savePages([
            .init(chapterID: first.id, question: "first", answer: "12.50 pg/mL [fixture-source]", saveType: .fullAnswer,
                  sourceIDs: ["fixture-source"], notes: "original note"),
            .init(chapterID: first.id, question: "second", answer: "second body", saveType: .fullAnswer)
        ], to: guide.id, chapterID: first.id)
        return (defaults, suite, store, guide.id, first.id, second.id, pages)
    }
    private func context(_ guideID: UUID) -> Prompt11GuideInteractionContext {
        .init(epoch: UUID(), languageID: "en", selectedGuideID: guideID, isVisible: true, isActive: true, allowsInteraction: true)
    }

    func testInactiveStaleAndWrongScopeCallbacksNeverWriteActualCanonicalStore() async throws {
        let (defaults, suite, store, guideID, chapterID, otherChapterID, pages) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let live = context(guideID), guide = try XCTUnwrap(store.encyclopedia(id: guideID))
        let sectionOwner = try XCTUnwrap(Prompt11GuideReorderOwner(guide: guide, scope: .sections, epoch: live.epoch, languageID: live.languageID))
        let pageOwner = try XCTUnwrap(Prompt11GuideReorderOwner(guide: guide, scope: .pages(chapterID), epoch: live.epoch, languageID: live.languageID))
        var contexts: [Prompt11GuideInteractionContext] = []
        var changed = live; changed.isVisible = false; contexts.append(changed)
        changed = live; changed.isActive = false; contexts.append(changed)
        changed = live; changed.allowsInteraction = false; contexts.append(changed)
        changed = live; changed.epoch = UUID(); contexts.append(changed)
        changed = live; changed.languageID = "ar"; contexts.append(changed)
        changed = live; changed.selectedGuideID = UUID(); contexts.append(changed)
        let before = defaults.data(forKey: "guide-owned"), snapshot = store.encyclopedias, writes = defaults.libraryWrites
        for rejected in contexts {
            XCTAssertFalse(try store.prompt11MoveOwnedSection(guideID: guideID, chapterID: chapterID, offset: 1, owner: sectionOwner, context: rejected))
            XCTAssertFalse(try store.prompt11MoveOwnedPage(guideID: guideID, chapterID: chapterID, pageID: pages[0].id, offset: 1, owner: pageOwner, context: rejected))
        }
        XCTAssertFalse(try store.prompt11MoveOwnedSection(guideID: guideID, chapterID: chapterID, offset: 1, owner: pageOwner, context: live))
        XCTAssertFalse(try store.prompt11MoveOwnedPage(guideID: guideID, chapterID: chapterID, pageID: pages[0].id, offset: 1, owner: sectionOwner, context: live))
        XCTAssertFalse(try store.prompt11MoveOwnedPage(guideID: guideID, chapterID: otherChapterID, pageID: pages[0].id, offset: 1, owner: pageOwner, context: live))
        XCTAssertFalse(try store.prompt11MoveOwnedPage(guideID: guideID, chapterID: chapterID, pageID: UUID(), offset: 1, owner: pageOwner, context: live))
        XCTAssertFalse(try store.prompt11MoveOwnedSection(guideID: guideID, chapterID: chapterID, offset: 1, owner: nil, context: live))
        XCTAssertEqual(defaults.libraryWrites, writes)
        XCTAssertEqual(defaults.data(forKey: "guide-owned"), before)
        XCTAssertEqual(store.encyclopedias, snapshot)
    }

    func testOwnedMovePreservesIndependentNotesAndSourceBytesButCannotReplayOldOrder() async throws {
        let (defaults, suite, store, guideID, chapterID, _, pages) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let live = context(guideID), guide = try XCTUnwrap(store.encyclopedia(id: guideID))
        let chapter = try XCTUnwrap(guide.chapters.first { $0.id == chapterID })
        let owner = try XCTUnwrap(Prompt11GuideReorderOwner(guideID: guideID, chapter: chapter, epoch: live.epoch, languageID: live.languageID))
        let note = "  cafe\u{301} 12,50 µg/L\n"
        try store.updatePageNotes(encyclopediaID: guideID, chapterID: chapterID, pageID: pages[0].id, notes: note)
        try store.setImportedImageIDs(encyclopediaID: guideID, chapterID: chapterID, pageID: pages[0].id, imageIDs: ["private-fixture-image"])
        XCTAssertTrue(owner.accepts(in: store.encyclopedias, context: live))
        let writes = defaults.libraryWrites
        XCTAssertTrue(try store.prompt11MoveOwnedPage(guideID: guideID, chapterID: chapterID, pageID: pages[0].id, offset: 1, owner: owner, context: live))
        XCTAssertEqual(defaults.libraryWrites, writes + 1)
        let reordered = try XCTUnwrap(store.encyclopedia(id: guideID)?.chapters.first { $0.id == chapterID })
        XCTAssertEqual(reordered.pages.sorted { $0.order < $1.order }.map(\.id), [pages[1].id, pages[0].id])
        let retained = try XCTUnwrap(reordered.pages.first { $0.id == pages[0].id })
        XCTAssertEqual(Data(retained.notes.utf8), Data(note.utf8))
        XCTAssertEqual(retained.answer, pages[0].answer)
        XCTAssertEqual(retained.sourceIDs, pages[0].sourceIDs)
        XCTAssertEqual(retained.importedImageIDs, ["private-fixture-image"])
        let before = defaults.data(forKey: "guide-owned")
        XCTAssertFalse(try store.prompt11MoveOwnedPage(guideID: guideID, chapterID: chapterID, pageID: pages[0].id, offset: -1, owner: owner, context: live))
        XCTAssertEqual(defaults.libraryWrites, writes + 1)
        XCTAssertEqual(defaults.data(forKey: "guide-owned"), before)
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "guide-owned")
        XCTAssertEqual(reopened.encyclopedias, store.encyclopedias)
    }

    func testChangedSectionOrderAndAmbiguousLegacyIdentitiesRejectWithoutRepair() async throws {
        let (defaults, suite, store, guideID, chapterID, _, _) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let live = context(guideID), guide = try XCTUnwrap(store.encyclopedia(id: guideID))
        let owner = try XCTUnwrap(Prompt11GuideReorderOwner(guide: guide, scope: .sections, epoch: live.epoch, languageID: live.languageID))
        XCTAssertTrue(try store.moveChapter(encyclopediaID: guideID, chapterID: chapterID, offset: 1))
        var before = defaults.data(forKey: "guide-owned"), writes = defaults.libraryWrites
        XCTAssertFalse(try store.prompt11MoveOwnedSection(guideID: guideID, chapterID: chapterID, offset: -1, owner: owner, context: live))
        XCTAssertEqual(defaults.libraryWrites, writes)
        XCTAssertEqual(defaults.data(forKey: "guide-owned"), before)
        let current = try XCTUnwrap(store.encyclopedia(id: guideID))
        let fresh = try XCTUnwrap(Prompt11GuideReorderOwner(guide: current, scope: .sections, epoch: live.epoch, languageID: live.languageID))
        defaults.set(try JSONEncoder().encode([current, current]), forKey: "guide-owned")
        store.reloadSavedLibrary()
        before = defaults.data(forKey: "guide-owned"); writes = defaults.libraryWrites
        XCTAssertFalse(try store.prompt11MoveOwnedSection(guideID: guideID, chapterID: chapterID, offset: -1, owner: fresh, context: live))
        XCTAssertEqual(defaults.libraryWrites, writes)
        XCTAssertEqual(defaults.data(forKey: "guide-owned"), before)
        var ambiguous = guide
        ambiguous.chapters.append(guide.chapters[0])
        XCTAssertNil(Prompt11GuideReorderOwner(guide: ambiguous, scope: .sections, epoch: live.epoch, languageID: live.languageID))
        XCTAssertNil(Prompt11GuideReorderOwner(guide: ambiguous, scope: .pages(chapterID), epoch: live.epoch, languageID: live.languageID))
    }
}
