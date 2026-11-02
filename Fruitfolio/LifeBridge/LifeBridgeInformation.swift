import Foundation

/// Organization information is separate from approved medical evidence. A
/// directory link must never grant research eligibility to website marketing.
enum LifeBridgeInformation {
    static let contentStatus = "awaiting_verified_lifebridge_content"
    static let unavailable = "details not available in the approved library yet"
    static let version = "lifebridge-directory-2026-11-01-v1"

    enum Destination: String, CaseIterable, Identifiable {
        case official, founder, instagram
        var id: String { rawValue }
        var title: String {
            switch self {
            case .official: "LifeBridge official website"
            case .founder: "FruitsofLife.xo founder website"
            case .instagram: "FruitsofLife.xo Instagram"
            }
        }
        var url: URL {
            // Exact founder-approved destinations, without referral identifiers,
            // user data, query interpolation, tracking parameters, or forms.
            switch self {
            case .official: URL(string: "https://lifebridgesurrogacy.com/")!
            case .founder: URL(string: "https://fruitsoflifexo.carrd.co/")!
            case .instagram: URL(string: "https://www.instagram.com/fruitsoflife.xo/")!
            }
        }
    }

    enum ContentSlot: String, CaseIterable, Identifiable {
        case overview, services, audience, eligibilityAndProcess, contact, founderRelationship
        var id: String { rawValue }
        var title: String {
            switch self {
            case .overview: "what is LifeBridge?"
            case .services: "services and resources"
            case .audience: "who may wish to learn more"
            case .eligibilityAndProcess: "current eligibility and process"
            case .contact: "official contact and application information"
            case .founderRelationship: "founder, referral, and commission information"
            }
        }
    }

    /// Discovery only. This does not classify medical risk, generate a claim,
    /// transmit a question, or change the grounded research pipeline.
    static func isDiscoveryQuery(_ query: String) -> Bool {
        let normalized = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "-", with: " ")
        return normalized.contains("lifebridge") || normalized.contains("life bridge") ||
            ["surrogacy support", "surrogate support", "surrogacy agency"].contains(where: normalized.contains)
    }
}
