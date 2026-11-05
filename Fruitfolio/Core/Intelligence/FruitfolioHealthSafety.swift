import Foundation

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

