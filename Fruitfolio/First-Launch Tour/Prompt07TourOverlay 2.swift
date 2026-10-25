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
            let availableWidth = max(
                proxy.size.width - 16,
                240
            )

            let bubbleWidth = min(
                max(
                    availableWidth * 0.47,
                    166
                ),
                184
            )

            let fruitWidth = min(
                max(
                    availableWidth * 0.15,
                    52
                ),
                62
            )

            ZStack {
                veil(in: proxy.size)

                if let targetRect = currentTargetRect {
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
                        width: targetRect.width + 12,
                        height: targetRect.height + 12
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
                        bubbleWidth: bubbleWidth,
                        fruitWidth: fruitWidth
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
            .onAppear {
                animateStepEntrance()
            }
            .onChange(of: step) {
                _,
                _ in

                animateStepEntrance()
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

                if let targetRect =
                    currentTargetRect
                {
                    let cutout =
                        targetRect.insetBy(
                            dx: -6,
                            dy: -6
                        )

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
        fruitWidth: CGFloat
    ) -> some View {
        HStack(
            alignment: .bottom,
            spacing: -12
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
                tourBubbleContent
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
                    size: 9.25
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
                        size: 10.25
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
                .minimumScaleFactor(
                    0.64
                )
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
                        size: 9.0
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
                        size: 8.4
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .primaryBurgundy
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: 28,
                    alignment: .center
                )
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "Start exploring"
                )

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
                                size: 8.75
                            )
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken
                                .secondaryBurgundy
                        )
                        .frame(
                            minHeight: 28
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
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 8.4
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
                        minHeight: 28
                    )
                    .buttonStyle(.plain)

                    Button(
                        "next →"
                    ) {
                        onNext()
                    }
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 9.0
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken
                            .primaryBurgundy
                    )
                    .frame(
                        minHeight: 28
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

    private var styledStepMessage: Text {
        switch step {

        case .ask:
            var message =
                AttributedString(
                    "got a question? start here\u{00A0}(\u{00A0}´﹀`\u{00A0}) i’ll look through the FruitsofLife.xo library for you."
                )

            if let range =
                message.range(
                    of: "FruitsofLife.xo"
                )
            {
                message[range].font =
                    .custom(
                        "Chalkboard SE",
                        size: 10.25
                    )
                    .bold()
            }

            return Text(
                message
            )

        case .library:
            return Text(
                "anything you love can be tucked into your own little encyclopedia!\u{00A0}♡"
            )

        case .guideBuilder:
            return Text(
                "organize your saved pages into chapters, notes, study guides, little handbooks… whatever works for you.\u{00A0}:-)"
            )

        case .cycle:
            return Text(
                "this is more than a period calendar. log what you know, and Fruitfolio will help you see the biology and patterns underneath your cycle."
            )

        case .fruitBasket:
            return Text(
                "and when you feel like playing… come fill your fruit basket!\u{00A0}(〃⌒∇⌒)"
            )

        case .ready:
            return Text(
                "that’s it! explore wherever you’d like.\u{00A0}♡"
            )
        }
    }

    private func animateStepEntrance() {
        dialogueVisible = false
        targetPulse = false

        Task { @MainActor in
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

            try? await Task.sleep(
                nanoseconds:
                    80_000_000
            )

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
}
