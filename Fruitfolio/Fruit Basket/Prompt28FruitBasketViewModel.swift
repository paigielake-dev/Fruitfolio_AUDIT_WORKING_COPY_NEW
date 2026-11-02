import Combine
import Foundation

@MainActor
final class Prompt28FruitBasketViewModel: ObservableObject {
    @Published var screen: Prompt28ScreenState = .home {
        didSet {
            if oldValue == .catchActive, screen != .catchActive { stopGameplay() }
            if screen != .catchActive, screen != .paused { showingStormNotice = false }
        }
    }
    @Published private(set) var showingStormNotice = false
    @Published var rawTopic = ""
    @Published var difficulty: Prompt28EducationalDifficulty
    @Published var currentQuestion: Prompt28Question?
    @Published var selectedAnswerID: String?
    @Published var session: Prompt28Session?
    @Published var activeFruit: [Prompt28FallingFruit] = []
    @Published var activeStars: [Prompt28FallingStar] = []
    @Published var basketX: Double = 0.5
    @Published private(set) var basketIsMeetingPuddleResistance = false
    @Published var lastBadFruit: Prompt28FruitID?
    @Published var message: String?
    @Published var isPaused = false
    @Published var classificationFruit: Prompt28FallingFruit?
    @Published var didSetPersonalBestThisRound = false

    let store: Prompt28FruitBasketStore
    let engine: Prompt28FruitBasketEngine

    private let researchProvider: any Prompt28ResearchProviding
    private var gameplayTask: Task<Void, Never>?
    private var roundCompletionTask: Task<Void, Never>?
    private var spawnPlanner = Prompt28SpawnPlanner()
    private var lastSpawnAt = Date.distantPast
    private var roundResultLocked = false
    private var lastStormNoticeKey: String?

    init(
        store: Prompt28FruitBasketStore,
        researchProvider: any Prompt28ResearchProviding,
        engine: Prompt28FruitBasketEngine? = nil
    ) {
        self.store = store
        self.researchProvider = researchProvider
        self.engine = engine ?? Prompt28FruitBasketEngine()
        self.difficulty = store.preferredDifficulty
    }

    deinit {
        gameplayTask?.cancel()
        roundCompletionTask?.cancel()
    }

    var normalizedTopic: String { engine.normalizeTopic(rawTopic) }

    var progress: Prompt28TopicProgress? {
        guard !normalizedTopic.isEmpty else { return nil }
        return store.progress(for: normalizedTopic)
    }

    var gameLevel: Int {
        session?.currentGameLevel ?? progress?.currentGameLevel ?? 1
    }

    var basketCount: Int { session?.goodFruitCaughtThisRound ?? 0 }
    var score: Int { session?.score ?? 0 }
    var currentRound: Int { session?.currentRound ?? 1 }
    var weather: Prompt28Weather { engine.weather(level: gameLevel, round: currentRound) }
    var levelConfig: Prompt28GameLevelConfig { engine.config(for: gameLevel) }
    var activeObstacles: Set<Prompt28ObstacleKind> {
        engine.activeObstacles(level: gameLevel, round: currentRound)
    }
    var windDirection: Double { engine.windDirection(round: currentRound) }
    var currentGoodFruitIDs: [Prompt28FruitID] {
        currentQuestion?.goodFruitIDs ?? Prompt28FruitID.allCases
    }

    func openSetup() {
        stopGameplay()
        screen = .learningSetup
        message = nil
    }

    func chooseSuggestedTopic(_ topic: String) {
        rawTopic = topic
    }

    func updateDifficulty(_ value: Prompt28EducationalDifficulty) {
        difficulty = value
        store.preferredDifficulty = value
        store.persistPreferences()
        if var session {
            session.educationalDifficulty = value
            self.session = session
        }
    }

    func startTopic() async {
        let normalized = normalizedTopic
        guard !normalized.isEmpty else {
            message = "type a topic first ♡"
            return
        }

        message = nil
        if let existing = store.progress(for: normalized), existing.totalRoundsCompleted > 0 {
            screen = .topicProgressChoice
            return
        }

        _ = store.ensureProgress(for: normalized)
        session = engine.newSession(
            topic: rawTopic,
            normalizedTopic: normalized,
            difficulty: difficulty,
            startingLevel: 1
        )
        await loadQuestion()
    }

    func continueReturningTopic(resetLevel: Bool) async {
        let normalized = normalizedTopic
        guard !normalized.isEmpty else { return }
        if resetLevel { store.resetCurrentGameLevel(for: normalized) }
        let progress = store.ensureProgress(for: normalized)
        session = engine.newSession(
            topic: rawTopic,
            normalizedTopic: normalized,
            difficulty: difficulty,
            startingLevel: progress.currentGameLevel
        )
        await loadQuestion()
    }

    func loadQuestion() async {
        let normalized = normalizedTopic
        guard !normalized.isEmpty else { return }
        screen = .loading
        message = nil
        do {
            let q = try await researchProvider.question(
                topic: rawTopic,
                normalizedTopic: normalized,
                difficulty: difficulty,
                excludingQuestionIDs: store.questionHistory[normalized] ?? []
            )
            guard q.isPlayable else { throw Prompt28ResearchError.invalidQuestion }
            currentQuestion = q
            selectedAnswerID = nil
            store.recordQuestion(q.id, topic: normalized)
            screen = .question
        } catch let error as Prompt28ResearchError {
            switch error {
            case .topicExhausted:
                screen = .topicExhausted
            case .unsupportedTopic, .providerUnavailable:
                screen = .topicUnsupported
            default:
                screen = .error
            }
            message = error.localizedDescription
        } catch {
            screen = .error
            message = "Fruit Basket couldn’t prepare a sourced question right now."
        }
    }

    func answer(_ answerID: String) {
        guard let question = currentQuestion, selectedAnswerID == nil else { return }
        selectedAnswerID = answerID
        if answerID == question.correctAnswerID {
            if var session {
                session.currentStreak += 1
                self.session = session
            }
            screen = .correctFeedback
        } else {
            if var session {
                session.currentStreak = 0
                self.session = session
            }
            screen = .incorrectFeedback
        }
    }

    func beginCatch() {
        guard currentQuestion != nil, var session else { return }
        stopGameplay()
        session.goodFruitCaughtThisRound = 0
        self.session = session
        activeFruit.removeAll()
        activeStars.removeAll()
        classificationFruit = nil
        basketX = 0.5
        basketIsMeetingPuddleResistance = false
        isPaused = false
        showingStormNotice = false
        roundResultLocked = false
        spawnPlanner.reset()
        lastSpawnAt = .distantPast
        screen = .catchActive

        let noticeKey = "\(session.id.uuidString):\(session.currentRound)"
        if weather == .softRain, lastStormNoticeKey != noticeKey {
            lastStormNoticeKey = noticeKey
            showingStormNotice = true
            isPaused = true
        } else {
            startCatchInteraction()
        }
    }

    func dismissStormNotice() {
        guard showingStormNotice else { return }
        showingStormNotice = false
        // Backgrounding already moves active play to the paused menu. Closing
        // its notice must not silently resume a background-paused round.
        guard screen == .catchActive else { return }
        isPaused = false
        startCatchInteraction()
    }

    private func startCatchInteraction() {
        if store.controlMode == .classification { spawnClassificationFruit() }
        else { startGameplayLoop() }
    }

    func viewWillDisappear() {
        stopGameplay()
        if screen == .catchActive { isPaused = true; screen = .paused }
    }

    func moveBasket(to normalizedX: Double) {
        guard screen == .catchActive, !isPaused else { return }
        let target = min(max(normalizedX, 0.10), 0.90)
        guard activeObstacles.contains(.puddle) else {
            basketIsMeetingPuddleResistance = false
            basketX = target
            return
        }

        // The puddle adds mild inertia only while crossing its central painted region.
        // It never removes enough control to make avoiding a BAD fruit unreasonable.
        let pathMin = min(basketX, target)
        let pathMax = max(basketX, target)
        let crossingPuddle = pathMax >= 0.33 && pathMin <= 0.67
        basketIsMeetingPuddleResistance = crossingPuddle
        let response = crossingPuddle ? 0.58 : 1.0
        basketX += (target - basketX) * response
        basketX = min(max(basketX, 0.10), 0.90)
    }

    func classificationDecision(accept: Bool) {
        guard
            screen == .catchActive,
            store.controlMode == .classification,
            let fruit = classificationFruit,
            !roundResultLocked
        else { return }

        classificationFruit = nil
        switch (fruit.classification, accept) {
        case (.good, true):
            handleGoodCatch(fruit.fruitID)
        case (.good, false):
            handleGoodMiss()
        case (.bad, true):
            handleBadCatch(fruit.fruitID)
        case (.bad, false):
            handleBadMiss()
        }

        if screen == .catchActive, !roundResultLocked {
            spawnClassificationFruit()
        }
    }

    func pause() {
        guard screen == .catchActive else { return }
        isPaused = true
        gameplayTask?.cancel()
        gameplayTask = nil
        screen = .paused
    }

    func resume() {
        guard screen == .paused else { return }
        isPaused = false
        screen = .catchActive
        if store.controlMode == .catchMode { startGameplayLoop() }
        else if classificationFruit == nil { spawnClassificationFruit() }
    }

    func retryRound() {
        guard var session else { return }
        session.goodFruitCaughtThisRound = 0
        self.session = session
        lastBadFruit = nil
        beginCatch()
    }

    func resetGameLevel() {
        let normalized = normalizedTopic
        guard !normalized.isEmpty else { return }
        stopGameplay()
        store.resetCurrentGameLevel(for: normalized)
        if var session {
            session.currentGameLevel = 1
            session.startingGameLevel = 1
            self.session = session
        }
        screen = .learningSetup
    }

    func continueAfterReveal() async {
        guard var session else { return }
        session.currentRound += 1
        session.goodFruitCaughtThisRound = 0
        self.session = session
        await loadQuestion()
    }

    func changeTopic() {
        stopGameplay()
        currentQuestion = nil
        selectedAnswerID = nil
        session = nil
        rawTopic = ""
        screen = .learningSetup
    }

    func setControlMode(_ mode: Prompt28ControlMode) {
        store.controlMode = mode
        store.persistPreferences()
    }

    func sceneBecameInactive() {
        if screen == .catchActive { pause() }
    }

    func savePendingContent() -> Prompt10PendingSavedContent? {
        guard let question = currentQuestion else { return nil }
        let revealBody = "basket reveal . ݁₊ ⊹ . ݁˖ . ݁\n\n ☆ \(question.explanation)"
        return Prompt10PendingSavedContent(
            question: "basket reveal . ݁₊ ⊹ . ݁˖ . ݁",
            answer: revealBody,
            saveType: .fullAnswer,
            originalAnswerID: "fruitbasket:\(question.id)",
            sourceIDs: question.sourceIDs,
            sourceVersions: Dictionary(uniqueKeysWithValues: question.sourceIDs.map { ($0, question.contentVersion) }),
            knowledgeBaseVersion: question.contentVersion,
            generationTimestamp: question.createdAt
        )
    }

    private func startGameplayLoop() {
        gameplayTask?.cancel()
        gameplayTask = Task { [weak self] in
            guard let self else { return }
            var previous = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000)
                guard !Task.isCancelled else { break }
                let now = Date()
                let delta = min(max(now.timeIntervalSince(previous), 0.001), 0.08)
                previous = now
                self.tick(delta: delta, now: now)
            }
        }
    }

    private func tick(delta: TimeInterval, now: Date) {
        guard screen == .catchActive, !isPaused, !roundResultLocked else { return }
        var remaining: [Prompt28FallingFruit] = []

        let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
        for var fruit in activeFruit {
            let vineMultiplier = activeObstacles.contains(.vines) && fruit.classification == .good && (0.22...0.58).contains(fruit.y) ? 0.56 : 1.0
            fruit.y += fruit.fallSpeed * vineMultiplier * delta

            var horizontalVelocity = fruit.horizontalDrift
            if activeObstacles.contains(.wind) {
                horizontalVelocity += windDirection * (weather == .softRain ? 0.030 : 0.021)
            }

            // The right-side branch gently redirects fruit before it reaches the basket.
            // This creates a readable obstacle without turning it into an unavoidable trap.
            if activeObstacles.contains(.branch),
               (0.27...0.55).contains(fruit.y),
               fruit.x > 0.66 {
                horizontalVelocity -= 0.095
            }

            fruit.x = min(max(fruit.x + horizontalVelocity * delta, laneBounds.lowerBound), laneBounds.upperBound)

            if engine.collision(fruitX: fruit.x, fruitY: fruit.y, basketX: basketX) {
                if fruit.classification == .good { handleGoodCatch(fruit.fruitID) }
                else { handleBadCatch(fruit.fruitID) }
                if roundResultLocked { break }
                continue
            }

            if fruit.y > 1.06 {
                if fruit.classification == .good { handleGoodMiss() }
                else { handleBadMiss() }
                continue
            }

            remaining.append(fruit)
        }

        activeFruit = roundResultLocked ? [] : remaining
        guard !roundResultLocked else { return }

        var remainingStars: [Prompt28FallingStar] = []
        for var star in activeStars {
            let vineMultiplier = activeObstacles.contains(.vines) && (0.22...0.58).contains(star.y) ? 0.56 : 1.0
            star.y += star.fallSpeed * vineMultiplier * delta
            star.x = min(max(star.x + star.horizontalDrift * delta, laneBounds.lowerBound), laneBounds.upperBound)
            if engine.collision(fruitX: star.x, fruitY: star.y, basketX: basketX) {
                handleStarCatch()
                continue
            }
            if star.y <= 1.06 { remainingStars.append(star) }
        }
        activeStars = remainingStars

        let interval = random(in: levelConfig.spawnIntervalRange)
        if activeFruit.count < levelConfig.maxConcurrentItems,
           now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnFruit()
            lastSpawnAt = now
        }
    }

    private func spawnFruit() {
        guard let question = currentQuestion else { return }
        if Double.random(in: 0...1) < 0.06 {
            let duration = random(in: levelConfig.fallDurationRange)
            let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
            activeStars.append(Prompt28FallingStar(
                x: Double.random(in: max(0.12, laneBounds.lowerBound)...min(0.88, laneBounds.upperBound)),
                fallSpeed: 1.18 / max(duration, 0.5),
                horizontalDrift: random(in: levelConfig.driftRange),
                rotationDegrees: Double.random(in: -6...6)
            ))
            return
        }
        let classification = spawnPlanner.nextClassification(
            goodProbability: levelConfig.goodProbability,
            randomUnit: Double.random(in: 0...1)
        )
        let pool = classification == .good ? question.goodFruitIDs : question.badFruitIDs
        guard let fruitID = pool.randomElement() else { return }
        let duration = random(in: levelConfig.fallDurationRange)
        let speed = 1.18 / max(duration, 0.5)
        let drift = random(in: levelConfig.driftRange)
        let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
        var x = Double.random(in: max(0.12, laneBounds.lowerBound)...min(0.88, laneBounds.upperBound))
        if activeObstacles.contains(.branch), x > 0.72 {
            x = Double.random(in: max(0.12, laneBounds.lowerBound)...0.70)
        }
        let rotation = Double.random(in: -6...6)
        activeFruit.append(
            Prompt28FallingFruit(
                fruitID: fruitID,
                classification: classification,
                x: x,
                fallSpeed: speed,
                horizontalDrift: drift,
                rotationDegrees: rotation
            )
        )
    }

    private func spawnClassificationFruit() {
        guard let question = currentQuestion else { return }
        let classification = spawnPlanner.nextClassification(
            goodProbability: levelConfig.goodProbability,
            randomUnit: Double.random(in: 0...1)
        )
        let pool = classification == .good ? question.goodFruitIDs : question.badFruitIDs
        guard let fruitID = pool.randomElement() else { return }
        classificationFruit = Prompt28FallingFruit(
            fruitID: fruitID,
            classification: classification,
            x: 0.5,
            y: 0.38,
            fallSpeed: 0,
            horizontalDrift: 0,
            rotationDegrees: 0
        )
    }

    private func handleGoodCatch(_ fruit: Prompt28FruitID) {
        guard !roundResultLocked, var session else { return }
        let outcome = engine.registerGoodCatch(session: &session)
        self.session = session
        if outcome == .success {
            roundResultLocked = true
            stopGameplay()
            roundCompletionTask?.cancel()
            roundCompletionTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 650_000_000)
                guard !Task.isCancelled, let self else { return }
                self.finishSuccessfulRound()
            }
        }
    }

    private func handleGoodMiss() {
        guard !roundResultLocked, var session else { return }
        _ = engine.registerGoodMiss(session: &session)
        self.session = session
    }

    private func handleBadMiss() {
        guard !roundResultLocked, var session else { return }
        _ = engine.registerBadMiss(session: &session)
        self.session = session
    }

    private func handleStarCatch() {
        guard !roundResultLocked, var session else { return }
        _ = engine.registerStarCatch(session: &session)
        self.session = session

        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress.totalStarsEarned += 1
        store.updateProgress(progress)
    }

    private func handleBadCatch(_ fruit: Prompt28FruitID) {
        guard !roundResultLocked, var session else { return }
        let outcome = engine.registerBadCatch(fruit, session: &session)
        self.session = session
        lastBadFruit = fruit
        if case .badFruitBlockedByStar = outcome { return }
        roundResultLocked = true
        stopGameplay()
        activeFruit.removeAll(); activeStars.removeAll(); classificationFruit = nil
        roundCompletionTask?.cancel()
        roundCompletionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled, let self else { return }
            self.finishUnsuccessfulRound()
        }
    }

    private func finishSuccessfulRound() {
        guard var session else { return }
        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress.totalRoundsCompleted += 1
        progress.totalSuccessfulRounds += 1
        progress.totalFruitCaught += Prompt28FruitBasketEngine.goodFruitTarget
        let newLevel = engine.levelAfterSuccessfulRounds(progress.totalSuccessfulRounds)
        progress.currentGameLevel = max(progress.currentGameLevel, newLevel)
        progress.highestGameLevelReached = max(progress.highestGameLevelReached, progress.currentGameLevel)
        didSetPersonalBestThisRound = session.score > progress.bestScore
        progress.bestScore = max(progress.bestScore, session.score)
        progress.bestStreak = max(progress.bestStreak, session.currentStreak)
        store.updateProgress(progress)
        session.currentGameLevel = progress.currentGameLevel
        self.session = session
        screen = .basketReveal
    }

    private func finishUnsuccessfulRound() {
        guard var session else { return }
        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress.totalRoundsCompleted += 1
        progress.bestScore = max(progress.bestScore, session.score)
        progress.bestStreak = max(progress.bestStreak, session.currentStreak)
        store.updateProgress(progress)
        session.currentGameLevel = progress.currentGameLevel
        self.session = session
        screen = .catchUnsuccessful
    }

    private func stopGameplay() {
        gameplayTask?.cancel(); gameplayTask = nil
        roundCompletionTask?.cancel(); roundCompletionTask = nil
    }

    private func random(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}
