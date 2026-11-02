import Combine
import Foundation
import SwiftUI

enum Prompt04IntroStage: String, CaseIterable, Sendable {
    case initialStillness
    case blankBookArriving
    case blankBookSettled
    case logoRevealing
    case brandedBookSettled
    case slightlyOpening
    case slightlyOpenSettled
    case fullyOpening
    case fullyOpenSettled
    case rightPageFocusing
    case standalonePaperResolving
    case hubRevealing
    case introComplete
}

/// One authoritative, cancellable Prompt 04 progression.
/// No Timer or delayed-callback pile is used. Every main book state has its own
/// readable stage, followed by a right-page focus, standalone-paper resolve,
/// and final live-Hub reveal.
@MainActor
final class Prompt04IntroStateMachine: ObservableObject {
    @Published private(set) var stage: Prompt04IntroStage = .initialStillness
    @Published private(set) var bookArrivalProgress: CGFloat = 0
    @Published private(set) var logoRevealProgress: CGFloat = 0
    @Published private(set) var brandedBookResolved = false
    @Published private(set) var logoSettleScale: CGFloat = 1
    @Published private(set) var sparkleOpacity: CGFloat = 0
    @Published private(set) var slightlyOpenProgress: CGFloat = 0
    @Published private(set) var fullyOpenProgress: CGFloat = 0
    @Published private(set) var rightPageFocusProgress: CGFloat = 0
    @Published private(set) var standalonePaperProgress: CGFloat = 0
    @Published private(set) var hubRevealProgress: CGFloat = 0
    @Published private(set) var hubInteractionEnabled = false
    @Published private(set) var hasStarted = false

    private var sequenceTask: Task<Void, Never>?
    private var sequenceGeneration: UInt = 0

    deinit {
        sequenceTask?.cancel()
    }

    func start(
        mode: Prompt04LaunchMode,
        audioManager: AudioManager,
        settings: SettingsStore,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void
    ) {
        guard !hasStarted else { return }

        hasStarted = true
        sequenceGeneration &+= 1

        let generation = sequenceGeneration

        resetVisualState()

        startAmbience(
            audioManager: audioManager,
            settings: settings
        )

        sequenceTask = Task { @MainActor [weak self] in
            guard let self else { return }

            if mode.usesReducedMotion {
                await self.runReducedMotionSequence(
                    mode: mode,
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion
                )
            } else if mode.isFirstLaunch {
                await self.runFirstLaunchSequence(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion
                )
            } else {
                await self.runReturningSequence(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion
                )
            }
        }
    }

    func handleBackgrounding(
        audioManager: AudioManager
    ) {
        guard hasStarted, stage != .introComplete else { return }

        sequenceGeneration &+= 1
        sequenceTask?.cancel()
        sequenceTask = nil

        audioManager.stop(category: .music)
        audioManager.stop(category: .rainAmbience)

        switch stage {
        case .initialStillness,
             .blankBookArriving,
             .blankBookSettled:
            settleAtBlankBook()

        case .logoRevealing,
             .brandedBookSettled:
            settleAtBrandedBook()

        case .slightlyOpening,
             .slightlyOpenSettled:
            settleAtSlightlyOpenBook()

        case .fullyOpening,
             .fullyOpenSettled:
            settleAtFullyOpenBook()

        case .rightPageFocusing:
            settleAtFullyOpenBook()

        case .standalonePaperResolving,
             .hubRevealing:
            settleAtHubPaper()

        case .introComplete:
            break
        }
    }

    func resolveAfterInterruption(
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void,
        wasFirstLaunch: Bool
    ) {
        guard hasStarted, stage != .introComplete else { return }

        sequenceGeneration &+= 1

        let generation = sequenceGeneration

        sequenceTask?.cancel()

        sequenceTask = Task { @MainActor [weak self] in
            guard let self else { return }

            switch self.stage {
            case .blankBookSettled:
                self.settleAtBrandedBook()

                guard await self.sleep(
                    .milliseconds(120),
                    generation: generation
                ) else {
                    return
                }

                await self.finishFromBrandedBook(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion,
                    wasFirstLaunch: wasFirstLaunch
                )

            case .brandedBookSettled:
                await self.finishFromBrandedBook(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion,
                    wasFirstLaunch: wasFirstLaunch
                )

            case .slightlyOpenSettled:
                await self.finishFromSlightlyOpenBook(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion,
                    wasFirstLaunch: wasFirstLaunch
                )

            case .fullyOpenSettled:
                await self.finishFromFullyOpenBook(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion,
                    wasFirstLaunch: wasFirstLaunch
                )

            case .hubRevealing,
                 .standalonePaperResolving:
                self.settleAtHubPaper()

                await self.complete(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion,
                    wasFirstLaunch: wasFirstLaunch
                )

            case .introComplete:
                break

            default:
                self.settleAtFullyOpenBook()

                await self.finishFromFullyOpenBook(
                    generation: generation,
                    audioManager: audioManager,
                    completion: completion,
                    wasFirstLaunch: wasFirstLaunch
                )
            }
        }
    }

    private func runFirstLaunchSequence(
        generation: UInt,
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void
    ) async {
        guard await sleep(
            Prompt04IntroConfiguration.initialStillness,
            generation: generation
        ) else {
            return
        }

        stage = .blankBookArriving

        withAnimation(
            .easeOut(
                duration: Prompt04IntroConfiguration
                    .firstLaunchBookArrival
                    .timeInterval
            )
        ) {
            bookArrivalProgress = 1
        }

        guard await sleep(
            Prompt04IntroConfiguration.firstLaunchBookArrival,
            generation: generation
        ) else {
            return
        }

        audioManager.play(.bookClose)

        stage = .blankBookSettled

        guard await sleep(
            Prompt04IntroConfiguration.blankBookHold,
            generation: generation
        ) else {
            return
        }

        stage = .logoRevealing

        withAnimation(
            .easeInOut(
                duration: Prompt04IntroConfiguration
                    .logoReveal
                    .timeInterval
            )
        ) {
            logoRevealProgress = 1
        }

        guard await sleep(
            Prompt04IntroConfiguration.logoReveal,
            generation: generation
        ) else {
            return
        }

        brandedBookResolved = true
        stage = .brandedBookSettled

        withAnimation(.easeInOut(duration: 0.18)) {
            logoSettleScale = 1.010
            sparkleOpacity = 0.58
        }

        audioManager.play(.starChime)

        guard await sleep(
            Prompt04IntroConfiguration.brandedSettlePulse,
            generation: generation
        ) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            logoSettleScale = 1
            sparkleOpacity = 0
        }

        guard await sleep(
            Prompt04IntroConfiguration.brandedBookHold,
            generation: generation
        ) else {
            return
        }

        stage = .slightlyOpening

        audioManager.play(.pageTurn)

        withAnimation(
            .easeInOut(
                duration: Prompt04IntroConfiguration
                    .slightlyOpenTransition
                    .timeInterval
            )
        ) {
            slightlyOpenProgress = 1
        }

        guard await sleep(
            Prompt04IntroConfiguration.slightlyOpenTransition,
            generation: generation
        ) else {
            return
        }

        stage = .slightlyOpenSettled

        guard await sleep(
            Prompt04IntroConfiguration.slightlyOpenHold,
            generation: generation
        ) else {
            return
        }

        stage = .fullyOpening

        audioManager.play(.pageTurn)

        withAnimation(
            .easeInOut(
                duration: Prompt04IntroConfiguration
                    .fullyOpenTransition
                    .timeInterval
            )
        ) {
            fullyOpenProgress = 1
        }

        guard await sleep(
            Prompt04IntroConfiguration.fullyOpenTransition,
            generation: generation
        ) else {
            return
        }

        stage = .fullyOpenSettled

        guard await sleep(
            Prompt04IntroConfiguration.fullyOpenHold,
            generation: generation
        ) else {
            return
        }

        await focusPageResolvePaperAndRevealHub(
            generation: generation,
            focusDuration: Prompt04IntroConfiguration.rightPageFocus,
            paperDuration: Prompt04IntroConfiguration.standalonePaperResolve,
            hubDuration: Prompt04IntroConfiguration.hubReveal,
            audioManager: audioManager,
            completion: completion,
            wasFirstLaunch: true
        )
    }

    private func runReturningSequence(
        generation: UInt,
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void
    ) async {
        settleAtBrandedBook()

        guard await sleep(
            Prompt04IntroConfiguration.returningClosedBookHold,
            generation: generation
        ) else {
            return
        }

        stage = .slightlyOpening

        audioManager.play(.pageTurn)

        withAnimation(
            .easeInOut(
                duration: Prompt04IntroConfiguration
                    .returningSlightlyOpenTransition
                    .timeInterval
            )
        ) {
            slightlyOpenProgress = 1
        }

        guard await sleep(
            Prompt04IntroConfiguration.returningSlightlyOpenTransition,
            generation: generation
        ) else {
            return
        }

        stage = .fullyOpening

        withAnimation(
            .easeInOut(
                duration: Prompt04IntroConfiguration
                    .returningFullyOpenTransition
                    .timeInterval
            )
        ) {
            fullyOpenProgress = 1
        }

        guard await sleep(
            Prompt04IntroConfiguration.returningFullyOpenTransition,
            generation: generation
        ) else {
            return
        }

        stage = .fullyOpenSettled

        await focusPageResolvePaperAndRevealHub(
            generation: generation,
            focusDuration: Prompt04IntroConfiguration.returningRightPageFocus,
            paperDuration: Prompt04IntroConfiguration.returningStandalonePaperResolve,
            hubDuration: Prompt04IntroConfiguration.returningHubReveal,
            audioManager: audioManager,
            completion: completion,
            wasFirstLaunch: false
        )
    }

    private func runReducedMotionSequence(
        mode: Prompt04LaunchMode,
        generation: UInt,
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void
    ) async {
        // Retain the normal stage clock. The view replaces the ripple/zoom/
        // arrival transforms with opacity-only transitions for Reduced Motion.
        if mode.isFirstLaunch {
            await runFirstLaunchSequence(
                generation: generation,
                audioManager: audioManager,
                completion: completion
            )
        } else {
            await runReturningSequence(
                generation: generation,
                audioManager: audioManager,
                completion: completion
            )
        }
    }

    private func finishFromBrandedBook(
        generation: UInt,
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void,
        wasFirstLaunch: Bool
    ) async {
        stage = .slightlyOpening

        withAnimation(.easeInOut(duration: 0.45)) {
            slightlyOpenProgress = 1
        }

        guard await sleep(
            .milliseconds(450),
            generation: generation
        ) else {
            return
        }

        await finishFromSlightlyOpenBook(
            generation: generation,
            audioManager: audioManager,
            completion: completion,
            wasFirstLaunch: wasFirstLaunch
        )
    }

    private func finishFromSlightlyOpenBook(
        generation: UInt,
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void,
        wasFirstLaunch: Bool
    ) async {
        stage = .fullyOpening

        withAnimation(.easeInOut(duration: 0.48)) {
            fullyOpenProgress = 1
        }

        guard await sleep(
            .milliseconds(480),
            generation: generation
        ) else {
            return
        }

        stage = .fullyOpenSettled

        await finishFromFullyOpenBook(
            generation: generation,
            audioManager: audioManager,
            completion: completion,
            wasFirstLaunch: wasFirstLaunch
        )
    }

    private func finishFromFullyOpenBook(
        generation: UInt,
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void,
        wasFirstLaunch: Bool
    ) async {
        await focusPageResolvePaperAndRevealHub(
            generation: generation,
            focusDuration: .milliseconds(420),
            paperDuration: .milliseconds(220),
            hubDuration: .milliseconds(280),
            audioManager: audioManager,
            completion: completion,
            wasFirstLaunch: wasFirstLaunch
        )
    }

    private func focusPageResolvePaperAndRevealHub(
        generation: UInt,
        focusDuration: Duration,
        paperDuration: Duration,
        hubDuration: Duration,
        audioManager: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void,
        wasFirstLaunch: Bool
    ) async {
        stage = .rightPageFocusing

        withAnimation(
            .easeInOut(duration: focusDuration.timeInterval)
        ) {
            rightPageFocusProgress = 1
        }

        guard await sleep(
            focusDuration,
            generation: generation
        ) else {
            return
        }

        stage = .standalonePaperResolving

        withAnimation(
            .easeInOut(duration: paperDuration.timeInterval)
        ) {
            standalonePaperProgress = 1
        }

        guard await sleep(
            paperDuration,
            generation: generation
        ) else {
            return
        }

        stage = .hubRevealing

        withAnimation(
            .easeOut(duration: hubDuration.timeInterval)
        ) {
            hubRevealProgress = 1
        }

        guard await sleep(
            hubDuration,
            generation: generation
        ) else {
            return
        }

        guard await sleep(
            Prompt04IntroConfiguration.completionSettle,
            generation: generation
        ) else {
            return
        }

        await complete(
            generation: generation,
            audioManager: audioManager,
            completion: completion,
            wasFirstLaunch: wasFirstLaunch
        )
    }

    private func complete(
        generation: UInt,
        audioManager _: AudioManager,
        completion: @escaping @MainActor (_ wasFirstLaunch: Bool) -> Void,
        wasFirstLaunch: Bool
    ) async {
        guard isCurrent(generation) else { return }

        stage = .introComplete
        hubInteractionEnabled = true

        completion(wasFirstLaunch)
    }

    private func startAmbience(
        audioManager: AudioManager,
        settings _: SettingsStore
    ) {
        // Always register both continuous ambience requests.
        //
        // AudioManager is the single authority for whether each channel
        // is currently allowed to play. If Music or Rain is disabled,
        // AudioManager can retain the requested loop without playing it.
        // Turning the setting back on can therefore recreate and resume
        // the appropriate continuous player.

        audioManager.fadeIn(
            .fruitBasketMusicbox,
            duration: 0.40
        )

        audioManager.fadeIn(
            .fruitBasketRainAmbience,
            duration: 0.45
        )
    }

    private func settleAtBlankBook() {
        stage = .blankBookSettled

        bookArrivalProgress = 1
        logoRevealProgress = 0
        brandedBookResolved = false
        slightlyOpenProgress = 0
        fullyOpenProgress = 0
        rightPageFocusProgress = 0
        standalonePaperProgress = 0
        hubRevealProgress = 0
    }

    private func settleAtBrandedBook() {
        stage = .brandedBookSettled

        bookArrivalProgress = 1
        logoRevealProgress = 1
        brandedBookResolved = true
        logoSettleScale = 1
        sparkleOpacity = 0
        slightlyOpenProgress = 0
        fullyOpenProgress = 0
        rightPageFocusProgress = 0
        standalonePaperProgress = 0
        hubRevealProgress = 0
    }

    private func settleAtSlightlyOpenBook() {
        settleAtBrandedBook()

        stage = .slightlyOpenSettled
        slightlyOpenProgress = 1
    }

    private func settleAtFullyOpenBook() {
        settleAtSlightlyOpenBook()

        stage = .fullyOpenSettled
        fullyOpenProgress = 1
    }

    private func settleAtHubPaper() {
        settleAtFullyOpenBook()

        stage = .hubRevealing
        rightPageFocusProgress = 1
        standalonePaperProgress = 1
        hubRevealProgress = 1
    }

    private func resetVisualState() {
        stage = .initialStillness
        bookArrivalProgress = 0
        logoRevealProgress = 0
        brandedBookResolved = false
        logoSettleScale = 1
        sparkleOpacity = 0
        slightlyOpenProgress = 0
        fullyOpenProgress = 0
        rightPageFocusProgress = 0
        standalonePaperProgress = 0
        hubRevealProgress = 0
        hubInteractionEnabled = false
    }

    private func sleep(
        _ duration: Duration,
        generation: UInt
    ) async -> Bool {
        do {
            try await Task.sleep(for: duration)
        } catch {
            return false
        }

        return isCurrent(generation)
    }

    private func isCurrent(
        _ generation: UInt
    ) -> Bool {
        !Task.isCancelled &&
        generation == sequenceGeneration
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = self.components

        let seconds = Double(
            components.seconds
        )

        let attoseconds =
            Double(components.attoseconds) /
            1_000_000_000_000_000_000

        return seconds + attoseconds
    }
}
