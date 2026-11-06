import SwiftUI

struct Prompt10LibraryStorageNotice: View {
    @ObservedObject var store: Prompt10SavedLibraryStore
    var interactionAllowed: () -> Bool = { true }
    var body: some View {
        if let reason = store.storageProtectionReason {
            VStack(spacing: 10) {
                FruitfolioTranslatedText(source: reason.localizedDescription,
                    font: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                WatercolorSecondaryButton(label: "reload saved library") {
                    guard interactionAllowed() else { return }
                    store.reloadSavedLibrary()
                }
                    .accessibilityIdentifier("library.reloadSavedRecord")
            }
            .accessibilityIdentifier("library.savedRecordNotice")
        }
    }
}
