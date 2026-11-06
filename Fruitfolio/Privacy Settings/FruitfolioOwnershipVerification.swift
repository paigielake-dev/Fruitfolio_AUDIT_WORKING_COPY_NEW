import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

nonisolated enum FruitfolioOwnershipVerification: Equatable, Sendable {
    case verifiedProductionInstallation, verifiedTestInstallation, unverified, unavailable
}
nonisolated enum FruitfolioStoreEnvironment: Sendable { case production, test, unknown }

/// Evaluates evidence supplied by the platform adapter, not a user-provided
/// receipt flag. Signature verification itself belongs to StoreKit.
nonisolated enum FruitfolioOwnershipRecordPolicy {
    static func evaluate(signatureVerified: Bool, bundleIdentifier: String,
                         expectedBundleIdentifier: String, environment: FruitfolioStoreEnvironment) -> FruitfolioOwnershipVerification {
        guard signatureVerified, !expectedBundleIdentifier.isEmpty,
              bundleIdentifier == expectedBundleIdentifier else { return .unverified }
        switch environment {
        case .production: return .verifiedProductionInstallation
        case .test: return .verifiedTestInstallation
        case .unknown: return .unavailable
        }
    }
}
nonisolated protocol FruitfolioOwnershipVerifying: Sendable {
    func verify(expectedBundleIdentifier: String) async -> FruitfolioOwnershipVerification
}

/// Optional, user-initiated app ownership check. No purchase product, account,
/// backend, health record, receipt upload or second access gate is introduced.
nonisolated struct FruitfolioStoreKitOwnershipVerifier: FruitfolioOwnershipVerifying {
    func verify(expectedBundleIdentifier: String) async -> FruitfolioOwnershipVerification {
        guard !expectedBundleIdentifier.isEmpty else { return .unavailable }
        #if canImport(StoreKit)
        do {
            let verification = try await AppTransaction.shared
            try Task.checkCancellation()
            switch verification {
            case .verified(let transaction):
                let environment: FruitfolioStoreEnvironment
                if transaction.environment == .production { environment = .production }
                else if transaction.environment == .sandbox || transaction.environment == .xcode { environment = .test }
                else { environment = .unknown }
                return FruitfolioOwnershipRecordPolicy.evaluate(signatureVerified: true,
                    bundleIdentifier: transaction.bundleID, expectedBundleIdentifier: expectedBundleIdentifier,
                    environment: environment)
            case .unverified:
                return .unverified
            }
        } catch { return .unavailable }
        #else
        return .unavailable
        #endif
    }
}
