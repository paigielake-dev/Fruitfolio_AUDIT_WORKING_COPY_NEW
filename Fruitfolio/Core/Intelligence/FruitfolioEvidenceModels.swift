import Foundation

nonisolated struct FruitfolioEvidencePacket:
    Sendable
{
    let normalizedQuestion: String
    let researchNoteChunks: [FruitfolioResearchNoteChunk]
    let sourceChunks: [FruitfolioSourceChunk]
    let claimEvidenceMap: [FruitfolioClaimEvidence]
    let sourceRecords: [FruitfolioResearchSource]
    let safetyClassification: Prompt34SafetyClassification
    let permittedContext: FruitfolioBoundedTrackerContext?
    let contentVersion: String
    var userProvidedContext: FruitfolioAskUserContext? = nil
    var conversationalPresentation: FruitfolioConversationalPresentation = .neutral
}

/// The local model never gets to hand arbitrary prose directly to the UI.
/// It must return a small evidence-linked draft that deterministic code can
/// validate before rendering. This keeps the model downstream of Research.
nonisolated struct FruitfolioGeneratedClaim:
    Codable,
    Hashable,
    Sendable
{
    let text: String
    let evidenceIDs: [String]
}

nonisolated struct FruitfolioGeneratedDraft:
    Codable,
    Hashable,
    Sendable
{
    let bridge: String?
    let claims: [FruitfolioGeneratedClaim]
    let limitation: String?
}

nonisolated enum FruitfolioResearchProgress:
    Sendable
{
    case lookingThroughLibrary
    case searchingApprovedSources
    case synthesizing
    case validating
}

nonisolated struct FruitfolioRetrievalDiagnostics:
    Sendable
{
    let noteCount: Int
    let sourceChunkCount: Int
    let didExpandSources: Bool
    let coverage: FruitfolioEvidenceCoverage
}

nonisolated struct FruitfolioBoundedTrackerContext:
    Codable,
    Hashable,
    Sendable
{
    let predictionConfidence: String?
    let reasonCode: String?
    let trackingGoal: String?
    let reproductiveStage: String?
    let cycleHealthContext: String?

    static let none = FruitfolioBoundedTrackerContext(
        predictionConfidence: nil,
        reasonCode: nil,
        trackingGoal: nil,
        reproductiveStage: nil,
        cycleHealthContext: nil
    )
}


nonisolated enum FruitfolioAnswerPresentationSanitizer {
    /// Research-note compilation occasionally removes a space after punctuation.
    /// Repair only obvious prose joins; do not rewrite scientific content, URLs,
    /// abbreviations such as e.g., or numeric notation.
    static func clean(_ raw: String) -> String {
        var value = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let patterns: [(String, String)] = [
            (#"(?<=[A-Za-z]{3})\.(?=[A-Za-z])"#, ". "),
            (#",(?=[A-Za-z])"#, ", "),
            (#";(?=[A-Za-z])"#, "; "),
            (#":(?=[A-Za-z])"#, ": ")
        ]

        for (pattern, replacement) in patterns {
            value = value.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }

        value = value.replacingOccurrences(
            of: #"[ \t]{2,}"#,
            with: " ",
            options: .regularExpression
        )

        return value
    }
}

// MARK: - Deterministic local retrieval

