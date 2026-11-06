import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BOwnedConfirmationTests: XCTestCase {
    private func request(_ id: UUID, priority: FruitPopupPriority = .sensitive) -> FruitPopupRequest {
        .init(id: id, character: .blueberry, message: "nonmedical confirmation fixture", dismissBehavior: .explicitActionOnly,
              priority: priority, surface: .tapedWhite)
    }
    func testQueuedOrCancelledOwnerCannotConsumeAnActionOrDismissAnotherFeature() async throws {
        let coordinator = PopupCoordinator()
        let other = request(UUID())
        coordinator.request(other)
        let owner = FruitfolioOwnedPopupSession(coordinator: coordinator)
        owner.present { request($0) }
        let queuedID = try XCTUnwrap(owner.requestID)
        XCTAssertTrue(coordinator.containsRequest(id: queuedID))
        XCTAssertFalse(owner.consumeAction(for: queuedID))
        owner.cancel()
        XCTAssertFalse(coordinator.containsRequest(id: queuedID))
        XCTAssertEqual(coordinator.currentPopup?.id, other.id)
        XCTAssertNotEqual(coordinator.presentationState, .dismissing)
        XCTAssertFalse(owner.consumeAction(for: queuedID))
    }
    func testCurrentActionIsSingleUseAndEscapeCannotBecomeAConfirm() async throws {
        let coordinator = PopupCoordinator()
        let owner = FruitfolioOwnedPopupSession(coordinator: coordinator)
        owner.present { request($0) }
        let id = try XCTUnwrap(owner.requestID)
        XCTAssertTrue(owner.consumeAction(for: id))
        XCTAssertFalse(owner.consumeAction(for: id))
        coordinator.finishDismissal(expectedPopupID: id)
        owner.present { request($0) }
        let escaped = try XCTUnwrap(owner.requestID)
        coordinator.dismissCurrent(reason: .programmatic)
        XCTAssertFalse(owner.consumeAction(for: escaped))
        coordinator.finishDismissal(expectedPopupID: escaped)
        owner.observeDismissal()
        XCTAssertNil(owner.requestID)
    }
    func testRapidRepeatedPresentationKeepsFirstConfirmationAndClosingIdentity() async throws {
        let coordinator = PopupCoordinator()
        let owner = FruitfolioOwnedPopupSession(coordinator: coordinator)
        owner.present { request($0) }
        let id = try XCTUnwrap(owner.requestID)
        var rebuilt = false
        owner.present { rebuilt = true; return request($0) }
        XCTAssertFalse(rebuilt)
        XCTAssertEqual(owner.requestID, id)
        XCTAssertEqual(coordinator.currentPopup?.id, id)
        XCTAssertNotEqual(coordinator.presentationState, .dismissing)
        XCTAssertTrue(owner.consumeAction(for: id))
        owner.present { rebuilt = true; return request($0) }
        XCTAssertFalse(rebuilt)
        XCTAssertEqual(owner.requestID, id)
        coordinator.finishDismissal(expectedPopupID: id)
        owner.observeDismissal()
        XCTAssertNil(owner.requestID)
    }

    func testHigherPriorityReplacementInvalidatesOldVisibleAction() async throws {
        let coordinator = PopupCoordinator()
        let owner = FruitfolioOwnedPopupSession(coordinator: coordinator)
        owner.present { request($0, priority: .educational) }
        let id = try XCTUnwrap(owner.requestID)
        let other = request(UUID())
        coordinator.request(other)
        XCTAssertFalse(owner.consumeAction(for: id))
        coordinator.finishDismissal(expectedPopupID: id)
        owner.observeDismissal()
        XCTAssertNil(owner.requestID)
        owner.cancel()
        XCTAssertEqual(coordinator.currentPopup?.id, other.id)
    }
    func testDeletionIntentCannotDeleteNewerSameStoreRevisionOrReplay() async throws {
        let suite = "Fruitfolio.MeasurementConfirmation." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        var record = FruitfolioHormoneMeasurement()
        record.result = "12.500"; record.unit = "pg/mL"
        try store.save(record)
        let originalIntent = FruitfolioMeasurementDeletionIntent(scope: .one(record.id), savedRevision: store.savedRecordRevision)
        record.notes = "newer note after dialog opened"
        try store.save(record)
        let newerBytes = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try originalIntent.perform(in: store)) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .confirmationChanged)
        }
        XCTAssertEqual(defaults.data(forKey: "fixture"), newerBytes)
        let current = FruitfolioMeasurementDeletionIntent(scope: .one(record.id), savedRevision: store.savedRecordRevision)
        try current.perform(in: store)
        let emptyBytes = defaults.data(forKey: "fixture")
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertThrowsError(try current.perform(in: store))
        XCTAssertEqual(defaults.data(forKey: "fixture"), emptyBytes)
    }
    func testAllDeletionIntentRejectsReloadAndExternalWriterWithoutLosingLatestBytes() async throws {
        let suite = "Fruitfolio.MeasurementConfirmationAll." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("corrupt original".utf8), forKey: "fixture")
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        let beforeReload = FruitfolioMeasurementDeletionIntent(scope: .all, savedRevision: store.savedRecordRevision)
        store.reloadSavedMeasurements()
        XCTAssertThrowsError(try beforeReload.perform(in: store))
        let beforeWriter = FruitfolioMeasurementDeletionIntent(scope: .all, savedRevision: store.savedRecordRevision)
        let newer = Data("newer original".utf8)
        defaults.set(newer, forKey: "fixture")
        XCTAssertThrowsError(try beforeWriter.perform(in: store)) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .storageChanged)
        }
        XCTAssertEqual(defaults.data(forKey: "fixture"), newer)
    }
}
