import Foundation

/// Fruitfolio is sold as a paid-upfront App Store download.
/// Prompt 03 must not create a second in-app purchase, subscription, premium tier, or paywall.
enum FruitfolioDistributionModel: String, Codable, Sendable {
    case paidAppStoreDownload
}

enum FruitfolioPurchasePolicy {
    static let distributionModel: FruitfolioDistributionModel = .paidAppStoreDownload
    static let normalInstalledUserHasAccess = true
    static let offersInAppUnlockPurchase = false
    static let offersSubscription = false
    static let offersFreePremiumSplit = false

    static func requiresPurchaseGate(for route: FruitfolioRoute) -> Bool {
        false
    }

    /// Prompt 03 retains the canonical route identity for architecture QA only.
    /// It is never a normal production destination for the paid-download product.
    static var allowsReservedPurchaseRouteForQA: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
