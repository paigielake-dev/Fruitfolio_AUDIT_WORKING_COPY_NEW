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
    @Published private(set) var roundCollection = Prompt28RoundCollection()
    @Published var currentQuestion: Prompt28Question?
    @Published var selectedAnswerID: String?
    @Published var session: Prompt28Session?
    @Published var activeFruit: [Prompt28FallingFruit] = []
    @Published private(set) var vineContactCount = 0
    @Published private(set) var branchContactCount = 0
    @Published private(set) var puddleMovementActive = false
    @Published private(set) var puddleContactActive = false
    private var branchDeflections: [UUID: Prompt28BranchDeflection] = [:]
    private var previousVineContacts: Set<UUID> = []
    private var gameplayFieldSize = CGSize.zero
    private var catchClock: TimeInterval = 0
    private var landingOrder = 0
    private var pendingLandings: [PendingLanding] = []

    private enum LandingKind { case fruit(Prompt28FruitID, Prompt28FruitClassification), star }
    private struct PendingLanding {
        let id: UUID
        let kind: LandingKind
        let readyAt: TimeInterval
        let order: Int
        var artworkSettled = false
        var presentationID: UUID?
    }
    @Published private(set) var settledCatches: [Prompt28SettledCatch] = []
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
    var availableStarPasses: Int { session?.availableStarPasses ?? 0 }
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
        guard store.loadError == nil else {
            message = store.loadError; screen = .error; return
        }
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
        guard store.loadError == nil else {
            message = store.loadError; screen = .error; return
        }
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
        roundCollection = .init(startingStarPasses: session.availableStarPasses, startingScore: session.score)
        self.session = session
        activeFruit.removeAll()
        activeStars.removeAll()
        settledCatches.removeAll()
        pendingLandings.removeAll()
        catchClock = 0
        landingOrder = 0
        classificationFruit = nil
        basketX = 0.5
        basketIsMeetingPuddleResistance = false
        isPaused = false
        showingStormNotice = false
        roundResultLocked = false
        spawnPlanner.reset()
        previousVineContacts = []
        branchDeflections = [:]
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
        guard normalizedX.isFinite else { return }
        let target = min(max(normalizedX, 0.10), 0.90)
        let previousX = basketX
        guard activeObstacles.contains(.puddle) else {
            basketIsMeetingPuddleResistance = false
            puddleMovementActive = false
            puddleContactActive = false
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
        // Audio follows real displacement inside the physical puddle, not a timer.
        puddleContactActive = basketX >= 0.33 && basketX <= 0.67
        puddleMovementActive = abs(basketX - previousX) > 0.000001 && puddleContactActive
    }

    func basketMovementEnded() { puddleMovementActive = false }

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
        let references = question.sourceTitles.joined(separator: "\n")
        let fruitNames = roundCollection.goodFruit.map(\.displayName).joined(separator: ", ")
        let outcome = "round results\ngood fruit collected: \(fruitNames)\nunstarred fruit caught: \(roundCollection.badFruit.count)\nstandalone stars collected: \(roundCollection.standaloneStarsCaught)\nstar passes used: \(roundCollection.starPassesConsumed)\nstar passes available: \(session?.availableStarPasses ?? 0)\nscore this round: \((session?.score ?? 0) - roundCollection.startingScore)"
        let revealBody = "basket reveal\n\n\(question.explanation)\n\n\(references)\n\n\(outcome)"
        return Prompt10PendingSavedContent(
            question: "basket reveal",
            answer: revealBody,
            saveType: .fullAnswer,
            originalAnswerID: "fruitbasket:\(question.id)",
            sourceIDs: question.sourceIDs,
            sourceVersions: Dictionary(uniqueKeysWithValues: (question.evidenceSnapshot?.sources ?? []).map { ($0.sourceID, $0.contentVersion) }),
            sourceSnapshots: question.evidenceSnapshot?.sources.map { source in
                AskSourceRecord(id: source.sourceID, title: source.apa7Reference ?? source.title,
                    sourceText: source.apa7Reference, urlString: source.canonicalURL, doi: source.doi,
                    publicationData: source.publicationDate, contentVersion: source.contentVersion)
            },
            knowledgeBaseVersion: question.contentVersion,
            generationTimestamp: question.createdAt
        )
    }

    private func startGameplayLoop() {
        gameplayTask?.cancel()
        gameplayTask = Task { [weak self] in
            var previous = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000)
                // Hold the model only during this synchronous frame. Keeping
                // a strong self before the loop retains it across every sleep
                // and prevents deinit's cancellation if a host drops the view
                // without delivering its ordinary disappearance callback.
                guard !Task.isCancelled, let self else { break }
                let now = Date()
                let delta = min(max(now.timeIntervalSince(previous), 0.001), 0.08)
                previous = now
                self.tick(delta: delta, now: now)
            }
        }
    }

    func updateGameplayFieldSize(width: Double, height: Double) {
        guard width.isFinite, height.isFinite, width > 0, height > 0 else { return }
        gameplayFieldSize = CGSize(width: width, height: height)
    }

    func isMeetingVines(x: Double, y: Double, classification: Prompt28FruitClassification = .good) -> Bool {
        guard classification == .good, activeObstacles.contains(.vines) else { return false }
        return Prompt28VineContactGeometry(fieldWidth: gameplayFieldSize.width,
                                          fieldHeight: gameplayFieldSize.height,
                                          level: gameLevel).contains(x: x, y: y)
    }

    // Internal frame entry point is also exercised by deterministic physics tests.
    func tick(delta: TimeInterval, now: Date) {
        guard screen == .catchActive, !isPaused, !roundResultLocked, delta.isFinite, delta >= 0 else { return }
        catchClock += delta
        var remaining: [Prompt28FallingFruit] = []
        var currentVineContacts: Set<UUID> = []

        let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
        for var fruit in activeFruit {
            let previousY = fruit.y
            let meetingVines = isMeetingVines(x: fruit.x, y: fruit.y, classification: fruit.classification)
            if meetingVines { currentVineContacts.insert(fruit.id) }
            let vineMultiplier = meetingVines ? 0.56 : 1.0
            if activeObstacles.contains(.branch), branchDeflections[fruit.id] == nil {
                let geometry = Prompt28BranchContactGeometry(fieldWidth: gameplayFieldSize.width,
                                                              fieldHeight: gameplayFieldSize.height)
                let radius = min(max(gameplayFieldSize.width * 0.13, 46), 66) * 0.44
                if geometry.contains(x: fruit.x, y: fruit.y + fruit.fallSpeed * delta, radius: radius) {
                    branchContactCount += 1
                    branchDeflections[fruit.id] = Prompt28BranchDeflection(horizontalVelocity: -max(abs(fruit.horizontalDrift), 0.08))
                }
            }
            let bounce = branchDeflections[fruit.id]
            fruit.y += fruit.fallSpeed * vineMultiplier * (bounce?.verticalMultiplier ?? 1) * delta
            var horizontalVelocity = bounce?.horizontalVelocity ?? fruit.horizontalDrift
            if var bounce {
                bounce.elapsed += delta
                branchDeflections[fruit.id] = bounce
            }
            if activeObstacles.contains(.wind) {
                horizontalVelocity += windDirection * (weather == .softRain ? 0.030 : 0.021)
            }

            fruit.x = min(max(fruit.x + horizontalVelocity * delta, laneBounds.lowerBound), laneBounds.upperBound)

            if engine.collision(fruitX: fruit.x, fruitY: fruit.y, basketX: basketX,
                                fieldWidth: gameplayFieldSize.width, fieldHeight: gameplayFieldSize.height,
                                itemDiameter: Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: gameplayFieldSize.width),
                                previousY: previousY) {
                beginLanding(id: fruit.id, kind: .fruit(fruit.fruitID, fruit.classification),
                             previousY: previousY, currentY: fruit.y,
                             diameter: Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: gameplayFieldSize.width), delta: delta)
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
        let remainingIDs = Set(activeFruit.map(\.id))
        branchDeflections = branchDeflections.filter { remainingIDs.contains($0.key) }
        guard !roundResultLocked else { return }

        var remainingStars: [Prompt28FallingStar] = []
        for var star in activeStars {
            let previousY = star.y
            let meetingVines = isMeetingVines(x: star.x, y: star.y)
            if meetingVines { currentVineContacts.insert(star.id) }
            let vineMultiplier = meetingVines ? 0.56 : 1.0
            star.y += star.fallSpeed * vineMultiplier * delta
            star.x = min(max(star.x + star.horizontalDrift * delta, laneBounds.lowerBound), laneBounds.upperBound)
            if engine.collision(fruitX: star.x, fruitY: star.y, basketX: basketX,
                                fieldWidth: gameplayFieldSize.width, fieldHeight: gameplayFieldSize.height,
                                itemDiameter: Prompt28BasketCatchGeometry.starDiameter(fieldWidth: gameplayFieldSize.width),
                                previousY: previousY) {
                beginLanding(id: star.id, kind: .star, previousY: previousY, currentY: star.y,
                             diameter: Prompt28BasketCatchGeometry.starDiameter(fieldWidth: gameplayFieldSize.width), delta: delta)
                continue
            }
            if star.y <= 1.06 { remainingStars.append(star) }
        }
        activeStars = remainingStars
        collectReadyLandings()
        guard !roundResultLocked else { return }
        if !currentVineContacts.subtracting(previousVineContacts).isEmpty { vineContactCount += 1 }
        previousVineContacts = currentVineContacts

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

    private func beginLanding(id: UUID, kind: LandingKind, previousY: Double, currentY: Double,
                              diameter: Double, delta: TimeInterval) {
        guard !pendingLandings.contains(where: { $0.id == id }) else { return }
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: gameplayFieldSize.width, fieldHeight: gameplayFieldSize.height)
        let threshold = (geometry.mouthY + diameter / 2) / gameplayFieldSize.height
        let fraction = currentY > previousY ? min(max((threshold - previousY) / (currentY - previousY), 0), 1) : 0
        let asset: FruitfolioAssetID
        let isStar: Bool
        switch kind {
        case .fruit(let fruit, _): asset = fruit.assetID; isStar = false
        case .star: asset = .fruitbasket_star; isStar = true
        }
        settledCatches.append(.init(id: id, assetID: asset, isStar: isStar))
        pendingLandings.append(.init(id: id, kind: kind,
            readyAt: catchClock - delta + fraction * delta + Prompt28BasketCatchGeometry.settlingDuration,
            order: landingOrder))
        landingOrder += 1
    }

    /// A real presentation completion, not a timer-only guess. Repeated/stale
    /// callbacks cannot collect twice. Paused games retain the acknowledgement
    /// but never advance scoring until active play resumes.
    func handleCatchPresentation(id: UUID, event: Prompt28CatchPresentationEvent) {
        guard let index = pendingLandings.firstIndex(where: { $0.id == id }) else { return }
        switch event {
        case .appeared(let token):
            pendingLandings[index].presentationID = token
            pendingLandings[index].artworkSettled = false
        case .settled(let token):
            guard pendingLandings[index].presentationID == token else { return }
            pendingLandings[index].artworkSettled = true
        case .disappeared(let token):
            guard pendingLandings[index].presentationID == token else { return }
            pendingLandings[index].presentationID = nil
            pendingLandings[index].artworkSettled = false
        }
        collectReadyLandings()
    }

    private func collectReadyLandings() {
        guard screen == .catchActive, !isPaused, !roundResultLocked else { return }
        let ready = pendingLandings.filter { $0.presentationID != nil && $0.artworkSettled && $0.readyAt <= catchClock }
            .sorted { $0.readyAt == $1.readyAt ? $0.order < $1.order : $0.readyAt < $1.readyAt }
        let readyIDs = Set(ready.map(\.id))
        pendingLandings.removeAll { readyIDs.contains($0.id) }
        var collectedIDs: Set<UUID> = []
        for landing in ready {
            guard !roundResultLocked else { break }
            collectedIDs.insert(landing.id)
            if let index = settledCatches.firstIndex(where: { $0.id == landing.id }) {
                settledCatches[index].collected = true
            }
            switch landing.kind {
            case .fruit(let fruit, .good): handleGoodCatch(fruit, existingArtworkID: landing.id)
            case .fruit(let fruit, .bad): handleBadCatch(fruit)
            case .star: handleStarCatch(existingArtworkID: landing.id)
            }
        }
        if roundResultLocked {
            let uncollected = readyIDs.subtracting(collectedIDs).union(pendingLandings.map(\.id))
            settledCatches.removeAll { uncollected.contains($0.id) }
            pendingLandings.removeAll()
        }
    }

    private func handleGoodCatch(_ fruit: Prompt28FruitID, existingArtworkID: UUID? = nil) {
        guard !roundResultLocked, var session else { return }
        if existingArtworkID == nil {
            settledCatches.append(.init(id: UUID(), assetID: fruit.assetID, isStar: false, collected: true))
        }
        let outcome = engine.registerGoodCatch(session: &session)
        roundCollection.goodFruit.append(fruit)
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

    private func handleStarCatch(existingArtworkID: UUID? = nil) {
        guard !roundResultLocked, var session else { return }
        if existingArtworkID == nil {
            settledCatches.append(.init(id: UUID(), assetID: .fruitbasket_star, isStar: true, collected: true))
        }
        if settledCatches.filter({ $0.isStar && $0.collected }).count > 8,
           let oldestStar = settledCatches.firstIndex(where: { $0.isStar && $0.collected }) {
            settledCatches.remove(at: oldestStar)
        }
        _ = engine.registerStarCatch(session: &session)
        roundCollection.standaloneStarsCaught += 1
        self.session = session

        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress.totalStarsEarned += 1
        store.updateProgress(progress)
    }

    private func handleBadCatch(_ fruit: Prompt28FruitID) {
        guard !roundResultLocked, var session else { return }
        let outcome = engine.registerBadCatch(fruit, session: &session)
        roundCollection.badFruit.append(fruit)
        if case .badFruitBlockedByStar = outcome { roundCollection.starPassesConsumed += 1 }
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
        puddleMovementActive = false
        puddleContactActive = false
        gameplayTask?.cancel(); gameplayTask = nil
        roundCompletionTask?.cancel(); roundCompletionTask = nil
    }

    private func random(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}
