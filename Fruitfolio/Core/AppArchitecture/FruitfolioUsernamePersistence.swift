import Foundation

nonisolated final class FruitfolioUsernamePersistence {
    struct Snapshot: Equatable {
        let username: String
        let confirmedNonIdentifying: Bool
    }
    private let defaults: UserDefaults
    private let key: String
    init(defaults: UserDefaults, key: String) { self.defaults = defaults; self.key = key }

    func load() -> Snapshot {
        let legacy = defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1")
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            .flatMap { $0["leaderboardPseudonym"] as? String }
        let candidate = defaults.string(forKey: key) ?? (defaults.bool(forKey: key + ".initialized") ? "" : (legacy ?? ""))
        // Preserve invalid stored data without silently rewriting it into a
        // different, accepted public identity.
        let username = Prompt28LeaderboardUsernamePolicy.isValid(candidate) ? candidate : ""
        return Snapshot(username: username, confirmedNonIdentifying: !username.isEmpty && defaults.string(forKey: key + ".nonIdentifyingConfirmation") == username)
    }

    func save(_ raw: String, confirmedNonIdentifying: Bool, identifyingText: [String]) -> String? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message = FruitfolioPseudonymPolicy.validationMessage(for: cleaned,
            confirmedNonIdentifying: confirmedNonIdentifying, identifyingText: identifyingText) { return message }
        defaults.set(true, forKey: key + ".initialized")
        defaults.set(cleaned, forKey: key)
        defaults.set(cleaned, forKey: key + ".nonIdentifyingConfirmation")
        return nil
    }
    func clear() {
        defaults.set(true, forKey: key + ".initialized")
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: key + ".nonIdentifyingConfirmation")
    }
}
