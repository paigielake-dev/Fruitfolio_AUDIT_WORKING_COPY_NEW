import Foundation

nonisolated enum FruitfolioSourceVerificationStatus:
    String,
    Codable,
    Sendable
{
    case founderCorpusAPA7
    case verified
    case unresolved
    case conflicted
}

nonisolated struct FruitfolioResearchNoteChunk:
    Codable,
    Hashable,
    Identifiable,
    Sendable
{
    let chunkID: String
    let researchTopicID: String
    let heading: String
    let subheading: String?
    let text: String
    let sourceIDs: [String]
    let semanticTags: [String]
    let domainTags: [String]
    var retrievalEligibility: Bool? = nil
    var sourceParagraphID: String? = nil

    var id: String {
        chunkID
    }
}

nonisolated struct FruitfolioResearchSource:
    Codable,
    Hashable,
    Identifiable,
    Sendable
{
    let sourceID: String
    let title: String
    let authors: String?
    let organization: String?
    let publicationDate: String?
    let publicationType: String?
    let canonicalURL: String?
    let doi: String?
    let apa7Reference: String?
    let verificationStatus: String
    let retrievalEligibility: Bool
    let sourceVersion: String
    let verifiedAt: String?
    let contentVersion: String

    var id: String {
        sourceID
    }

    var isApprovedForDisplay: Bool {
        retrievalEligibility
            && (
                verificationStatus
                    == FruitfolioSourceVerificationStatus
                        .founderCorpusAPA7
                        .rawValue
                || verificationStatus
                    == FruitfolioSourceVerificationStatus
                        .verified
                        .rawValue
            )
            && !(
                apa7Reference?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                ?? true
            )
    }
}

nonisolated struct FruitfolioSourceChunk:
    Codable,
    Hashable,
    Identifiable,
    Sendable
{
    let sourceChunkID: String
    let sourceID: String
    let section: String?
    let text: String
    let locationMetadata: String?
    let claimCategories: [String]

    var id: String {
        sourceChunkID
    }
}

nonisolated struct FruitfolioResearchPackage:
    Codable,
    Sendable
{
    let schemaVersion: Int
    let contentVersion: String
    let generatedFrom: String
    let generationNote: String
    let researchNoteChunks: [FruitfolioResearchNoteChunk]
    let sources: [FruitfolioResearchSource]
    let sourceChunks: [FruitfolioSourceChunk]
    var sourceParagraphs: [String: String]? = nil
}

nonisolated struct FruitfolioClaimNeed:
    Hashable,
    Codable,
    Sendable
{
    let id: String
    let text: String
}

nonisolated struct FruitfolioRankedNote:
    Hashable,
    Sendable
{
    let chunk: FruitfolioResearchNoteChunk
    let score: Double
    // Retrieval relevance only, never medical entailment or source approval.
    var matchedConceptCount: Int = 0
}

nonisolated struct FruitfolioRankedSourceChunk:
    Hashable,
    Sendable
{
    let chunk: FruitfolioSourceChunk
    let score: Double
}

nonisolated struct FruitfolioEvidenceCoverage:
    Hashable,
    Sendable
{
    let requestedClaims: [FruitfolioClaimNeed]
    let supportedClaims: [FruitfolioClaimNeed]
    let partiallySupportedClaims: [FruitfolioClaimNeed]
    let unsupportedClaims: [FruitfolioClaimNeed]

    var isSufficient: Bool {
        unsupportedClaims.isEmpty
            && partiallySupportedClaims.isEmpty
    }

    var hasAnySupport: Bool {
        !supportedClaims.isEmpty
            || !partiallySupportedClaims.isEmpty
    }
}

nonisolated struct FruitfolioClaimEvidence:
    Hashable,
    Sendable
{
    let claim: FruitfolioClaimNeed
    let noteChunkIDs: [String]
    let sourceChunkIDs: [String]
}


nonisolated enum FruitfolioQueryNormalizer {
    private static let synonymMap: [String: String] = [
        "period": "menstruation",
        "periods": "menstruation",
        "discharge": "cervical fluid",
        "mucus": "cervical fluid",
        "temp": "temperature",
        "temps": "temperature",
        "preggo": "pregnancy",
        "pcos": "polycystic ovary syndrome pcos",
        "endo": "endometriosis",
        "ttc": "trying to conceive ttc"
    ]

    static func normalize(
        _ question: String
    ) -> String {
        var value = question.folding(
            options: [
                .caseInsensitive,
                .diacriticInsensitive
            ],
            locale: .current
        )
        .lowercased()

        value = value.replacingOccurrences(
            of: "’",
            with: "'"
        )

        for (from, to) in synonymMap {
            value = value.replacingOccurrences(
                of: "\\b\(from)\\b",
                with: to,
                options: .regularExpression
            )
        }

        return value
            .replacingOccurrences(
                of: "[^a-z0-9' ]",
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    static func tokens(
        _ text: String
    ) -> Set<String> {
        let stop: Set<String> = [
            "a",
            "an",
            "and",
            "are",
            "as",
            "at",
            "be",
            "because",
            "can",
            "do",
            "does",
            "for",
            "from",
            "how",
            "i",
            "in",
            "is",
            "it",
            "me",
            "my",
            "of",
            "on",
            "or",
            "the",
            "this",
            "to",
            "what",
            "when",
            "why",
            "with",
            "you"
        ]

        return Set(
            normalize(text)
                .split(separator: " ")
                .map(String.init)
                .filter {
                    $0.count > 2
                        && !stop.contains($0)
                }
        )
    }
}

nonisolated enum FruitfolioQuestionDecomposer {
    static func claims(
        from normalizedQuestion: String
    ) -> [FruitfolioClaimNeed] {
        let pieces = normalizedQuestion
            .replacingOccurrences(
                of: "?",
                with: " and "
            )
            .components(
                separatedBy: " and "
            )
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        var seen = Set<String>()

        let unique = pieces.filter {
            seen.insert($0).inserted
        }

        return unique.enumerated().map {
            index,
            text in

            FruitfolioClaimNeed(
                id: "claim_\(index)",
                text: text
            )
        }
    }
}

nonisolated struct FruitfolioLocalResearchRetriever:
    Sendable
{
    let package: FruitfolioResearchPackage

    private struct IndexedNote: Sendable {
        let chunk: FruitfolioResearchNoteChunk
        let headingTokens: Set<String>
        let bodyTokens: Set<String>
        let lowercaseBody: String
    }
    private struct IndexedSource: Sendable {
        let chunk: FruitfolioSourceChunk
        let bodyTokens: Set<String>
    }
    private let indexedNotes: [IndexedNote]
    private let indexedSources: [IndexedSource]

    init(package: FruitfolioResearchPackage) {
        self.package = package
        indexedNotes = package.researchNoteChunks.filter { $0.retrievalEligibility != false }.map { chunk in
            IndexedNote(chunk: chunk,
                        headingTokens: FruitfolioQueryNormalizer.tokens(chunk.heading),
                        bodyTokens: chunk.semanticTags.isEmpty ? FruitfolioQueryNormalizer.tokens(chunk.text) : Set(chunk.semanticTags),
                        lowercaseBody: chunk.text.lowercased())
        }
        let approvedIDs = Set(package.sources.filter(\.isApprovedForDisplay).map(\.sourceID))
        indexedSources = package.sourceChunks.filter { approvedIDs.contains($0.sourceID) }.map { chunk in
            IndexedSource(chunk: chunk, bodyTokens: FruitfolioQueryNormalizer.tokens(chunk.text))
        }
    }

    func searchNotes(
        question: String,
        limit: Int = 8,
        personalContextTerms: Set<String> = []
    ) -> [FruitfolioRankedNote] {
        var queryTokens =
            FruitfolioQueryNormalizer.tokens(
                question
            )

        // Personal text may influence lexical relevance only through words
        // present in eligible library headings. Never concatenate narrative
        // instructions into the question or turn these words into claims.
        if !personalContextTerms.isEmpty {
            let libraryVocabulary = Set(indexedNotes.flatMap { $0.headingTokens })
            func nameForm(_ term: String) -> String {
                if term.hasSuffix("'s") { return String(term.dropLast(2)) }
                if term.hasSuffix("'") { return String(term.dropLast()) }
                return term
            }
            let reportedForms = Set(personalContextTerms.map(nameForm))
            queryTokens.formUnion(libraryVocabulary.filter { reportedForms.contains(nameForm($0)) })
        }

        guard !queryTokens.isEmpty, limit > 0 else {
            return []
        }

        let normalizedQuestion = FruitfolioQueryNormalizer.normalize(question)
        return indexedNotes.compactMap { indexed -> FruitfolioRankedNote? in
                let chunk = indexed.chunk
                let headingTokens = indexed.headingTokens
                let bodyTokens = indexed.bodyTokens

                let headingHits = Double(
                    queryTokens
                        .intersection(
                            headingTokens
                        )
                        .count
                )

                let bodyHits = Double(
                    queryTokens
                        .intersection(
                            bodyTokens
                        )
                        .count
                )

                let exactBonus = indexed.lowercaseBody.contains(normalizedQuestion) ? 3.0 : 0.0

                let score =
                    (headingHits * 3.0)
                    + bodyHits
                    + exactBonus

                guard score > 0 else {
                    return nil
                }

                return FruitfolioRankedNote(
                    chunk: chunk,
                    score: score,
                    matchedConceptCount: queryTokens.intersection(headingTokens.union(bodyTokens)).count
                )
            }
            .sorted {
                lhs,
                rhs in

                // A single repeated heading term must not crowd out a passage
                // that actually addresses multiple requested concepts.
                if lhs.matchedConceptCount != rhs.matchedConceptCount {
                    return lhs.matchedConceptCount > rhs.matchedConceptCount
                }
                if lhs.score == rhs.score {
                    return lhs.chunk.chunkID
                        < rhs.chunk.chunkID
                }

                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map {
                $0
            }
    }

    func searchSources(
        question: String,
        approvedSourceIDs: Set<String>,
        limit: Int = 6
    ) -> [FruitfolioRankedSourceChunk] {
        guard !indexedSources.isEmpty, limit > 0 else {
            return []
        }

        let queryTokens =
            FruitfolioQueryNormalizer.tokens(
                question
            )

        return indexedSources.compactMap { indexed -> FruitfolioRankedSourceChunk? in
                let chunk = indexed.chunk
                guard approvedSourceIDs.isEmpty || approvedSourceIDs.contains(chunk.sourceID) else { return nil }
                let bodyTokens = indexed.bodyTokens

                let score = Double(
                    queryTokens
                        .intersection(
                            bodyTokens
                        )
                        .count
                )

                guard score > 0 else {
                    return nil
                }

                return FruitfolioRankedSourceChunk(
                    chunk: chunk,
                    score: score
                )
            }
            .sorted {
                $0.score > $1.score
            }
            .prefix(limit)
            .map {
                $0
            }
    }

    /// Ranking uses compact slices; scientific presentation restores the complete
    /// original paragraph so a chunk boundary cannot remove a qualifier.
    func contextualizedNotes(_ ranked: [FruitfolioRankedNote]) -> [FruitfolioResearchNoteChunk] {
        var seen: Set<String> = []
        return ranked.compactMap { result in
            let chunk = result.chunk
            let key = chunk.sourceParagraphID ?? chunk.chunkID
            guard seen.insert(key).inserted else { return nil }
            let text: String
            if let paragraphID = chunk.sourceParagraphID {
                guard let original = package.sourceParagraphs?[paragraphID] else { return nil }
                text = original
            } else { text = chunk.text }
            return FruitfolioResearchNoteChunk(chunkID: chunk.chunkID, researchTopicID: chunk.researchTopicID,
                heading: chunk.heading, subheading: chunk.subheading, text: text, sourceIDs: chunk.sourceIDs,
                semanticTags: chunk.semanticTags, domainTags: chunk.domainTags,
                retrievalEligibility: chunk.retrievalEligibility, sourceParagraphID: chunk.sourceParagraphID)
        }
    }

    func coverage(
        claims: [FruitfolioClaimNeed],
        notes: [FruitfolioRankedNote],
        sourceChunks: [FruitfolioRankedSourceChunk] = []
    ) -> FruitfolioEvidenceCoverage {
        var supported: [FruitfolioClaimNeed] = []
        var partial: [FruitfolioClaimNeed] = []
        var unsupported: [FruitfolioClaimNeed] = []

        let evidenceTexts =
            notes.map {
                $0.chunk.text
            }
            + sourceChunks.map {
                $0.chunk.text
            }

        let evidenceTokens = Set(
            evidenceTexts.flatMap {
                FruitfolioQueryNormalizer.tokens(
                    $0
                )
            }
        )

        for claim in claims {
            let needed =
                FruitfolioQueryNormalizer.tokens(
                    claim.text
                )

            guard !needed.isEmpty else {
                unsupported.append(claim)
                continue
            }

            let matchingCount =
                needed
                    .intersection(
                        evidenceTokens
                    )
                    .count

            let ratio =
                Double(matchingCount)
                / Double(
                    max(
                        needed.count,
                        1
                    )
                )

            if ratio >= 0.72 {
                supported.append(claim)

            } else if ratio >= 0.34 {
                partial.append(claim)

            } else {
                unsupported.append(claim)
            }
        }

        return FruitfolioEvidenceCoverage(
            requestedClaims: claims,
            supportedClaims: supported,
            partiallySupportedClaims: partial,
            unsupportedClaims: unsupported
        )
    }
}

