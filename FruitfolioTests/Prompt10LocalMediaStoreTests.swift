import XCTest
@testable import Fruitfolio

final class Prompt10LocalMediaStoreTests: XCTestCase {
    func testImportedMediaRoundTripAndDelete() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = Prompt10LocalMediaStore(root: root)
        let original = Data([0, 1, 2, 3, 4, 5])
        let id = try store.saveImageData(original)
        XCTAssertEqual(store.data(for: id), original)
        try store.delete(id)
        XCTAssertNil(store.data(for: id))
    }
}
