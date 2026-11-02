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

    @State
    private var appeared = false

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
        min(max(availableWidth * 0.18, 58), 72)
    }

    private var bubbleWidth: CGFloat {
        let messageBonus: CGFloat
        switch request.message.count {
        case 0...58: messageBonus = 0
        case 59...105: messageBonus = 18
        default: messageBonus = 30
        }

        let desired = max(availableWidth * 0.58, 184) + messageBonus
        let maximum = max(188, availableWidth - characterWidth + 10)
        return min(desired, min(246, maximum))
    }

    private var compositionSpacing: CGFloat {
        -min(14, characterWidth * 0.20)
    }

    var body: some View {
        Group {
            if characterSide == .left {
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
            invitationSafeMessage
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
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

    private var invitationSafeMessage: Text {
        if request.message == "hello there! ♡ want me to show you around?" {
            return Text("hello there!\u{00A0}♡\nwant me to show you around?")
        }

        return Text(
            request.message.replacingOccurrences(
                of: " ♡",
                with: "\u{00A0}♡"
            )
        )
    }

    private func popupActionButton(
        _ action: FruitPopupAction,
        isPrimary: Bool
    ) -> some View {
        Button {
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
    }
}
