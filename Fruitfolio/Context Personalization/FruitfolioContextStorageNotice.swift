import SwiftUI
import UIKit

struct FruitfolioContextStorageNotice: View {
    @ObservedObject var store: Prompt27AContextStore
    var messageFocusRequest: UUID? = nil
    var interactionAllowed = true
    @AccessibilityFocusState private var messageFocused: Bool
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    private var canInteract: Bool {
        interactionAllowed && viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active && popupCoordinator.currentPopup == nil
    }
    var body: some View {
        if let message = store.persistenceMessage {
            VStack(alignment: .leading, spacing: 10) {
                FruitfolioTranslatedContent(source: message) { display, _ in
                    FruitfolioSemanticText(markdown: display,
                        baseFont: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                        .accessibilityFocused($messageFocused)
                }
                .task(id: messageFocusRequest) {
                    guard messageFocusRequest != nil else { return }
                    await Task.yield()
                    guard !Task.isCancelled, canInteract, store.persistenceMessage == message else { return }
                    messageFocused = true
                }
                if store.storageProtectionReason != nil {
                    WatercolorSecondaryButton(label: "reload saved context") { guard canInteract else { return }; store.reloadSavedContext() }
                        .accessibilityIdentifier("myContext.reloadSavedRecord")
                }
            }
            .accessibilityIdentifier("myContext.savedRecordNotice")
            .onAppear { viewIsVisible = true }
            .onDisappear { viewIsVisible = false }
        }
    }
}
