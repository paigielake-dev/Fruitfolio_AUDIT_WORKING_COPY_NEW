import SwiftUI
import UIKit

/// Noninteractive source artwork; interactive explanations/hotspots stay in their
/// own controls. Layout sizes the full source canvas before placing the image.
struct FruitfolioScientificIllustration: View {
    private let image: UIImage?
    let accessibilityDescription: String
    var maximumWidth: CGFloat = 310
    var maximumHeight: CGFloat = 360
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var descriptionTranslation = FruitfolioControlTranslationState()


    init(imageName: String, accessibilityDescription: String, maximumWidth: CGFloat = 310, maximumHeight: CGFloat = 360) {
        image = UIImage(named: imageName)
        self.accessibilityDescription = accessibilityDescription
        self.maximumWidth = maximumWidth
        self.maximumHeight = maximumHeight
    }
    init(assetID: FruitfolioAssetID, accessibilityDescription: String, maximumWidth: CGFloat = 310, maximumHeight: CGFloat = 360) {
        image = try? FruitfolioAssetLoader.uiImage(assetID)
        self.accessibilityDescription = accessibilityDescription
        self.maximumWidth = maximumWidth
        self.maximumHeight = maximumHeight
    }

    var body: some View {
        let source = image == nil ? "Required scientific artwork unavailable. " + accessibilityDescription : accessibilityDescription
        let literals = ["DNA", "RNA", "E2", "LH", "FSH", "AMH", "BBT", "hCG"].filter { source.contains($0) }
        let key = FruitfolioControlTranslationState.Key(source: source, language: settings.language, protectedLiterals: literals)
        let description = descriptionTranslation.presentation(for: key)
        Group {
            if let image {
                FruitfolioScientificPlateLayout(intrinsic: image.size, maximumWidth: maximumWidth, maximumHeight: maximumHeight) {
                    Image(uiImage: image).resizable()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: description.text))
            } else {
                FruitfolioFixedText(source: "required scientific artwork unavailable", font: .footnote, serious: true)
                    .accessibilityLabel(Text(verbatim: description.text))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHint(Text(description.status.accessibilityDetail(original: source, localized: { settings.localized($0) })))
        .task(id: FruitfolioControlTranslationState.TaskKey(key: key, inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await descriptionTranslation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
    }
}

private struct FruitfolioScientificPlateLayout: Layout {
    let intrinsic: CGSize
    let maximumWidth: CGFloat
    let maximumHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        FruitfolioScientificArtSizing.fit(intrinsic: intrinsic, availableWidth: proposal.width,
                                         availableHeight: proposal.height, maximumWidth: maximumWidth, maximumHeight: maximumHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let size = FruitfolioScientificArtSizing.fit(intrinsic: intrinsic, availableWidth: bounds.width,
                                                    availableHeight: bounds.height, maximumWidth: maximumWidth, maximumHeight: maximumHeight)
        for subview in subviews {
            subview.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center,
                          proposal: ProposedViewSize(width: size.width, height: size.height))
        }
    }
}
