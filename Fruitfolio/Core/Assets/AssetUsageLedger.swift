import Foundation

struct AssetUsageLedgerEntry: Identifiable, Hashable, Sendable {
    let id: FruitfolioAssetID
    let physicalPath: String
    let assetClass: FruitfolioAssetClass
    let primaryDestination: String
    let allowedSecondaryDestinations: [String]
    var exactReachableProductionStates: [String]
    var interactionBehavior: String
    var longPressLabel: String?
    var voiceOverBehavior: String
    var colorRole: String
    var sizingBehavior: String
    var animationPermissions: [String]
    var status: FruitfolioImplementationStatus
    var notes: String
}

/// Phase-zero bookkeeping only. It intentionally does not conform to ObservableObject:
/// no production UI needs to observe this ledger yet, and avoiding unnecessary reactive
/// state keeps Prompt 01 independent from Combine.
@MainActor
final class AssetUsageLedger {
    static let shared = AssetUsageLedger()

    private(set) var entries: [FruitfolioAssetID: AssetUsageLedgerEntry]

    private init() {
        entries = Dictionary(
            uniqueKeysWithValues: AssetRegistry.all.map { record in
                (
                    record.id,
                    AssetUsageLedgerEntry(
                        id: record.id,
                        physicalPath: record.physicalPath,
                        assetClass: record.assetClass,
                        primaryDestination: record.primaryDestination,
                        allowedSecondaryDestinations: record.allowedSecondaryDestinations,
                        exactReachableProductionStates: [],
                        interactionBehavior: record.interactionBehavior,
                        longPressLabel: record.longPressLabel,
                        voiceOverBehavior: record.accessibilityLabel.map { "Expose as: \($0)" }
                            ?? "Hide when decorative/non-communicative",
                        colorRole: "Preserve founder color; semantic screen color is assigned by the owning prompt",
                        sizingBehavior: "scaledToFit; preserve aspect ratio and transparent watercolor boundary",
                        animationPermissions: record.allowedAnimations,
                        status: .registered,
                        notes: record.notes
                    )
                )
            }
        )
    }

    func markWired(_ id: FruitfolioAssetID, productionState: String) {
        guard var entry = entries[id] else { return }
        if !entry.exactReachableProductionStates.contains(productionState) {
            entry.exactReachableProductionStates.append(productionState)
        }
        if entry.status == .registered {
            entry.status = .wired
        }
        entries[id] = entry
    }

    func markRendered(_ id: FruitfolioAssetID) {
        guard var entry = entries[id] else { return }
        entry.status = .rendered
        entries[id] = entry
    }

    func markQAPassed(_ id: FruitfolioAssetID) {
        guard var entry = entries[id] else { return }
        entry.status = .qaPassed
        entries[id] = entry
    }

    var orphanedIDs: [FruitfolioAssetID] {
        entries.values
            .filter { $0.exactReachableProductionStates.isEmpty }
            .map(\.id)
            .sorted { $0.rawValue < $1.rawValue }
    }
}
