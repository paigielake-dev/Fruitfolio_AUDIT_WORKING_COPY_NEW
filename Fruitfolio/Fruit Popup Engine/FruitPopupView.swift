import SwiftUI

// Shared visual primitives for every Fruitfolio fruit dialogue.
// Prompt 06 owns this renderer; Prompt 07 reuses it so popup typography,
// safe text bounds, optical centering, and fruit-to-bubble relationships stay
// consistent everywhere.

enum FruitPopupCharacterSide {
    case left
    case right
}

struct FruitPopupCharacterArtwork: View {
    let character: FruitPopupCharacter
    let width: CGFloat

    /// The source PNGs have different transparent/painted bounds. These tiny
    /// corrections center the *visible watercolor fruit* rather than blindly
    /// centering the rectangular PNG canvas.
    private var opticalOffset: CGSize {
        switch character {
        case .strawberry:
            return CGSize(width: 1, height: 1)
        case .blueberry:
            return CGSize(width: 0, height: 2)
        case .peach:
            return CGSize(width: -5, height: -1)
        }
    }

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

    var body: some View {
        FruitfolioPopupArtworkSurface(assetName: "popup_speech_bubble",
            normalizedWriting: CGRect(x: characterSide == .left ? 0.15 : 0.09,
                                      y: 0.12, width: 0.76, height: 0.68),
            maximumWidth: width, mirrorsArtwork: characterSide == .right, edgeClearance: 0,
            content: content)
            .frame(width: width, height: width * 499 / 497)
    }
}

struct FruitPopupView: View {
    let request: FruitPopupRequest
    let availableWidth: CGFloat
    let reduceMotion: Bool
    @EnvironmentObject private var audioManager: AudioManager

    @State
    private var appeared = false
    @AccessibilityFocusState(for: .voiceOver) private var messageFocused: Bool

    init(
        request: FruitPopupRequest,
        availableWidth: CGFloat = 361,
        reduceMotion: Bool
    ) {
        self.request = request
        self.availableWidth = availableWidth
        self.reduceMotion = reduceMotion
    }

    private var characterSide: FruitPopupCharacterSide {
        switch request.positionPreference {
        case .upperTrailing, .centerTrailing, .lowerTrailing:
            return .right
        default:
            return .left
        }
    }

    private var characterWidth: CGFloat {
        composition.characterWidth
    }

    private var bubbleWidth: CGFloat {
        composition.bubbleWidth
    }

    private var compositionSpacing: CGFloat {
        composition.spacing
    }

    private var composition: FruitPopupCompositionMetrics {
        .init(availableWidth: availableWidth, messageLength: request.message.count)
    }

    var body: some View {
        Group {
            if characterSide == .left {
                HStack(alignment: .bottom, spacing: compositionSpacing) {
                    if composition.showsCharacter { animatedCharacter }
                    animatedBubble
                }
            } else {
                HStack(alignment: .bottom, spacing: compositionSpacing) {
                    animatedBubble
                    if composition.showsCharacter { animatedCharacter }
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
            // Focus only this presentation, after its existing entrance. A
            // replacement/dismissal cancels this view-owned task; streaming or
            // unrelated body updates must not repeatedly steal reading focus.
            let delay = reduceMotion ? 0.19 : request.character.entranceDuration + 0.03
            do { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
            catch { return }
            guard !Task.isCancelled else { return }
            messageFocused = true
        }
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
            bubbleContent
        }
        .scaleEffect(
            reduceMotion ? 1 : (appeared ? 1 : 0.92),
            anchor: characterSide == .left ? .bottomLeading : .bottomTrailing
        )
        .offset(y: reduceMotion ? 0 : (appeared ? 0 : 6))
        .opacity(appeared ? 1 : 0)
        .zIndex(1)
    }

    private var bubbleContent: some View { messageAndActions }

    // Keep short dialogue optically centered; long and Dynamic Type dialogue
    // remains inside the painted writing area and is reachable by scrolling.
    private var messageAndActions: some View {
        VStack(alignment: .center, spacing: 7) {
            FruitfolioSemanticText(document: invitationSafeMessage,
                baseFont: .custom("Chalkboard SE", size: 13, relativeTo: .body))
                .accessibilityIdentifier("popup.message")
                .accessibilityFocused($messageFocused)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                .multilineTextAlignment(.center)
                .lineSpacing(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
                .layoutPriority(2)

            if request.primaryAction != nil || request.secondaryAction != nil {
                VStack(alignment: .center, spacing: 2) {
                    if let primaryAction = request.primaryAction {
                        popupActionButton(primaryAction, isPrimary: true)
                    }

                    if let secondaryAction = request.secondaryAction {
                        popupActionButton(secondaryAction, isPrimary: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var invitationSafeMessage: FruitfolioSemanticDocument {
        if request.message == "hello there! ♡ want me to show you around?" {
            return .init(spans: [.init(text: "hello there!\u{00A0}♡\nwant me to show you around?")])
        }

        return request.semanticMessage
    }

    private func popupActionButton(
        _ action: FruitPopupAction,
        isPrimary: Bool
    ) -> some View {
        Button {
            audioManager.play(.buttonSoftPop)
            action.handler()
        } label: {
            Text(action.label)
                .font(.custom("Chalkboard SE", size: 12.25, relativeTo: .body))
                .fontWeight(isPrimary ? .bold : .regular)
                .foregroundStyle(
                    isPrimary
                        ? DesignTokens.ColorToken.primaryBurgundy
                        : DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: DesignTokens.Layout.minimumHitTarget, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(CutePopButtonStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(action.accessibilityLabel ?? action.label)
        .accessibilityIdentifier(isPrimary ? "popup.action.primary" : "popup.action.secondary")
    }
}

/// Keep the approved fruit/bubble relationship at ordinary phone widths. If a
/// constrained container cannot fit both at their usable sizes, omit decorative
/// fruit rather than force the text column outside its parent or shrink text.
nonisolated struct FruitPopupCompositionMetrics {
    let characterWidth: CGFloat
    let bubbleWidth: CGFloat
    let spacing: CGFloat
    let showsCharacter: Bool

    init(availableWidth: CGFloat, messageLength: Int) {
        let available = availableWidth.isFinite ? max(0, availableWidth) : 0
        let character = min(max(available * 0.18, 58), 72)
        let overlap = min(14, character * 0.20)
        showsCharacter = available >= character + 188 - overlap
        characterWidth = showsCharacter ? character : 0
        spacing = showsCharacter ? -overlap : 0
        let bonus: CGFloat = messageLength <= 58 ? 0 : (messageLength <= 105 ? 18 : 30)
        let desired = max(available * 0.58, 184) + bonus
        bubbleWidth = min(desired, 246, max(0, available - characterWidth - spacing))
    }
}
