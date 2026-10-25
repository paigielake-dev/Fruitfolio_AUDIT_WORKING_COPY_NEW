import Foundation
import GameKit

// The registry must ultimately be backed by a trusted server with authenticated,
// atomic reservations. This development implementation never claims a global name.
enum Prompt28UsernameKey {
    static func normalized(_ username: String) -> String {
        username.precomposedStringWithCanonicalMapping.lowercased(with: Locale(identifier: "en_US_POSIX"))
    }
}

enum Prompt28RegistrationResult: Equatable {
    case reserved
    case taken
    case unavailable
}

protocol Prompt28UsernameRegistry {
    func reserve(username: String, ownerID: String) async -> Prompt28RegistrationResult
    func release(username: String, ownerID: String) async -> Bool
}

struct Prompt28UnavailableUsernameRegistry: Prompt28UsernameRegistry {
    func reserve(username: String, ownerID: String) async -> Prompt28RegistrationResult { .unavailable }
    func release(username: String, ownerID: String) async -> Bool { false }
}

// Deterministic test double only: not shared across devices or suitable for production.
actor Prompt28InMemoryUsernameRegistry: Prompt28UsernameRegistry {
    private var owners: [String: String] = [:]

    func reserve(username: String, ownerID: String) async -> Prompt28RegistrationResult {
        let key = Prompt28UsernameKey.normalized(username)
        guard Prompt28LeaderboardUsernamePolicy.isValid(username), !ownerID.isEmpty else { return .unavailable }
        if let existing = owners[key] { return existing == ownerID ? .reserved : .taken }
        owners[key] = ownerID
        return .reserved
    }

    func release(username: String, ownerID: String) async -> Bool {
        let key = Prompt28UsernameKey.normalized(username)
        guard owners[key] == ownerID else { return false }
        owners.removeValue(forKey: key)
        return true
    }
}

enum Prompt28GameCenterBoard: String, CaseIterable {
    // Create matching leaderboard IDs in App Store Connect before enabling live sync.
    case fruit = "fruitfolio.fruitbasket.fruit"
    case stars = "fruitfolio.fruitbasket.stars"
    case baskets = "fruitfolio.fruitbasket.baskets"
    case level = "fruitfolio.fruitbasket.level"

    func score(from totals: Prompt28LeaderboardTotals) -> Int {
        switch self {
        case .fruit: return totals.fruitCollected
        case .stars: return totals.starsEarned
        case .baskets: return totals.basketReveals
        case .level: return totals.highestLevel
        }
    }
}

// Deliberately no public score submission or authentication prompt until a
// secure registry, consent lifecycle, and Apple capabilities are configured.
struct Prompt28GameCenterConfiguration {
    static let isLiveSyncEnabled = false
    static let boardIDs = Prompt28GameCenterBoard.allCases.map(\.rawValue)
}
