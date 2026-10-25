import Combine
import Foundation

@MainActor
final class Prompt28FruitBasketStore: ObservableObject {
    private struct PersistedState: Codable {
        var topicProgress: [String: Prompt28TopicProgress] = [:]
        var questionHistory: [String: [String]] = [:]
        var tourState = Prompt28TourState()
        var appearOnLeaderboard = false
        var leaderboardPseudonym: String? = nil
        var controlMode = Prompt28ControlMode.catchMode
        var preferredDifficulty = Prompt28EducationalDifficulty.easy
    }

    @Published private(set) var topicProgress: [String: Prompt28TopicProgress] = [:]
    @Published private(set) var questionHistory: [String: Set<String>] = [:]
    @Published var tourState = Prompt28TourState()
    @Published var appearOnLeaderboard = false
    @Published var leaderboardPseudonym = ""
    @Published var controlMode = Prompt28ControlMode.catchMode
    @Published var preferredDifficulty = Prompt28EducationalDifficulty.easy

    private let defaults: UserDefaults
    private let persistenceKey: String

    init(
        defaults: UserDefaults = .standard,
        persistenceKey: String = "fruitfolio.prompt28.fruitBasket.v1"
    ) {
        self.defaults = defaults
        self.persistenceKey = persistenceKey
        load()
    }

    var leaderboardTotals: Prompt28LeaderboardTotals {
        Prompt28LeaderboardTotals(progress: topicProgress)
    }

    func progress(for normalizedTopic: String) -> Prompt28TopicProgress? {
        topicProgress[normalizedTopic]
    }

    func ensureProgress(for normalizedTopic: String) -> Prompt28TopicProgress {
        if let existing = topicProgress[normalizedTopic] { return existing }
        let created = Prompt28TopicProgress(normalizedTopicID: normalizedTopic)
        topicProgress[normalizedTopic] = created
        persist()
        return created
    }

    func updateProgress(_ progress: Prompt28TopicProgress) {
        var clean = progress
        clean.currentGameLevel = min(max(clean.currentGameLevel, 1), Prompt28FruitBasketEngine.maxGameLevel)
        clean.highestGameLevelReached = min(
            Prompt28FruitBasketEngine.maxGameLevel,
            max(clean.highestGameLevelReached, clean.currentGameLevel)
        )
        clean.lastPlayedAt = Date()
        topicProgress[clean.normalizedTopicID] = clean
        persist()
    }

    func resetCurrentGameLevel(for normalizedTopic: String) {
        var progress = ensureProgress(for: normalizedTopic)
        progress.currentGameLevel = 1
        progress.lastPlayedAt = Date()
        topicProgress[normalizedTopic] = progress
        persist()
    }

    func recordQuestion(_ questionID: String, topic: String) {
        var ids = questionHistory[topic] ?? []
        ids.insert(questionID)
        questionHistory[topic] = ids
        persist()
    }

    func completeTour() {
        tourState.hasCompletedTour = true
        tourState.currentStep = 0
        tourState.tutorialBasketCount = 0
        tourState.tutorialCatchState = "idle"
        persist()
    }

    func skipTourAfterRules() {
        completeTour()
    }

    func resetTourForReplay() {
        tourState = Prompt28TourState()
        persist()
    }

    func persistPreferences() {
        persist()
    }

    private func load() {
        guard
            let data = defaults.data(forKey: persistenceKey),
            let state = try? JSONDecoder().decode(PersistedState.self, from: data)
        else { return }

        topicProgress = state.topicProgress
        questionHistory = state.questionHistory.mapValues(Set.init)
        tourState = state.tourState
        leaderboardPseudonym = Prompt28LeaderboardUsernamePolicy.sanitized(state.leaderboardPseudonym ?? "")
        // Legacy local opt-in is not proof of global registration.
        appearOnLeaderboard = false
        controlMode = state.controlMode
        preferredDifficulty = state.preferredDifficulty
    }

    private func persist() {
        let state = PersistedState(
            topicProgress: topicProgress,
            questionHistory: questionHistory.mapValues { Array($0).sorted() },
            tourState: tourState,
            appearOnLeaderboard: appearOnLeaderboard,
            leaderboardPseudonym: leaderboardPseudonym,
            controlMode: controlMode,
            preferredDifficulty: preferredDifficulty
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: persistenceKey)
    }
}
