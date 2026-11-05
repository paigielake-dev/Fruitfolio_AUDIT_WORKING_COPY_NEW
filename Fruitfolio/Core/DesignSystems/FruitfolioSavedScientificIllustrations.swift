import SwiftUI

/// Reopens only explicitly saved canonical science artwork. It never reruns
/// topic matching or inserts decorative art into a saved page.
struct FruitfolioSavedScientificIllustrations: View {
    let assetIDs: [FruitfolioAssetID]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(assetIDs, id: \.self) { assetID in
                if let descriptor = EducationalAssetRouter.canonicalDescriptors.first(where: { $0.assetID == assetID }) {
                    FruitfolioImage(id: assetID)
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .accessibilityLabel(descriptor.accessibilityDescription)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
