import Combine
import Foundation

@MainActor
final class Prompt28FruitBasketStore: ObservableObject {
    private struct PersistedState: Codable {
        var topicProgress: [String: Prompt28TopicProgress] = [:]
        var questionHistory: [String: [String]] = [:]
        var completedRounds: [Prompt28CompletedRound]? = nil
        var tourState = Prompt28TourState()
        var appearOnLeaderboard = false
        var leaderboardPseudonym: String? = nil
        var controlMode = Prompt28ControlMode.catchMode
        var preferredDifficulty = Prompt28EducationalDifficulty.easy
    }

    @Published private(set) var loadError: String?
    @Published private(set) var topicProgress: [String: Prompt28TopicProgress] = [:]
    @Published private(set) var questionHistory: [String: Set<String>] = [:]
    @Published private(set) var completedRounds: [Prompt28CompletedRound] = []
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

    func recordCompletedRound(_ record: Prompt28CompletedRound) {
        guard loadError == nil, !completedRounds.contains(where: { $0.id == record.id }) else { return }
        completedRounds.append(record)
        persist()
    }

    /// Commit progress and its immutable evidence/catch record as one snapshot.
    /// Staging before publication avoids a saved score without its original
    /// round attribution if encoding fails or the process stops between writes.
    @discardableResult
    func commitCompletedRound(_ record: Prompt28CompletedRound,
                              updating progress: Prompt28TopicProgress) -> Bool {
        guard loadError == nil else { return false }
        if let existing = completedRounds.first(where: { $0.id == record.id }) {
            return existing == record
        }
        var clean = progress
        clean.currentGameLevel = min(max(clean.currentGameLevel, 1), Prompt28FruitBasketEngine.maxGameLevel)
        clean.highestGameLevelReached = min(Prompt28FruitBasketEngine.maxGameLevel,
                                            max(clean.highestGameLevelReached, clean.currentGameLevel))
        clean.lastPlayedAt = record.completedAt
        var state = persistenceSnapshot()
        state.topicProgress[clean.normalizedTopicID] = clean
        state.completedRounds = completedRounds + [record]
        guard let data = try? JSONEncoder().encode(state) else { return false }
        defaults.set(data, forKey: persistenceKey)
        topicProgress = state.topicProgress
        completedRounds = state.completedRounds ?? []
        return true
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
        guard defaults.object(forKey: persistenceKey) != nil else { return }
        guard let data = defaults.data(forKey: persistenceKey) else {
            loadError = "your saved game data couldn’t be read. it hasn’t been replaced."
            return
        }
        let state: PersistedState
        do { state = try JSONDecoder().decode(PersistedState.self, from: data) }
        catch {
            loadError = "your saved game data couldn’t be read. it hasn’t been replaced."
            return
        }

        topicProgress = state.topicProgress
        questionHistory = state.questionHistory.mapValues(Set.init)
        completedRounds = state.completedRounds ?? []
        tourState = state.tourState
        leaderboardPseudonym = Prompt28LeaderboardUsernamePolicy.sanitized(state.leaderboardPseudonym ?? "")
        // Legacy local opt-in is not proof of global registration.
        appearOnLeaderboard = false
        controlMode = state.controlMode
        preferredDifficulty = state.preferredDifficulty
    }

    private func persist() {
        // Never overwrite unreadable saved records with an empty/default state.
        guard loadError == nil else { return }
        let state = persistenceSnapshot()
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: persistenceKey)
    }

    private func persistenceSnapshot() -> PersistedState {
        PersistedState(
            topicProgress: topicProgress,
            questionHistory: questionHistory.mapValues { Array($0).sorted() },
            completedRounds: completedRounds,
            tourState: tourState,
            appearOnLeaderboard: appearOnLeaderboard,
            leaderboardPseudonym: leaderboardPseudonym,
            controlMode: controlMode,
            preferredDifficulty: preferredDifficulty
        )
    }
}
