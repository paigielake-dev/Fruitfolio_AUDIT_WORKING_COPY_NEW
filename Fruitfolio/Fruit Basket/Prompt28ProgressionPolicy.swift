import Foundation

nonisolated enum Prompt28ProgressionPolicy {
    static func successesRequired(at level: Int) -> Int {
        switch level {
        case 1...3: return 2
        case 4...5: return 3
        case 6...7: return 4
        default: return 0
        }
    }
    private static func legacyTierOffset(_ progress: Prompt28TopicProgress) -> Int {
        let engine = Prompt28FruitBasketEngine()
        guard engine.levelAfterSuccessfulRounds(progress.totalSuccessfulRounds) == progress.currentGameLevel else { return 0 }
        let minimumWins = [0, 0, 2, 4, 6, 9, 12, 16, 20]
        return max(0, progress.totalSuccessfulRounds - minimumWins[engine.clampedLevel(progress.currentGameLevel)])
    }
    static func afterSuccessfulRound(_ original: Prompt28TopicProgress) -> Prompt28TopicProgress {
        var progress = original
        let engine = Prompt28FruitBasketEngine()
        let level = engine.clampedLevel(progress.currentGameLevel)
        progress.totalRoundsCompleted += 1
        progress.totalSuccessfulRounds += 1
        if level == Prompt28FruitBasketEngine.maxGameLevel {
            progress.currentGameLevel = level
            progress.successesInCurrentLevel = 0
        } else {
            let wins = (original.successesInCurrentLevel ?? legacyTierOffset(original)) + 1
            if wins >= successesRequired(at: level) {
                progress.currentGameLevel = level + 1
                progress.successesInCurrentLevel = 0
            } else {
                progress.currentGameLevel = level
                progress.successesInCurrentLevel = wins
            }
        }
        progress.highestGameLevelReached = max(progress.highestGameLevelReached, progress.currentGameLevel)
        return progress
    }
    static func afterUnsuccessfulRound(_ original: Prompt28TopicProgress) -> Prompt28TopicProgress {
        var progress = original
        progress.totalRoundsCompleted += 1
        return progress
    }
    static func resettingLevel(_ original: Prompt28TopicProgress) -> Prompt28TopicProgress {
        var progress = original
        progress.currentGameLevel = 1
        progress.successesInCurrentLevel = 0
        return progress
    }
}
