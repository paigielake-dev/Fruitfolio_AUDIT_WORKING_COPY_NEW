import Foundation

/// Game rules only: never a medical interpretation of a fruit or source paragraph.
nonisolated enum Prompt28RulesCopy {
    static var catches: String {
        let rules = Prompt28RoundRules.canonical
        return "catch \(rules.goodFruitTarget) starred fruits to fill your basket. the small star attached to a fruit marks a good fruit; it is not a bonus star. fruit counts only after it enters and settles in the basket. each good catch earns +\(rules.goodFruitCatchScore) points. missing good fruit or letting bad fruit pass costs no points."
    }
    static let protection = "a standalone star banks one star pass and does not fill the basket or add points. catching bad fruit spends exactly one available pass and play continues. without a pass, that catch attempt ends; you can retry. passes carry between catch attempts in this learning session, not into a new session."
    static let results = "the result shows actual catches, stars collected, passes used and remaining, points earned in that attempt, and the session score. a failed attempt keeps its already-earned points and catches. the library explanation is separate from the visual catch rule."
    static let totals = "on-device totals count good fruit and standalone stars when caught, including failed or unfinished attempts. successful baskets count only completed baskets. older saved fruit totals may omit failed or unfinished attempts; no missing history is guessed. worldwide rankings are unavailable until secure registration is configured."
    static let accessibleMode = "classification mode uses catch and pass buttons with the same scoring and protection rules, without reflex dragging. question difficulty changes the learning depth; game level changes catching. resetting game level preserves lifetime progress."
}
