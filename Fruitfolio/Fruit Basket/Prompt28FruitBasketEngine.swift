import Foundation

struct Prompt28FruitBasketEngine: Sendable {
    static let goodFruitTarget = 10
    static let maxGameLevel = 8

    let rules: Prompt28RoundRules

    init(rules: Prompt28RoundRules = .canonical) {
        self.rules = rules
    }

    func normalizeTopic(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    func newSession(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        startingLevel: Int
    ) -> Prompt28Session {
        Prompt28Session(
            rawTopicQuery: topic,
            normalizedTopicID: normalizedTopic,
            educationalDifficulty: difficulty,
            startingGameLevel: clampedLevel(startingLevel)
        )
    }

    func config(for level: Int) -> Prompt28GameLevelConfig {
        switch clampedLevel(level) {
        case 1:
            return .init(level: 1, fallDurationRange: 3.7...4.0, spawnIntervalRange: 1.25...1.55, driftRange: -0.015...0.015, goodProbability: 0.72, obstacleProbability: 0, branchEnabled: false, puddleEnabled: false, vinesEnabled: false, windEnabled: false, maxConcurrentItems: 2)
        case 2:
            return .init(level: 2, fallDurationRange: 3.5...3.85, spawnIntervalRange: 1.15...1.45, driftRange: -0.025...0.025, goodProbability: 0.70, obstacleProbability: 0.05, branchEnabled: false, puddleEnabled: false, vinesEnabled: true, windEnabled: false, maxConcurrentItems: 2)
        case 3:
            return .init(level: 3, fallDurationRange: 3.3...3.7, spawnIntervalRange: 1.05...1.35, driftRange: -0.04...0.04, goodProbability: 0.68, obstacleProbability: 0.10, branchEnabled: true, puddleEnabled: false, vinesEnabled: true, windEnabled: true, maxConcurrentItems: 2)
        case 4:
            return .init(level: 4, fallDurationRange: 3.15...3.55, spawnIntervalRange: 0.98...1.28, driftRange: -0.05...0.05, goodProbability: 0.66, obstacleProbability: 0.14, branchEnabled: true, puddleEnabled: false, vinesEnabled: true, windEnabled: true, maxConcurrentItems: 3)
        case 5:
            return .init(level: 5, fallDurationRange: 3.0...3.4, spawnIntervalRange: 0.94...1.22, driftRange: -0.06...0.06, goodProbability: 0.65, obstacleProbability: 0.18, branchEnabled: true, puddleEnabled: true, vinesEnabled: true, windEnabled: true, maxConcurrentItems: 3)
        case 6:
            return .init(level: 6, fallDurationRange: 2.9...3.3, spawnIntervalRange: 0.90...1.18, driftRange: -0.07...0.07, goodProbability: 0.64, obstacleProbability: 0.20, branchEnabled: true, puddleEnabled: true, vinesEnabled: true, windEnabled: true, maxConcurrentItems: 3)
        case 7:
            return .init(level: 7, fallDurationRange: 2.82...3.2, spawnIntervalRange: 0.86...1.14, driftRange: -0.075...0.075, goodProbability: 0.63, obstacleProbability: 0.22, branchEnabled: true, puddleEnabled: true, vinesEnabled: true, windEnabled: true, maxConcurrentItems: 3)
        default:
            return .init(level: 8, fallDurationRange: 2.8...3.15, spawnIntervalRange: 0.84...1.12, driftRange: -0.08...0.08, goodProbability: 0.62, obstacleProbability: 0.24, branchEnabled: true, puddleEnabled: true, vinesEnabled: true, windEnabled: true, maxConcurrentItems: 4)
        }
    }

    func registerGoodCatch(session: inout Prompt28Session) -> Prompt28RoundOutcome {
        guard session.goodFruitCaughtThisRound < rules.goodFruitTarget else { return .success }
        session.goodFruitCaughtThisRound += 1
        session.fruitCaught += 1
        session.score += rules.goodFruitCatchScore
        return session.goodFruitCaughtThisRound >= rules.goodFruitTarget ? .success : .active
    }

    func registerGoodMiss(session: inout Prompt28Session) -> Prompt28RoundOutcome {
        if rules.goodFruitMissPenalty != 0 {
            session.score = max(0, session.score - rules.goodFruitMissPenalty)
        }
        return rules.goodFruitMissEndsRound ? .unsuccessful(badFruit: .apple) : .active
    }

    func registerBadMiss(session: inout Prompt28Session) -> Prompt28RoundOutcome {
        if rules.badFruitMissPenalty != 0 {
            session.score = max(0, session.score - rules.badFruitMissPenalty)
        }
        return .active
    }

    func registerBadCatch(_ fruit: Prompt28FruitID, session: inout Prompt28Session) -> Prompt28RoundOutcome {
        if session.availableStarPasses > 0 {
            session.availableStarPasses -= 1
            return .badFruitBlockedByStar(badFruit: fruit)
        }
        return .unsuccessful(badFruit: fruit)
    }

    func registerStarCatch(session: inout Prompt28Session) -> Prompt28RoundOutcome {
        session.availableStarPasses += 1
        return .active
    }

    func levelAfterSuccessfulRounds(_ successfulRounds: Int) -> Int {
        switch successfulRounds {
        case ..<2: return 1
        case 2..<4: return 2
        case 4..<6: return 3
        case 6..<9: return 4
        case 9..<12: return 5
        case 12..<16: return 6
        case 16..<20: return 7
        default: return 8
        }
    }

    func activeObstacles(level: Int, round: Int) -> Set<Prompt28ObstacleKind> {
        let level = clampedLevel(level)
        switch level {
        case 1:
            return []
        case 2:
            return [.vines]
        case 3:
            return round.isMultiple(of: 2) ? [.vines, .wind] : [.vines, .branch]
        case 4:
            switch round % 3 {
            case 0: return [.vines, .wind]
            case 1: return [.vines, .branch]
            default: return [.branch, .wind]
            }
        default:
            // Rain creates the puddle. Keep the existing two-obstacle budget
            // rather than add a third obstacle to the ordinary round plan.
            if level >= 6, round.isMultiple(of: 3) { return [.puddle, .vines] }
            // Levels 5–8 vary the challenge without stacking every obstacle at once.
            switch round % 4 {
            case 0: return [.vines, .puddle]
            case 1: return [.branch, .wind]
            case 2: return [.vines, .branch]
            default: return [.puddle, .wind]
            }
        }
    }

    func weather(level: Int, round: Int) -> Prompt28Weather {
        let level = clampedLevel(level)
        if level >= 6, round.isMultiple(of: 3) { return .softRain }
        if activeObstacles(level: level, round: round).contains(.wind) { return .breezy }
        return .clear
    }

    func windDirection(round: Int) -> Double {
        round.isMultiple(of: 2) ? -1 : 1
    }

    func fruitLaneBounds(level: Int, round: Int) -> ClosedRange<Double> {
        let obstacles = activeObstacles(level: level, round: round)
        if clampedLevel(level) >= 5, obstacles.contains(.vines) {
            return 0.12...0.88
        }
        if clampedLevel(level) == 2, obstacles.contains(.vines) {
            return 0.09...0.91
        }
        return 0.08...0.92
    }

    func basketFullness(for goodCount: Int) -> Double {
        min(max(Double(goodCount) / Double(rules.goodFruitTarget), 0), 1)
    }

    func collision(
        fruitX: Double,
        fruitY: Double,
        basketX: Double,
        basketHalfWidth: Double = 0.13,
        basketTopY: Double = 0.82
    ) -> Bool {
        fruitY >= basketTopY
            && fruitY <= 1.0
            && abs(fruitX - basketX) <= basketHalfWidth
    }

    func clampedLevel(_ level: Int) -> Int {
        min(max(level, 1), Self.maxGameLevel)
    }
}

struct Prompt28SpawnPlanner: Sendable {
    private(set) var consecutiveBadSpawns = 0

    mutating func nextClassification(
        goodProbability: Double,
        randomUnit: Double
    ) -> Prompt28FruitClassification {
        if consecutiveBadSpawns >= 2 {
            consecutiveBadSpawns = 0
            return .good
        }

        if randomUnit <= goodProbability {
            consecutiveBadSpawns = 0
            return .good
        }

        consecutiveBadSpawns += 1
        return .bad
    }

    mutating func reset() {
        consecutiveBadSpawns = 0
    }
}

/// The same normalized image bounds used by the original vine artwork renderer.
/// Contact is a bounded image-envelope approximation, not an invisible full-width band.
struct Prompt28VineContactGeometry: Sendable {
    let fieldWidth: Double
    let fieldHeight: Double
    let level: Int

    var normalizedArtworkBounds: CGRect {
        guard fieldWidth > 0, fieldHeight > 0 else { return .zero }
        let width = level == 2 ? 0.20 : 0.30
        let centerX = level == 2 ? 0.07 : 0.11
        // Original fruitbasket_vines is 344 x 448 pixels; .fit preserves its aspect ratio.
        let height = width * fieldWidth * (448.0 / 344.0) / fieldHeight
        return CGRect(x: centerX - width / 2, y: 0.54 - height / 2,
                      width: width, height: height)
    }

    func contains(x: Double, y: Double) -> Bool {
        guard fieldWidth > 0, fieldHeight > 0 else { return false }
        return normalizedArtworkBounds.contains(CGPoint(x: x, y: y))
    }
}

/// Original branch is mirrored so its painted trunk grows from the right edge.
/// Centerline contact approximates the painted wood, not the transparent image box.
struct Prompt28BranchContactGeometry: Sendable {
    let fieldWidth: Double
    let fieldHeight: Double
    var artworkWidth: Double { min(fieldWidth * 0.30, 176) }
    var artworkCenterX: Double { fieldWidth - artworkWidth * ((1 - 78.0 / 450.0) - 0.5) }

    func point(originalX: Double, originalY: Double) -> CGPoint {
        CGPoint(x: artworkCenterX + ((1 - originalX / 450) - 0.5) * artworkWidth,
                y: fieldHeight * 0.40 + (originalY / 448 - 0.5) * artworkWidth * (448.0 / 450.0))
    }

    func contains(x: Double, y: Double, radius: Double) -> Bool {
        guard fieldWidth > 0, fieldHeight > 0 else { return false }
        let point = CGPoint(x: x * fieldWidth, y: y * fieldHeight)
        let paths: [[CGPoint]] = [
            [self.point(originalX: 78, originalY: 410), self.point(originalX: 187, originalY: 348),
             self.point(originalX: 249, originalY: 257), self.point(originalX: 295, originalY: 140), self.point(originalX: 361, originalY: 52)],
            [self.point(originalX: 249, originalY: 277), self.point(originalX: 326, originalY: 244), self.point(originalX: 372, originalY: 206)],
            [self.point(originalX: 280, originalY: 268), self.point(originalX: 385, originalY: 276)]
        ]
        for path in paths {
            for (a, b) in zip(path, path.dropFirst()) {
                let dx = b.x - a.x, dy = b.y - a.y
                let denominator = dx * dx + dy * dy
                let t = denominator > 0 ? min(max(((point.x - a.x) * dx + (point.y - a.y) * dy) / denominator, 0), 1) : 0
                let distance = hypot(point.x - (a.x + t * dx), point.y - (a.y + t * dy))
                if distance <= radius + artworkWidth * (10.0 / 450.0) { return true }
            }
        }
        return false
    }
}

struct Prompt28BranchDeflection {
    var elapsed: Double = 0
    let horizontalVelocity: Double
    var verticalMultiplier: Double { min(1, -0.45 + 1.45 * elapsed / 0.24) }
}
