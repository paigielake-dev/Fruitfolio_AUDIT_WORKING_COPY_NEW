import Foundation

/// Prompt 03 centralized semantic route vocabulary.
/// Keep these top-level identities stable; future nested destinations should add typed context.
enum FruitfolioRoute: String, Hashable, Codable, Sendable, CaseIterable {
    case intro
    case hub
    case ask
    case library
    case guideBuilder
    case cycle
    case fruitBasket
    case faq
    case contact
    case settings
    case account
    case privacy
    case purchase

    static let hubPrimaryDestinations: [FruitfolioRoute] = [
        .ask, .library, .guideBuilder, .cycle, .fruitBasket, .faq
    ]

    static let hubUtilityDestinations: [FruitfolioRoute] = [
        .contact, .settings, .account
    ]

    static var normalHubDestinations: [FruitfolioRoute] {
        hubPrimaryDestinations + hubUtilityDestinations
    }

    var title: String {
        switch self {
        case .intro: return "Intro"
        case .hub: return "Fruitfolio"
        case .ask: return "Ask the Encyclopedia"
        case .library: return "My Encyclopedias"
        case .guideBuilder: return "Build Your Own Guide"
        case .cycle: return "Cycle Tracker"
        case .fruitBasket: return "Fruit Basket"
        case .faq: return "FAQ"
        case .contact: return "Contact"
        case .settings: return "Settings"
        case .account: return "Account"
        case .privacy: return "Privacy"
        case .purchase: return "Purchase"
        }
    }

    var debugName: String { rawValue }
}
