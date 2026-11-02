import SwiftUI

nonisolated enum Prompt28WeatherCopy {
    static let stormNotice = "uh oh! a little storm is passing. o__o"
}

/// The specified original large contact-card PNG, using the same adaptive
/// writing-region and scrolling system as other founder-artwork popups.
struct Prompt28StormNoticeView: View {
    let onContinue: () -> Void
    @EnvironmentObject private var audio: AudioManager
    @AccessibilityFocusState private var messageFocused: Bool

    var body: some View {
        FruitfolioPopupArtworkSurface(assetName: "control_large_card",
            normalizedWriting: CGRect(x: 0.12, y: 0.12, width: 0.76, height: 0.76), maximumWidth: 350) {
            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    FruitfolioImage(id: .fruit_strawberry_silly)
                        .frame(width: 72, height: 72)
                        .accessibilityLabel("Strawberry")
                    Text(Prompt28WeatherCopy.stormNotice)
                        .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($messageFocused)
                }
                FruitfolioControlPillButton(label: "keep catching") { onContinue() }
                    .accessibilityIdentifier("fruitBasket.stormContinue")
            }
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("fruitBasket.stormNotice")
        .accessibilityAction(.escape) { onContinue() }
        .task { await Task.yield(); guard !Task.isCancelled else { return }; messageFocused = true }
        .onAppear { audio.play(.popupOpen) }
    }
}

struct Prompt28PuddleArtwork: View {
    let reduceMotion: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: reduceMotion)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
            FruitfolioImage(id: .fruitbasket_puddle)
                .scaleEffect(x: reduceMotion ? 1 : 1 + 0.012 * sin(phase * 1.7),
                             y: reduceMotion ? 1 : 1 + 0.008 * cos(phase * 1.5), anchor: .center)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
