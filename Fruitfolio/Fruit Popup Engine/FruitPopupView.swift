import SwiftUI

// Shared visual primitives for every Fruitfolio fruit dialogue.
// Prompt 06 owns this renderer; Prompt 07 reuses it so popup typography,
// safe text bounds, optical centering, and fruit-to-bubble relationships stay
// consistent everywhere.

struct FruitPopupCharacterArtwork: View {
    let character: FruitPopupCharacter
    let width: CGFloat

    private var artworkMetrics: FruitfolioPopupLayout.CharacterArtwork {
        switch character {
        case .strawberry: return .strawberry
        case .blueberry: return .blueberry
        case .peach: return .peach
        }
    }

    private var opticalOffset: CGSize { artworkMetrics.opticalOffset(boxSide: width) }

    var body: some View {
        FruitfolioImage(id: character.assetID)
            .scaledToFit()
            .frame(
                width: width,
                height: width,
                alignment: .center
            )
            .offset(
                x: opticalOffset.width,
                y: opticalOffset.height
            )
            .accessibilityHidden(true)
    }
}

struct FruitPopupBubbleShell<Content: View>: View {
    let width: CGFloat
    let characterSide: FruitPopupCharacterSide

    @ViewBuilder
    let content: () -> Content

    private var bubbleHeight: CGFloat {
        width * FruitfolioPopupLayout.speechBubblePixelSize.height / FruitfolioPopupLayout.speechBubblePixelSize.width
    }

    var body: some View {
        ZStack {
            FruitfolioImage(id: .popup_speech_bubble)
                .scaledToFit()
                .frame(width: width, height: bubbleHeight)
                .scaleEffect(
                    x: characterSide == .right ? -1 : 1,
                    y: 1,
                    anchor: .center
                )
                .accessibilityHidden(true)

            content()
                // Keep live text inside the painted body, not the bubble tail.
                // Mirroring moves the tail, so mirror the small optical inset too.
                .frame(
                    width: width * 0.76,
                    height: bubbleHeight * 0.68,
                    alignment: .center
                )
                .offset(
                    x: (characterSide == .left ? 1 : -1) * width * 0.030,
                    y: -bubbleHeight * 0.040
                )
        }
        .frame(width: width, height: bubbleHeight)
    }
}

struct FruitPopupView: View {
    let request: FruitPopupRequest
    let availableWidth: CGFloat
    let availableHeight: CGFloat
    let reduceMotion: Bool
    @Environment(\.layoutDirection) private var layoutDirection

    @State
    private var appeared = false
    @AccessibilityFocusState private var messageFocus: UUID?

    init(
        request: FruitPopupRequest,
        availableWidth: CGFloat = 361,
        availableHeight: CGFloat = .greatestFiniteMagnitude,
        reduceMotion: Bool
    ) {
        self.request = request
        self.availableWidth = availableWidth
        self.availableHeight = availableHeight
        self.reduceMotion = reduceMotion
    }

    private var prefersTrailingCharacter: Bool {
        switch request.positionPreference {
        case .upperTrailing, .centerTrailing, .lowerTrailing: return true
        default: return false
        }
    }
    private var characterSide: FruitPopupCharacterSide {
        FruitfolioPopupLayout.characterSide(prefersTrailing: prefersTrailingCharacter,
                                            rightToLeft: layoutDirection == .rightToLeft)
    }

    private var composition: FruitfolioPopupLayout.DialogueMetrics {
        FruitfolioPopupLayout.dialogue(availableWidth: availableWidth, availableHeight: availableHeight, messageCount: request.message.count)
    }

    private var characterWidth: CGFloat { composition.characterWidth }
    private var bubbleWidth: CGFloat { composition.bubbleWidth }
    private var compositionSpacing: CGFloat { composition.spacing }

    var body: some View {
        Group {
            if !prefersTrailingCharacter {
                HStack(alignment: .bottom, spacing: compositionSpacing) {
                    animatedCharacter
                    animatedBubble
                }
            } else {
                HStack(alignment: .bottom, spacing: compositionSpacing) {
                    animatedBubble
                    animatedCharacter
                }
            }
        }
        .fixedSize(horizontal: true, vertical: true)
        .frame(maxWidth: availableWidth, alignment: .center)
        .onAppear {
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.17)) {
                    appeared = true
                }
            } else {
                withAnimation(
                    .spring(
                        response: request.character.entranceDuration,
                        dampingFraction: 0.86
                    )
                ) {
                    appeared = true
                }
            }
        }
        .accessibilityElement(children: .contain)
        .task(id: request.id) {
            messageFocus = nil
            await Task.yield()
            guard !Task.isCancelled else { return }
            messageFocus = request.id
        }
        .onDisappear { messageFocus = nil }
    }

    private var animatedCharacter: some View {
        FruitPopupCharacterArtwork(
            character: request.character,
            width: characterWidth
        )
        .offset(y: reduceMotion ? 0 : (appeared ? 0 : 12))
        .opacity(appeared ? 1 : 0)
        .zIndex(2)
    }

    private var animatedBubble: some View {
        FruitPopupBubbleShell(
            width: bubbleWidth,
            characterSide: characterSide
        ) {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    bubbleContent
                        .frame(minHeight: geometry.size.height, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
                .accessibilityIdentifier("fruitPopup.scroll")
            }
        }
        .scaleEffect(
            reduceMotion ? 1 : (appeared ? 1 : 0.92),
            anchor: UnitPoint(x: characterSide == .left ? 0 : 1, y: 1)
        )
        .offset(y: reduceMotion ? 0 : (appeared ? 0 : 6))
        .opacity(appeared ? 1 : 0)
        .zIndex(1)
    }

    private var bubbleContent: some View {
        VStack(alignment: .center, spacing: 7) {
            invitationSafeMessage
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                .multilineTextAlignment(.center)
                .lineSpacing(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
                .layoutPriority(2)

            if request.primaryAction != nil || request.secondaryAction != nil || request.tertiaryAction != nil {
                VStack(alignment: .center, spacing: 2) {
                    if let primaryAction = request.primaryAction {
                        popupActionButton(primaryAction, isPrimary: true)
                    }

                    if let secondaryAction = request.secondaryAction {
                        popupActionButton(secondaryAction, isPrimary: false)
                    }
                    if let tertiaryAction = request.tertiaryAction {
                        popupActionButton(tertiaryAction, isPrimary: false, identifier: "fruitPopup.action.tertiary")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var invitationSafeMessage: some View {
        FruitfolioTranslatedContent(source: request.message, protectedLiterals: ["Fruitfolio", "FruitsofLife.xo"]) { display, _ in
            FruitfolioSemanticText(
                markdown: invitationMessage(display),
                baseFont: .custom("Chalkboard SE", size: 13, relativeTo: .body),
                serious: request.tone == .cautionary
            )
            .accessibilityFocused($messageFocus, equals: request.id)
        }
    }

    // Typography is applied after lookup so the canonical source remains the
    // catalog key and the saved request is never changed by display translation.
    private func invitationMessage(_ display: String) -> String {
        if display == "hello there! ♡ want me to show you around?" {
            return "hello there!\u{00A0}♡\nwant me to show you around?"
        }
        return display.replacingOccurrences(of: " ♡", with: "\u{00A0}♡")
    }

    private func popupActionButton(
        _ action: FruitPopupAction,
        isPrimary: Bool,
        identifier: String? = nil
    ) -> some View {
        FruitfolioControlPillButton(label: action.label, action: action.handler)
            .controlSize(.small)
            .accessibilityLabel(Text(LocalizedStringKey(action.accessibilityLabel ?? action.label)))
            .accessibilityIdentifier(identifier ?? (isPrimary ? "fruitPopup.action.primary" : "fruitPopup.action.secondary"))
    }
}
