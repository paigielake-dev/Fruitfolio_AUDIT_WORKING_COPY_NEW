#if DEBUG
import Foundation
#if canImport(Combine)
import Combine
#endif

/// A failure boundary around the real file codec, confined to disposable QA data.
private actor Prompt1BCycleModalOnboardingBoundary: Prompt14OnboardingPersistence {
    private let file: Prompt14FileOnboardingPersistence
    private var remainingFailures: Int
    init(fileURL: URL, failures: Int) {
        file = Prompt14FileOnboardingPersistence(fileURL: fileURL)
        remainingFailures = failures
    }
    func load() async throws -> Prompt14OnboardingDraft { try await file.load() }
    func save(_ draft: Prompt14OnboardingDraft) async throws {
        if remainingFailures > 0 {
            remainingFailures -= 1
            throw Prompt14OnboardingPersistenceError.unavailable
        }
        try await file.save(draft)
    }
    func erase() async throws { try await file.erase() }
}

@MainActor
private final class Prompt1BCycleModalFixture {
    let directory: URL
    let dailyURL: URL
    let onboardingURL: URL
    let owner = Prompt20DailyLogOwnerID(rawValue: "disposable-cycle-modal-fixture")
    let selectedDate = Date().addingTimeInterval(-86_400)
    let calendar: Calendar
    let daily: Prompt20CycleDailyLogStore
    let onboarding: Prompt14CycleOnboardingStore
    let scenario: String
    #if canImport(Combine)
    @Published
    #endif
    var ready = false
    #if canImport(Combine)
    @Published
    #endif
    var didExit = false
    #if canImport(Combine)
    @Published
    #endif
    var error: String?
    #if canImport(Combine)
    @Published
    #endif
    var savedNote = "not read"
    #if canImport(Combine)
    @Published
    #endif
    var savedMedicationCount = "not read"
    #if canImport(Combine)
    @Published
    #endif
    var savedContextCount = "not read"

    init() {
        let args = ProcessInfo.processInfo.arguments
        let index = args.firstIndex(of: "-fruitfolioCycleModalQAScenario")
        scenario = index.flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil } ?? "daily-notes"
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("fruitfolio-cycle-modal-" + UUID().uuidString, isDirectory: true)
        dailyURL = directory.appendingPathComponent("daily.json")
        onboardingURL = directory.appendingPathComponent("onboarding.json")
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        daily = Prompt20CycleDailyLogStore(fileURL: dailyURL, calendar: gregorian)
        let boundary = Prompt1BCycleModalOnboardingBoundary(fileURL: onboardingURL, failures: scenario == "onboarding-retry" ? 1 : Int.max)
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: directory.appendingPathComponent("cycle.json")))
        onboarding = Prompt14CycleOnboardingStore(persistence: boundary, cycleStore: cycle)
    }

    func prepare() async {
        guard !ready else { return }
        do {
            if scenario == "prediction-sign" { ready = true; return }
            if scenario.hasPrefix("daily-") {
                var draft = Prompt20DailyLogDraft()
                draft.generalNote = "original fixture note"
                if scenario == "daily-medication" {
                    var entry = Prompt20MedicationEntry()
                    entry.name = "fixture medication"
                    entry.dose = "fixture recorded dose"
                    draft.medications = [entry]
                }
                _ = try await daily.save(ownerID: owner, date: .init(date: selectedDate, calendar: calendar), draft: draft, now: selectedDate)
            } else {
                try await Prompt14FileOnboardingPersistence(fileURL: onboardingURL).save(Prompt14OnboardingDraft())
            }
            ready = true
        } catch { self.error = error.localizedDescription }
    }

    func readActualSavedFilesAfterExit() async {
        didExit = true
        do {
            if scenario.hasPrefix("daily-") {
                let fresh = Prompt20CycleDailyLogStore(fileURL: dailyURL, calendar: calendar)
                let log = try await fresh.load(ownerID: owner, date: .init(date: selectedDate, calendar: calendar))
                savedNote = log?.generalNote?.text ?? "none"
                savedMedicationCount = String(log?.medications.count ?? 0)
            } else {
                let draft = try await Prompt14FileOnboardingPersistence(fileURL: onboardingURL).load()
                savedContextCount = String(draft.cycleAffectingContexts.count)
            }
            try FileManager.default.removeItem(at: directory)
        } catch { self.error = error.localizedDescription }
    }
    deinit { try? FileManager.default.removeItem(at: directory) }
}

#if canImport(Combine)
extension Prompt1BCycleModalFixture: ObservableObject {}
#endif

#if canImport(SwiftUI)
import SwiftUI

/// DEBUG route only: real feature views, stores and modal host, no production
/// health records or preferences. Acknowledged status reopens the actual files.
struct Prompt1BCycleModalRegressionHarness: View {
    @StateObject private var fixture = Prompt1BCycleModalFixture()
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var contextStore: Prompt27AContextStore
    @EnvironmentObject private var coordinator: PopupCoordinator
    @State private var predictionOwner: FruitfolioOwnedPopupSession?
    @State private var predictionScope = UUID()
    @State private var predictionVisible = false
    @State private var didShowPrediction = false
    @State private var predictionClosed = false
    @AccessibilityFocusState private var predictionFocused: Bool
    @State private var dailyPresented = false
    @State private var didPresentDaily = false

    var body: some View {
        Group {
            if let error = fixture.error {
                Text(error).accessibilityIdentifier("cycleModalQA.error")
            } else if !fixture.ready {
                ProgressView().accessibilityLabel("Preparing disposable cycle fixture")
            } else if fixture.scenario == "prediction-sign" {
                VStack(spacing: 16) {
                    FruitfolioControlPillButton(label: "open prediction explanation") { presentPredictionFixture() }
                        .accessibilityFocused($predictionFocused)
                        .accessibilityIdentifier("cycleModalQA.predictionInfo")
                    Text(predictionClosed ? "prediction explanation closed" : "prediction fixture ready")
                        .accessibilityIdentifier("cycleModalQA.predictionStatus")
                }
            } else if fixture.scenario.hasPrefix("onboarding-") && !fixture.didExit {
                Prompt14CycleOnboardingView(store: fixture.onboarding) {
                    Task { await fixture.readActualSavedFilesAfterExit() }
                }
            } else {
                VStack(spacing: 12) {
                    Text(fixture.didExit ? "feature exited" : "disposable cycle fixture")
                        .accessibilityIdentifier("cycleModalQA.status")
                    Text(fixture.savedNote).accessibilityIdentifier("cycleModalQA.savedNote")
                    Text(fixture.savedMedicationCount).accessibilityIdentifier("cycleModalQA.savedMedicationCount")
                    Text(fixture.savedContextCount).accessibilityIdentifier("cycleModalQA.savedContextCount")
                }
            }
        }
        .environment(\.layoutDirection, ProcessInfo.processInfo.arguments.contains("-fruitfolioCycleModalRTL") ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $dailyPresented, onDismiss: {
            Task { await fixture.readActualSavedFilesAfterExit() }
        }) {
            FruitfolioPresentedPopupHost {
                Prompt20DailyLogView(ownerID: fixture.owner, selectedDate: fixture.selectedDate,
                    repository: fixture.daily, calendar: fixture.calendar,
                    initialExpandedSection: fixture.scenario == "daily-medication" ? .medication : .notes)
            }
            .environment(\.layoutDirection, ProcessInfo.processInfo.arguments.contains("-fruitfolioCycleModalRTL") ? .rightToLeft : .leftToRight)
        }
        .onAppear {
            predictionVisible = true
            if predictionOwner == nil { predictionOwner = FruitfolioOwnedPopupSession(coordinator: coordinator) }
        }
        .onDisappear {
            predictionVisible = false
            predictionOwner?.cancel()
        }
        .onChange(of: coordinator.currentPopup?.id) { _, _ in
            predictionOwner?.observeDismissal()
            guard predictionVisible, didShowPrediction, predictionOwner?.requestID == nil, coordinator.currentPopup == nil else { return }
            predictionClosed = true
            predictionFocused = true
            didShowPrediction = false
        }
        .task {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioCycleModalReduceMotion")
            await Task.yield()
            if fixture.scenario.hasPrefix("onboarding-") {
                // The shell supplies a disposable context/preferences suite for
                // this registered route. Actual shared-context merge triggers
                // the controlled first-save failure in the production editor.
                contextStore.setContraceptionContext(.hormonalContraception)
            }
            await fixture.prepare()
            if fixture.ready, fixture.scenario.hasPrefix("daily-"), !didPresentDaily {
                didPresentDaily = true
                dailyPresented = true
            }
        }
    }
    private func presentPredictionFixture() {
        guard predictionVisible, let owner = predictionOwner else { return }
        didShowPrediction = true
        predictionClosed = false
        predictionFocused = false
        owner.present { id in
            Prompt16PredictionPopupRequest.make(info: .init(title: "disposable prediction explanation fixture",
                body: String(repeating: "This is disposable fixture text for checking scroll and layout. It supplies no clinical advice or measurements. ", count: 8),
                progress: "The actual request factory preserves its original title, body and progress copy."),
                id: id, scope: predictionScope) {
                    guard predictionVisible else { return }
                    _ = owner.consumeAction(for: id)
                }
        }
    }

}
#endif
#endif
