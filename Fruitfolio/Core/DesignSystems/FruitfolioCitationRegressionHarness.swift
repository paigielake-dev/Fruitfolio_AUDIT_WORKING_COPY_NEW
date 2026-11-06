#if DEBUG
import SwiftUI

/// Uses the actual citation component and real root popup host, never a system
/// alert or bare test modal. The injected OpenURLAction does not open a service.
struct FruitfolioCitationRegressionHarness: View {
    @State private var actions = 0
    @State private var showingSheet = false
    private var usesSheet: Bool { ProcessInfo.processInfo.arguments.contains("-fruitfolioCitationQAInSheet") }
    @EnvironmentObject private var settings: SettingsStore
    var body: some View {
        Group {
            if usesSheet {
                Color.clear
                    .sheet(isPresented: $showingSheet) {
                        FruitfolioPresentedPopupHost { citationContent }
                    }
            } else { citationContent }
        }
        .onAppear {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioCitationReduceMotion")
            if usesSheet { showingSheet = true }
        }
    }
    private var citationContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button("citation QA background action") { actions += 1 }
                    .accessibilityIdentifier("citationQA.background")
                Text("background actions: \(actions)").accessibilityIdentifier("citationQA.actions")
                FruitPopupHost { FruitfolioCharacterPopupRegressionButton() }
                FruitfolioSourceCitationList(sources: [.init(id: "qa-citation", title: "UI attribution fixture",
                    sourceText: "Original, A. (2020). UI fixture only; not medical research.",
                    urlString: "https://example.invalid/source", doi: "10.1000/fixture", contentVersion: "qa-only")])
            }
            .padding(24)
        }
    }
}
private struct FruitfolioCharacterPopupRegressionButton: View {
    @EnvironmentObject private var coordinator: PopupCoordinator
    var body: some View {
        Button("character QA popup") {
            coordinator.request(.init(character: .blueberry,
                message: "UI fixture only. close this informational popup when ready.",
                primaryAction: .init(label: "close root popup") { coordinator.dismissCurrent(reason: .programmatic) },
                dismissBehavior: .explicitActionOnly, tone: .informational))
        }
        .accessibilityIdentifier("citationQA.characterPopup")
    }
}

#endif
