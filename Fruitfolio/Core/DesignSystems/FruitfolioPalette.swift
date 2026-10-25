import SwiftUI

enum FruitfolioSemanticColor: String, CaseIterable, Sendable {
    case neutral
    case inquiry
    case organization
    case creation
    case bodyAction
    case playReward
    case helpReference
    case scientificSecondary
    case reproductiveWarmth

    var color: Color {
        switch self {
        case .neutral: return DesignTokens.ColorToken.backgroundCream
        case .inquiry: return DesignTokens.ColorToken.mint
        case .organization: return DesignTokens.ColorToken.sage
        case .creation: return DesignTokens.ColorToken.peach
        case .bodyAction: return DesignTokens.ColorToken.coral
        case .playReward: return DesignTokens.ColorToken.paleYellow
        case .helpReference: return DesignTokens.ColorToken.lavender
        case .scientificSecondary: return DesignTokens.ColorToken.dustyBlue
        case .reproductiveWarmth: return DesignTokens.ColorToken.watercolorPink
        }
    }
}

enum FruitfolioColorTheory {
    // Informational screens: neutral + one primary + normally no more than one secondary.
    static func informationalPalette(
        primary: FruitfolioSemanticColor,
        secondary: FruitfolioSemanticColor? = nil
    ) -> [FruitfolioSemanticColor] {
        var palette: [FruitfolioSemanticColor] = [.neutral]
        if primary != .neutral { palette.append(primary) }
        if let secondary, secondary != .neutral, secondary != primary { palette.append(secondary) }
        return palette
    }

    static let hubMemoryMap: [String: FruitfolioSemanticColor] = [
        "Ask the Encyclopedia": .inquiry,
        "My Encyclopedias": .organization,
        "Build Your Own Guide": .creation,
        "Cycle Tracker": .bodyAction,
        "Fruit Basket": .playReward,
        "FAQ": .helpReference
    ]
}
