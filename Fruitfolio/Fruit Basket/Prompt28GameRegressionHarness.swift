#if DEBUG
import SwiftUI

/// Nonclinical UI fixtures only, inside the real root environment. All game and
/// username writes use this disposable suite, never the user's standard store.
@MainActor
private final class Prompt28GameRegressionFixture: ObservableObject {
    let model: Prompt28FruitBasketViewModel
    let username: FruitfolioUsernameStore
    let library: Prompt10SavedLibraryStore
    let defaults: UserDefaults
    let protectedOriginal: Data?
    let recoveryToken = UUID().uuidString
    private let suite = "Fruitfolio.gameUIQA." + UUID().uuidString
    init() {
        defaults = UserDefaults(suiteName: suite)!
        let args = ProcessInfo.processInfo.arguments
        let scenarioIndex = args.firstIndex(of: "-fruitfolioGameQAScenario")
        let scenario = scenarioIndex.flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
        if ["protected-progress-top", "protected-progress-null"].contains(scenario ?? "") {
            do {
                let encoded = try JSONEncoder().encode(Prompt28PersistedGameState())
                var json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
                if scenario == "protected-progress-top" { json["future"] = ["keep": "fixture original"] }
                else {
                    var tour = json["tourState"] as! [String: Any]
                    tour["future"] = NSNull()
                    json["tourState"] = tour
                }
                let original = try JSONSerialization.data(withJSONObject: json)
                protectedOriginal = original
                defaults.set(original, forKey: "fruitfolio.prompt28.fruitBasket.v1")
            } catch { preconditionFailure("Unable to build the private game recovery fixture") }
        } else { protectedOriginal = nil }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let isTour = scenarioIndex.map { $0 + 1 < args.count && args[$0 + 1] == "tour" } ?? false
        if !store.isReadOnly {
            if !isTour { store.completeTour() }
            let isCatchLayout = scenarioIndex.map { $0 + 1 < args.count && ["hud-catch", "catch-objects"].contains(args[$0 + 1]) } ?? false
            store.controlMode = isCatchLayout ? .catchMode : .classification
            store.persistPreferences()
        }
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
    @State private var modalActive = false
    @State private var celebrationArtActive = false
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
            .onPreferenceChange(Prompt28GameOverlayVisibilityKey.self) { visible in
                modalActive = visible
            }
            .onPreferenceChange(Prompt28CelebrationArtVisibilityKey.self) { active in celebrationArtActive = active }
            .overlay(alignment: .bottomLeading) {
                if !modalActive {
                    VStack(alignment: .leading) {
                        Prompt28GameDiagnosticReadback(model: model, store: model.store, backRequests: backRequests)
                        Text("celebration art active: \(celebrationArtActive)")
                            .accessibilityIdentifier("gameQA.celebrationArtActive")
                        if let original = fixture.protectedOriginal {
                            Prompt28ProtectedGameBlobReadback(store: model.store, defaults: fixture.defaults,
                                expected: original, token: fixture.recoveryToken)
                        }
                    }.font(.caption2).allowsHitTesting(false)
                }
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
        if scenario.hasPrefix("protected-progress-") { return }
        if scenario == "tour" { return } // Exercise the existing first-run overlay.
        if scenario == "setup" {
            model.rawTopic = "QA control layout fixture"
            model.openSetup()
            return
        }
        if scenario == "home" { model.screen = .home; return }
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
            seriousFeedback: ["question-excerpt-serious", "failure-serious", "storm-serious", "good-serious", "success-serious"].contains(scenario) ? true : nil)
        let isStorm = ["storm", "storm-serious"].contains(scenario)
        let isReset = ["reset-paused", "reset-result"].contains(scenario)
        if isReset {
            model.store.updateProgress(.init(normalizedTopicID: model.normalizedTopic,
                currentGameLevel: 6, highestGameLevelReached: 8, totalFruitCaught: 20,
                totalStarsEarned: 3, bestScore: 90))
        }
        var session = model.engine.newSession(topic: model.rawTopic, normalizedTopic: "qa visual fixture",
            difficulty: .easy, startingLevel: (isStorm || isReset) ? 6 : 1)
        if isStorm { session.currentRound = 3 }
        model.session = session
        model.screen = .question
        if isExcerpt { return }
        if let question = model.currentQuestion {
            model.answer(question.correctAnswerID, expectedQuestionID: question.id)
            model.presentCatchIntro(expectedQuestionID: question.id)
            model.beginCatch(expectedQuestionID: question.id)
        }
        if isStorm { return } // Real screen-change observer presents the real storm modal.
        if scenario == "reset-paused" { model.pause(); return }
        if scenario == "reset-result" {
            for _ in 0..<model.engine.rules.goodFruitTarget { catchFruit(.pear, classification: .good) }
            model.sceneBecameInactive()
            return
        }
        if scenario == "star" {
            model.classificationFruit = nil
            model.classificationStarAvailable = true
        } else if ["success", "success-serious", "failure", "failure-serious"].contains(scenario) {
            let count = ["success", "success-serious"].contains(scenario) ? model.engine.rules.goodFruitTarget : 7
            for _ in 0..<count { catchFruit(.pear, classification: .good) }
            if scenario == "failure" || scenario == "failure-serious" { catchFruit(.lemon, classification: .bad) }
            model.sceneBecameInactive() // Deterministically completes the real queued result.
        } else {
            model.classificationStarAvailable = false
            model.classificationFruit = fruit(.pear, classification: .good)
        }
        if scenario == "catch-objects" {
            // Actual render records held by the real frame guard: layout/AX only.
            model.activeFruit = [
                .init(fruitID: .pear, classification: .good, x: 0.25, y: 0.2, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0),
                .init(fruitID: .lemon, classification: .bad, x: 0.75, y: 0.4, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)
            ]
            model.activeStars = [.init(x: 0.5, y: 0.6, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)]
        }
        if ["hud-catch", "hud-classification", "catch-objects"].contains(scenario) {
            // Layout-only fixture: hold the real frame-advance guard while the
            // active renderer stays visible. This does not verify live physics.
            model.isPaused = true
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
        VStack(alignment: .leading) {
            Text("back requests: \(backRequests)")
                .accessibilityIdentifier("gameQA.backRequests")
            Text("tour completed: \(store.tourState.hasCompletedTour)")
                .accessibilityIdentifier("gameQA.tourCompleted")
            Text("game screen: \(String(describing: model.screen))")
                .accessibilityIdentifier("gameQA.screen")
            Text("actual personal best: \(model.didSetPersonalBestThisRound)")
                .accessibilityIdentifier("gameQA.actualPersonalBest")
            Text("raw basket count: \(model.basketCount)")
                .accessibilityIdentifier("gameQA.rawBasketCount")
            Text("raw session score: \(model.score)")
                .accessibilityIdentifier("gameQA.rawSessionScore")
            if let result = model.roundResult {
                Text("raw fruit count: \(result.caughtFruit.count) / \(result.targetFruit)")
                    .accessibilityIdentifier("gameQA.rawResultFruit")
            }
            Prompt28GameProgressReadback(model: model, store: store)
            Text("stored highest level: \(store.leaderboardTotals.highestLevel)")
                .accessibilityIdentifier("gameQA.storedHighestLevel")
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                FruitfolioInteractionSoundDiagnostics()
            }
        }
    }
}

/// Independent observations of the real private store and its backing bytes.
@MainActor
private struct Prompt28ProtectedGameBlobReadback: View {
    @ObservedObject var store: Prompt28FruitBasketStore
    let defaults: UserDefaults
    let expected: Data
    let token: String
    var body: some View {
        VStack {
            Text("protected blob intact: \(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1") == expected)")
                .accessibilityIdentifier("gameQA.protectedBlobIntact")
            Text("protected store: \(store.isReadOnly)")
                .accessibilityIdentifier("gameQA.protectedStore")
            Text("recovery owner: " + token).accessibilityIdentifier("gameQA.recoveryOwner")
        }
    }
}

/// Read only the disposable QA store; never mutates or fabricates progress.
@MainActor
struct Prompt28GameProgressReadback: View {
    @ObservedObject var model: Prompt28FruitBasketViewModel
    @ObservedObject var store: Prompt28FruitBasketStore
    var body: some View {
        let progress = store.progress(for: model.normalizedTopic)
        VStack {
            Text("stored current level: \(progress?.currentGameLevel ?? 0)")
                .accessibilityIdentifier("gameQA.storedCurrentLevel")
            Text("stored conserved totals: highest \(progress?.highestGameLevelReached ?? 0); fruit \(progress?.totalFruitCaught ?? 0); stars \(progress?.totalStarsEarned ?? 0); best \(progress?.bestScore ?? 0)")
                .accessibilityIdentifier("gameQA.conservedTotals")
        }.font(.caption2).allowsHitTesting(false)
    }
}

/// Emitted by the actual conditional confetti branch, not a fixture guess.
nonisolated struct Prompt28CelebrationArtVisibilityKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

/// Read actual logical overlay visibility rather than infer it from game state.
nonisolated struct Prompt28GameOverlayVisibilityKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
#endif
