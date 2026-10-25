import Foundation
import SwiftUI

// MARK: - Prompt 32 — Notifications

enum Prompt32NotificationAuthorizationState:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case notDetermined
    case denied
    case authorized
    case provisional
}

struct Prompt32NotificationPreference:
    Codable,
    Hashable,
    Sendable
{
    var authorizationState:
        Prompt32NotificationAuthorizationState

    var cycleRemindersEnabled: Bool
    var symptomRemindersEnabled: Bool
    var educationalRemindersEnabled: Bool

    init(
        authorizationState:
            Prompt32NotificationAuthorizationState
            = .notDetermined,
        cycleRemindersEnabled: Bool = false,
        symptomRemindersEnabled: Bool = false,
        educationalRemindersEnabled: Bool = false
    ) {
        self.authorizationState =
            authorizationState

        self.cycleRemindersEnabled =
            cycleRemindersEnabled

        self.symptomRemindersEnabled =
            symptomRemindersEnabled

        self.educationalRemindersEnabled =
            educationalRemindersEnabled
    }
}

// MARK: - Prompt 33 — User-facing errors

enum Prompt33UserFacingErrorTone:
    String,
    Codable,
    Sendable
{
    case neutral
    case sensitive
    case blocking
}

struct Prompt33UserFacingError:
    Identifiable,
    Codable,
    Hashable,
    Sendable
{
    let id: UUID
    let title: String
    let message: String
    let tone: Prompt33UserFacingErrorTone

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        tone: Prompt33UserFacingErrorTone = .neutral
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.tone = tone
    }
}

enum Prompt33ErrorPresenter {
    static func userFacingError(
        title: String = "something went wrong",
        message: String,
        sensitive: Bool = false
    ) -> Prompt33UserFacingError {
        Prompt33UserFacingError(
            title: title,
            message: message,
            tone: sensitive
                ? .sensitive
                : .neutral
        )
    }
}

// MARK: - Prompt 34 — Local serious-health safety router

enum Prompt34SafetyLevel:
    String,
    Codable,
    Comparable,
    Sendable
{
    case normal
    case sensitive
    case urgent

    private var rank: Int {
        switch self {
        case .normal:
            return 0
        case .sensitive:
            return 1
        case .urgent:
            return 2
        }
    }

    static func < (
        lhs: Prompt34SafetyLevel,
        rhs: Prompt34SafetyLevel
    ) -> Bool {
        lhs.rank < rhs.rank
    }
}

struct Prompt34SafetyClassification:
    Codable,
    Hashable,
    Sendable
{
    let level: Prompt34SafetyLevel
    let matchedPatterns: [String]

    var requiresSeriousTone: Bool {
        level != .normal
    }

    var requiresUrgentGuidance: Bool {
        level == .urgent
    }
}

enum Prompt34LocalSafetyRouter {
    private static let urgentPatterns: [String] = [
        "severe bleeding",
        "heavy bleeding",
        "bleeding heavily",
        "soaking through",
        "soaking a pad",
        "soaking pads",
        "passing out",
        "passed out",
        "fainting",
        "fainted",
        "syncope",
        "chest pain",
        "can't breathe",
        "cannot breathe",
        "difficulty breathing",
        "trouble breathing",
        "shortness of breath",
        "suicide",
        "suicidal",
        "kill myself",
        "hurt myself",
        "self harm",
        "self-harm"
    ]

    private static let sensitivePatterns: [String] = [
        "miscarriage",
        "pregnancy loss",
        "stillbirth",
        "abortion",
        "infertility",
        "sexual assault",
        "rape",
        "abuse",
        "domestic violence",
        "ectopic",
        "cancer",
        "tumor"
    ]

    static func classify(
        _ text: String
    ) -> Prompt34SafetyClassification {
        let normalized =
            text.folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive
                ],
                locale: .current
            )
            .lowercased()

        let urgentMatches =
            urgentPatterns.filter {
                normalized.contains($0)
            }

        if !urgentMatches.isEmpty {
            return Prompt34SafetyClassification(
                level: .urgent,
                matchedPatterns: urgentMatches
            )
        }

        let sensitiveMatches =
            sensitivePatterns.filter {
                normalized.contains($0)
            }

        if !sensitiveMatches.isEmpty {
            return Prompt34SafetyClassification(
                level: .sensitive,
                matchedPatterns: sensitiveMatches
            )
        }

        return Prompt34SafetyClassification(
            level: .normal,
            matchedPatterns: []
        )
    }

    static func urgentResponseText() -> String {
        """
        this may need urgent medical attention. Fruitfolio can give educational context, but it cannot assess an emergency. if you have severe symptoms, are in immediate danger, or think something is seriously wrong, seek emergency medical care now.
        """
    }
}

// MARK: - Prompt 35 — Accessibility

enum Prompt35AccessibilityPolicy {
    static let minimumInteractiveDimension:
        CGFloat = 44

    static let supportsDynamicType = true
    static let respectsReduceMotion = true
    static let avoidsColorOnlyMeaning = true
}

// MARK: - Prompt 36 — Empty states

enum Prompt36EmptyState:
    String,
    CaseIterable,
    Codable,
    Sendable
{
    case savedLibrary
    case guideBuilder
    case cycleNotes
    case askHistory
    case searchResults

    var message: String {
        switch self {
        case .savedLibrary:
            return "your encyclopedia is ready for its first saved page ♡"
        case .guideBuilder:
            return "your guide is ready for its first page ♡"
        case .cycleNotes:
            return "nothing logged here yet ♡"
        case .askHistory:
            return "ask what you need whenever you're ready ♡"
        case .searchResults:
            return "nothing in the library matched that search."
        }
    }
}

// MARK: - Prompt 37 — Motion semantics

enum Prompt37MotionDuration {
    static let microInteraction: Double = 0.18
    static let popupEntrance: Double = 0.26
    static let pageTurn: Double = 0.24
    static let accordion: Double = 0.26
    static let bookTransition: Double = 0.48
}

enum Prompt37MotionPolicy {
    static func duration(
        normal: Double,
        reduceMotion: Bool
    ) -> Double {
        reduceMotion
            ? min(normal, 0.14)
            : normal
    }
}

// MARK: - Prompt 38 — Graph animation

enum Prompt38GraphAnimationPolicy {
    static let normalDuration: Double = 0.42
    static let reducedMotionDuration: Double = 0.12

    static func duration(
        reduceMotion: Bool
    ) -> Double {
        reduceMotion
            ? reducedMotionDuration
            : normalDuration
    }
}

// MARK: - Prompt 39 — Page-turn semantics

enum Prompt39PageTurnDirection:
    String,
    Codable,
    Sendable
{
    case forward
    case backward
}

enum Prompt39PageTurnPolicy {
    static func soundID(
        for direction:
            Prompt39PageTurnDirection
    ) -> String {
        switch direction {
        case .forward,
             .backward:
            return "audio_page_turn"
        }
    }
}

// Prompt 40 intentionally skipped.

// MARK: - Prompt 41 — Truth domains

enum Prompt41TruthDomain:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case recorded
    case calculated
    case estimated
    case predicted
    case educational
    case userReported

    var displayName: String {
        switch self {
        case .recorded:
            return "recorded"
        case .calculated:
            return "calculated"
        case .estimated:
            return "estimated"
        case .predicted:
            return "predicted"
        case .educational:
            return "educational"
        case .userReported:
            return "user-reported"
        }
    }
}

// MARK: - Prompt 42 — Offline capability boundaries

enum Prompt42OfflineCapability:
    String,
    CaseIterable,
    Codable,
    Sendable
{
    case savedEncyclopedia
    case savedGuides
    case cycleLogging
    case localResearchSearch
    case localAIWhenSupported
    case fruitBasket
    case settings
}

enum Prompt42OfflinePolicy {
    static let requiresCloudForCoreExperience = false
    static let permitsPaidFallback = false
    static let permitsRemoteLLMFallback = false
}

// MARK: - Prompt 43 — Privacy-safe analytics

struct Prompt43AnalyticsEvent:
    Codable,
    Hashable,
    Sendable
{
    let name: String
    let timestamp: Date
    let metadata: [String: String]
}

actor Prompt43PrivacySafeAnalytics {
    static let shared =
        Prompt43PrivacySafeAnalytics()

    private(set) var events:
        [Prompt43AnalyticsEvent]
        = []

    func record(
        name: String,
        metadata: [String: String] = [:]
    ) {
        events.append(
            Prompt43AnalyticsEvent(
                name: name,
                timestamp: Date(),
                metadata: metadata
            )
        )
    }

    func recordRawHealthQuestion(
        _ rawQuestion: String
    ) {
        // Deliberate privacy sink:
        // raw health questions are never persisted
        // to analytics.
    }

    func reset() {
        events.removeAll()
    }
}

// MARK: - Prompt 44 — Hormone asset audit

enum Prompt44HormoneAssetAudit {
    static let requiredHormoneAssets:
        Set<String>
        = [
            "hormone_estrogen",
            "hormone_progesterone",
            "hormone_testosterone"
        ]

    static func missingAssets(
        from registeredAssets: Set<String>
    ) -> Set<String> {
        requiredHormoneAssets
            .subtracting(
                registeredAssets
            )
    }
}

// MARK: - Prompt 45 — Educational media policy

enum Prompt45EducationalMediaPolicy {
    static let requiresSourceContext = true
    static let permitsDiagnosticImageryClaims = false
    static let permitsMeasuredHormoneInference = false
    static let predictionIsConfirmation = false
}

// MARK: - Prompt 46 — Founder development controls

enum Prompt46FounderDevelopmentPolicy {
    static var founderBypassEnabled:
        Bool
    {
        #if DEBUG
        return UserDefaults.standard.bool(
            forKey:
                "fruitfolio.debug.founderBypass"
        )
        #else
        return false
        #endif
    }
}

// MARK: - Prompt 47 — Ask presentation

enum Prompt47AskPresentationCopy {
    static let lookingThroughLibrary =
        "looking through the library . . ."

    static let searchingSources =
        "searching sources . . ."

    static let puttingItTogether =
        "putting it together . . ."

    static let educationalDisclaimer =
        "Fruitfolio is educational and does not diagnose or replace medical care."
}

// MARK: - Prompt 48 — Semantic styling

enum Prompt48SemanticStyle:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case anchor
    case spokenStress
    case symptom
    case practicalClue
    case actionable
    case critical
}

enum Prompt48SemanticStylePolicy {
    static func style(
        for semanticRole: String
    ) -> Prompt48SemanticStyle? {
        switch semanticRole
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
        {
        case "condition",
             "hormone",
             "mechanism",
             "nutrient",
             "number",
             "food":
            return .anchor

        case "spoken stress":
            return .spokenStress

        case "symptom":
            return .symptom

        case "practical clue":
            return .practicalClue

        case "actionable":
            return .actionable

        case "not",
             "never",
             "every":
            return .critical

        default:
            return nil
        }
    }

    static var symptomsAreUnderlined:
        Bool
    {
        true
    }
}

// MARK: - Prompt 49 — Localization boundary

enum Prompt49LocalizationPolicy {
    static let canonicalLanguageCode =
        "en"

    static func mayTranslateScientificEvidence(
        hasApprovedLocalizedEvidence: Bool
    ) -> Bool {
        hasApprovedLocalizedEvidence
    }
}

// MARK: - Prompt 50 — Cycle information density

enum Prompt50CycleDensity:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case simple
    case standard
    case detailed
}

struct Prompt50CyclePresentationPreference:
    Codable,
    Sendable
{
    var density: Prompt50CycleDensity

    let changesPredictionSemantics: Bool

    init(
        density:
            Prompt50CycleDensity
            = .standard
    ) {
        self.density = density
        self.changesPredictionSemantics = false
    }

    private enum CodingKeys:
        String,
        CodingKey
    {
        case density
    }

    init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy:
                    CodingKeys.self
            )

        density =
            try container.decodeIfPresent(
                Prompt50CycleDensity.self,
                forKey: .density
            )
            ?? .standard

        changesPredictionSemantics = false
    }

    func encode(
        to encoder: Encoder
    ) throws {
        var container =
            encoder.container(
                keyedBy:
                    CodingKeys.self
            )

        try container.encode(
            density,
            forKey: .density
        )
    }
}

// MARK: - Prompt 51 — Decorative string / Unicode integrity

enum Prompt51UnicodeIntegrity {
    static let canonicalSequences:
        [String]
        = [
            "﹒ ⋆ ⋆ ₊⊹ ꩜ 𓂃",
            "₊˚✩",
            "☆ ‧ ₊ ˚",
            "♡"
        ]

    static func isRoundTripStable(
        _ string: String
    ) -> Bool {
        guard
            let data =
                string.data(
                    using: .utf8
                ),
            let restored =
                String(
                    data: data,
                    encoding: .utf8
                )
        else {
            return false
        }

        return restored == string
    }
}

// MARK: - Prompt 52 / 53 — Production gates

struct Prompt52ProductionGateResult:
    Codable,
    Sendable
{
    let name: String
    let passed: Bool
    let note: String
}

enum Prompt52ProductionGate {
    static func evaluate(
        name: String,
        condition: Bool,
        note: String
    ) -> Prompt52ProductionGateResult {
        Prompt52ProductionGateResult(
            name: name,
            passed: condition,
            note: note
        )
    }
}

enum Prompt53ScreenInventory {
    static let requiredRoutes:
        Set<String>
        = [
            "intro",
            "hub",
            "ask",
            "library",
            "guideBuilder",
            "cycle",
            "fruitBasket",
            "faq",
            "contact",
            "settings",
            "account",
            "privacy",
            "purchase"
        ]
}

// MARK: - Prompt 54 — Canonical voice boundary

enum Prompt54CanonicalVoicePolicy {
    static let maximumKaomojiPerAnswer = 4
    static let preferredKaomojiRange = 0...2
    static let seriousContentUsesKaomoji = false
    static let symptomsMustBeUnderlined = true
    static let foodNamesAreBolded = true
    static let evidenceMustFollowHumanBridge = true
    static let allowsInfluencerTherapyCliches = false
}

// MARK: - Prompt 55 — Ask highlight and verified citation policy

struct Prompt55SourceVerificationChecklist:
    Codable,
    Sendable
{
    let sourceIdentityResolved: Bool
    let supportingRelationshipConfirmed: Bool
    let metadataVerificationStatus: Bool
    let sourceTypeResolved: Bool
    let apa7CitationConstructed: Bool
    let apa7CitationValidated: Bool
    let unresolvedMetadataFlagged: Bool
    let conflictsRecorded: Bool

    var approvedForDisplay: Bool {
        sourceIdentityResolved
            && supportingRelationshipConfirmed
            && metadataVerificationStatus
            && sourceTypeResolved
            && apa7CitationConstructed
            && apa7CitationValidated
    }
}

enum Prompt55AskSelectionStyle {
    static let textHex =
        "#800000"

    static let selectedHighlightHex =
        "#F4C7C7"

    static let sourcesHeading =
        "sources ˚ ☆ ‧ ₊"
}
