import Foundation

/// Prompt 03 bridge to the canonical Prompt 01 asset registry.
/// Views request typed canonical IDs, never raw physical filenames.
enum AssetConstants {
    static var productionAssetCount: Int { AssetRegistry.all.count }

    static func record(_ id: FruitfolioAssetID) -> FruitfolioAssetRecord {
        AssetRegistry.record(for: id)
    }

    static func physicalPath(_ id: FruitfolioAssetID) -> String {
        record(id).physicalPath
    }

    static func isProductionRenderable(_ id: FruitfolioAssetID) -> Bool {
        record(id).status != .awaitingFutureAsset
    }
}
