import Foundation

/// Keeps the existing game JSON keys and defaults key. No extra user data store.
nonisolated struct Prompt28PersistedGameState: Codable, Sendable {
    var schemaVersion: Int? = 1
    var topicProgress: [String: Prompt28TopicProgress] = [:]
    var questionHistory: [String: [String]] = [:]
    var tourState = Prompt28TourState()
    var appearOnLeaderboard = false
    var leaderboardPseudonym: String? = nil
    var controlMode = Prompt28ControlMode.catchMode
    var preferredDifficulty = Prompt28EducationalDifficulty.easy
}

@MainActor
final class Prompt28GamePersistence {
    enum Failure: Error, Equatable {
        case notLoaded, wrongStoredType, unreadable, invalidState, changedElsewhere, unsupportedFormat, failedToSave
        var message: String {
            switch self {
            case .notLoaded: return "game progress has not been loaded yet."
            case .wrongStoredType, .unreadable, .invalidState:
                return "game progress could not be read safely. the original stored data is retained; play and progress changes are paused."
            case .failedToSave: return "game progress could not be saved. the previous stored state is retained; reload before playing."
            case .unsupportedFormat: return "this game data uses a newer format. the original data is retained; open it with a compatible Fruitfolio build."
            case .changedElsewhere:
                return "game progress changed or was cleared in another view. reload the current local state before playing."
            }
        }
    }
    private let defaults: UserDefaults
    private let key: String
    private var loaded = false
    private var baseline: Data?
    private(set) var failure: Failure?
    var isWriteBlocked: Bool { !loaded || failure != nil }
    init(defaults: UserDefaults, key: String) { self.defaults = defaults; self.key = key }

    func load() throws -> Prompt28PersistedGameState? {
        loaded = true
        guard let raw = defaults.object(forKey: key) else {
            baseline = nil; failure = nil
            return nil
        }
        guard let data = raw as? Data else {
            failure = .wrongStoredType
            throw Failure.wrongStoredType
        }
        let state: Prompt28PersistedGameState
        do { state = try JSONDecoder().decode(Prompt28PersistedGameState.self, from: data) }
        catch { failure = .unreadable; throw Failure.unreadable }
        guard state.schemaVersion == nil || state.schemaVersion == 1 else { failure = .unsupportedFormat; throw Failure.unsupportedFormat }
        guard Self.isValid(state) else { failure = .invalidState; throw Failure.invalidState }
        baseline = data; failure = nil
        return state
    }
    func save(_ state: Prompt28PersistedGameState) throws {
        guard loaded else { throw Failure.notLoaded }
        if let failure { throw failure }
        let raw = defaults.object(forKey: key)
        let same = raw == nil ? baseline == nil : (raw as? Data).map { $0 == baseline } == true
        guard same else { failure = .changedElsewhere; throw Failure.changedElsewhere }
        guard Self.isValid(state) else { failure = .invalidState; throw Failure.invalidState }
        let data: Data
        do { data = try JSONEncoder().encode(state) }
        catch { failure = .failedToSave; throw Failure.failedToSave }
        defaults.set(data, forKey: key)
        baseline = data
    }
    private static func isValid(_ state: Prompt28PersistedGameState) -> Bool {
        (state.schemaVersion == nil || state.schemaVersion == 1) && state.topicProgress.allSatisfy { key, progress in
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && key == progress.normalizedTopicID
                && (1...Prompt28FruitBasketEngine.maxGameLevel).contains(progress.currentGameLevel)
                && (progress.currentGameLevel...Prompt28FruitBasketEngine.maxGameLevel).contains(progress.highestGameLevelReached)
                && [progress.totalRoundsCompleted, progress.totalFruitCaught, progress.totalStarsEarned,
                    progress.totalSuccessfulRounds, progress.bestScore, progress.bestStreak].allSatisfy { $0 >= 0 }
                && progress.totalSuccessfulRounds <= progress.totalRoundsCompleted
                && (progress.successesInCurrentLevel.map { $0 >= 0 } ?? true)
                && progress.lastPlayedAt.timeIntervalSinceReferenceDate.isFinite
        } && state.questionHistory.allSatisfy { key, ids in
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && ids.allSatisfy { !$0.isEmpty }
        }
    }
}
