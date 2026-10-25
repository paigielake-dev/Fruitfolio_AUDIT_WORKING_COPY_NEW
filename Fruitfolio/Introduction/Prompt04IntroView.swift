import SwiftUI

struct Prompt04IntroView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var navigation: NavigationCoordinator
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var launchStore: IntroLaunchStore

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var machine = Prompt04IntroStateMachine()
    @State private var launchMode: Prompt04LaunchMode?
    @State private var wasInterrupted = false
    @State private var preloadFailed = false

    var body: some View {
        GeometryReader { proxy in
            let metrics = Prompt04BookLayout.metrics(for: proxy.size)

            ZStack {
                DesignTokens.ColorToken.backgroundCream
                    .ignoresSafeArea()
                if preloadFailed {
                    Prompt04StandaloneHubComposition(
                        interactive: false,
                        navigate: { _ in }
                    )
                } else {
                    introComposition(metrics: metrics)
                }
            }
            .frame(width: max(1, proxy.size.width), height: max(1, proxy.size.height))
            .clipped()
        }
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .task {
            guard launchMode == nil else { return }

            let preloadResult = Prompt04AssetPreloader.preload()
            if !preloadResult.allCriticalAssetsReady {
                preloadFailed = true
                safelyResolveToHub(markSignatureComplete: false)
                return
            }

            let resolvedMode = resolveLaunchMode()
            launchMode = resolvedMode
            machine.start(
                mode: resolvedMode,
                audioManager: audioManager,
                settings: settings,
                completion: completeIntro(wasFirstLaunch:)
            )
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
        }
        .accessibilityElement(children: machine.hubInteractionEnabled ? .contain : .ignore)
    }

    @ViewBuilder
    private func introComposition(metrics: Prompt04BookLayout.Metrics) -> some View {
        let arrival = clamped(machine.bookArrivalProgress)
        let slight = clamped(machine.slightlyOpenProgress)
        let full = clamped(machine.fullyOpenProgress)
        let focus = clamped(machine.rightPageFocusProgress)
        let paper = clamped(machine.standalonePaperProgress)

        let closedOpacity = 1 - slight
        let slightOpacity = slight * (1 - full)
        let openOpacity = full * (1 - paper)

        let currentOpenWidth = lerp(metrics.centeredOpenBookWidth, metrics.focusedBookWidth, focus)
        let currentOpenHeight = lerp(metrics.centeredOpenBookHeight, metrics.focusedBookHeight, focus)
        let currentOpenOffsetX = lerp(0, metrics.focusedBookOffsetX, focus)
        let currentOpenOffsetY = lerp(0, metrics.focusedBookOffsetY, focus)

        ZStack {
            // FINAL PAPER — standalone blank founder art, no book visible.
            // It fades in only after the right-page zoom has reached full focus.
            FruitfolioImage(id: .ask_answer_paper)
                .scaledToFill()
                .frame(width: metrics.viewportWidth, height: metrics.viewportHeight)
                .clipped()
                .opacity(paper)
                .accessibilityHidden(true)

            // STATE 4 — fully open blank book. It remains centered and wholly
            // on-screen before the camera begins the explicit right-page zoom.
            FruitfolioImage(id: .book_open_blank)
                .scaledToFit()
                .frame(width: currentOpenWidth, height: currentOpenHeight)
                .offset(x: currentOpenOffsetX, y: currentOpenOffsetY)
                .opacity(openOpacity)
                .accessibilityHidden(true)

            // STATE 3 — slightly open branded book. It gets its own complete,
            // centered, readable beat instead of flashing by as interpolation.
            FruitfolioImage(id: .book_slightly_open_logo)
                .scaledToFit()
                .frame(width: metrics.slightlyOpenBookWidth)
                .opacity(slightOpacity)
                .accessibilityHidden(true)

            // STATES 1 + 2 — blank closed book, then exact branded closed book.
            closedBookComposition(metrics: metrics)
                .opacity(closedOpacity)
                .scaleEffect(0.94 + (0.06 * arrival))
                .opacity(arrival)

            // Hub controls appear only on the standalone paper, never over the
            // full-book presentation or during the zoom itself.
            Prompt04HubPaperControls(
                metrics: metrics,
                interactive: false,
                navigate: { _ in }
            )
            .opacity(machine.hubRevealProgress)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .clipped()
    }

    private func closedBookComposition(metrics: Prompt04BookLayout.Metrics) -> some View {
        // Exact founder sequence: the physical blank book is present first.
        // The branded cover is then revealed through an irregular pigment mask.
        // Revealing the final branded-book art itself guarantees the settled state
        // cannot jump relative to book_closed_logo.
        ZStack {
            FruitfolioImage(id: .book_closed_blank)
                .scaledToFit()
                .frame(width: metrics.closedBookWidth)

            FruitfolioImage(id: .book_closed_logo)
                .scaledToFit()
                .frame(width: metrics.closedBookWidth)
                .mask {
                    Prompt04WatercolorPuddleMask(
                        progress: machine.logoRevealProgress
                    )
                }
                .opacity(machine.logoRevealProgress > 0 ? 1 : 0)
        }
        .accessibilityHidden(true)
    }

    private func resolveLaunchMode() -> Prompt04LaunchMode {
        #if DEBUG
        if let override = Prompt04DebugLaunchOverride.resolve() {
            return override
        }
        #endif

        let firstLaunch = !launchStore.hasCompletedSignatureIntro
        if motionPreferences.reduceMotionActive {
            return firstLaunch ? .reducedMotionFirstLaunch : .reducedMotionReturningLaunch
        }
        return firstLaunch ? .firstLaunch : .returningLaunch
    }

    private func completeIntro(wasFirstLaunch: Bool) {
        launchStore.markSignatureIntroComplete()
        appState.hasEnteredMainApp = true
        navigation.enterHub()

        if wasFirstLaunch && !appState.tutorialCompleted {
            Task { @MainActor in
                try? await Task.sleep(for: Prompt04IntroConfiguration.blueberryHookDelay)
                guard !Task.isCancelled else { return }
                appState.firstLaunchOnboardingHookReady = true
            }
        }
    }

    private func handleScenePhase(_ newPhase: ScenePhase) {
        guard let launchMode else { return }

        switch newPhase {
        case .background:
            wasInterrupted = machine.stage != .introComplete
            machine.handleBackgrounding(audioManager: audioManager)
        case .active:
            guard wasInterrupted else { return }
            wasInterrupted = false
            machine.resolveAfterInterruption(
                audioManager: audioManager,
                completion: completeIntro(wasFirstLaunch:),
                wasFirstLaunch: launchMode.isFirstLaunch
            )
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func safelyResolveToHub(markSignatureComplete: Bool) {
        if markSignatureComplete {
            launchStore.markSignatureIntroComplete()
        }
        appState.hasEnteredMainApp = true
        navigation.enterHub()
    }

    private func pageTurnOpacity(fullProgress: CGFloat) -> CGFloat {
        let p = clamped(fullProgress)
        let distance = abs(p - 0.52)
        return max(0, 1 - (distance / 0.34)) * 0.74
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }

    private func lerp(_ start: CGFloat, _ end: CGFloat, _ progress: CGFloat) -> CGFloat {
        start + ((end - start) * clamped(progress))
    }
}

private struct Prompt04WatercolorPuddleMask: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            let p = min(max(progress, 0), 1)

            ZStack {
                Prompt04OrganicBlob(seed: 0)
                    .frame(
                        width: width * (0.11 + 1.22 * p),
                        height: height * (0.12 + 1.02 * p)
                    )
                    .offset(
                        x: width * (-0.18 + 0.12 * p),
                        y: height * (-0.17 + 0.10 * p)
                    )

                Prompt04OrganicBlob(seed: 1)
                    .frame(
                        width: width * (0.10 + 1.10 * p),
                        height: height * (0.10 + 0.98 * p)
                    )
                    .offset(
                        x: width * (0.15 - 0.08 * p),
                        y: height * (-0.05 + 0.02 * p)
                    )

                Prompt04OrganicBlob(seed: 2)
                    .frame(
                        width: width * (0.09 + 1.16 * p),
                        height: height * (0.10 + 1.08 * p)
                    )
                    .offset(
                        x: width * (-0.02 + 0.04 * p),
                        y: height * (0.18 - 0.11 * p)
                    )
            }
        }
    }
}

private struct Prompt04OrganicBlob: Shape {
    let seed: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = normalizedPoints(for: seed)
        guard let first = points.first else { return path }

        path.move(to: point(first, in: rect))
        for index in points.indices {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            let midpoint = CGPoint(
                x: (current.x + next.x) * 0.5,
                y: (current.y + next.y) * 0.5
            )
            path.addQuadCurve(
                to: point(midpoint, in: rect),
                control: point(current, in: rect)
            )
        }
        path.closeSubpath()
        return path
    }

    private func point(_ normalized: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + (normalized.x * rect.width),
            y: rect.minY + (normalized.y * rect.height)
        )
    }

    private func normalizedPoints(for seed: Int) -> [CGPoint] {
        switch seed {
        case 1:
            return [
                CGPoint(x: 0.12, y: 0.24), CGPoint(x: 0.38, y: 0.07),
                CGPoint(x: 0.71, y: 0.14), CGPoint(x: 0.95, y: 0.40),
                CGPoint(x: 0.86, y: 0.74), CGPoint(x: 0.57, y: 0.96),
                CGPoint(x: 0.25, y: 0.84), CGPoint(x: 0.05, y: 0.55)
            ]
        case 2:
            return [
                CGPoint(x: 0.08, y: 0.36), CGPoint(x: 0.24, y: 0.10),
                CGPoint(x: 0.61, y: 0.04), CGPoint(x: 0.90, y: 0.23),
                CGPoint(x: 0.97, y: 0.60), CGPoint(x: 0.73, y: 0.91),
                CGPoint(x: 0.39, y: 0.97), CGPoint(x: 0.10, y: 0.72)
            ]
        default:
            return [
                CGPoint(x: 0.06, y: 0.29), CGPoint(x: 0.29, y: 0.06),
                CGPoint(x: 0.66, y: 0.09), CGPoint(x: 0.94, y: 0.34),
                CGPoint(x: 0.91, y: 0.70), CGPoint(x: 0.65, y: 0.94),
                CGPoint(x: 0.31, y: 0.90), CGPoint(x: 0.05, y: 0.61)
            ]
        }
    }
}
