import Foundation

nonisolated enum FruitfolioHormoneLibrarySection: String, CaseIterable, Identifiable, Sendable {
    case functions, reproductiveRelevance, measurementLimitations, testingContext, medicalGuidance
    var id: String { rawValue }
    var title: String {
        switch self {
        case .functions: return "biological functions"
        case .reproductiveRelevance: return "reproductive relevance"
        case .measurementLimitations: return "measurement limitations"
        case .testingContext: return "testing context"
        case .medicalGuidance: return "medical guidance and interpretation"
        }
    }
    var retrievalTerms: String {
        switch self {
        case .functions: return "function role production secretion regulation"
        case .reproductiveRelevance: return "reproductive ovulation cycle follicle fertility ovary sperm"
        case .measurementLimitations: return "limitations measurement single fluctuation variability assay snapshot"
        case .testingContext: return "testing test sample blood laboratory timing reference"
        case .medicalGuidance: return "clinician doctor evaluate consult interpret diagnosis"
        }
    }
}

nonisolated struct FruitfolioHormoneLibraryExcerpt: Identifiable, Sendable {
    let section: FruitfolioHormoneLibrarySection
    let noteID: String
    let heading: String
    let originalText: String
    let presentation: String
    let sources: [AskSourceRecord]
    var id: String { section.rawValue + ":" + noteID }
}
nonisolated struct FruitfolioHormoneLibraryArticle: Sendable {
    let hormone: FruitfolioMeasuredHormone
    let excerpts: [FruitfolioHormoneLibraryExcerpt]
    let contentVersion: String
}

nonisolated enum FruitfolioHormoneResearchMatch {
    static func contains(_ hormone: FruitfolioMeasuredHormone, in text: String) -> Bool {
        makeMatcher(for: hormone)(text)
    }

    /// Compile once for an exhaustive article lookup, retaining the exact
    /// existing Unicode/name boundary policy for every source paragraph.
    static func makeMatcher(for hormone: FruitfolioMeasuredHormone) -> (String) -> Bool {
        // Typography in an original medical name may use a Unicode hyphen or
        // nonbreaking space. This lookup never rewrites the quoted evidence.
        let compoundSeparator = #"[\p{Pd}\p{Zs}\t\r\n]+"#
        let alternatives: String
        switch hormone {
        case .estradiol: alternatives = "estradiol|estrogen|oestrogen|e2"
        case .progesterone: alternatives = "progesterone"
        case .lh: alternatives = "luteinizing|luteinising|lh"
        case .fsh: alternatives = "follicle" + compoundSeparator + "stimulating|fsh"
        case .testosterone: alternatives = "testosterone"
        case .prolactin: alternatives = "prolactin"
        case .amh: alternatives = "anti" + compoundSeparator + "mullerian|amh"
        case .other: return { _ in false }
        }
        let pattern = "(?<![\\p{L}\\p{N}])(?:" + alternatives + ")(?![\\p{L}\\p{N}])"
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return { _ in false } }
        return { text in
            let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            return expression.firstMatch(in: folded, range: NSRange(location: 0, length: folded.utf16.count)) != nil
        }
    }
}

/// Static educational retrieval only: no measurement, profile or question input,
/// no network, no model-memory fallback, no inferred normal/abnormal result.
actor FruitfolioHormoneLibraryProvider {
    static let shared = FruitfolioHormoneLibraryProvider()
    private let packageStore: FruitfolioResearchPackageStore
    private var cache: [FruitfolioMeasuredHormone: FruitfolioHormoneLibraryArticle] = [:]
    init(packageStore: FruitfolioResearchPackageStore = .shared) { self.packageStore = packageStore }
    enum Failure: Error { case unspecifiedHormone, invalidPackage }

    func article(for hormone: FruitfolioMeasuredHormone) async throws -> FruitfolioHormoneLibraryArticle {
        guard hormone != .other else { throw Failure.unspecifiedHormone }
        try Task.checkCancellation()
        if let article = cache[hormone] { return article }
        let retriever = try await packageStore.retriever()
        let package = retriever.package
        let aliases: String
        switch hormone {
        case .estradiol: aliases = "estradiol estrogen"
        case .progesterone: aliases = "progesterone"
        case .lh: aliases = "luteinizing LH"
        case .fsh: aliases = "follicle-stimulating FSH"
        case .testosterone: aliases = "testosterone"
        case .prolactin: aliases = "prolactin"
        case .amh: aliases = "anti-Müllerian AMH"
        case .other: throw Failure.unspecifiedHormone
        }
        let approvedRecords = package.sources.filter(\.isApprovedForDisplay)
        guard Set(approvedRecords.map(\.sourceID)).count == approvedRecords.count else { throw Failure.invalidPackage }
        let approved = Dictionary(uniqueKeysWithValues: approvedRecords.map { ($0.sourceID, $0) })
        // Scope the complete eligible, original paragraphs to the selected
        // hormone BEFORE ranking. A global top24 can consist entirely of other
        // topics and falsely hide suitable approved material below that cutoff.
        // Keep the retriever's contextualization and exact source-approval gate.
        let eligible = package.researchNoteChunks.filter { $0.retrievalEligibility != false }
            .sorted { $0.chunkID < $1.chunkID }
            .map { FruitfolioRankedNote(chunk: $0, score: 0) }
        let matchesHormone = FruitfolioHormoneResearchMatch.makeMatcher(for: hormone)
        let candidates = retriever.contextualizedNotes(eligible).filter { note in
            matchesHormone(note.text)
                && !note.sourceIDs.isEmpty
                && note.sourceIDs.allSatisfy { approved[$0] != nil }
        }.map { note in
            (note: note, bodyTokens: FruitfolioQueryNormalizer.tokens(note.text),
             headingTokens: FruitfolioQueryNormalizer.tokens(note.heading),
             normalizedBody: FruitfolioQueryNormalizer.normalize(note.text))
        }
        var usedParagraphs: Set<String> = []
        var excerpts: [FruitfolioHormoneLibraryExcerpt] = []
        for section in FruitfolioHormoneLibrarySection.allCases {
            try Task.checkCancellation()
            let terms = FruitfolioQueryNormalizer.tokens(section.retrievalTerms)
            let question = aliases + " " + section.retrievalTerms
            let queryTokens = FruitfolioQueryNormalizer.tokens(question)
            let normalizedQuestion = FruitfolioQueryNormalizer.normalize(question)
            var ranked: [FruitfolioRankedNote] = []
            for candidate in candidates where !candidate.bodyTokens.intersection(terms).isEmpty {
                let headingScore = 3 * candidate.headingTokens.intersection(queryTokens).count
                let bodyScore = candidate.bodyTokens.intersection(queryTokens).count
                let phraseScore = candidate.normalizedBody.contains(normalizedQuestion) ? 3 : 0
                ranked.append(.init(chunk: candidate.note, score: Double(headingScore + bodyScore + phraseScore)))
            }
            ranked.sort { lhs, rhs in
                lhs.score == rhs.score ? lhs.chunk.chunkID < rhs.chunk.chunkID : lhs.score > rhs.score
            }
            for result in ranked {
                let note = result.chunk
                guard !usedParagraphs.contains(note.text), !note.sourceIDs.isEmpty,
                      note.sourceIDs.allSatisfy({ approved[$0] != nil }),
                      let presentation = FruitfolioEvidenceCopyPolicy.validatedPresentation(note.text, original: note.text) else { continue }
                let sources = note.sourceIDs.compactMap { approved[$0] }.map {
                    AskSourceRecord(id: $0.sourceID, title: $0.apa7Reference ?? $0.title, sourceText: $0.apa7Reference,
                        urlString: $0.canonicalURL, doi: $0.doi, publicationData: $0.publicationDate, contentVersion: $0.contentVersion)
                }
                excerpts.append(.init(section: section, noteID: note.chunkID, heading: note.heading,
                    originalText: note.text, presentation: presentation, sources: sources))
                usedParagraphs.insert(note.text)
                break
            }
        }
        try Task.checkCancellation()
        let article = FruitfolioHormoneLibraryArticle(hormone: hormone, excerpts: excerpts, contentVersion: package.contentVersion)
        cache[hormone] = article
        return article
    }
}
