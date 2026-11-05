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
    @State private var isPresented = true
    private let reduceMotion = ProcessInfo.processInfo.arguments.contains("-fruitfolioModalReduceMotion")

    var body: some View {
        ZStack {
            Button("Background action") { isPresented = true }
                .accessibilityIdentifier("modalQA.background")
                .fruitfolioModalBlur(active: isPresented, reduceMotion: reduceMotion)

            if isPresented {
                FruitPopupView(
                    request: FruitPopupRequest(
                        character: .blueberry,
                        message: String(repeating: "Educational estimates carry uncertainty. Keep citations and units attached to their sources. ", count: 3),
                        primaryAction: FruitPopupAction(label: "Close this educational explanation") {
                            isPresented = false
                        }
                    ),
                    availableWidth: 320,
                    reduceMotion: reduceMotion
                )
                .accessibilityIdentifier("modalQA.popup")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.ColorToken.backgroundCream)
    }
}
#endif
