import Foundation

/// One app-wide resolver for user-facing strings that must be produced outside
/// SwiftUI's Text/LocalizedStringKey pipeline (errors, deterministic fallbacks,
/// generated-status text, accessibility values, etc.).
enum FruitfolioLocalization {
    static func localized(
        _ key: String,
        language: FruitfolioLanguage = FruitfolioLanguagePreferences.current,
        fallback: String? = nil
    ) -> String {
        localized(key, locale: Locale(identifier: language.localeIdentifier), fallback: fallback)
    }

    struct Resolution: Equatable, Sendable {
        let text: String
        let languageIdentifier: String
        let usedSourceFallback: Bool
    }

    /// Resolve the explicitly selected locale, not the system's preferred app
    /// language. Missing UI translations retain their original source wording.
    static func localized(_ key: String, locale: Locale, fallback: String? = nil) -> String {
        resolve(key, locale: locale, fallback: fallback).text
    }

    static func resolve(_ key: String, locale: Locale, fallback: String? = nil,
                        bundle: Bundle = .main) -> Resolution {
        // A real translation can equal its key (for example "no"). An explicit
        // missing sentinel distinguishes that case from an absent resource.
        let missing = "\u{FDD0}FRUITFOLIO_MISSING_TRANSLATION\u{FDD1}"
        func lookup(_ candidate: String) -> String? {
            guard let directory = bundle.url(forResource: candidate, withExtension: "lproj"),
                  let localizedBundle = Bundle(url: directory) else { return nil }
            let value = localizedBundle.localizedString(forKey: key, value: missing, table: "Localizable")
            guard value != missing, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return value
        }
        for candidate in localeCandidates(for: locale) {
            if let value = lookup(candidate) {
                return .init(text: value, languageIdentifier: candidate, usedSourceFallback: false)
            }
        }
        if let fallback { return .init(text: fallback, languageIdentifier: "en", usedSourceFallback: true) }
        if let source = lookup("en") {
            return .init(text: source, languageIdentifier: "en", usedSourceFallback: true)
        }
        return .init(text: key, languageIdentifier: "en", usedSourceFallback: true)
    }

    static func localeCandidates(for locale: Locale) -> [String] {
        let exact = locale.identifier.replacingOccurrences(of: "_", with: "-")
        let language = locale.language.languageCode?.identifier ?? "en"
        let explicitScript = exact.split(separator: "-").dropFirst().contains {
            $0.count == 4 && $0.allSatisfy(\.isLetter)
        }
        var script = locale.language.script?.identifier
        if language == "zh", script == nil {
            switch locale.region?.identifier {
            case "TW", "HK", "MO": script = "Hant"
            case "CN", "SG": script = "Hans"
            default: break
            }
        }
        var candidates = [exact]
        if let script { candidates.append(language + "-" + script) }
        // A generic Chinese bundle may contain the opposite script. Never
        // silently substitute it for an explicit Hans/Hant choice. Apply the
        // same rule to other explicitly requested script variants.
        if !explicitScript && !(language == "zh" && script != nil) { candidates.append(language) }
        var seen: Set<String> = []
        return candidates.filter { seen.insert($0).inserted }
    }
}

/// Actual delivery readiness, separate from whether a tokenizer tag exists.
/// Model presence or preservation fixtures do not approve clinical display.
enum FruitfolioLanguageDisplayReadiness: Equatable {
    case originalEnglish
    case requiresVerification
    case unsupportedOfficialTarget
}

extension FruitfolioLocalization {
    static func displayReadiness(for language: FruitfolioLanguage) -> FruitfolioLanguageDisplayReadiness {
        if language == .english { return .originalEnglish }
        switch language {
        case .tokPisin, .tahitian, .cookIslandsMaori, .niuean, .kiribati:
            return .unsupportedOfficialTarget
        default:
            return .requiresVerification
        }
    }

    /// UI resource availability is independent of future answer translation.
    /// Missing labels are disclosed rather than silently implying full coverage.
    static func interfaceAvailabilityNotice(for language: FruitfolioLanguage) -> String? {
        guard language != .english else { return nil }
        let interface = "interface translations are incomplete. labels without an available translation keep their original English wording."
        return [interface, untranslatedContentNotice(for: language)].compactMap { $0 }.joined(separator: "\n\n")
    }

    static func untranslatedContentNotice(for language: FruitfolioLanguage) -> String? {
        switch displayReadiness(for: language) {
        case .originalEnglish: return nil
        case .unsupportedOfficialTarget:
            return "offline generated-answer translation isn’t available for \(language.nativeDisplayName). original research and generated answers remain in English; your language selection is saved."
        case .requiresVerification:
            return "translation for \(language.nativeDisplayName) hasn’t been verified for safe scientific display yet. original research and generated answers remain in English; your language selection is saved."
        }
    }
}
