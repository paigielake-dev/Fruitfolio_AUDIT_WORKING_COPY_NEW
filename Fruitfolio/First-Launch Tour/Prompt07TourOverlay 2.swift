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

    @AccessibilityFocusState private var messageFocus: Int?
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
                messageFocus = nil
                await animateStepEntrance()
                await Task.yield()
                guard !Task.isCancelled else { return }
                messageFocus = step.rawValue
            }
        }
        .ignoresSafeArea(edges: [])
        .onDisappear { messageFocus = nil }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) {
            audioManager.play(.popupClose)
            onSkip()
        }
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
                    .id(step.id)
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
            Text("\(step.rawValue) of 6")
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

                FruitfolioControlPillButton(label: "start exploring") {
                    audioManager.play(.popupClose)
                    onFinish()
                }
                .controlSize(.small)
                .accessibilityIdentifier("tour.finish")
            } else {
                // Stack inside the existing scrollable writing area so three
                // translated actions do not compete for one narrow line.
                VStack(spacing: 4) {
                    if step.rawValue > 1 {
                        FruitfolioControlPillButton(label: "← back", action: onBack)
                            .accessibilityIdentifier("tour.back")
                    }
                    FruitfolioControlPillButton(label: "skip tour") {
                        audioManager.play(.popupClose)
                        onSkip()
                    }
                    .accessibilityIdentifier("tour.skip")
                    FruitfolioControlPillButton(label: "next →", action: onNext)
                        .accessibilityIdentifier("tour.next")
                }
                .controlSize(.small)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private var styledStepMessage: some View {
        FruitfolioTranslatedContent(source: step.message, protectedLiterals: ["Fruitfolio", "FruitsofLife.xo"]) { display, _ in
            FruitfolioSemanticText(
                markdown: display
                    .replacingOccurrences(of: "FruitsofLife.xo", with: "**FruitsofLife.xo**")
                    .replacingOccurrences(of: " ♡", with: "\u{00A0}♡")
                    .replacingOccurrences(of: " :-)", with: "\u{00A0}:-)"),
                baseFont: .custom("Chalkboard SE", size: 10.25, relativeTo: .body)
            )
            .accessibilityFocused($messageFocus, equals: step.rawValue)
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
