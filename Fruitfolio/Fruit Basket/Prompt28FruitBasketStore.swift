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
    private var acknowledgedState = Prompt28PersistedGameState()

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
        var candidate = currentState
        candidate.topicProgress[normalizedTopic] = created
        persist(candidate)
        return created
    }

    @discardableResult
    func updateProgress(_ progress: Prompt28TopicProgress) -> Bool {
        guard !isReadOnly else { return false }
        var clean = progress
        clean.currentGameLevel = min(max(clean.currentGameLevel, 1), Prompt28FruitBasketEngine.maxGameLevel)
        clean.highestGameLevelReached = min(
            Prompt28FruitBasketEngine.maxGameLevel,
            max(clean.highestGameLevelReached, clean.currentGameLevel)
        )
        clean.lastPlayedAt = Date()
        var candidate = currentState
        candidate.topicProgress[clean.normalizedTopicID] = clean
        return persist(candidate)
    }

    @discardableResult
    func resetCurrentGameLevel(for normalizedTopic: String) -> Bool {
        guard !isReadOnly else { return false }
        let original = ensureProgress(for: normalizedTopic)
        guard !isReadOnly else { return false }
        var progress = Prompt28ProgressionPolicy.resettingLevel(original)
        progress.lastPlayedAt = Date()
        var candidate = currentState
        candidate.topicProgress[normalizedTopic] = progress
        return persist(candidate)
    }

    func recordQuestion(_ questionID: String, topic: String) {
        guard !isReadOnly else { return }
        var ids = questionHistory[topic] ?? []
        ids.insert(questionID)
        var candidate = currentState
        candidate.questionHistory[topic] = Array(ids).sorted()
        persist(candidate)
    }

    func completeTour() {
        guard !isReadOnly else { return }
        var candidate = currentState
        candidate.tourState.hasCompletedTour = true
        candidate.tourState.currentStep = 0
        candidate.tourState.tutorialBasketCount = 0
        candidate.tourState.tutorialCatchState = "idle"
        persist(candidate)
    }

    func skipTourAfterRules() {
        completeTour()
    }

    func resetTourForReplay() {
        guard !isReadOnly else { return }
        var candidate = currentState
        candidate.tourState = Prompt28TourState()
        persist(candidate)
    }

    @discardableResult
    func persistPreferences() -> Bool {
        persist(currentState)
    }

    func reload() {
        do {
            let state = try persistence.load() ?? Prompt28PersistedGameState()
            apply(state, loadedRecord: true)
            acknowledgedState = currentState
            persistenceMessage = nil
        } catch {
            persistenceMessage = persistence.failure?.message ?? "game progress could not be loaded. original local data is retained."
        }
    }

    private var currentState: Prompt28PersistedGameState {
        Prompt28PersistedGameState(
            topicProgress: topicProgress,
            questionHistory: questionHistory.mapValues { Array($0).sorted() },
            tourState: tourState,
            appearOnLeaderboard: appearOnLeaderboard,
            leaderboardPseudonym: leaderboardPseudonym,
            controlMode: controlMode,
            preferredDifficulty: preferredDifficulty
        )
    }

    private func apply(_ state: Prompt28PersistedGameState, loadedRecord: Bool = false) {
        if topicProgress != state.topicProgress { topicProgress = state.topicProgress }
        let history = state.questionHistory.mapValues(Set.init)
        if questionHistory != history { questionHistory = history }
        if tourState != state.tourState { tourState = state.tourState }
        let name = loadedRecord ? Prompt28LeaderboardUsernamePolicy.sanitized(state.leaderboardPseudonym ?? "")
            : state.leaderboardPseudonym ?? ""
        if leaderboardPseudonym != name { leaderboardPseudonym = name }
        // Preserve reload policy: a legacy local opt-in is not global registration.
        let optIn = loadedRecord ? false : state.appearOnLeaderboard
        if appearOnLeaderboard != optIn { appearOnLeaderboard = optIn }
        if controlMode != state.controlMode { controlMode = state.controlMode }
        if preferredDifficulty != state.preferredDifficulty { preferredDifficulty = state.preferredDifficulty }
    }

    @discardableResult
    private func persist(_ state: Prompt28PersistedGameState) -> Bool {
        guard !isReadOnly else { return false }
        do {
            try persistence.save(state)
            apply(state)
            acknowledgedState = currentState
            persistenceMessage = nil
            return true
        } catch {
            // Restore only the last acknowledged in-memory snapshot. An explicit
            // reload still owns accepting external bytes and clearing protection.
            apply(acknowledgedState)
            persistenceMessage = persistence.failure?.message ?? "game progress could not be saved; reload the current local state."
            return false
        }
    }

}

#if canImport(Combine)
extension Prompt28FruitBasketStore: ObservableObject {}
#endif
