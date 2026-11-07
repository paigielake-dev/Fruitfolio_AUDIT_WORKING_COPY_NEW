import Foundation
import XCTest
#if canImport(Combine)
import Combine
#endif
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

/// Explicit release scheduling fixture, not native or learned model output.
private actor LifecycleTranslationFixture: FruitfolioLocalTranslationRuntime {
    private var calls = 0
    private var releases = 0
    private var gates: [Int: CheckedContinuation<Void, Never>] = [:]
    private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []
    func translate(_ text: String, targetTag: String) async throws -> String {
        calls += 1
        return text
    }
    func releaseResources() async {
        releases += 1
        let index = releases
        await withCheckedContinuation { continuation in
            gates[index] = continuation
            let ready = waiters.filter { $0.0 <= releases }
            waiters.removeAll { $0.0 <= releases }
            for (_, waiter) in ready { waiter.resume() }
        }
    }
    func waitForRelease(_ count: Int = 1) async {
        if releases >= count { return }
        await withCheckedContinuation { waiters.append((count, $0)) }
    }
    func finishReleases() {
        let pending = Array(gates.values); gates.removeAll()
        for gate in pending { gate.resume() }
    }
    func counts() -> (calls: Int, releases: Int) { (calls, releases) }
}

@MainActor
final class Prompt1BControlTranslationStateTests: XCTestCase {
    private typealias Key = FruitfolioControlTranslationState.Key
    private func lifecycleSettings() throws -> (SettingsStore, String) {
        let suite = "fruitfolio.tests.translationLifecycle." + UUID().uuidString
        return (SettingsStore(defaults: try XCTUnwrap(UserDefaults(suiteName: suite))), suite)
    }

    func testLifecycleServiceRejectsAdmissionAndPrematureResumeUntilReleaseAcknowledges() async throws {
        let runtime = LifecycleTranslationFixture()
        let service = FruitfolioTranslationService(runtime: runtime)
        let token = UUID()
        let release = Task { await service.suspendForLifecycle(token) }
        await runtime.waitForRelease()
        let premature = await service.resumeAfterLifecycle(token)
        XCTAssertFalse(premature)
        do {
            _ = try await service.translate("original", language: .german, preferCatalog: false)
            XCTFail("Inactive service admitted inference")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .pausedForLifecycle) }
        let blocked = await runtime.counts()
        XCTAssertEqual(blocked.calls, 0)
        await runtime.finishReleases()
        await release.value
        let resumed = await service.resumeAfterLifecycle(token)
        XCTAssertTrue(resumed)
        let result = try await service.translate("original", language: .german, preferCatalog: false)
        XCTAssertEqual(result, "original")
    }

    func testSupersededLifecycleReleaseCannotReopenNewerSuspension() async throws {
        let runtime = LifecycleTranslationFixture()
        let service = FruitfolioTranslationService(runtime: runtime)
        let old = UUID(), current = UUID()
        let first = Task { await service.suspendForLifecycle(old) }
        await runtime.waitForRelease()
        let second = Task { await service.suspendForLifecycle(current) }
        await runtime.waitForRelease(2)
        await runtime.finishReleases()
        await first.value; await second.value
        let stale = await service.resumeAfterLifecycle(old)
        XCTAssertFalse(stale)
        do {
            _ = try await service.translate("original", language: .german, preferCatalog: false)
            XCTFail("Superseded token reopened admission")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .pausedForLifecycle) }
        let accepted = await service.resumeAfterLifecycle(current)
        XCTAssertTrue(accepted)
    }

    func testLifecycleOwnerHandlesForegroundDuringReleaseAndPreservesMemoryPause() async throws {
        let (settings, suite) = try lifecycleSettings()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let runtime = LifecycleTranslationFixture()
        let owner = FruitfolioTranslationLifecycleOwner(settings: settings, service: .init(runtime: runtime))
        settings.translationPausedForMemoryPressure = true
        owner.setActive(true)
        await owner.debugWaitForReconciliation()
        XCTAssertFalse(settings.translationPausedForLifecycle)
        XCTAssertFalse(settings.translationInferenceAllowed)
        owner.setActive(false)
        await runtime.waitForRelease()
        owner.setActive(true)
        XCTAssertTrue(settings.translationPausedForLifecycle)
        await runtime.finishReleases()
        await owner.debugWaitForReconciliation()
        XCTAssertFalse(settings.translationPausedForLifecycle)
        XCTAssertTrue(settings.translationPausedForMemoryPressure)
        XCTAssertFalse(settings.translationInferenceAllowed)
        settings.translationPausedForMemoryPressure = false
        XCTAssertTrue(settings.translationInferenceAllowed)
        owner.setActive(false)
        await runtime.waitForRelease(2)
        owner.setActive(true); owner.setActive(false)
        await runtime.finishReleases()
        await owner.debugWaitForReconciliation()
        XCTAssertTrue(settings.translationPausedForLifecycle)
        XCTAssertFalse(settings.translationInferenceAllowed)
        owner.setActive(true)
        await owner.debugWaitForReconciliation()
        XCTAssertTrue(settings.translationInferenceAllowed)
        let counts = await runtime.counts()
        XCTAssertEqual(counts.releases, 2)
    }

    func testRecreatedShellRecoversAnAcknowledgedSuspensionWithoutTheOldOwnerToken() async throws {
        let runtime = LifecycleTranslationFixture()
        let service = FruitfolioTranslationService(runtime: runtime)
        let oldToken = UUID()
        let oldRelease = Task { await service.suspendForLifecycle(oldToken) }
        await runtime.waitForRelease()
        await runtime.finishReleases()
        await oldRelease.value
        let (settings, suite) = try lifecycleSettings()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let replacement = FruitfolioTranslationLifecycleOwner(settings: settings, service: service)
        replacement.setActive(true)
        await runtime.waitForRelease(2)
        XCTAssertTrue(settings.translationPausedForLifecycle)
        let stale = await service.resumeAfterLifecycle(oldToken)
        XCTAssertFalse(stale)
        await runtime.finishReleases()
        await replacement.debugWaitForReconciliation()
        XCTAssertTrue(settings.translationInferenceAllowed)
        let result = try await service.translate("original", language: .german, preferCatalog: false)
        XCTAssertEqual(result, "original")
    }

    func testAcceptedControlSurvivesReleaseAndUnresolvedKeyRetriesAfterAcknowledgement() async throws {
        let (settings, suite) = try lifecycleSettings()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let runtime = LifecycleTranslationFixture()
        let service = FruitfolioTranslationService(runtime: runtime)
        let owner = FruitfolioTranslationLifecycleOwner(settings: settings, service: service)
        owner.setActive(true)
        await owner.debugWaitForReconciliation()
        let accepted = FruitfolioControlTranslationState(service: service)
        let key = Key(source: "hello", language: .german)
        await accepted.resolve(key, inferenceAllowed: settings.translationInferenceAllowed)
        XCTAssertEqual(accepted.presentation(for: key).status, .machine)
        owner.setActive(false)
        await runtime.waitForRelease()
        await accepted.resolve(key, inferenceAllowed: settings.translationInferenceAllowed)
        XCTAssertEqual(accepted.presentation(for: key).status, .machine)
        XCTAssertEqual(accepted.presentation(for: key).text, "hello")
        let unresolved = FruitfolioControlTranslationState(service: service)
        let next = Key(source: "save", language: .german)
        await unresolved.resolve(next, inferenceAllowed: settings.translationInferenceAllowed)
        XCTAssertEqual(unresolved.presentation(for: next).text, "save")
        XCTAssertEqual(unresolved.presentation(for: next).status, .unavailable)
        let before = await runtime.counts()
        XCTAssertEqual(before.calls, 1)
        owner.setActive(true)
        await runtime.finishReleases()
        await owner.debugWaitForReconciliation()
        await unresolved.resolve(next, inferenceAllowed: settings.translationInferenceAllowed)
        XCTAssertEqual(unresolved.presentation(for: next).status, .machine)
        let after = await runtime.counts()
        XCTAssertEqual(after.calls, 2)
    }

    #if canImport(Combine)
    func testActualCombinePublisherAnnouncesResolvedControlDisplay() async {
        let runtime = ControlLabelFixtureRuntime()
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        var notifications = 0
        let observation = state.objectWillChange.sink { notifications += 1 }
        defer { observation.cancel() }
        let key = Key(source: "save", language: .german)
        await state.resolve(key, inferenceAllowed: true)
        XCTAssertGreaterThan(notifications, 0)
        XCTAssertEqual(state.presentation(for: key).text, "fixture output")
    }
    #endif
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
        let service = FruitfolioTranslationService(runtime: runtime)
        await service.suspendForLifecycle(UUID())
        let state = FruitfolioControlTranslationState(service: service)
        for (source, expected) in [("save", "speichern"), ("DNA", "DNA"), ("LifeBridge information", "LifeBridge Informationen")] {
            let key = Key(source: source, language: .german, protectedLiterals: source == "DNA" ? ["DNA"] : [])
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
    func testIndependentNavigationTitleAndDetailKeepTheirOwnResults() async {
        for cancelTitle in [false, true] {
            let runtime = ControlLabelFixtureRuntime(holdFirst: true)
            let service = FruitfolioTranslationService(runtime: runtime)
            let title = FruitfolioControlTranslationState(service: service)
            let detail = FruitfolioControlTranslationState(service: service)
            let titleKey = Key(source: "open", language: .german)
            let detailKey = Key(source: "details", language: .german)
            let task = Task { await title.resolve(titleKey, inferenceAllowed: true) }
            await runtime.waitForHeldCall()
            await detail.resolve(detailKey, inferenceAllowed: true)
            if cancelTitle { task.cancel() }
            await runtime.finishHeld()
            await task.value
            XCTAssertEqual(detail.presentation(for: detailKey).text, "fixture output")
            XCTAssertEqual(detail.presentation(for: detailKey).status, .machine)
            XCTAssertEqual(title.presentation(for: titleKey).text, cancelTitle ? "open" : "older fixture output")
            let pausedDetail = Key(source: "new details", language: .german)
            await detail.resolve(pausedDetail, inferenceAllowed: false)
            XCTAssertEqual(detail.presentation(for: pausedDetail).text, "new details")
            XCTAssertEqual(detail.presentation(for: pausedDetail).status, .unavailable)
            XCTAssertEqual(title.presentation(for: titleKey).text, cancelTitle ? "open" : "older fixture output")
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
    func testChangingProtectedLiteralsInvalidatesAcceptedCompactDisplay() async {
        let runtime = ControlLabelFixtureRuntime()
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        let original = Key(source: "alpha label", language: .german)
        await state.resolve(original, inferenceAllowed: true)
        XCTAssertEqual(state.presentation(for: original).status, .machine)
        let protected = Key(source: original.source, language: original.language, protectedLiterals: ["alpha"])
        XCTAssertNotEqual(original, protected)
        XCTAssertEqual(state.presentation(for: protected).text, protected.source)
        XCTAssertEqual(state.presentation(for: protected).status, .preparing)
        await state.resolve(protected, inferenceAllowed: true)
        XCTAssertEqual(state.presentation(for: protected).status, .unavailable)
        XCTAssertEqual(state.presentation(for: protected).text, protected.source)
        let calls = await runtime.calls
        XCTAssertEqual(calls, 2, "A prior accepted display cannot bypass changed caller protection")
    }

    func testExplicitHormoneAbbreviationsCannotDisappearFromCompactOutput() async {
        let runtime = ControlLabelFixtureRuntime()
        let state = FruitfolioControlTranslationState(service: .init(runtime: runtime))
        for hormone in [FruitfolioMeasuredHormone.estradiol, .lh, .fsh, .amh] {
            let key = Key(source: hormone.label, language: .french, protectedLiterals: hormone.protectedAbbreviations)
            XCTAssertFalse(key.protectedLiterals.isEmpty)
            await state.resolve(key, inferenceAllowed: true)
            XCTAssertEqual(state.presentation(for: key).status, .unavailable, "Fixture output omits the protected symbol and must be rejected")
            XCTAssertEqual(state.presentation(for: key).text, hormone.label)
        }
    }

}
