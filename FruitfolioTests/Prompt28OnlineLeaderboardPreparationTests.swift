import XCTest
@testable import Fruitfolio

final class Prompt28OnlineLeaderboardPreparationTests: XCTestCase {
    func testUsernameKeysAreCaseInsensitive() {
        XCTAssertEqual(Prompt28UsernameKey.normalized("Strawberry"), Prompt28UsernameKey.normalized("STRAWBERRY"))
    }

    func testDuplicateNameIsRejectedAcrossOwners() async {
        let registry = Prompt28InMemoryUsernameRegistry()
        let first = await registry.reserve(username: "Strawberry", ownerID: "owner-a")
        let second = await registry.reserve(username: "strawberry", ownerID: "owner-b")
        XCTAssertEqual(first, .reserved)
        XCTAssertEqual(second, .taken)
    }

    func testOnlyOwnerCanRelease() async {
        let registry = Prompt28InMemoryUsernameRegistry()
        _ = await registry.reserve(username: "Strawberry", ownerID: "owner-a")
        let denied = await registry.release(username: "strawberry", ownerID: "owner-b")
        let allowed = await registry.release(username: "STRAWBERRY", ownerID: "owner-a")
        XCTAssertFalse(denied)
        XCTAssertTrue(allowed)
    }

    func testLiveSyncDisabledUntilSecureServiceConfigured() {
        XCTAssertFalse(Prompt28GameCenterConfiguration.isLiveSyncEnabled)
        XCTAssertEqual(Prompt28GameCenterConfiguration.boardIDs.count, 4)
    }
}
