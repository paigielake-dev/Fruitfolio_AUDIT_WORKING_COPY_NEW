import Foundation

struct Prompt26PregnancyAssetAuditResult: Equatable, Sendable {
    let expectedImageNames: [String]
    let missingImageNames: [String]

    var isComplete: Bool { missingImageNames.isEmpty }
}

enum Prompt26PregnancyAssetAudit {
    static var expectedImageNames: [String] {
        Prompt26PregnancyAsset.allCases.map(\.imageName).sorted()
    }

    static var catalogReachabilityIsComplete: Bool {
        Prompt26PregnancyEducationCatalog.reachableAssets == Set(Prompt26PregnancyAsset.allCases)
    }
}

#if canImport(UIKit)
import UIKit

extension Prompt26PregnancyAssetAudit {
    static func audit(bundle: Bundle = .main) -> Prompt26PregnancyAssetAuditResult {
        let missing = expectedImageNames.filter { name in
            UIImage(named: name, in: bundle, compatibleWith: nil) == nil
        }
        return Prompt26PregnancyAssetAuditResult(
            expectedImageNames: expectedImageNames,
            missingImageNames: missing
        )
    }
}
#endif
