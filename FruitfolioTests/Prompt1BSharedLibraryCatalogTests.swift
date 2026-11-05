import XCTest
@testable import Fruitfolio

final class Prompt1BSharedLibraryCatalogTests: XCTestCase {
    private func book(page: Prompt10SavedPage, guide: Bool?) -> Prompt10Encyclopedia {
        .init(name: "same shared book", guideBuilderEnabled: guide, style: .coral,
              chapters: [.init(id: page.chapterID, encyclopediaID: UUID(), name: "section", order: 0, pages: [page])])
    }
    func testLegacyAskAndGuideBooksAppearAsSameRecordsWithoutNewIdentifiers() {
        let page = Prompt10SavedPage(chapterID: UUID(), question: "saved", answer: "exact evidence", saveType: .fullAnswer)
        let records = [book(page: page, guide: nil), book(page: page, guide: true), book(page: page, guide: false)]
        let projected = Prompt10SharedLibraryCatalog.books(records)
        XCTAssertEqual(Set(projected.map(\.id)), Set(records.map(\.id)))
        XCTAssertTrue(projected.allSatisfy { $0.style == .coral && $0.chapters.first?.pages.first?.answer == "exact evidence" })
        let roundtrip = try? JSONDecoder().decode([Prompt10Encyclopedia].self, from: JSONEncoder().encode(records))
        XCTAssertEqual(roundtrip, records)
    }
    func testOriginalOutranksNewerSnapshotAndOwnPagesAreAlreadyPresent() {
        let original = Prompt10SavedPage(chapterID: UUID(), question: "original", answer: "original evidence", saveType: .fullAnswer,
            savedAt: Date(timeIntervalSince1970: 1))
        let copy = Prompt10SavedPage(chapterID: UUID(), question: "snapshot", answer: "snapshot evidence", saveType: .fullAnswer,
            savedAt: Date(timeIntervalSince1970: 100), sourceSavedPageID: original.id)
        let sourceBook = book(page: original, guide: nil)
        let copiedBook = book(page: copy, guide: true)
        XCTAssertEqual(Prompt10SharedLibraryCatalog.material([copiedBook, sourceBook]).map(\.id), [original.id])
        XCTAssertEqual(Prompt10SharedLibraryCatalog.material([sourceBook, copiedBook]).map(\.id), [original.id])
        XCTAssertEqual(Prompt10SharedLibraryCatalog.containedSourceKeys(in: sourceBook), [original.id])
        XCTAssertEqual(Prompt10SharedLibraryCatalog.containedSourceKeys(in: copiedBook), [original.id])
        XCTAssertEqual(Prompt10SharedLibraryCatalog.material([copiedBook]).first?.id, copy.id)
        XCTAssertEqual(Prompt10SharedLibraryCatalog.originalPage(sourceKey: original.id, in: [copiedBook, sourceBook])?.id, original.id)
        XCTAssertNil(Prompt10SharedLibraryCatalog.originalPage(sourceKey: original.id, in: [copiedBook]))
    }
}
