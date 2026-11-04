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

extension Prompt10LocalMediaStoreTests {
    func testImportedMediaRejectsPathTraversalAndIsExcludedFromBackup() throws {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let root = parent.appendingPathComponent("media")
        defer { try? FileManager.default.removeItem(at: parent) }
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let secret = parent.appendingPathComponent("private.image")
        try Data("unrelated private file".utf8).write(to: secret)
        let store = Prompt10LocalMediaStore(root: root)
        let id = try store.saveImageData(Data([1,2,3]))
        XCTAssertNil(store.data(for: "../private"))
        XCTAssertThrowsError(try store.delete("../private"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secret.path))
        XCTAssertEqual(try root.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    func testImportedMediaCompleteProtectionOnPhysicalDevice() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("NOT VERIFIED: Run21 simulator omits NSFileProtectionKey even after explicit setAttributes. Requires a physical passcode-protected iPhone; this is not a privacy PASS.")
        #else
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = Prompt10LocalMediaStore(root: root)
        let id = try store.saveImageData(Data([1,2,3]))
        let attributes = try FileManager.default.attributesOfItem(atPath: root.appendingPathComponent(id).appendingPathExtension("image").path)
        XCTAssertTrue((attributes[.protectionKey] as? String) == FileProtectionType.complete.rawValue
                      || (attributes[.protectionKey] as? FileProtectionType) == .complete,
                      "Imported media must retain complete protection; actual file attributes: \(attributes)")
        #endif
    }
}


extension Prompt10LocalMediaStoreTests {
    func testDraftRecoveryPromotesReferencedBytesAndRemovesAbandonedDraftsOnly() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = Prompt10LocalMediaStore(root: root)
        let kept = try store.stageImageData(Data([4,5,6]))
        let abandoned = try store.stageImageData(Data([7,8]))
        XCTAssertEqual(store.data(for: kept), Data([4,5,6]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(kept + ".image").path))
        try store.reconcile(referencedIDs: [kept], discardAbandonedDrafts: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(kept + ".image").path))
        XCTAssertNotNil(store.data(for: abandoned), "An active unsaved editor must retain its draft")
        try store.reconcile(referencedIDs: [kept], discardAbandonedDrafts: true)
        XCTAssertEqual(store.data(for: kept), Data([4,5,6]))
        XCTAssertNil(store.data(for: abandoned))
    }

    func testReconciliationRemovesUnreferencedImportsButPreservesUnknownFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = Prompt10LocalMediaStore(root: root)
        let removed = try store.saveImageData(Data([1]))
        let unknown = root.appendingPathComponent("unrelated.txt")
        try Data([9]).write(to: unknown)
        try store.reconcile(referencedIDs: [], discardAbandonedDrafts: true)
        XCTAssertNil(store.data(for: removed))
        XCTAssertEqual(try Data(contentsOf: unknown), Data([9]))
        XCTAssertThrowsError(try store.reconcile(referencedIDs: ["../outside"], discardAbandonedDrafts: true))
    }
}
