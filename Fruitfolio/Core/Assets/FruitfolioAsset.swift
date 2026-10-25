
import Foundation

enum FruitfolioAssetClass: String, Codable, Sendable {
    case functional
    case decorative
    case educational
    case character
    case brand
    case environmental
    case biologicalContext
}

enum FruitfolioImplementationStatus: String, Codable, Sendable {
    case registered
    case wired
    case rendered
    case qaPassed
    case awaitingFutureAsset
}

struct FruitfolioAssetRecord: Identifiable, Hashable, Sendable {
    let id: FruitfolioAssetID
    let filename: String
    let physicalFolder: String
    let assetClass: FruitfolioAssetClass
    let category: String
    let subcategory: String?
    let primaryDestination: String
    let allowedSecondaryDestinations: [String]
    let interactionBehavior: String
    let accessibilityLabel: String?
    let longPressLabel: String?
    let researchSupportRequired: Bool
    let preferredWidthMinFraction: Double?
    let preferredWidthMaxFraction: Double?
    let animationAllowed: Bool
    let allowedAnimations: [String]
    let status: FruitfolioImplementationStatus
    let notes: String

    var physicalPath: String { "\(physicalFolder)/\(filename)" }
    var resourceStem: String { (filename as NSString).deletingPathExtension }
}
