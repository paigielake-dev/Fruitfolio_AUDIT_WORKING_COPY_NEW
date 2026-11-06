import XCTest
@testable import Fruitfolio

final class Prompt1BContextPersistenceTests: XCTestCase {
    func testCorruptAndWrongTypeContextRemainUntouchedUntilExplicitErase() throws {
        let suite = "ContextPersistenceTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for original: Any in [Data("broken original context".utf8), "wrong stored type"] {
            defaults.set(original, forKey: "context")
            let store = Prompt27ALocalContextPersistence(defaults: defaults, key: "context")
            XCTAssertTrue(store.storageUnreadable)
            XCTAssertTrue(store.context.isCompletelyUnspecified)
            XCTAssertThrowsError(try store.apply { $0.setReproductiveStage(.pregnant) })
            XCTAssertThrowsError(try store.exportJSON())
            if let data = original as? Data { XCTAssertEqual(defaults.data(forKey: "context"), data) }
            else { XCTAssertEqual(defaults.string(forKey: "context"), original as? String) }
            try store.erase()
            XCTAssertNil(defaults.object(forKey: "context"))
            XCTAssertFalse(store.storageUnreadable)
        }
    }
    func testMutationCommitsOnlyAfterValidationAndRestartsWithExactContext() throws {
        let suite = "ContextPersistenceTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27ALocalContextPersistence(defaults: defaults, key: "context")
        try store.apply {
            $0 = .init(timestamp: Date(timeIntervalSince1970: 0))
            $0.setTrackingGoal(.tryingToConceive, at: Date(timeIntervalSince1970: 10))
        }
        let snapshot = store.context
        let data = defaults.data(forKey: "context")
        enum Rejection: Error { case rejected }
        XCTAssertThrowsError(try store.apply { context in context.setReproductiveStage(.pregnant); throw Rejection.rejected })
        XCTAssertEqual(store.context, snapshot)
        XCTAssertEqual(defaults.data(forKey: "context"), data)
        XCTAssertEqual(Prompt27ALocalContextPersistence(defaults: defaults, key: "context").context, snapshot)
        try store.erase()
        XCTAssertTrue(Prompt27ALocalContextPersistence(defaults: defaults, key: "context").context.isCompletelyUnspecified)
    }
}
