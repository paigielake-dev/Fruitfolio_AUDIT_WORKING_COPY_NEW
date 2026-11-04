import Foundation
import StoreKit

nonisolated enum FruitfolioStorefrontOwnershipResult: Equatable, Sendable {
    case verified(bundleID: String)
    case unverified
    case unavailable
}

nonisolated protocol FruitfolioStorefrontOwnershipValidating: Sendable {
    func validate() async -> FruitfolioStorefrontOwnershipResult
}

/// Paid-download ownership only: never offers a second purchase or subscription.
/// StoreKit verifies the App Store signature; unverified payloads are not trusted.
nonisolated struct FruitfolioAppleOwnershipValidator: FruitfolioStorefrontOwnershipValidating {
    func validate() async -> FruitfolioStorefrontOwnershipResult {
        do {
            let result = try await AppTransaction.shared
            switch result {
            case .verified(let transaction): return .verified(bundleID: transaction.bundleID)
            case .unverified(_, _): return .unverified
            @unknown default: return .unavailable
            }
        } catch {
            return .unavailable
        }
    }
}
