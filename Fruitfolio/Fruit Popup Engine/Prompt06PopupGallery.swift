#if DEBUG
import SwiftUI

struct Prompt06PopupGallery: View {
    @EnvironmentObject private var coordinator: PopupCoordinator

    var body: some View {
        FruitPopupHost {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Prompt 06 — Fruit Popup QA")
                        .font(.title2.bold())

                    Button("Blueberry") {
                        coordinator.request(.init(character: .blueberry, message: "here’s how this works :-) ", positionPreference: .lowerLeading, tone: .educational, priority: .educational, deduplicationKey: "qa-blueberry"))
                    }

                    Button("Peach") {
                        coordinator.request(.init(character: .peach, message: "Fruitfolio doesn’t have enough information yet.", positionPreference: .upperTrailing, dismissBehavior: .persistentUntilAcknowledged, tone: .gentle, priority: .sensitive, deduplicationKey: "qa-peach"))
                    }

                    Button("Strawberry") {
                        coordinator.request(.init(character: .strawberry, message: "you did it!! ♡", positionPreference: .bottom, dismissBehavior: .timed(seconds: 2.0), tone: .celebratory, priority: .success, deduplicationKey: "qa-strawberry"))
                    }

                    Text(FruitfolioMicroLabelFont.comicSansMSAvailable ? "Comic Sans MS: available" : "BLOCKER: Comic Sans MS unavailable")
                        .font(.footnote)
                }
                .padding(24)
            }
        }
    }
}
/// Disposable UI regression route; never enabled in release builds and does not
/// read or write production settings, research, conversations, or user content.
struct Prompt1BModalRegressionHarness: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var coordinator: PopupCoordinator
    @State private var owner: FruitfolioOwnedPopupSession?
    @State private var visible = false
    @AccessibilityFocusState private var backgroundFocused: Bool

    private var character: FruitPopupCharacter {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-fruitfolioDialogueCharacter"),
              arguments.indices.contains(index + 1),
              let character = FruitPopupCharacter(rawValue: arguments[index + 1]) else { return .blueberry }
        return character
    }

    var body: some View {
        Button("Background action") { presentDialogue() }
            .accessibilityIdentifier("modalQA.background")
            .accessibilityFocused($backgroundFocused)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.ColorToken.backgroundCream)
            .task {
                visible = true
                settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioModalReduceMotion")
                if ProcessInfo.processInfo.arguments.contains("-fruitfolioDialogueRTL") { settings.language = .arabic }
                // Let the real root preference observers synchronize before
                // requesting the first entrance; no separate fixture motion.
                await Task.yield()
                guard !Task.isCancelled, visible else { return }
                if owner == nil { owner = FruitfolioOwnedPopupSession(coordinator: coordinator) }
                presentDialogue()
            }
            .onChange(of: coordinator.currentPopup?.id) { _, _ in
                guard let owner, owner.requestID != nil else { return }
                owner.observeDismissal()
                if visible, owner.requestID == nil, coordinator.currentPopup == nil { backgroundFocused = true }
            }
            .onDisappear { visible = false; owner?.cancel() }
    }

    private func presentDialogue() {
        guard visible, let owner else { return }
        backgroundFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: character,
                message: String(repeating: "Educational estimates carry uncertainty. Keep citations and units attached to their sources. ", count: 3),
                primaryAction: .init(label: "Close this educational explanation") { _ = owner.consumeAction(for: id) },
                positionPreference: ProcessInfo.processInfo.arguments.contains("-fruitfolioDialogueTrailing") ? .centerTrailing : .centerLeading,
                dismissBehavior: .explicitActionOnly, tone: .informational,
                source: "disposable-modal-regression")
        }
    }
}
/// Exercises production tour composition without mutating onboarding progress.
struct Prompt1BTourRegressionHarness: View {
    @State private var step: Prompt07TourStep = .ask
    @State private var active = true
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motionPreferences: MotionPreferences
    private var reduceMotion: Bool { motionPreferences.reduceMotionActive }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()
            if active {
                Prompt07TourOverlay(frames: [:], step: step, reduceMotion: reduceMotion,
                    onBack: { step = Prompt07TourStep(rawValue: max(1, step.rawValue - 1)) ?? .ask },
                    onNext: { step = Prompt07TourStep(rawValue: min(6, step.rawValue + 1)) ?? .ready },
                    onSkip: { active = false }, onFinish: { active = false })
            } else {
                Text("tour finished").accessibilityIdentifier("tourQA.finished")
            }
        }
        .onAppear {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioModalReduceMotion")
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioDialogueRTL") { settings.language = .arabic }
        }
    }
}
#endif
