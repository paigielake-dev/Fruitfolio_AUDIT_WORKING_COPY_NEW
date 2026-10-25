import Foundation
import UIKit

struct Prompt04AssetPreloadResult: Sendable {
    let missingIDs: [FruitfolioAssetID]

    var allCriticalAssetsReady: Bool { missingIDs.isEmpty }
}

enum Prompt04AssetPreloader {
    /// Loads critical Prompt 04 images before the first visible animated state.
    /// UIKit decoding occurs synchronously on the main actor only once at launch;
    /// the complete Prompt 04 visible asset set is decoded once and never per-frame.
    @MainActor
    static func preload(bundle: Bundle = .main) -> Prompt04AssetPreloadResult {
        var missing: [FruitfolioAssetID] = []

        for id in Prompt04IntroConfiguration.requiredAssetIDs {
            do {
                _ = try FruitfolioAssetLoader.uiImage(id, bundle: bundle)
            } catch {
                missing.append(id)
                #if DEBUG
                print("[Fruitfolio][Prompt04] Critical Intro asset unavailable: \(id.rawValue)")
                #endif
            }
        }

        return Prompt04AssetPreloadResult(missingIDs: missing)
    }
}
