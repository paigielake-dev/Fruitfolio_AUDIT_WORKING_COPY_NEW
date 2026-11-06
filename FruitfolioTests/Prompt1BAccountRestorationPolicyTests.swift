import XCTest
@testable import Fruitfolio

final class Prompt1BAccountRestorationPolicyTests: XCTestCase {
    func testDiskFlagsCannotRestoreAnAuthenticatedOrInFlightRemoteOperation() {
        for state: Prompt12AuthenticationState in [.signedIn, .signingIn, .signingOut, .deletingAccount] {
            XCTAssertEqual(Prompt12SessionRestorationPolicy.authentication(state, hasLocalAccount: true), .sessionExpired)
            XCTAssertEqual(Prompt12SessionRestorationPolicy.authentication(state, hasLocalAccount: false), .signedOut)
        }
    }
    func testHistoricalDeletionDoesNotBecomeNewRemoteAcknowledgmentAndOrdinaryStatesRemainDistinct() {
        XCTAssertEqual(Prompt12SessionRestorationPolicy.authentication(.accountDeleted, hasLocalAccount: false), .signedOut)
        for state: Prompt12AuthenticationState in [.signedOut, .sessionExpired, .signInFailed] {
            XCTAssertEqual(Prompt12SessionRestorationPolicy.authentication(state, hasLocalAccount: true), state)
        }
    }
    func testOldSyncedOrSyncingFlagsDoNotInventCurrentServiceAcknowledgment() {
        XCTAssertEqual(Prompt12SessionRestorationPolicy.sync(.synced), .unavailable)
        XCTAssertEqual(Prompt12SessionRestorationPolicy.sync(.syncing), .unavailable)
        for state: Prompt12SyncState in [.localOnly, .pendingLocalChanges, .failed, .unavailable] {
            XCTAssertEqual(Prompt12SessionRestorationPolicy.sync(state), state)
        }
    }
}
