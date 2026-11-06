import SwiftUI

struct FruitfolioContextStorageNotice: View {
    @ObservedObject var store: Prompt27AContextStore
    var messageFocusRequest: UUID? = nil
    @AccessibilityFocusState private var messageFocused: Bool
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
                    guard !Task.isCancelled, store.persistenceMessage == message else { return }
                    messageFocused = true
                }
                if store.storageProtectionReason != nil {
                    WatercolorSecondaryButton(label: "reload saved context") { store.reloadSavedContext() }
                        .accessibilityIdentifier("myContext.reloadSavedRecord")
                }
            }
            .accessibilityIdentifier("myContext.savedRecordNotice")
        }
    }
}
