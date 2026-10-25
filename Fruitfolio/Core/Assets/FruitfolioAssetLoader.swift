import SwiftUI
import UIKit

/// Errors are explicit by design. Fruitfolio never silently substitutes founder artwork.
enum FruitfolioAssetLoadingError: LocalizedError, Equatable {
    case missing(FruitfolioAssetID, String)

    var errorDescription: String? {
        switch self {
        case let .missing(id, path):
            return "Missing Fruitfolio asset \(id.rawValue) at \(path)"
        }
    }
}

enum FruitfolioAssetLoader {
    /// Returns the physical bundle URL for a registered PNG when available.
    /// Supports either the preserved founder folders (including trailing colons),
    /// normalized folder names, or a flattened bundle resource.
    static func resourceURL(
        for id: FruitfolioAssetID,
        bundle: Bundle = .main
    ) -> URL? {
        let record = AssetRegistry.record(for: id)

        let candidateSubdirectories: [String?] = [
            record.physicalFolder,
            "Fruitfolio Assets/\(record.physicalFolder)",
            record.physicalFolder.replacingOccurrences(of: ":", with: ""),
            "Fruitfolio Assets/\(record.physicalFolder.replacingOccurrences(of: ":", with: ""))",
            nil
        ]

        for subdirectory in candidateSubdirectories {
            if let url = bundle.url(
                forResource: record.resourceStem,
                withExtension: "png",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return nil
    }

    /// Loads raw PNG bytes. Validator and duplicate checks use this API so they do
    /// not depend on image re-encoding.
    static func data(
        for id: FruitfolioAssetID,
        bundle: Bundle = .main
    ) throws -> Data {
        if let url = resourceURL(for: id, bundle: bundle),
           let data = try? Data(contentsOf: url) {
            return data
        }

        let record = AssetRegistry.record(for: id)
        throw FruitfolioAssetLoadingError.missing(id, record.physicalPath)
    }

    /// Loads founder art for UIKit/SwiftUI presentation.
    static func uiImage(
        _ id: FruitfolioAssetID,
        bundle: Bundle = .main
    ) throws -> UIImage {
        let record = AssetRegistry.record(for: id)

        // Handles asset-catalog or name-based bundle imports.
        if let image = UIImage(named: record.resourceStem, in: bundle, compatibleWith: nil) {
            return image
        }
        if let image = UIImage(named: record.filename, in: bundle, compatibleWith: nil) {
            return image
        }

        // Handles folder-reference resources.
        if let url = resourceURL(for: id, bundle: bundle),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        throw FruitfolioAssetLoadingError.missing(id, record.physicalPath)
    }

    static func image(
        _ id: FruitfolioAssetID,
        bundle: Bundle = .main
    ) -> Image {
        do {
            return Image(uiImage: try uiImage(id, bundle: bundle))
        } catch {
            assertionFailure(error.localizedDescription)
            // Empty image only exposes the failure during development; it is not a
            // replacement artwork, SF Symbol, emoji, or fabricated asset.
            return Image(uiImage: UIImage())
        }
    }

    static func exists(
        _ id: FruitfolioAssetID,
        bundle: Bundle = .main
    ) -> Bool {
        if resourceURL(for: id, bundle: bundle) != nil {
            return true
        }

        let record = AssetRegistry.record(for: id)
        return UIImage(named: record.resourceStem, in: bundle, compatibleWith: nil) != nil
            || UIImage(named: record.filename, in: bundle, compatibleWith: nil) != nil
    }
}

struct FruitfolioImage: View {
    let id: FruitfolioAssetID
    var contentMode: ContentMode = .fit
    var accessibilityLabelOverride: String? = nil

    var body: some View {
        let record = AssetRegistry.record(for: id)
        let semanticLabel = accessibilityLabelOverride ?? record.accessibilityLabel
        let shouldHide = record.assetClass == .decorative || semanticLabel == nil

        FruitfolioAssetLoader.image(id)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .accessibilityHidden(shouldHide)
            .accessibilityLabel(Text(semanticLabel ?? ""))
    }
}
