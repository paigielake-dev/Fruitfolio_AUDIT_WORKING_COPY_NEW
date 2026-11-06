import Foundation
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif
import XCTest
@testable import Fruitfolio

final class Prompt1BLocalDataExportTests: XCTestCase {
    @MainActor
    func testUsernameRecordAndLegacyConsentExportWithoutRewritingOriginals() async throws {
        let suite = "Fruitfolio.UsernameExport." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = FruitfolioUsernamePersistence.defaultKey
        defaults.set("old_berry", forKey: key)
        defaults.set(true, forKey: key + ".initialized")
        defaults.set("old_berry", forKey: key + ".nonIdentifyingConfirmation")
        defaults.set("exclude this fixture", forKey: "outside.private.key")
        let store = FruitfolioUsernameStore(defaults: defaults)
        XCTAssertNil(store.setUsername("new_berry", confirmedNonIdentifying: true))
        let recordKey = FruitfolioUsernamePersistence.recordKey()
        let bytes = try XCTUnwrap(defaults.data(forKey: recordKey))
        let captured = try FruitfolioLocalDataExport.capturePreferences(defaults: defaults)
        XCTAssertEqual(Set(captured.map(\.key)), Set([key, key + ".initialized", key + ".nonIdentifyingConfirmation", recordKey]))
        let record = try XCTUnwrap(captured.first { $0.key == recordKey })
        XCTAssertTrue(record.isRawData)
        XCTAssertEqual(record.data, bytes)
        XCTAssertEqual(defaults.string(forKey: key), "old_berry")
        XCTAssertEqual(defaults.string(forKey: key + ".nonIdentifyingConfirmation"), "old_berry")
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "new_berry")
    }

    func testInvalidDuplicateAndAbsoluteArchivePathsCannotOverwriteExistingOutput() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let output = root.appendingPathComponent("existing.zip")
        let original = Data("preserve me".utf8)
        try original.write(to: output)
        for names in [["../escape"], ["/absolute"], ["a//b"], ["a\\b"], ["x", "x"], ["valid.json"]] {
            XCTAssertThrowsError(try FruitfolioZIPArchive.write(names.map { .init(path: $0, payload: .bytes(Data())) }, to: output))
            XCTAssertEqual(try Data(contentsOf: output), original)
        }
    }

    func testMissingAndLinkedSourceFailuresRemoveOnlyThePartialExport() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source")
        let bytes = Data("original user file".utf8)
        try bytes.write(to: source)
        let link = root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: source)
        for input in [root.appendingPathComponent("missing"), link] {
            let output = root.appendingPathComponent(UUID().uuidString + ".zip")
            XCTAssertThrowsError(try FruitfolioZIPArchive.write([
                .init(path: "first", payload: .bytes(Data("written first".utf8))),
                .init(path: "second", payload: .file(input))], to: output))
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            XCTAssertEqual(try Data(contentsOf: source), bytes)
        }
    }

    func testCancellationDoesNotLeaveAnExportOrTouchOriginals() async throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try FruitfolioZIPArchive.write([.init(path: "data", payload: .bytes(Data("original".utf8)))], to: output)
        }
        do { try await task.value; XCTFail("Cancelled export unexpectedly succeeded") }
        catch is CancellationError {} catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
    }

    func testCancellationDuringStreamingRemovesPartialArchiveAndPreservesSource() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.image")
        let bytes = Data(repeating: 0xa5, count: 16 * 1_048_576)
        try bytes.write(to: source)
        let output = root.appendingPathComponent("partial.zip")
        let worker = Task.detached {
            try FruitfolioZIPArchive.write([.init(path: "image", payload: .file(source))], to: output)
        }
        for _ in 0..<1000 {
            if FileManager.default.fileExists(atPath: output.path) { break }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        worker.cancel()
        do { try await worker.value; XCTFail("Streaming export did not cancel") }
        catch is CancellationError {} catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        XCTAssertEqual(try Data(contentsOf: source), bytes)
    }

    #if os(Linux) || os(macOS)
    private func verifyWithPython(_ archive: URL, script: String, extra: [String] = []) throws {
        let python = ["/usr/bin/python3", "/usr/local/bin/python3"].first { FileManager.default.isExecutableFile(atPath: $0) }
        guard let python else { throw XCTSkip("Independent Python ZIP reader unavailable") }
        // Use POSIX spawn/wait here. Foundation Process pipe/termination handling
        // stalled after its child exited under the Linux XCTest sandbox.
        var arguments = ([python, "-c", script, archive.path] + extra).map { strdup($0) }
        arguments.append(nil)
        defer { for pointer in arguments { free(pointer) } }
        var environment: [UnsafeMutablePointer<CChar>?] = [nil]
        var child: pid_t = 0
        let spawned = posix_spawn(&child, python, nil, nil, &arguments, &environment)
        XCTAssertEqual(spawned, 0)
        guard spawned == 0 else { return }
        var status: Int32 = 0
        var waited: pid_t
        repeat { waited = waitpid(child, &status, 0) } while waited == -1 && errno == EINTR
        XCTAssertEqual(waited, child)
        XCTAssertEqual(status, 0, "Independent Python ZIP reader failed; inspect its stderr above.")
    }

    func testIndependentZIPReaderValidatesCRCEmptyAndStreamedBoundaryPayloads() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.image")
        let bytes = Data((0..<1_048_593).map { UInt8($0 % 251) })
        try bytes.write(to: source)
        let output = root.appendingPathComponent("export.zip")
        try FruitfolioZIPArchive.write([
            .init(path: "empty", payload: .bytes(Data())),
            .init(path: "images/original.image", payload: .file(source)),
            .init(path: "notes.json", payload: .bytes(Data("{\"notes\":\"أهلاً — citations 12.5 pg/mL\"}".utf8)))], to: output)
        try verifyWithPython(output, script: #"""
import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    assert z.testzip() is None
    assert z.namelist() == ['empty', 'images/original.image', 'notes.json']
    assert z.read('empty') == b''
    assert z.read('images/original.image') == open(sys.argv[2], 'rb').read()
    assert json.loads(z.read('notes.json'))['notes'] == 'أهلاً — citations 12.5 pg/mL'
"""#, extra: [source.path])
        XCTAssertEqual(try Data(contentsOf: source), bytes)
    }

    func testReferencedImagesAreDeduplicatedAndOriginalSavedProvenanceIsUnchanged() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let media = root.appendingPathComponent("Fruitfolio/SavedLibraryMedia")
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let imageID = UUID().uuidString.lowercased()
        let missingID = UUID().uuidString.lowercased()
        let image = media.appendingPathComponent(imageID + ".image")
        let bytes = Data([0, 255, 12, 14, 18])
        try bytes.write(to: image)
        let bookID = UUID(), chapterID = UUID()
        let page = Prompt10SavedPage(chapterID: chapterID, question: "original question", answer: "12.5 pg/mL [A]",
            saveType: .fullAnswer, originalAnswerID: "answer-1", sourceIDs: ["A"], sourceVersions: ["A": "original-v1"],
            notes: "my original note", importedImageIDs: [imageID, imageID, missingID, "../escape"])
        let chapter = Prompt10Chapter(id: chapterID, encyclopediaID: bookID, name: "notes", order: 0, pages: [page])
        let book = Prompt10Encyclopedia(id: bookID, name: "guide", guideBuilderEnabled: true, style: .sage, chapters: [chapter])
        let raw = try JSONEncoder().encode([book])
        let rawFile = root.appendingPathComponent("original-library.json")
        try raw.write(to: rawFile)
        let output = root.appendingPathComponent("export.zip")
        let result = try FruitfolioLocalDataExport.create(preferences: [
            .init(key: "fruitfolio.prompt10.savedLibrary.v2", data: raw, isRawData: true)],
            applicationSupport: root, output: output)
        XCTAssertEqual(result.warnings.count, 2)
        try verifyWithPython(output, script: #"""
import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    assert z.testzip() is None
    m = json.loads(z.read('manifest.json'))
    assert len(m['warnings']) == 2
    assert len([p for p in z.namelist() if p.endswith('.image')]) == 1
    assert z.read(m['preferences']['fruitfolio.prompt10.savedLibrary.v2']) == open(sys.argv[2], 'rb').read()
    assert z.read(m['savedFiles'][0]) == bytes([0, 255, 12, 14, 18])
"""#, extra: [rawFile.path])
        XCTAssertEqual(try Data(contentsOf: image), bytes)
        XCTAssertEqual(try Data(contentsOf: rawFile), raw)
    }

    func testUnreadableLibraryRetainsOriginalBytesAndWarnsInsteadOfSweepingImages() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let output = root.appendingPathComponent("export.zip")
        let original = Data("unreadable original library".utf8)
        let result = try FruitfolioLocalDataExport.create(preferences: [
            .init(key: "fruitfolio.prompt10.savedLibrary.v2", data: original, isRawData: true)],
            applicationSupport: root, output: output)
        XCTAssertEqual(result.warnings.count, 2)
        try verifyWithPython(output, script: #"""
import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    assert z.testzip() is None
    m = json.loads(z.read('manifest.json'))
    assert len(m['warnings']) == 2
    p = m['preferences']['fruitfolio.prompt10.savedLibrary.v2']
    assert p.endswith('.bin')
    assert z.read(p) == b'unreadable original library'
    assert m['savedFiles'] == []
"""#)
    }

    func testScopedExportPreservesRawRecordsAndKnownCycleFilesExcludesAskAndOrphanImages() throws {
        let suite = "Fruitfolio.Export." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cycle = root.appendingPathComponent("Fruitfolio/CycleDomain")
        try FileManager.default.createDirectory(at: cycle, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let raw = Data("{\"recordedValue\":\"12.500\",\"unit\":\"pg/mL\",\"source\":\"do not normalize\"}".utf8)
        defaults.set(raw, forKey: "fruitfolio.hormoneMeasurements.v1")
        defaults.set("he", forKey: "fruitfolio.settings.language")
        defaults.set("never include unsaved question", forKey: "fruitfolio.ask.unsaved")
        let cycleBytes = Data("exact original cycle bytes, even if unreadable".utf8)
        try cycleBytes.write(to: cycle.appendingPathComponent("daily-logs-v1.json"))
        let media = root.appendingPathComponent("Fruitfolio/SavedLibraryMedia")
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        try Data("orphan must stay private".utf8).write(to: media.appendingPathComponent(UUID().uuidString + ".image"))
        let records = try FruitfolioLocalDataExport.capturePreferences(defaults: defaults)
        let output = root.appendingPathComponent("export.zip")
        let result = try FruitfolioLocalDataExport.create(preferences: records, applicationSupport: root, output: output)
        XCTAssertTrue(result.warnings.isEmpty)
        try verifyWithPython(output, script: #"""
import json, plistlib, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    assert z.testzip() is None
    assert len(z.namelist()) == 4
    m = json.loads(z.read('manifest.json'))
    assert m['formatVersion'] == 1
    assert not m['warnings']
    assert 'fruitfolio.ask.unsaved' not in m['preferences']
    assert z.read(m['preferences']['fruitfolio.hormoneMeasurements.v1']) == b'{"recordedValue":"12.500","unit":"pg/mL","source":"do not normalize"}'
    assert plistlib.loads(z.read(m['preferences']['fruitfolio.settings.language']))['value'] == 'he'
    assert z.read('Fruitfolio/CycleDomain/daily-logs-v1.json') == b'exact original cycle bytes, even if unreadable'
    assert not any('.image' in name for name in z.namelist())
"""#)
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.hormoneMeasurements.v1"), raw)
        XCTAssertEqual(try Data(contentsOf: cycle.appendingPathComponent("daily-logs-v1.json")), cycleBytes)
    }
    #endif
}
