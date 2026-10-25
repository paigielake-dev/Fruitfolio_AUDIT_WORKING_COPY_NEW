import Foundation
import CryptoKit

struct AssetValidationResult: Sendable {
    let registeredCount: Int
    let uniqueIDCount: Int
    let uniquePhysicalPathCount: Int
    let missingPhysicalAssets: [FruitfolioAssetRecord]
    let duplicateByteGroups: [[FruitfolioAssetID]]
    let referenceOnlyInventory: [String]
    let artVsCodeWarnings: [String]

    var passedRegistryShape: Bool {
        registeredCount == AssetRegistry.expectedProductionPNGCount
            && uniqueIDCount == AssetRegistry.expectedProductionPNGCount
            && uniquePhysicalPathCount == AssetRegistry.expectedProductionPNGCount
    }

    var passedPhysicalAvailability: Bool {
        missingPhysicalAssets.isEmpty
    }

    var passedPhaseZeroAssetValidation: Bool {
        passedRegistryShape && passedPhysicalAvailability
    }
}

enum FruitfolioAssetValidator {
    static let referenceOnlyInventory = [
        "cycle_calendar_reference.png",
        "cycle_wheel_reference.png"
    ]

    static let artVsCodeWarnings = [
        "Keep names, usernames, dates, titles, questions, answers, citations, source text, cycle values, predictions, scores, timers, graph data, BBT values, hormone values, symptoms, selection states, user data, progress, accessibility labels, and hit targets in code.",
        "Never render ReferenceOnly material as production UI.",
        "Never substitute missing founder art with emoji or SF Symbols.",
        "EducationalVisuals are educational media, never decoration, and require Research support before Ask routing."
    ]

    static func validate(bundle: Bundle = .main) -> AssetValidationResult {
        let uniqueIDs = Set(AssetRegistry.all.map(\.id))
        let uniquePaths = Set(AssetRegistry.all.map(\.physicalPath))
        let missing = AssetRegistry.all.filter {
            !FruitfolioAssetLoader.exists($0.id, bundle: bundle)
        }

        return AssetValidationResult(
            registeredCount: AssetRegistry.all.count,
            uniqueIDCount: uniqueIDs.count,
            uniquePhysicalPathCount: uniquePaths.count,
            missingPhysicalAssets: missing,
            duplicateByteGroups: exactDuplicateByteGroups(bundle: bundle),
            referenceOnlyInventory: referenceOnlyInventory,
            artVsCodeWarnings: artVsCodeWarnings
        )
    }

    private static func exactDuplicateByteGroups(bundle: Bundle) -> [[FruitfolioAssetID]] {
        var groups: [String: [FruitfolioAssetID]] = [:]

        for record in AssetRegistry.all {
            guard let data = try? FruitfolioAssetLoader.data(for: record.id, bundle: bundle) else {
                continue
            }

            let digest = SHA256.hash(data: data)
                .map { String(format: "%02x", $0) }
                .joined()

            groups[digest, default: []].append(record.id)
        }

        return groups.values
            .filter { $0.count > 1 }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return (lhs.first?.rawValue ?? "") < (rhs.first?.rawValue ?? "")
                }
                return lhs.count > rhs.count
            }
    }
}

extension AssetValidationResult {
    func consoleReport() -> String {
        var lines: [String] = []
        lines.append("FRUITFOLIO PROMPT 01 — ASSET REPORT")
        lines.append("Registered: \(registeredCount)/\(AssetRegistry.expectedProductionPNGCount)")
        lines.append("Unique IDs: \(uniqueIDCount)/\(AssetRegistry.expectedProductionPNGCount)")
        lines.append("Unique physical paths: \(uniquePhysicalPathCount)/\(AssetRegistry.expectedProductionPNGCount)")
        lines.append("Missing physical assets: \(missingPhysicalAssets.count)")

        if !missingPhysicalAssets.isEmpty {
            lines.append(contentsOf: missingPhysicalAssets.map { "  MISSING: \($0.physicalPath)" })
        }

        lines.append("Exact duplicate groups: \(duplicateByteGroups.count)")
        for group in duplicateByteGroups {
            lines.append("  DUPLICATE BYTES: " + group.map(\.rawValue).joined(separator: ", "))
        }

        lines.append("ReferenceOnly: " + referenceOnlyInventory.joined(separator: ", "))
        lines.append("Art-vs-code rules:")
        lines.append(contentsOf: artVsCodeWarnings.map { "  - \($0)" })
        lines.append("Phase Zero asset validation: \(passedPhaseZeroAssetValidation ? "PASS" : "FAIL")")
        return lines.joined(separator: "\n")
    }
}
