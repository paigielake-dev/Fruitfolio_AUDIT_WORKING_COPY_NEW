import Foundation

@MainActor
enum Prompt28AssetUsageRegistrar {
    static let allFruitBasketAssets: [FruitfolioAssetID] = [
        .fruitbasket_orange, .fruitbasket_blueberry, .fruitbasket_peach,
        .fruitbasket_basket, .fruitbasket_branch, .fruitbasket_grape,
        .fruitbasket_wind, .fruitbasket_background, .fruitbasket_star_balloons,
        .fruitbasket_watermelon, .fruitbasket_rain_cloud, .fruitbasket_apple,
        .fruitbasket_confetti, .fruitbasket_cloud, .fruitbasket_pear,
        .fruitbasket_vines, .fruitbasket_star, .fruitbasket_strawberry,
        .fruitbasket_plum, .fruitbasket_lemon, .fruitbasket_chalkboard,
        .fruitbasket_rain, .fruitbasket_puddle, .fruitbasket_crown
    ]

    static func markProductionRoutes() {
        let ledger = AssetUsageLedger.shared
        for id in allFruitBasketAssets {
            ledger.markWired(id, productionState: productionState(for: id))
        }
    }

    static func markRendered(_ id: FruitfolioAssetID) {
        AssetUsageLedger.shared.markRendered(id)
    }

    private static func productionState(for id: FruitfolioAssetID) -> String {
        switch id {
        case .fruitbasket_background: return "Fruit Basket — meadow environment"
        case .fruitbasket_basket: return "Fruit Basket — active catch field / basket progress"
        case .fruitbasket_star: return "Fruit Basket — GOOD fruit indicator"
        case .fruitbasket_branch: return "Fruit Basket — level 3+ branch obstacle"
        case .fruitbasket_puddle: return "Fruit Basket — level 5+ puddle obstacle"
        case .fruitbasket_vines: return "Fruit Basket — level 3+ edge vines"
        case .fruitbasket_wind, .fruitbasket_cloud: return "Fruit Basket — breezy weather state"
        case .fruitbasket_rain, .fruitbasket_rain_cloud: return "Fruit Basket — soft-rain weather state"
        case .fruitbasket_chalkboard: return "Fruit Basket — leaderboard / game status"
        case .fruitbasket_crown: return "Fruit Basket — personal-best / first-place milestone"
        case .fruitbasket_star_balloons, .fruitbasket_confetti: return "Fruit Basket — bounded milestone celebration"
        default: return "Fruit Basket — provider-approved GOOD/BAD catch classification"
        }
    }
}
