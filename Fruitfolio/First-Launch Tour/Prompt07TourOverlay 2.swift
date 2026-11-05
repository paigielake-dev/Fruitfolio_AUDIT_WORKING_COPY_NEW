import SwiftUI

struct Prompt07TourOverlay: View {
    let frames: [Prompt07TourTarget: CGRect]
    let step: Prompt07TourStep
    let reduceMotion: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let onFinish: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    @State private var targetPulse = false
    @State private var dialogueVisible = false

    private let veilOpacity = 0.52

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = max(proxy.safeAreaInsets.bottom + 56, 62)
            let metrics = FruitfolioPopupLayout.dialogue(
                availableWidth: max(0, proxy.size.width - 16),
                availableHeight: max(0, proxy.size.height - bottomInset - 16),
                messageCount: 0, maximumBubbleWidth: 184, maximumCharacterWidth: 62
            )

            ZStack {
                veil(in: proxy.size)

                if let targetRect = highlight(in: proxy.size) {
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .stroke(
                        DesignTokens.ColorToken
                            .primaryBurgundy
                            .opacity(0.10),
                        lineWidth: 1
                    )
                    .frame(
                        width: targetRect.width,
                        height: targetRect.height
                    )
                    .position(
                        x: targetRect.midX,
                        y: targetRect.midY
                    )
                    .scaleEffect(
                        reduceMotion
                            ? 1
                            : (
                                targetPulse
                                    ? 1
                                    : 1.025
                            )
                    )
                    .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    dialogue(
                        bubbleWidth: metrics.bubbleWidth,
                        fruitWidth: metrics.characterWidth,
                        spacing: metrics.spacing
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .trailing
                    )
                    .padding(.trailing, 6)
                    .padding(
                        .bottom,
                        max(
                            proxy.safeAreaInsets.bottom
                                + 56,
                            62
                        )
                    )
                }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
            .contentShape(Rectangle())
            .task(id: "\(step.rawValue)-\(reduceMotion)") {
                await animateStepEntrance()
            }
        }
        .ignoresSafeArea(edges: [])
        .accessibilityElement(
            children: .contain
        )
    }

    private var currentTargetRect: CGRect? {
        guard let target = step.target else {
            return nil
        }

        return frames[target]
    }

    private func highlight(in size: CGSize) -> CGRect? {
        Prompt07SpotlightGeometry.highlight(target: currentTargetRect, viewport: CGRect(origin: .zero, size: size))
    }

    @ViewBuilder
    private func veil(
        in size: CGSize
    ) -> some View {
        if step == .ready {
            Color.clear
                .allowsHitTesting(true)
                .onTapGesture { }

        } else {
            Path { path in
                path.addRect(
                    CGRect(
                        origin: .zero,
                        size: size
                    )
                )

                if let cutout = highlight(in: size) {

                    path.addRoundedRect(
                        in: cutout,
                        cornerSize: CGSize(
                            width: 18,
                            height: 18
                        )
                    )
                }
            }
            .fill(
                DesignTokens.ColorToken
                    .backgroundCream
                    .opacity(
                        veilOpacity
                    ),
                style: FillStyle(
                    eoFill: true
                )
            )
            .allowsHitTesting(true)
            .onTapGesture {
                // Consume taps while the guided tour is active.
            }
        }
    }

    private func dialogue(
        bubbleWidth: CGFloat,
        fruitWidth: CGFloat,
        spacing: CGFloat
    ) -> some View {
        HStack(
            alignment: .bottom,
            spacing: spacing
        ) {
            FruitPopupCharacterArtwork(
                character: step.character,
                width: fruitWidth
            )
            .offset(y: -14)
            .accessibilityHidden(true)
            .zIndex(2)

            FruitPopupBubbleShell(
                width: bubbleWidth,
                characterSide: .left
            ) {
                GeometryReader { geometry in
                    ScrollView(.vertical) {
                        tourBubbleContent.frame(minHeight: geometry.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .accessibilityIdentifier("tour.dialogue.scroll")
                }
            }
            .zIndex(1)
        }
        .fixedSize(
            horizontal: true,
            vertical: true
        )
        .opacity(
            dialogueVisible
                ? 1
                : 0
        )
        .offset(
            y: reduceMotion
                ? 0
                : (
                    dialogueVisible
                        ? 0
                        : 8
                )
        )
        .animation(
            reduceMotion
                ? .easeOut(
                    duration: 0.17
                )
                : .easeOut(
                    duration: 0.24
                ),
            value: dialogueVisible
        )
    }

    private var tourBubbleContent: some View {
        VStack(
            alignment: .center,
            spacing: 5
        ) {
            Text(
                step.progressText
            )
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 9.25, relativeTo: .body
                )
            )
            .fontWeight(.bold)
            .foregroundStyle(
                DesignTokens.ColorToken
                    .secondaryBurgundy
            )
            .multilineTextAlignment(
                .center
            )

            styledStepMessage
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 10.25, relativeTo: .body
                    )
                )
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .primaryBurgundy
                )
                .multilineTextAlignment(
                    .center
                )
                .lineSpacing(0.35)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                .layoutPriority(2)

            if step == .ready {
                Text(
                    "replay anytime in settings"
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 9.0, relativeTo: .body
                    )
                )
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .secondaryBurgundy
                )
                .multilineTextAlignment(
                    .center
                )

                Button(
                    "start exploring"
                ) {
                    // Canonical asset: audio_popup_close.mp3
                    audioManager.play(
                        .popupClose
                    )
                    onFinish()
                }
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 8.4, relativeTo: .body
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .primaryBurgundy
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: DesignTokens.Layout.minimumHitTarget,
                    alignment: .center
                )
                .buttonStyle(.plain)
                .accessibilityLabel("Start exploring")
                .accessibilityIdentifier("tour.finish")

            } else {
                HStack(
                    spacing: 4
                ) {
                    if step.rawValue > 1 {
                        Button(
                            "← back"
                        ) {
                            onBack()
                        }
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 8.75, relativeTo: .body
                            )
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken
                                .secondaryBurgundy
                        )
                        .frame(
                            minHeight: DesignTokens.Layout.minimumHitTarget
                        )
                        .buttonStyle(.plain)
                    }

                    Spacer(
                        minLength: 2
                    )

                    Button(
                        "skip tour"
                    ) {
                        // Canonical asset: audio_popup_close.mp3
                        audioManager.play(
                            .popupClose
                        )
                        onSkip()
                    }
                    .accessibilityIdentifier("tour.skip")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 8.4, relativeTo: .body
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken
                            .secondaryBurgundy
                            .opacity(
                                0.82
                            )
                    )
                    .frame(
                        minHeight: DesignTokens.Layout.minimumHitTarget
                    )
                    .buttonStyle(.plain)

                    Button(
                        "next →"
                    ) {
                        onNext()
                    }
                    .accessibilityIdentifier("tour.next")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 9.0, relativeTo: .body
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken
                            .primaryBurgundy
                    )
                    .frame(
                        minHeight: DesignTokens.Layout.minimumHitTarget
                    )
                    .buttonStyle(.plain)
                }
                .frame(
                    maxWidth: .infinity
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private var styledStepMessage: some View {
        FruitfolioTranslatedText(source: stepMessage, font: .custom("Chalkboard SE", size: 10.25, relativeTo: .body))
    }

    private var stepMessage: String {
        switch step {
        case .ask:
            return "got a question? start here\u{00A0}(\u{00A0}´﹀`\u{00A0}) i’ll look through the **FruitsofLife.xo** library for you."
        case .library:
            return (
                "anything you love can be tucked into your own little encyclopedia!\u{00A0}♡"
            )

        case .guideBuilder:
            return (
                "organize your saved pages into chapters, notes, study guides, little handbooks… whatever works for you.\u{00A0}:-)"
            )

        case .cycle:
            return (
                "this is more than a period calendar. log what you know, and Fruitfolio will help you see the biology and patterns underneath your cycle."
            )

        case .fruitBasket:
            return (
                "and when you feel like playing… come fill your fruit basket!\u{00A0}(〃⌒∇⌒)"
            )

        case .ready:
            return (
                "that’s it! explore wherever you’d like.\u{00A0}♡"
            )
        }
    }

    @MainActor
    private func animateStepEntrance() async {
        dialogueVisible = false
        targetPulse = false

        if reduceMotion {
            withAnimation(
                .easeOut(
                    duration: 0.17
                )
            ) {
                dialogueVisible = true
                targetPulse = true
            }

            return
        }

        do { try await Task.sleep(nanoseconds: 80_000_000) }
        catch { return }
        guard !Task.isCancelled else { return }

        withAnimation(
            .easeOut(
                duration: 0.24
            )
        ) {
            dialogueVisible = true
        }

        withAnimation(
            .easeOut(
                duration: 0.36
            )
        ) {
            targetPulse = true
        }
    }
}
