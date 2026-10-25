import Combine
import Foundation

/// Single persistent pseudonymous username authority shared by Account and Fruit Basket.
/// This deliberately contains no health/cycle state and never derives a public name from email.
@MainActor
final class FruitfolioUsernameStore: ObservableObject {
    static let shared = FruitfolioUsernameStore()

    @Published private(set) var username: String

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "fruitfolio.identity.publicUsername.v1") {
        self.defaults = defaults
        self.key = key
        if let saved = defaults.string(forKey: key) {
            username = Prompt28LeaderboardUsernamePolicy.sanitized(saved)
        } else {
            let legacy = defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1")
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                .flatMap { $0["leaderboardPseudonym"] as? String } ?? ""
            username = Prompt28LeaderboardUsernamePolicy.sanitized(legacy)
            if !username.isEmpty { defaults.set(username, forKey: key) }
        }
    }

    @discardableResult
    func setUsername(_ raw: String) -> String? {
        let cleaned = Prompt28LeaderboardUsernamePolicy.sanitized(raw)
        if let message = Prompt28LeaderboardUsernamePolicy.validationMessage(for: cleaned) {
            return message
        }
        username = cleaned
        defaults.set(cleaned, forKey: key)
        return nil
    }

    func clear() {
        username = ""
        defaults.removeObject(forKey: key)
    }
}
