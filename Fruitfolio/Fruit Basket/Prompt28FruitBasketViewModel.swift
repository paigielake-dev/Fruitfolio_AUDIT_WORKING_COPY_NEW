#if canImport(Combine)
import Combine
#endif
import Foundation

@MainActor
final class Prompt28FruitBasketViewModel {
    #if canImport(Combine)
    @Published
    #endif
    var screen: Prompt28ScreenState = .home
    #if canImport(Combine)
    @Published
    #endif
    var rawTopic = ""
    #if canImport(Combine)
    @Published
    #endif
    var difficulty: Prompt28EducationalDifficulty
    #if canImport(Combine)
    @Published
    #endif
    var currentQuestion: Prompt28Question?
    #if canImport(Combine)
    @Published
    #endif
    private(set) var selectedAnswerID: String?
    #if canImport(Combine)
    @Published
    #endif
    var session: Prompt28Session?
    #if canImport(Combine)
    @Published
    #endif
    var activeFruit: [Prompt28FallingFruit] = []
    #if canImport(Combine)
    @Published
    #endif
    var activeStars: [Prompt28FallingStar] = []
    #if canImport(Combine)
    @Published
    #endif
    private(set) var catchTransits: [Prompt28CatchTransit] = []
    #if canImport(Combine)
    @Published
    #endif
    private(set) var roundLedger = Prompt28RoundLedger()
    #if canImport(Combine)
    @Published
    #endif
    private(set) var roundResult: Prompt28RoundResult?
    var collectedFruit: [Prompt28FruitID] { roundLedger.caughtFruit }
    #if canImport(Combine)
    @Published
    #endif
    var basketX: Double = 0.5
    #if canImport(Combine)
    @Published
    #endif
    var lastBadFruit: Prompt28FruitID?
    #if canImport(Combine)
    @Published
    #endif
    var message: String?
    #if canImport(Combine)
    @Published
    #endif
    private(set) var vineContactSequence = 0
    #if canImport(Combine)
    @Published
    #endif
    private(set) var basketResistance = 0.0
    #if canImport(Combine)
    @Published
    #endif
    private(set) var basketIsInPuddle = false
    #if canImport(Combine)
    @Published
    #endif
    var isPaused = false
    #if canImport(Combine)
    @Published
    #endif
    var classificationStarAvailable = false
    #if canImport(Combine)
    @Published
    #endif
    var classificationFruit: Prompt28FallingFruit?
    #if canImport(Combine)
    @Published
    #endif
    var didSetPersonalBestThisRound = false

    let store: Prompt28FruitBasketStore
    let engine: Prompt28FruitBasketEngine

    private let obstacleLibrary: Prompt28ObstacleMaskLibrary?
    private var basketTargetX = 0.5
    private let researchProvider: any Prompt28ResearchProviding
    private var questionGeneration = UUID()
    var questionInteractionID: UUID { questionGeneration }
    var allowsTopicEditing: Bool {
        switch screen {
        case .learningSetup, .topicProgressChoice, .loading, .topicUnsupported, .topicExhausted, .error: return true
        default: return false
        }
    }
    private var gameplayTask: Task<Void, Never>?
    private var roundCompletionTask: Task<Void, Never>?
    private var spawnPlanner = Prompt28SpawnPlanner()
    private var starPlanner = Prompt28RareStarPlanner()
    private var playfieldSize: CGSize = .zero
    private var nextSpawnInterval: TimeInterval = 2
    private var lastSpawnAt = Date.distantPast
    private var roundResultLocked = false
    private var roundID = UUID()
    private var finalizedRoundID: UUID?
    private var pendingRoundSuccess: Bool?

    init(
        store: Prompt28FruitBasketStore,
        researchProvider: any Prompt28ResearchProviding,
        engine: Prompt28FruitBasketEngine? = nil,
        obstacleLibrary: Prompt28ObstacleMaskLibrary? = .bundled
    ) {
        self.store = store
        self.obstacleLibrary = obstacleLibrary
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

    func editTopic(_ topic: String) {
        guard !store.isReadOnly, allowsTopicEditing else { return }
        rawTopic = topic
    }

    func chooseSuggestedTopic(_ topic: String) { editTopic(topic) }

    func updateDifficulty(_ value: Prompt28EducationalDifficulty) {
        guard !store.isReadOnly, allowsTopicEditing else { return }
        difficulty = value
        store.preferredDifficulty = value
        store.persistPreferences()
        if var session {
            session.educationalDifficulty = value
            self.session = session
        }
    }

    func startTopic() async {
        guard !Task.isCancelled, !store.isReadOnly else { return }
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
        guard !Task.isCancelled, !store.isReadOnly else { return }
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
        guard !Task.isCancelled, !store.isReadOnly else { return }
        let normalized = normalizedTopic
        guard !normalized.isEmpty else { return }
        let request = UUID()
        questionGeneration = request
        let requestedTopic = rawTopic
        let requestedDifficulty = difficulty
        func isCurrent() -> Bool {
            !Task.isCancelled && questionGeneration == request && screen == .loading
                && rawTopic == requestedTopic && difficulty == requestedDifficulty
        }
        screen = .loading
        defer { if questionGeneration == request && screen == .loading { screen = .learningSetup } }
        message = nil
        do {
            let q = try await researchProvider.question(
                topic: requestedTopic,
                normalizedTopic: normalized,
                difficulty: requestedDifficulty,
                excludingQuestionIDs: store.questionHistory[normalized] ?? []
            )
            guard isCurrent() else { return }
            guard q.isPlayable, q.normalizedTopic == normalized, q.educationalDifficulty == requestedDifficulty else { throw Prompt28ResearchError.invalidQuestion }
            currentQuestion = q
            selectedAnswerID = nil
            store.recordQuestion(q.id, topic: normalized)
            screen = .question
        } catch let error as Prompt28ResearchError {
            guard isCurrent() else { return }
            switch error {
            case .topicExhausted:
                screen = .topicExhausted
            case .unsupportedTopic, .providerUnavailable, .urgentTopic, .practiceUnavailable:
                screen = .topicUnsupported
            default:
                screen = .error
            }
            message = error.localizedDescription
        } catch {
            guard isCurrent() else { return }
            screen = .error
            message = "Fruit Basket couldn’t prepare a sourced question right now."
        }
    }

    func answer(_ answerID: String, expectedQuestionID: String? = nil, expectedInteractionID: UUID? = nil) {
        guard !store.isReadOnly, expectedInteractionID == nil || expectedInteractionID == questionGeneration, screen == .question,
              let question = currentQuestion, question.isPlayable, selectedAnswerID == nil,
              expectedQuestionID == nil || expectedQuestionID == question.id,
              question.answerOptions.contains(where: { $0.id == answerID }) else { return }
        questionGeneration = UUID()
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

    func retryQuestion(expectedQuestionID: String? = nil, expectedInteractionID: UUID? = nil) {
        guard !store.isReadOnly, expectedInteractionID == nil || expectedInteractionID == questionGeneration, screen == .incorrectFeedback,
              let question = currentQuestion, question.isPlayable,
              let selectedAnswerID, selectedAnswerID != question.correctAnswerID,
              expectedQuestionID == nil || expectedQuestionID == question.id else { return }
        questionGeneration = UUID()
        self.selectedAnswerID = nil
        screen = .question
    }

    func presentCatchIntro(expectedQuestionID: String? = nil, expectedInteractionID: UUID? = nil) {
        guard !store.isReadOnly, expectedInteractionID == nil || expectedInteractionID == questionGeneration, screen == .correctFeedback,
              let question = currentQuestion, question.isPlayable,
              selectedAnswerID == question.correctAnswerID,
              expectedQuestionID == nil || expectedQuestionID == question.id else { return }
        questionGeneration = UUID()
        screen = .catchIntro
    }

    func beginCatch(expectedQuestionID: String? = nil, expectedInteractionID: UUID? = nil) {
        guard !store.isReadOnly, expectedInteractionID == nil || expectedInteractionID == questionGeneration, screen == .catchIntro,
              let question = currentQuestion, question.isPlayable, var session,
              selectedAnswerID == question.correctAnswerID,
              expectedQuestionID == nil || expectedQuestionID == question.id else { return }
        questionGeneration = UUID()
        stopGameplay()
        if !activeObstacles.intersection([.vines, .branch, .puddle]).isEmpty && obstacleLibrary == nil {
            screen = .error
            message = "required game obstacle geometry is unavailable. this round cannot start safely; no progress has been removed."
            return
        }
        session.goodFruitCaughtThisRound = 0
        self.session = session
        activeFruit.removeAll()
        activeStars.removeAll()
        catchTransits.removeAll()
        classificationStarAvailable = false
        classificationFruit = nil
        basketX = 0.5
        basketTargetX = 0.5
        basketResistance = 0
        basketIsInPuddle = false
        vineContactSequence = 0
        roundResultLocked = false
        isPaused = false
        roundID = UUID()
        roundLedger = Prompt28RoundLedger(roundID: roundID, targetFruit: engine.rules.goodFruitTarget,
            gameLevelPlayed: session.currentGameLevel, startingScore: session.score, startingPasses: session.availableStarPasses)
        roundResult = nil
        pendingRoundSuccess = nil
        spawnPlanner.reset()
        starPlanner = Prompt28RareStarPlanner()
        nextSpawnInterval = random(in: levelConfig.spawnIntervalRange)
        lastSpawnAt = .distantPast
        screen = .catchActive

        if store.controlMode == .classification {
            spawnClassificationFruit()
        } else {
            startGameplayLoop()
        }
    }

    func updatePlayfield(size: CGSize) {
        playfieldSize = size
    }

    func moveBasket(to normalizedX: Double) {
        guard screen == .catchActive, !isPaused, normalizedX.isFinite else { return }
        basketTargetX = min(max(normalizedX, 0.10), 0.90)
        if !activeObstacles.contains(.puddle) { basketX = basketTargetX }
    }

    func classificationDecision(accept: Bool, expectedFruitID: UUID? = nil, expectedInteractionID: UUID? = nil) {
        guard
            screen == .catchActive, !isPaused, !store.isReadOnly, catchTransits.isEmpty,
            store.controlMode == .classification,
            let fruit = classificationFruit,
            expectedFruitID == nil || expectedFruitID == fruit.id,
            expectedInteractionID == nil || expectedInteractionID == questionGeneration,
            !roundResultLocked
        else { return }

        questionGeneration = UUID()
        classificationFruit = nil
        if accept {
            catchTransits.append(.init(id: fruit.id, kind: .fruit(fruit.fruitID, fruit.classification), relativeX: 0))
            startGameplayLoop()
        } else {
            if fruit.classification == .good { handleGoodMiss(eventID: fruit.id) } else { handleBadMiss(eventID: fruit.id) }
            spawnClassificationFruit()
        }
    }

    func classificationStarDecision(accept: Bool, expectedInteractionID: UUID? = nil) {
        guard screen == .catchActive, !isPaused, !store.isReadOnly, store.controlMode == .classification,
              classificationStarAvailable, catchTransits.isEmpty, !roundResultLocked,
              expectedInteractionID == nil || expectedInteractionID == questionGeneration else { return }
        questionGeneration = UUID()
        classificationStarAvailable = false
        if accept {
            catchTransits.append(.init(id: UUID(), kind: .star, relativeX: 0))
            startGameplayLoop()
        } else {
            _ = roundLedger.recordPassedStar(eventID: UUID())
            spawnClassificationFruit()
        }
    }

    func pause() {
        if roundResultLocked { resolvePendingRound(); return }
        guard screen == .catchActive else { return }
        questionGeneration = UUID()
        isPaused = true
        gameplayTask?.cancel()
        gameplayTask = nil
        screen = .paused
    }

    func resume() {
        guard screen == .paused, !roundResultLocked else { return }
        isPaused = false
        screen = .catchActive
        if store.controlMode == .catchMode || !catchTransits.isEmpty { startGameplayLoop() }
        else if classificationFruit == nil && !classificationStarAvailable { spawnClassificationFruit() }
    }

    func retryRound(expectedQuestionID: String? = nil, expectedRoundID: UUID? = nil, expectedInteractionID: UUID? = nil) {
        guard !store.isReadOnly, expectedInteractionID == nil || expectedInteractionID == questionGeneration, screen == .catchUnsuccessful, session != nil,
              let question = currentQuestion, question.isPlayable,
              selectedAnswerID == question.correctAnswerID,
              let result = roundResult, !result.succeeded, result.roundID == roundLedger.roundID,
              expectedQuestionID == nil || expectedQuestionID == question.id,
              expectedRoundID == nil || expectedRoundID == result.roundID else { return }
        lastBadFruit = nil
        screen = .catchIntro
        beginCatch(expectedQuestionID: question.id)
    }

    func resetGameLevel() {
        guard !store.isReadOnly else { return }
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

    func continueAfterReveal(expectedRoundID: UUID? = nil, expectedInteractionID: UUID? = nil) async {
        guard !Task.isCancelled, !store.isReadOnly, expectedInteractionID == nil || expectedInteractionID == questionGeneration, screen == .basketReveal,
              let result = roundResult, result.succeeded, result.roundID == roundLedger.roundID,
              expectedRoundID == nil || expectedRoundID == result.roundID,
              var session else { return }
        questionGeneration = UUID()
        screen = .learningSetup
        session.currentRound += 1
        session.goodFruitCaughtThisRound = 0
        self.session = session
        await loadQuestion()
    }

    func changeTopic() {
        questionGeneration = UUID()
        stopGameplay()
        currentQuestion = nil
        selectedAnswerID = nil
        session = nil
        roundResult = nil
        roundLedger = Prompt28RoundLedger()
        rawTopic = ""
        screen = .learningSetup
    }

    func setControlMode(_ mode: Prompt28ControlMode) {
        guard !store.isReadOnly else { return }
        guard mode != store.controlMode else { return }
        // Earned counters and entering objects survive the control change.
        // Unselected presentations are replaced so no invisible object can catch.
        activeFruit.removeAll(); activeStars.removeAll()
        classificationFruit = nil; classificationStarAvailable = false
        basketTargetX = basketX; basketResistance = 0; basketIsInPuddle = false
        store.controlMode = mode
        store.persistPreferences()
    }

    func sceneBecameInactive() {
        questionGeneration = UUID()
        if screen == .loading { screen = .learningSetup }
        if roundResultLocked { resolvePendingRound() }
        else if screen == .catchActive { pause() }
    }

    func leaveScreen() {
        questionGeneration = UUID()
        if screen == .loading { screen = .learningSetup }
        sceneBecameInactive()
        stopGameplay()
    }

    private func resolvePendingRound() {
        guard let success = pendingRoundSuccess else { return }
        roundCompletionTask?.cancel()
        if success { finishSuccessfulRound(expectedRoundID: roundID) }
        else { finishUnsuccessfulRound(expectedRoundID: roundID) }
    }

    func savePendingContent() -> Prompt10PendingSavedContent? {
        guard let question = currentQuestion, question.isPlayable else { return nil }
        return Prompt28SavedResearchCopy.pending(question: question)
    }

    private func startGameplayLoop() {
        gameplayTask?.cancel()
        gameplayTask = Task { [weak self] in
            var previous = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000)
                // Keep ownership local to this frame, never across the next sleep.
                guard !Task.isCancelled, let self else { break }
                let now = Date()
                let delta = min(max(now.timeIntervalSince(previous), 0.001), 0.08)
                previous = now
                self.advanceGameplayFrame(delta: delta, now: now)
            }
        }
    }

    /// Shared frame entry for the owned clock and deterministic regression driving.
    func advanceGameplayFrame(delta: TimeInterval, now: Date) {
        guard delta.isFinite, delta > 0 else { return }
        let frameDelta = min(delta, 0.08)
        guard screen == .catchActive, !isPaused, !roundResultLocked, !store.isReadOnly else { return }
        let geometry = Prompt28CatchGeometry(playfield: playfieldSize)
        var pending: [Prompt28CatchTransit] = []
        for var transit in catchTransits {
            if transit.advance(by: frameDelta) {
                switch transit.kind {
                case .star: handleStarCatch(eventID: transit.id)
                case .fruit(let fruit, .good): handleGoodCatch(fruit, eventID: transit.id)
                case .fruit(let fruit, .bad): handleBadCatch(fruit, eventID: transit.id)
                }
            } else { pending.append(transit) }
            if roundResultLocked { break }
        }
        catchTransits = roundResultLocked ? [] : pending
        guard !store.isReadOnly else { stopGameplay(); return }
        guard !roundResultLocked else { return }
        if store.controlMode == .classification {
            if catchTransits.isEmpty {
                stopGameplay()
                if classificationFruit == nil && !classificationStarAvailable { spawnClassificationFruit() }
            }
            return
        }
        let obstacleGeometry = obstacleLibrary.map { Prompt28ObstacleGeometry(playfield: playfieldSize, level: gameLevel, library: $0) }
        if let obstacleGeometry {
            let response = Prompt28ObstaclePhysics.moveBasket(position: basketX, target: basketTargetX, delta: frameDelta,
                geometry: obstacleGeometry, puddleActive: activeObstacles.contains(.puddle))
            basketX = response.position; basketResistance = response.resistance
            basketIsInPuddle = activeObstacles.contains(.puddle) && obstacleGeometry.basketTouchesPuddle(at: basketX)
        } else { basketX = basketTargetX; basketResistance = 0; basketIsInPuddle = false }
        var remaining: [Prompt28FallingFruit] = []

        let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
        for var fruit in activeFruit {
            let previousY = fruit.y
            if let obstacleGeometry {
                if Prompt28ObstaclePhysics.advanceFruit(&fruit, delta: frameDelta, geometry: obstacleGeometry,
                    obstacles: activeObstacles, lanes: laneBounds, windDirection: windDirection, weather: weather) {
                    vineContactSequence += 1
                }
            } else {
                fruit.y += fruit.fallSpeed * frameDelta
                fruit.x = min(max(fruit.x + fruit.horizontalDrift * frameDelta, laneBounds.lowerBound), laneBounds.upperBound)
            }

            if geometry.crossedMouth(x: fruit.x, previousY: previousY, currentY: fruit.y, basketX: basketX, objectSize: geometry.fruitSize) {
                catchTransits.append(.init(id: fruit.id, kind: .fruit(fruit.fruitID, fruit.classification), relativeX: fruit.x - basketX))
                continue
            }

            if fruit.y > 1.06 {
                if fruit.classification == .good { handleGoodMiss(eventID: fruit.id) }
                else { handleBadMiss(eventID: fruit.id) }
                continue
            }

            remaining.append(fruit)
        }

        activeFruit = roundResultLocked ? [] : remaining
        guard !roundResultLocked else { return }

        var remainingStars: [Prompt28FallingStar] = []
        for var star in activeStars {
            let previousY = star.y
            if let obstacleGeometry {
                if Prompt28ObstaclePhysics.advanceStar(&star, delta: frameDelta, geometry: obstacleGeometry,
                    obstacles: activeObstacles, lanes: laneBounds, windDirection: windDirection, weather: weather) {
                    vineContactSequence += 1
                }
            } else {
                star.y += star.fallSpeed * frameDelta
                star.x = min(max(star.x + star.horizontalDrift * frameDelta, laneBounds.lowerBound), laneBounds.upperBound)
            }

            if geometry.crossedMouth(x: star.x, previousY: previousY, currentY: star.y, basketX: basketX, objectSize: geometry.starSize) {
                catchTransits.append(.init(id: star.id, kind: .star, relativeX: star.x - basketX))
                continue
            }
            if star.y <= 1.06 { remainingStars.append(star) }
            else { _ = roundLedger.recordPassedStar(eventID: star.id) }
        }
        activeStars = remainingStars

        if activeFruit.count + activeStars.count + catchTransits.count < levelConfig.maxConcurrentItems,
           now.timeIntervalSince(lastSpawnAt) >= nextSpawnInterval {
            spawnFruit()
            lastSpawnAt = now
            nextSpawnInterval = random(in: levelConfig.spawnIntervalRange)
        }
    }

    private func spawnFruit() {
        guard let question = currentQuestion else { return }
        if starPlanner.shouldDropStar(randomUnit: Double.random(in: 0...1)) {
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
        let x = Double.random(in: max(0.12, laneBounds.lowerBound)...min(0.88, laneBounds.upperBound))
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
        questionGeneration = UUID()
        if starPlanner.shouldDropStar(randomUnit: Double.random(in: 0...1)) {
            classificationFruit = nil
            classificationStarAvailable = true
            return
        }
        classificationStarAvailable = false
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

    private func handleGoodCatch(_ fruit: Prompt28FruitID, eventID: UUID) {
        guard !store.isReadOnly, !roundResultLocked, var session else { return }
        var ledger = roundLedger
        guard ledger.recordGoodFruit(fruit, eventID: eventID) else { return }
        let outcome = engine.registerGoodCatch(session: &session)
        var progress = store.progress(for: session.normalizedTopicID)
            ?? Prompt28TopicProgress(normalizedTopicID: session.normalizedTopicID)
        progress.totalFruitCaught += 1
        guard store.updateProgress(progress) else { return }
        roundLedger = ledger
        self.session = session
        if outcome == .success {
            roundResultLocked = true
            pendingRoundSuccess = true
            let completedRoundID = roundID
            stopGameplay()
            roundCompletionTask?.cancel()
            roundCompletionTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 650_000_000)
                guard !Task.isCancelled, let self else { return }
                self.finishSuccessfulRound(expectedRoundID: completedRoundID)
            }
        }
    }

    private func handleGoodMiss(eventID: UUID) {
        guard !store.isReadOnly, !roundResultLocked, var session,
              roundLedger.recordPassedFruit(.good, eventID: eventID) else { return }
        _ = engine.registerGoodMiss(session: &session)
        self.session = session
    }

    private func handleBadMiss(eventID: UUID) {
        guard !store.isReadOnly, !roundResultLocked, var session,
              roundLedger.recordPassedFruit(.bad, eventID: eventID) else { return }
        _ = engine.registerBadMiss(session: &session)
        self.session = session
    }

    private func handleStarCatch(eventID: UUID) {
        guard !store.isReadOnly, !roundResultLocked, var session else { return }
        var ledger = roundLedger
        guard ledger.recordStar(eventID: eventID) else { return }
        _ = engine.registerStarCatch(session: &session)
        var progress = store.progress(for: session.normalizedTopicID)
            ?? Prompt28TopicProgress(normalizedTopicID: session.normalizedTopicID)
        progress.totalStarsEarned += 1
        guard store.updateProgress(progress) else { return }
        roundLedger = ledger
        self.session = session
    }

    private func handleBadCatch(_ fruit: Prompt28FruitID, eventID: UUID) {
        guard !store.isReadOnly, !roundResultLocked, var session, roundLedger.canRecord(eventID) else { return }
        let outcome = engine.registerBadCatch(fruit, session: &session)
        _ = roundLedger.recordBadFruit(fruit, outcome: outcome, eventID: eventID)
        self.session = session
        lastBadFruit = fruit
        guard case .unsuccessful = outcome else { return }
        roundResultLocked = true
        pendingRoundSuccess = false
        let completedRoundID = roundID
        stopGameplay()
        activeFruit.removeAll(); activeStars.removeAll(); catchTransits.removeAll(); classificationFruit = nil
        roundCompletionTask?.cancel()
        roundCompletionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled, let self else { return }
            self.finishUnsuccessfulRound(expectedRoundID: completedRoundID)
        }
    }

    private func finishSuccessfulRound(expectedRoundID: UUID) {
        guard !store.isReadOnly, expectedRoundID == roundID, finalizedRoundID != expectedRoundID,
              pendingRoundSuccess == true, var session else { return }
        guard roundLedger.terminalSuccess == true,
              roundLedger.caughtFruit.count == session.goodFruitCaughtThisRound else {
            pendingRoundSuccess = nil
            message = "the round result could not be verified from its capture events."
            screen = .error
            return
        }
        finalizedRoundID = expectedRoundID
        pendingRoundSuccess = nil
        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress = Prompt28ProgressionPolicy.afterSuccessfulRound(progress)
        didSetPersonalBestThisRound = session.score > progress.bestScore
        progress.bestScore = max(progress.bestScore, session.score)
        progress.bestStreak = max(progress.bestStreak, session.currentStreak)
        store.updateProgress(progress)
        guard !store.isReadOnly else { return }
        session.currentGameLevel = progress.currentGameLevel
        self.session = session
        roundResult = roundLedger.result(score: session.score, passesRemaining: session.availableStarPasses, nextGameLevel: session.currentGameLevel)
        guard roundResult?.succeeded == true else {
            message = "the round result could not be verified from its capture events."
            screen = .error
            return
        }
        screen = .basketReveal
    }

    private func finishUnsuccessfulRound(expectedRoundID: UUID) {
        guard !store.isReadOnly, expectedRoundID == roundID, finalizedRoundID != expectedRoundID,
              pendingRoundSuccess == false, var session else { return }
        guard roundLedger.terminalSuccess == false else {
            pendingRoundSuccess = nil
            message = "the round-ending event could not be verified."
            screen = .error
            return
        }
        finalizedRoundID = expectedRoundID
        pendingRoundSuccess = nil
        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress = Prompt28ProgressionPolicy.afterUnsuccessfulRound(progress)
        progress.bestScore = max(progress.bestScore, session.score)
        progress.bestStreak = max(progress.bestStreak, session.currentStreak)
        store.updateProgress(progress)
        guard !store.isReadOnly else { return }
        session.currentGameLevel = progress.currentGameLevel
        self.session = session
        roundResult = roundLedger.result(score: session.score, passesRemaining: session.availableStarPasses, nextGameLevel: session.currentGameLevel)
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

#if canImport(Combine)
extension Prompt28FruitBasketViewModel: ObservableObject {}
#endif
