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
        let alternatives: String
        switch hormone {
        case .estradiol: alternatives = "estradiol|estrogen|oestrogen|e2"
        case .progesterone: alternatives = "progesterone"
        case .lh: alternatives = "luteinizing|luteinising|lh"
        case .fsh: alternatives = "follicle[- ]+stimulating|fsh"
        case .testosterone: alternatives = "testosterone"
        case .prolactin: alternatives = "prolactin"
        case .amh: alternatives = "anti[- ]+mullerian|amh"
        case .other: return false
        }
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let pattern = "(?<![\\p{L}\\p{N}])(?:" + alternatives + ")(?![\\p{L}\\p{N}])"
        return folded.range(of: pattern, options: .regularExpression) != nil
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
        var usedParagraphs: Set<String> = []
        var excerpts: [FruitfolioHormoneLibraryExcerpt] = []
        for section in FruitfolioHormoneLibrarySection.allCases {
            try Task.checkCancellation()
            let terms = FruitfolioQueryNormalizer.tokens(section.retrievalTerms)
            let ranked = retriever.searchNotes(question: aliases + " " + section.retrievalTerms, limit: 24)
            let candidates = retriever.contextualizedNotes(ranked)
            for note in candidates {
                let tokens = FruitfolioQueryNormalizer.tokens(note.text)
                guard FruitfolioHormoneResearchMatch.contains(hormone, in: note.text),
                      !tokens.intersection(terms).isEmpty,
                      !usedParagraphs.contains(note.text), !note.sourceIDs.isEmpty,
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
