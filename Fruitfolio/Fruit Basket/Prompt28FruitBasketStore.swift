#if canImport(Combine)
import Combine
#endif
import Foundation

@MainActor
final class Prompt28FruitBasketStore {
    #if canImport(Combine)
    @Published
    #endif
    private(set) var topicProgress: [String: Prompt28TopicProgress] = [:]
    #if canImport(Combine)
    @Published
    #endif
    private(set) var questionHistory: [String: Set<String>] = [:]
    #if canImport(Combine)
    @Published
    #endif
    var tourState = Prompt28TourState()
    #if canImport(Combine)
    @Published
    #endif
    var appearOnLeaderboard = false
    #if canImport(Combine)
    @Published
    #endif
    var leaderboardPseudonym = ""
    #if canImport(Combine)
    @Published
    #endif
    var controlMode = Prompt28ControlMode.catchMode
    #if canImport(Combine)
    @Published
    #endif
    var preferredDifficulty = Prompt28EducationalDifficulty.easy

    private let persistence: Prompt28GamePersistence
    #if canImport(Combine)
    @Published
    #endif
    private(set) var persistenceMessage: String?
    var isReadOnly: Bool { persistence.isWriteBlocked }

    init(
        defaults: UserDefaults = .standard,
        persistenceKey: String = "fruitfolio.prompt28.fruitBasket.v1"
    ) {
        persistence = Prompt28GamePersistence(defaults: defaults, key: persistenceKey)
        reload()
    }

    var hasLegacyCaptureTotals: Bool { topicProgress.values.contains { $0.captureTotalsCompleteFromStart != true } }

    var leaderboardTotals: Prompt28LeaderboardTotals {
        Prompt28LeaderboardTotals(progress: topicProgress)
    }

    func progress(for normalizedTopic: String) -> Prompt28TopicProgress? {
        topicProgress[normalizedTopic]
    }

    func ensureProgress(for normalizedTopic: String) -> Prompt28TopicProgress {
        if let existing = topicProgress[normalizedTopic] { return existing }
        guard !isReadOnly, !normalizedTopic.isEmpty else { return Prompt28TopicProgress(normalizedTopicID: normalizedTopic) }
        let created = Prompt28TopicProgress(normalizedTopicID: normalizedTopic)
        topicProgress[normalizedTopic] = created
        persist()
        return created
    }

    func updateProgress(_ progress: Prompt28TopicProgress) {
        guard !isReadOnly else { return }
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
        guard !isReadOnly else { return }
        var progress = Prompt28ProgressionPolicy.resettingLevel(ensureProgress(for: normalizedTopic))
        progress.lastPlayedAt = Date()
        topicProgress[normalizedTopic] = progress
        persist()
    }

    func recordQuestion(_ questionID: String, topic: String) {
        guard !isReadOnly else { return }
        var ids = questionHistory[topic] ?? []
        ids.insert(questionID)
        questionHistory[topic] = ids
        persist()
    }

    func completeTour() {
        guard !isReadOnly else { return }
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
        guard !isReadOnly else { return }
        tourState = Prompt28TourState()
        persist()
    }

    func persistPreferences() {
        persist()
    }

    func reload() {
        do {
            let state = try persistence.load() ?? Prompt28PersistedGameState()
            topicProgress = state.topicProgress
            questionHistory = state.questionHistory.mapValues(Set.init)
            tourState = state.tourState
            leaderboardPseudonym = Prompt28LeaderboardUsernamePolicy.sanitized(state.leaderboardPseudonym ?? "")
            // Legacy local opt-in is not proof of global registration.
            appearOnLeaderboard = false
            controlMode = state.controlMode
            preferredDifficulty = state.preferredDifficulty
            persistenceMessage = nil
        } catch {
            persistenceMessage = persistence.failure?.message ?? "game progress could not be loaded. original local data is retained."
        }
    }

    private func persist() {
        guard !isReadOnly else { return }
        let state = Prompt28PersistedGameState(
            topicProgress: topicProgress,
            questionHistory: questionHistory.mapValues { Array($0).sorted() },
            tourState: tourState,
            appearOnLeaderboard: appearOnLeaderboard,
            leaderboardPseudonym: leaderboardPseudonym,
            controlMode: controlMode,
            preferredDifficulty: preferredDifficulty
        )
        do { try persistence.save(state); persistenceMessage = nil }
        catch { persistenceMessage = persistence.failure?.message ?? "game progress could not be saved; reload the current local state." }
    }
}

#if canImport(Combine)
extension Prompt28FruitBasketStore: ObservableObject {}
#endif
