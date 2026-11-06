import Foundation
import XCTest
@testable import Fruitfolio

/// Explicit service fixtures test display ownership, not linguistic quality.
private actor ControlLabelFixtureRuntime: FruitfolioLocalTranslationRuntime {
    private(set) var calls = 0
    private let fail: Bool
    private let holdFirst: Bool
    private var held: CheckedContinuation<String, Never>?
    private var startWaiter: CheckedContinuation<Void, Never>?
    init(fail: Bool = false, holdFirst: Bool = false) { self.fail = fail; self.holdFirst = holdFirst }
    func translate(_ text: String, targetTag: String) async throws -> String {
        calls += 1
        if fail { throw FruitfolioTranslationError.resourcesMissing }
        if holdFirst, calls == 1 {
            return await withCheckedContinuation { continuation in
                held = continuation
                startWaiter?.resume(); startWaiter = nil
            }
        }
        return "fixture output"
    }
    func waitForHeldCall() async {
        if held != nil { return }
        await withCheckedContinuation { startWaiter = $0 }
    }
    func finishHeld() { held?.resume(returning: "older fixture output"); held = nil }
    func releaseResources() {}
}

@MainActor
final class Prompt1BControlTranslationStateTests: XCTestCase {
    private typealias Key = FruitfolioControlTranslationState.Key
    func testActualCatalogResolvesControlLabelsWhileInferenceIsPaused() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        defer { try? FileManager.default.removeItem(at: directory) }
        let folder = directory.appendingPathComponent("de.lproj")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": "fixture." + UUID().uuidString,
            "CFBundleDevelopmentRegion": "en"], format: .xml, options: 0)
            .write(to: directory.appendingPathComponent("Info.plist"))
        try PropertyListSerialization.data(fromPropertyList: ["save": "speichern", "DNA": "DNA", "LifeBridge information": "LifeBridge Informationen"],
            format: .binary, options: 0).write(to: folder.appendingPathComponent("Localizable.strings"))
        let bundle = try XCTUnwrap(Bundle(url: directory))
        let runtime = ControlLabelFixtureRuntime(fail: true)
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        for (source, expected) in [("save", "speichern"), ("DNA", "DNA"), ("LifeBridge information", "LifeBridge Informationen")] {
            let key = Key(source: source, language: .german)
            await state.resolve(key, inferenceAllowed: false, bundle: bundle)
            XCTAssertEqual(state.presentation(for: key).text, expected)
            XCTAssertEqual(state.presentation(for: key).status, .catalog)
        }
        let count = await runtime.calls
        XCTAssertEqual(count, 0)
    }

    func testSourceAndBlankLabelsNeverInvokeInference() async {
        let runtime = ControlLabelFixtureRuntime()
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        for key in [Key(source: "save", language: .english), Key(source: " \n", language: .german)] {
            await state.resolve(key, inferenceAllowed: true)
            XCTAssertEqual(state.presentation(for: key).text, key.source)
            XCTAssertEqual(state.presentation(for: key).status, .source)
        }
        let count = await runtime.calls
        XCTAssertEqual(count, 0)
    }
    func testBrandNamesCannotDisappearFromAnAcceptedControlLabel() async {
        let runtime = ControlLabelFixtureRuntime()
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        for brand in ["Fruitfolio", "LifeBridge"] {
            let key = Key(source: "open " + brand, language: .german)
            await state.resolve(key, inferenceAllowed: true)
            XCTAssertEqual(state.presentation(for: key).text, key.source)
            XCTAssertEqual(state.presentation(for: key).status, .unavailable)
        }
    }

    func testUnresolvedLanguageCannotDisplayPreviousTranslation() async {
        let runtime = ControlLabelFixtureRuntime()
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        let german = Key(source: "save", language: .german)
        await state.resolve(german, inferenceAllowed: true)
        XCTAssertEqual(state.presentation(for: german).text, "fixture output")
        XCTAssertEqual(state.presentation(for: german).status, .machine)
        let changed = Key(source: "save", language: .spanish)
        XCTAssertEqual(state.presentation(for: changed).text, "save")
        XCTAssertEqual(state.presentation(for: changed).status, .preparing)
        let source = Key(source: "delete", language: .german)
        XCTAssertEqual(state.presentation(for: source).text, "delete")
    }
    func testUnavailableAndPausedLabelsRetainTheirOriginalText() async {
        for fail in [false, true] {
            let runtime = ControlLabelFixtureRuntime(fail: fail)
            let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
            let key = Key(source: "save", language: .german)
            await state.resolve(key, inferenceAllowed: fail)
            XCTAssertEqual(state.presentation(for: key).text, "save")
            XCTAssertEqual(state.presentation(for: key).status, .unavailable)
            let count = await runtime.calls
            XCTAssertEqual(count, fail ? 1 : 0)
        }
    }
    func testAcceptedDisplaySurvivesMemoryReleasePauseWithoutRepeatedInference() async {
        let runtime = ControlLabelFixtureRuntime()
        let service = FruitfolioTranslationService(runtime: runtime)
        let state = FruitfolioControlTranslationState(service: service)
        let key = Key(source: "save", language: .german)
        await state.resolve(key, inferenceAllowed: true)
        await service.releaseResources()
        await state.resolve(key, inferenceAllowed: false)
        XCTAssertEqual(state.presentation(for: key).text, "fixture output")
        XCTAssertEqual(state.presentation(for: key).status, .machine)
        let count = await runtime.calls
        XCTAssertEqual(count, 1)
    }
    func testLateOldLanguageOrSourceCannotReplaceCurrentLabel() async {
        for changeLanguage in [false, true] {
            let runtime = ControlLabelFixtureRuntime(holdFirst: true)
            let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
            let old = Key(source: "older", language: .german)
            let new = Key(source: changeLanguage ? "older" : "newer", language: changeLanguage ? .spanish : .german)
            let task = Task { await state.resolve(old, inferenceAllowed: true) }
            await runtime.waitForHeldCall()
            await state.resolve(new, inferenceAllowed: true)
            await runtime.finishHeld()
            await task.value
            XCTAssertEqual(state.presentation(for: new).text, "fixture output")
            XCTAssertEqual(state.presentation(for: new).status, .machine)
            XCTAssertEqual(state.presentation(for: old).text, old.source)
        }
    }
    func testCancelledLateResultCannotBecomeAcceptedDisplay() async {
        let runtime = ControlLabelFixtureRuntime(holdFirst: true)
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        let key = Key(source: "save", language: .german)
        let task = Task { await state.resolve(key, inferenceAllowed: true) }
        await runtime.waitForHeldCall()
        task.cancel()
        await runtime.finishHeld()
        await task.value
        XCTAssertEqual(state.presentation(for: key).text, "save")
        XCTAssertEqual(state.presentation(for: key).status, .preparing)
        await state.resolve(key, inferenceAllowed: true)
        XCTAssertEqual(state.presentation(for: key).status, .machine)
    }
}
