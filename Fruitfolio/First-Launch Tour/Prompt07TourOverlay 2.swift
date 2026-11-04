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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var targetPulse = false
    @State private var dialogueVisible = false

    private let veilOpacity = 0.52

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(
                proxy.size.width - 16,
                240
            )

            let normalBubbleWidth = min(max(availableWidth * 0.47, 166), 184)
            let bubbleWidth = dynamicTypeSize.isAccessibilitySize
                ? min(340, availableWidth - min(max(availableWidth * 0.15, 52), 62) + 12)
                : max(normalBubbleWidth, step.rawValue > 1 && step != .ready ? 196 : normalBubbleWidth)

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
            .task(id: step.rawValue) { await animateStepEntrance() }
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
                    size: 9.25, relativeTo: .caption
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
                        size: 9.0, relativeTo: .caption
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
                        size: 8.4, relativeTo: .caption
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .primaryBurgundy
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: 44,
                    alignment: .center
                )
                .buttonStyle(CutePopButtonStyle(reduceMotion: reduceMotion))
                .accessibilityLabel(
                    "Start exploring"
                )

            } else {
                tourControlLayout {
                    if step.rawValue > 1 {
                        Button(
                            "← back"
                        ) {
                            onBack()
                        }
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 8.75, relativeTo: .caption
                            )
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken
                                .secondaryBurgundy
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .buttonStyle(CutePopButtonStyle(reduceMotion: reduceMotion))
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
                            size: 8.4, relativeTo: .caption
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
                    .frame(minWidth: 44, minHeight: 44)
                    .buttonStyle(CutePopButtonStyle(reduceMotion: reduceMotion))

                    Button(
                        "next →"
                    ) {
                        onNext()
                    }
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 9.0, relativeTo: .caption
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken
                            .primaryBurgundy
                    )
                    .frame(minWidth: 44, minHeight: 44)
                    .buttonStyle(CutePopButtonStyle(reduceMotion: reduceMotion))
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

    private var tourControlLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 4))
    }

    private var styledStepMessage: some View {
        FruitfolioSemanticText(document: step.semanticMessage,
            baseFont: .custom("Chalkboard SE", size: 10.25, relativeTo: .body))
    }

    @MainActor
    private func animateStepEntrance() async {
        dialogueVisible = false
        targetPulse = false
        guard !Task.isCancelled else { return }
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.17)) {
                dialogueVisible = true; targetPulse = true
            }
            return
        }
        do { try await Task.sleep(nanoseconds: 80_000_000) } catch { return }
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.24)) { dialogueVisible = true }
        withAnimation(.easeOut(duration: 0.36)) { targetPulse = true }
    }
}
