import Foundation

/// Game rules only: never a medical interpretation of a fruit or source paragraph.
nonisolated enum Prompt28RulesCopy {
    static let standaloneStar = "a standalone star — catch it to bank one star pass after it fully enters and settles. it does not fill the fruit basket or add points."

    static func fruitAccessibilitySource(_ fruit: Prompt28FallingFruit, classificationPrompt: Bool = false) -> String {
        let marker = fruit.classification == .good ? "attached star marker" : "no attached star marker"
        let purpose = classificationPrompt ? "Does this belong in the basket?"
            : fruit.classification == .good ? "belongs in basket" : "does not belong in basket"
        return "\(fruit.fruitID.displayName). \(marker). \(purpose)"
    }

    static var catches: String {
        let rules = Prompt28RoundRules.canonical
        return "catch \(rules.goodFruitTarget) starred fruits to fill your basket. the small star attached to a fruit marks a good fruit; it is not a bonus star. fruit counts only after it enters and settles in the basket. each good catch earns +\(rules.goodFruitCatchScore) points. missing good fruit or letting bad fruit pass costs no points."
    }
    static let protection = "standalone stars are rare. each caught star adds one star pass to the passes you already have, with no fixed limit. stars do not fill the basket or add points. a pass is banked only after the star fully enters and settles. catching bad fruit spends exactly one available pass and play continues. without a pass, that catch attempt ends; you can retry. passes carry between catch attempts in this learning session, not into a new session."
    static let results = "the result shows actual catches, stars collected, passes used and remaining, points earned in that attempt, and the session score. a failed attempt keeps its already-earned points and catches. the library explanation is separate from the visual catch rule."
    static let totals = "on-device totals count good fruit and standalone stars when caught, including failed or unfinished attempts. successful baskets count only completed baskets. older saved fruit totals may omit failed or unfinished attempts; no missing history is guessed. worldwide rankings are unavailable until secure registration is configured."
    static let accessibleMode = "classification mode uses catch and pass buttons with the same scoring and protection rules, without reflex dragging. question difficulty changes the learning depth; game level changes catching. resetting game level preserves lifetime progress."
}

/// One source of truth for the existing ten tutorial pages. Copy and demo
/// selection remain unchanged; step counts derive from this ordered catalog.
nonisolated struct Prompt28TourPage: Equatable, Sendable {
    let title: String
    let body: String
    var showsFruitDemo = false
}

nonisolated enum Prompt28TourCatalog {
    static let pages: [Prompt28TourPage] = [
        .init(title: "welcome to the Fruit Basket!",
              body: "you pick something you wanna learn about, answer a little question, and then fill your basket with the fruits that belong. ♡"),
        .init(title: "pick what you wanna learn",
              body: "type any topic the approved library supports, then choose easy, medium, or hard. that only changes how deep the questions go."),
        .init(title: "your game level",
              body: "game level only changes the catching. you can start a topic’s game level over whenever you want without changing the science."),
        .init(title: "answer the question",
              body: "pick the answer you think is right. a wrong answer shows the correct answer + sourced explanation, with no point loss."),
        .init(title: "the catch rule",
              body: Prompt28RulesCopy.catches + "\n\n" + Prompt28RulesCopy.protection, showsFruitDemo: true),
        .init(title: "practice a good catch",
              body: "a good catch adds +1 to your basket and +10 points. ten good fruits fills it."),
        .init(title: "missing is okay",
              body: "miss a good fruit? nothing gets taken away. another one will come along."),
        .init(title: "let bad fruit pass",
              body: "bad fruit can fall away safely. if you catch one with a star pass banked, exactly one pass is used and the round keeps going. with zero passes, the round ends."),
        .init(title: "fill to 10",
              body: "the tenth good fruit lands first, the basket reaches 10 / 10, then the result shows what you actually caught. the sourced library explanation stays separate from the catch rule."),
        .init(title: "one last reminder",
              body: "catch \(Prompt28RoundRules.canonical.goodFruitTarget) good fruits. " + Prompt28RulesCopy.standaloneStar + " question difficulty and game level stay separate. ♡"),
    ]
}
