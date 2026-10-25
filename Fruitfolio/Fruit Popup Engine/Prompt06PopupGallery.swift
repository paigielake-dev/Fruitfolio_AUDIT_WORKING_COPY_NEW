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
#endif
