#if DEBUG
import Foundation
#if canImport(Combine)
import Combine
#endif

/// Unrelated StoreKit verification stays explicitly unavailable in this fixture;
/// it never inspects a real receipt or supplies a fabricated verified result.
private nonisolated struct Prompt12AccountQAOwnershipUnavailable: FruitfolioOwnershipVerifying {
    func verify(expectedBundleIdentifier: String) async -> FruitfolioOwnershipVerification { .unavailable }
}

/// Refuses only selected account writes; all normal I/O is actual private-suite
/// UserDefaults. It does not emulate a configured account/cloud service.
private final class Prompt12AccountQADefaults: UserDefaults {
    var rejectAccountWrites = false
    override func set(_ value: Any?, forKey key: String) {
        if rejectAccountWrites && key == "fixture.account" { return }
        super.set(value, forKey: key)
    }
}

@MainActor
final class Prompt12AccountActionFixture {
    let suite = "Fruitfolio.accountActionQA." + UUID().uuidString
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("fruitfolio-account-action-" + UUID().uuidString, isDirectory: true)
    private let defaults: Prompt12AccountQADefaults
    let store: Prompt12AccountPrivacyStore
    let username: FruitfolioUsernameStore
    let cycle: Prompt13CycleStore
    let scenario: String
    private var originalCycleData: Data?
    private var comparisonAccountData: Data?
    private var injectedReplacement = false
    #if canImport(Combine)
    @Published
    #endif
    var ready = false
    #if canImport(Combine)
    @Published
    #endif
    var error: String?
    #if canImport(Combine)
    @Published
    #endif
    var identity = "not read"
    #if canImport(Combine)
    @Published
    #endif
    var pending = "not read"
    #if canImport(Combine)
    @Published
    #endif
    var healthFileUnchanged = "not read"
    #if canImport(Combine)
    @Published
    #endif
    var accountRecordUnchanged = "not read"

    init() {
        let args = ProcessInfo.processInfo.arguments
        let index = args.firstIndex(of: "-fruitfolioAccountActionQAScenario")
        scenario = index.flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil } ?? "sign-out"
        defaults = Prompt12AccountQADefaults(suiteName: suite)!
        store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture.account",
            ownershipVerifier: Prompt12AccountQAOwnershipUnavailable(), expectedBundleIdentifier: "fixture.account.action")
        username = FruitfolioUsernameStore(defaults: defaults, key: "fixture.username")
        cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: directory.appendingPathComponent("cycle.json")))
    }

    func prepare() async {
        guard !ready else { return }
        do {
            // Explicitly local DEBUG identity, not real authentication.
            try store.signInForDevelopment(email: "fixture-a@example.invalid")
            store.markLocalChangePending()
            let cycleURL = directory.appendingPathComponent("cycle.json")
            let day = try Prompt13LocalDate(Date().addingTimeInterval(-86_400), calendar: Calendar(identifier: .gregorian))
            _ = try await cycle.recordNote(on: day, text: "disposable account fixture observation", today: day)
            originalCycleData = try Data(contentsOf: cycleURL)
            comparisonAccountData = defaults.data(forKey: "fixture.account")
            defaults.rejectAccountWrites = scenario == "rejected-write"
            captureActualState()
            ready = true
        } catch { self.error = error.localizedDescription }
    }

    func replaceIdentityWhileConfirmationIsOpen() {
        guard scenario == "stale-sign-out", !injectedReplacement else { return }
        injectedReplacement = true
        do {
            try store.signInForDevelopment(email: "fixture-b@example.invalid")
            store.markLocalChangePending()
            comparisonAccountData = defaults.data(forKey: "fixture.account")
            captureActualState()
        } catch { self.error = error.localizedDescription }
    }

    func captureActualState() {
        identity = store.account?.email ?? "none"
        pending = store.pendingLocalChanges ? "yes" : "no"
        let actualCycle = try? Data(contentsOf: directory.appendingPathComponent("cycle.json"))
        healthFileUnchanged = actualCycle != nil && actualCycle == originalCycleData ? "yes" : "no"
        accountRecordUnchanged = defaults.data(forKey: "fixture.account") == comparisonAccountData ? "yes" : "no"
    }
    func cleanUp() {
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: directory)
    }
    deinit {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: directory)
    }
}

#if canImport(Combine)
extension Prompt12AccountActionFixture: ObservableObject {}
#endif

#if canImport(SwiftUI)
import SwiftUI

/// Registered private-shell DEBUG route. Actual AccountView with private account
/// and username stores; confirmation actions never call a real remote service.
struct Prompt12AccountActionRegressionHarness: View {
    @StateObject private var fixture = Prompt12AccountActionFixture()
    @EnvironmentObject private var coordinator: PopupCoordinator
    @EnvironmentObject private var settings: SettingsStore
    @State private var visible = false
    @State private var backRequests = 0
    @State private var privacyRequests = 0
    @State private var exportRequests = 0
    var body: some View {
        Group {
            if let error = fixture.error {
                Text(error).accessibilityIdentifier("accountQA.error")
            } else if fixture.ready {
                VStack(spacing: 4) {
                    Text("disposable local account fixture — no remote authentication")
                        .font(.system(size: 9)).dynamicTypeSize(.xSmall).accessibilityIdentifier("accountQA.fixture")
                    Prompt12AccountView(store: fixture.store, onBack: { backRequests += 1 }, onShowPrivacy: { privacyRequests += 1 },
                        usernameStore: fixture.username, onShowDataExport: { exportRequests += 1 })
                    HStack {
                        Text(fixture.identity).accessibilityIdentifier("accountQA.identity")
                        Text(fixture.pending).accessibilityIdentifier("accountQA.pending")
                        Text(fixture.healthFileUnchanged).accessibilityIdentifier("accountQA.healthUnchanged")
                        Text(fixture.accountRecordUnchanged).accessibilityIdentifier("accountQA.recordUnchanged")
                    }
                    .font(.system(size: 9)).dynamicTypeSize(.xSmall)
                    Text("back requests: \(backRequests)")
                        .font(.system(size: 9)).dynamicTypeSize(.xSmall).accessibilityIdentifier("accountQA.backRequests")
                    Text("privacy requests: \(privacyRequests)")
                        .font(.system(size: 9)).dynamicTypeSize(.xSmall).accessibilityIdentifier("accountQA.privacyRequests")
                    Text("export requests: \(exportRequests)")
                        .font(.system(size: 9)).dynamicTypeSize(.xSmall).accessibilityIdentifier("accountQA.exportRequests")
                    Text(fixture.username.username.isEmpty ? "empty private username" : "private username set")
                        .font(.system(size: 9)).dynamicTypeSize(.xSmall).accessibilityIdentifier("accountQA.username")
                }
            } else { ProgressView().accessibilityLabel("Preparing disposable account fixture") }
        }
        .environment(\.layoutDirection, ProcessInfo.processInfo.arguments.contains("-fruitfolioAccountActionRTL") ? .rightToLeft : .leftToRight)
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .onChange(of: coordinator.currentPopup?.id) { _, id in
            if id != nil, coordinator.currentPopup?.source == "account-sign-out" {
                fixture.replaceIdentityWhileConfirmationIsOpen()
            } else if id == nil {
                Task { @MainActor in
                    await Task.yield()
                    guard visible, !Task.isCancelled else { return }
                    fixture.captureActualState()
                }
            }
        }
        .task {
            settings.language = .english
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioAccountActionReduceMotion")
            await Task.yield()
            await fixture.prepare()
        }
    }
}
#endif
#endif
