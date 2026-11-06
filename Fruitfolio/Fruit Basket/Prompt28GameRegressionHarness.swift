#if DEBUG
import SwiftUI

/// Nonclinical UI fixtures only, inside the real root environment. All game and
/// username writes use this disposable suite, never the user's standard store.
@MainActor
private final class Prompt28GameRegressionFixture: ObservableObject {
    let model: Prompt28FruitBasketViewModel
    let username: FruitfolioUsernameStore
    let library: Prompt10SavedLibraryStore
    private let defaults: UserDefaults
    private let suite = "Fruitfolio.gameUIQA." + UUID().uuidString
    init() {
        defaults = UserDefaults(suiteName: suite)!
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let args = ProcessInfo.processInfo.arguments
        let scenarioIndex = args.firstIndex(of: "-fruitfolioGameQAScenario")
        let isTour = scenarioIndex.map { $0 + 1 < args.count && args[$0 + 1] == "tour" } ?? false
        if !isTour { store.completeTour() }
        store.controlMode = .classification
        store.persistPreferences()
        model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        if let index = args.firstIndex(of: "-fruitfolioGameQAScenario"), index + 1 < args.count,
           args[index + 1] == "leaderboard-username-future" {
            defaults.set(Data(#"{"schemaVersion":3,"username":"future_berry","confirmedNonIdentifying":true,"future":null}"#.utf8),
                forKey: FruitfolioUsernamePersistence.recordKey())
        }
        username = FruitfolioUsernameStore(defaults: defaults)
        library = Prompt10SavedLibraryStore(defaults: defaults)
    }
    deinit {
        // A transient disappearance/background event does not end this fixture.
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }
}

struct Prompt28GameRegressionHarness: View {
    @StateObject private var fixture = Prompt28GameRegressionFixture()
    @State private var configured = false
    @State private var backRequests = 0
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audioManager: AudioManager
    private var model: Prompt28FruitBasketViewModel { fixture.model }
    private var scenario: String {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-fruitfolioGameQAScenario"), index + 1 < arguments.count {
            return arguments[index + 1]
        }
        return "good"
    }

    var body: some View {
        Prompt28FruitBasketView(onBack: { backRequests += 1 }, regressionModel: model, usernameStore: fixture.username, libraryStore: fixture.library)
            .overlay(alignment: .bottomLeading) {
                Prompt28GameDiagnosticReadback(model: model, store: model.store, backRequests: backRequests)
                .font(.caption2)
                .allowsHitTesting(false)
            }
            .task {
                guard !configured else { return }
                configured = true
                let args = ProcessInfo.processInfo.arguments
                if let index = args.firstIndex(of: "-fruitfolioGameQALanguage"), index + 1 < args.count,
                   let language = FruitfolioLanguage(rawValue: args[index + 1]) {
                    settings.language = language
                } else { settings.language = .english }
                if args.contains("-fruitfolioAudioDiagnostics") {
                    settings.globallyMuted = args.contains("-fruitfolioAudioMuted")
                    settings.soundEffectsEnabled = true
                    settings.soundEffectsVolume = 0.5
                    audioManager.debugRecordInteractions(true)
                }
                settings.translationPausedForMemoryPressure = args.contains("-fruitfolioGameQAPauseInference")
                settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioGameReduceMotion")
                configure()
            }
    }

    private func configure() {
        if scenario == "tour" { return } // Exercise the existing first-run overlay.
        if scenario == "setup" {
            model.rawTopic = "QA control layout fixture"
            model.openSetup()
            return
        }
        if scenario == "rules" { model.screen = .howItWorks; return }
        if scenario == "leaderboard" || scenario == "leaderboard-username-future" {
            model.screen = .leaderboard
            return
        }
        model.rawTopic = "QA visual fixture"
        let isExcerpt = ["question-excerpt", "question-excerpt-serious"].contains(scenario)
        model.currentQuestion = Prompt28Question(id: "qa-only", topicQuery: "QA visual fixture",
            normalizedTopic: "qa visual fixture", category: isExcerpt ? Prompt28ExcerptQuestionPresentation.category : "UI fixture — not medical research",
            educationalDifficulty: .easy, questionText: isExcerpt
                ? Prompt28ExcerptQuestionPresentation.prefix + "UI fixture only: the selected word is [blank]."
                : "UI fixture only: choose the first option.",
            answerOptions: [.init(id: "first", text: "first"), .init(id: "second", text: "second")], correctAnswerID: "first",
            explanation: "UI regression fixture only. This is not medical content.", sourceIDs: ["qa-only"],
            sourceTitles: ["UI fixture — not medical research"], catchConceptID: "visual-starred-fruit",
            catchRule: "starred fruit", goodFruitIDs: [.pear], badFruitIDs: [.lemon],
            contentVersion: "qa-only", reviewStatus: "test-only", createdAt: Date(timeIntervalSince1970: 0),
            seriousFeedback: ["question-excerpt-serious", "failure-serious"].contains(scenario) ? true : nil)
        var session = model.engine.newSession(topic: model.rawTopic, normalizedTopic: "qa visual fixture",
            difficulty: .easy, startingLevel: scenario == "storm" ? 6 : 1)
        if scenario == "storm" { session.currentRound = 3 }
        model.session = session
        if isExcerpt { model.screen = .question; return }
        model.beginCatch()
        if scenario == "storm" { return } // Real screen-change observer presents the real storm modal.
        if scenario == "star" {
            model.classificationFruit = nil
            model.classificationStarAvailable = true
        } else if ["success", "failure", "failure-serious"].contains(scenario) {
            let count = scenario == "success" ? model.engine.rules.goodFruitTarget : 7
            for _ in 0..<count { catchFruit(.pear, classification: .good) }
            if scenario == "failure" || scenario == "failure-serious" { catchFruit(.lemon, classification: .bad) }
            model.sceneBecameInactive() // Deterministically completes the real queued result.
        } else {
            model.classificationStarAvailable = false
            model.classificationFruit = fruit(.pear, classification: .good)
        }
    }
    private func fruit(_ id: Prompt28FruitID, classification: Prompt28FruitClassification) -> Prompt28FallingFruit {
        .init(fruitID: id, classification: classification, x: 0.5, y: 0.5, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)
    }
    private func catchFruit(_ id: Prompt28FruitID, classification: Prompt28FruitClassification) {
        model.classificationStarAvailable = false
        model.classificationFruit = fruit(id, classification: classification)
        model.classificationDecision(accept: true)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
    }
}
/// Observe the actual model/store, not merely their enclosing fixture owner.
/// Readback must follow result creation/retry and acknowledge real store state.
@MainActor
private struct Prompt28GameDiagnosticReadback: View {
    @ObservedObject var model: Prompt28FruitBasketViewModel
    @ObservedObject var store: Prompt28FruitBasketStore
    let backRequests: Int
    var body: some View {
        if store.tourState.hasCompletedTour {
        VStack(alignment: .leading) {
            Text("back requests: \(backRequests)")
                .accessibilityIdentifier("gameQA.backRequests")
            Text("tour completed: \(store.tourState.hasCompletedTour)")
                .accessibilityIdentifier("gameQA.tourCompleted")
            Text("game screen: \(String(describing: model.screen))")
                .accessibilityIdentifier("gameQA.screen")
            if let result = model.roundResult {
                Text("raw fruit count: \(result.caughtFruit.count) / \(result.targetFruit)")
                    .accessibilityIdentifier("gameQA.rawResultFruit")
            }
            Text("stored highest level: \(store.leaderboardTotals.highestLevel)")
                .accessibilityIdentifier("gameQA.storedHighestLevel")
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                FruitfolioInteractionSoundDiagnostics()
            }
        }
        }
    }
}
#endif
