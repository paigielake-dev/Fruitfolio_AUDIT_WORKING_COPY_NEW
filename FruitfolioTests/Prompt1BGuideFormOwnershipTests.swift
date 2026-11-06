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
