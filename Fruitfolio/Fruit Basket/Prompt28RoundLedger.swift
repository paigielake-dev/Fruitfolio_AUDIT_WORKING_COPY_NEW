import Foundation

nonisolated struct Prompt28RoundResult: Equatable, Sendable {
    let roundID: UUID
    let succeeded: Bool
    let targetFruit: Int
    let gameLevelPlayed: Int
    let nextGameLevel: Int
    let caughtFruit: [Prompt28FruitID]
    let starsCollected: Int
    let starPassesAtStart: Int
    let starPassesSpent: Int
    let starPassesRemaining: Int
    let goodFruitPassed: Int
    let badFruitPassed: Int
    let starsPassed: Int
    let blockedBadFruit: [Prompt28FruitID]
    let endingBadFruit: Prompt28FruitID?
    let scoreChange: Int
    let cumulativeScore: Int
}

/// Accepted in-game events only. It cannot create a successful reveal before the
/// target or a failed result without the actual unprotected bad-fruit outcome.
nonisolated struct Prompt28RoundLedger: Equatable, Sendable {
    let roundID: UUID
    let targetFruit: Int
    let gameLevelPlayed: Int
    let startingScore: Int
    let startingPasses: Int
    private var seen: Set<UUID> = []
    private(set) var caughtFruit: [Prompt28FruitID] = []
    private(set) var starsCollected = 0
    private(set) var blockedBadFruit: [Prompt28FruitID] = []
    private(set) var endingBadFruit: Prompt28FruitID?
    private(set) var goodFruitPassed = 0
    private(set) var badFruitPassed = 0
    private(set) var starsPassed = 0
    var terminalSuccess: Bool? {
        if endingBadFruit != nil { return false }
        if caughtFruit.count >= targetFruit { return true }
        return nil
    }
    init(roundID: UUID = UUID(), targetFruit: Int = Prompt28FruitBasketEngine.goodFruitTarget,
         gameLevelPlayed: Int = 1, startingScore: Int = 0, startingPasses: Int = 0) {
        self.roundID = roundID; self.targetFruit = max(targetFruit, 1)
        self.gameLevelPlayed = gameLevelPlayed; self.startingScore = startingScore; self.startingPasses = startingPasses
    }
    func canRecord(_ eventID: UUID) -> Bool { terminalSuccess == nil && !seen.contains(eventID) }
    @discardableResult
    mutating func recordGoodFruit(_ fruit: Prompt28FruitID, eventID: UUID) -> Bool {
        guard canRecord(eventID) else { return false }
        seen.insert(eventID); caughtFruit.append(fruit)
        return true
    }
    @discardableResult
    mutating func recordStar(eventID: UUID) -> Bool {
        guard canRecord(eventID) else { return false }
        seen.insert(eventID); starsCollected += 1
        return true
    }
    @discardableResult
    mutating func recordBadFruit(_ fruit: Prompt28FruitID, outcome: Prompt28RoundOutcome, eventID: UUID) -> Bool {
        guard canRecord(eventID) else { return false }
        seen.insert(eventID)
        switch outcome {
        case .badFruitBlockedByStar: blockedBadFruit.append(fruit)
        case .unsuccessful: endingBadFruit = fruit
        default: break
        }
        return true
    }
    @discardableResult
    mutating func recordPassedFruit(_ classification: Prompt28FruitClassification, eventID: UUID) -> Bool {
        guard canRecord(eventID) else { return false }
        seen.insert(eventID)
        if classification == .good { goodFruitPassed += 1 } else { badFruitPassed += 1 }
        return true
    }
    @discardableResult
    mutating func recordPassedStar(eventID: UUID) -> Bool {
        guard canRecord(eventID) else { return false }
        seen.insert(eventID); starsPassed += 1
        return true
    }
    func result(score: Int, passesRemaining: Int, nextGameLevel: Int) -> Prompt28RoundResult? {
        guard let succeeded = terminalSuccess else { return nil }
        return Prompt28RoundResult(roundID: roundID, succeeded: succeeded, targetFruit: targetFruit,
            gameLevelPlayed: gameLevelPlayed, nextGameLevel: nextGameLevel, caughtFruit: caughtFruit,
            starsCollected: starsCollected, starPassesAtStart: startingPasses, starPassesSpent: blockedBadFruit.count,
            starPassesRemaining: passesRemaining, goodFruitPassed: goodFruitPassed, badFruitPassed: badFruitPassed,
            starsPassed: starsPassed, blockedBadFruit: blockedBadFruit, endingBadFruit: endingBadFruit,
            scoreChange: score - startingScore, cumulativeScore: score)
    }
}

/// Display-only integer formatting; no counts or scores enter translation.
nonisolated enum Prompt28GameStatisticFormatting {
    static func integer(_ value: Int, language: FruitfolioLanguage, signed: Bool = false) -> String {
        let locale = Locale(identifier: language.localeIdentifier)
        if signed {
            return value.formatted(.number.locale(locale).sign(strategy: .always(includingZero: true)))
        }
        return value.formatted(.number.locale(locale))
    }
    static func fraction(_ count: Int, target: Int, language: FruitfolioLanguage) -> String {
        integer(count, language: language) + " / " + integer(target, language: language)
    }
}
