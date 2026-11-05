import Foundation

/// Local validation never reserves a global identity and never reads health data.
nonisolated enum FruitfolioPseudonymPolicy {
    static func validationMessage(for raw: String, confirmedNonIdentifying: Bool, identifyingText: [String] = []) -> String? {
        if let invalid = Prompt28LeaderboardUsernamePolicy.validationMessage(for: raw) { return invalid }
        guard confirmedNonIdentifying else { return "confirm that this username is not your real or legal name and contains no identifying details." }
        let candidate = normalized(raw)
        let privateFragments = identifyingText.flatMap { value -> [String] in
            let local = value.split(separator: "@", maxSplits: 1).first.map(String.init) ?? value
            let words = local.components(separatedBy: CharacterSet.letters.inverted)
            return ([normalized(local)] + words.map(normalized)).filter { $0.count >= 3 }
        }
        guard !privateFragments.contains(where: candidate.contains) else {
            return "choose a pseudonym that does not include your name or email identity."
        }
        return nil
    }
    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .unicodeScalars.filter { CharacterSet.letters.contains($0) }.map(String.init).joined()
    }
}
