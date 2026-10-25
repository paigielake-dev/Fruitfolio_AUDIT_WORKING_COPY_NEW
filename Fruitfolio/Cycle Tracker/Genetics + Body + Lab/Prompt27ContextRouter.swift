import Foundation

struct Prompt27ContextRouter: Sendable {
    let catalog: Prompt27ScientificAssetCatalog

    init(catalog: Prompt27ScientificAssetCatalog = .init()) {
        self.catalog = catalog
    }

    func route(
        section: Prompt27ContextualScienceSection
    ) -> Result<Prompt27ScienceVisualRoute, Prompt27ScienceRoutingError> {
        switch section.primaryVisualFamily {
        case .none:
            guard section.primaryIllustrationAssetID == nil else {
                return .failure(.assetNotAllowedForNoneContext)
            }
            return .success(
                Prompt27ScienceVisualRoute(
                    family: .none,
                    primaryAsset: nil
                )
            )

        case .genetics, .body, .lab:
            guard let assetID = section.primaryIllustrationAssetID else {
                return .failure(
                    .assetRequiredForVisualContext(section.primaryVisualFamily)
                )
            }

            guard let asset = catalog.asset(for: assetID) else {
                return .failure(.missingAsset(assetID))
            }

            guard asset.isProductionEligible else {
                return .failure(.unapprovedAsset(assetID))
            }

            guard asset.family == section.primaryVisualFamily else {
                return .failure(
                    .familyMismatch(
                        expected: section.primaryVisualFamily,
                        actual: asset.family
                    )
                )
            }

            return .success(
                Prompt27ScienceVisualRoute(
                    family: section.primaryVisualFamily,
                    primaryAsset: asset
                )
            )

        case .other:
            // Prompt 27 does not invent or generate an illustration for "other".
            // Existing non-Prompt-27 visual systems may handle that context upstream.
            guard section.primaryIllustrationAssetID == nil else {
                return .failure(.assetNotAllowedForNoneContext)
            }
            return .success(
                Prompt27ScienceVisualRoute(
                    family: .other,
                    primaryAsset: nil
                )
            )
        }
    }
}
