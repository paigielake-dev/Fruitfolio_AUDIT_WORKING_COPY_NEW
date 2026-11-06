import SwiftUI

struct FruitfolioContextStorageNotice: View {
    @ObservedObject var store: Prompt27AContextStore
    var body: some View {
        if let message = store.persistenceMessage {
            VStack(alignment: .leading, spacing: 10) {
                FruitfolioTranslatedText(source: message,
                    font: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                if store.storageProtectionReason != nil {
                    WatercolorSecondaryButton(label: "reload saved context") { store.reloadSavedContext() }
                        .accessibilityIdentifier("myContext.reloadSavedRecord")
                }
            }
            .accessibilityIdentifier("myContext.savedRecordNotice")
        }
    }
}
