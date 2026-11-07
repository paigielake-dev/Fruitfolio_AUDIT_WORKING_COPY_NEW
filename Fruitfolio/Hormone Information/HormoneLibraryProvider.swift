import Foundation

nonisolated enum FruitfolioHormoneLibrarySection: String, CaseIterable, Identifiable, Sendable {
    case overview, functions, reproductiveRelevance, measurementInfluences, testingContext, measurementLimitations, medicalGuidance
    // Preserve the established primary source assignments; new aspects may
    // reference an already displayed paragraph through alsoCovers.
    static let retrievalOrder: [Self] = [.functions, .reproductiveRelevance,
        .measurementLimitations, .testingContext, .medicalGuidance, .overview, .measurementInfluences]
    var id: String { rawValue }
    var title: String {
        switch self {
        case .overview: return "what the hormone is"
        case .functions: return "biological functions"
        case .reproductiveRelevance: return "reproductive relevance"
        case .measurementLimitations: return "measurement limitations"
        case .testingContext: return "testing context"
        case .medicalGuidance: return "medical guidance and interpretation"
        case .measurementInfluences: return "factors affecting measured levels"
        }
    }
    var retrievalTerms: String {
        switch self {
        case .overview: return "hormone hormones steroid estrogen androgen gonadotropin messenger definition"
        case .functions: return "function role production secretion regulation"
        case .reproductiveRelevance: return "reproductive ovulation cycle follicle fertility ovary sperm"
        case .measurementLimitations: return "limitations measurement single fluctuation variability assay snapshot guarantee"
        case .testingContext: return "testing test tests tested sample samples sampling blood serum plasma saliva urine collection laboratory assay assays measurement measurements measured measuring timing reference"
        case .medicalGuidance: return "clinician doctor evaluate consult interpret diagnosis"
        case .measurementInfluences: return "levels concentration stress sleep age cycle ovulation pregnancy postpartum menopause medication timing assay method variation increase decrease rise fall"
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
    var alsoCovers: [FruitfolioHormoneLibrarySection] = []
    var id: String { section.rawValue + ":" + noteID }
}
nonisolated struct FruitfolioHormoneLibraryArticle: Sendable {
    let hormone: FruitfolioMeasuredHormone
    let excerpts: [FruitfolioHormoneLibraryExcerpt]
    let contentVersion: String

    func excerpt(for section: FruitfolioHormoneLibrarySection) -> FruitfolioHormoneLibraryExcerpt? {
        excerpts.first { $0.section == section } ?? excerpts.first { $0.alsoCovers.contains(section) }
    }
}

/// A hormone elsewhere in a paragraph does not make unrelated Pap/STI testing
/// a hormone measurement. This is a bounded retrieval-scope gate, not clinical
/// entailment or complete chapter acceptance. Original paragraphs stay intact.
nonisolated enum FruitfolioHormoneLibraryScope {
    private static let testing = try? NSRegularExpression(
        pattern: #"\b(?:tests?|testing|tested|assays?|laborator(?:y|ies)|blood|serum|plasma|saliva|urine|samples?|sampling|collection|measure(?:ments?|d)?|measuring)\b"#,
        options: .caseInsensitive)
    private static let otherTesting = try? NSRegularExpression(
        pattern: #"\b(?:pap|smears?|sti|stis|hpv|cervical|chlamydia|gonorrhea|mammograms?|mammography)\b"#,
        options: .caseInsensitive)

    static func makeMatcher(for section: FruitfolioHormoneLibrarySection,
                            hormone: FruitfolioMeasuredHormone) -> (String) -> Bool {
        switch section {
        case .overview:
            // Require an actual named-hormone definition, not another hormone's
            // definition elsewhere in the same paragraph or a test-value claim.
            let definition = #"(?:\s+hormone)?(?:\s*\([^)]{1,40}\))?\s*,?\s*(?:(?:is|are)\s+|:\s*)(?:(?:a|an|the)\s+)?(?:(?:type|form|kind|member)\s+of\s+(?:the\s+)?)?(?:(?:main|major|primary|principal|predominant|important|gonadal|pituitary|reproductive|sex|steroid|peptide|protein|glycoprotein|polypeptide|anabolic)\s+){0,5}(?:hormones?|androgens?|estrogens?|gonadotropins?|steroids?|chemical\s+messengers?)\b"#
            return FruitfolioHormoneResearchMatch.makeMatcher(for: hormone,
                includeClassAliases: false, followingPattern: definition)
        case .measurementInfluences:
            let factors = #"\b(?:stress|sleep|exercise|age|aging|cycle|ovulation|follicular|luteal|pregnan\w*|post[\s-]*partum|lactat\w*|breastfeed\w*|menopause|perimenopause|medications?|drugs?|contracept\w*|therapy|assays?|methods?|laborator\w*|timing|time|morning|evening|fasting|meals?|illness|thyroid|pituitary|pcos)\b"#
            let modifiers = #"(?:(?:can|may|might|often|normally|usually|typically|naturally|also|be|is|are|does|do|not|will)\s+){0,5}"#
            let levels = #"(?:\s+hormone)?(?:\s*\([^)]{1,40}\))?(?:\s+(?:levels?|concentrations?|results?)){0,2}"#
            let change = #"(?:rise[sn]?|rising|surges?|falls?|increase[sd]?|decrease[sd]?|varies|vary|fluctuat\w*|peaks?|changes?|depend\w*|affected|influenced|altered|elevated|lowered|higher|lower)\b"#
            let connection = #"\s+(?:(?:slightly|substantially|temporarily|significantly)\s+){0,2}(?:in|with|during|after|before|by|over|following|throughout|around|across|under|because\s+of|depending\s+on|in\s+response\s+to|due\s+to)\s+(?:the\s+)?(?:(?:menstrual|daily|physical|intense|heavy|chronic|acute|different|certain|some|normal|early|late|prolonged|hormonal|reproductive)\s+){0,3}"#
            let forward = FruitfolioHormoneResearchMatch.makeMatcher(for: hormone,
                includeClassAliases: false,
                followingPattern: levels + #"\s+"# + modifiers + change + connection + factors)
            let reverse = FruitfolioHormoneResearchMatch.makeMatcher(for: hormone,
                includeClassAliases: false, followingPattern: levels,
                precedingPattern: factors + #"\s+"# + modifiers +
                    #"(?:raise[sd]?|lower[sd]?|increase[sd]?|decrease[sd]?|affect[sd]?|alter[sd]?|change[sd]?|elevate[sd]?|influence[sd]?|reduce[sd]?)\s+(?:(?:measured|serum|blood|circulating)\s+)?(?:levels?\s+of\s+)?"#)
            return { forward($0) || reverse($0) }
        case .testingContext:
            let named = FruitfolioHormoneResearchMatch.makeMatcher(for: hormone)
            return { permits(section, text: $0, matchesHormone: named) }
        default:
            return { _ in true }
        }
    }

    static func permits(_ section: FruitfolioHormoneLibrarySection, text: String,
                        matchesHormone: (String) -> Bool) -> Bool {
        guard section == .testingContext else { return true }
        guard let testing, let otherTesting else { return false }
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?\n")).contains { clause in
            let range = NSRange(clause.startIndex..., in: clause)
            return matchesHormone(clause) && testing.firstMatch(in: clause, range: range) != nil &&
                otherTesting.firstMatch(in: clause, range: range) == nil
        }
    }
}

nonisolated enum FruitfolioHormoneResearchMatch {
    static func contains(_ hormone: FruitfolioMeasuredHormone, in text: String) -> Bool {
        makeMatcher(for: hormone)(text)
    }

    /// Compile once for an exhaustive article lookup, retaining the exact
    /// existing Unicode/name boundary policy for every source paragraph.
    static func makeMatcher(for hormone: FruitfolioMeasuredHormone, includeClassAliases: Bool = true,
                            followingPattern: String = "", precedingPattern: String = "") -> (String) -> Bool {
        // Typography in an original medical name may use a Unicode hyphen or
        // nonbreaking space. This lookup never rewrites the quoted evidence.
        let compoundSeparator = #"[\p{Pd}\p{Zs}\t\r\n]+"#
        let alternatives: String
        switch hormone {
        case .estradiol: alternatives = includeClassAliases ? "estradiol|estrogen|oestrogen|e2" : "estradiol|e2"
        case .progesterone: alternatives = "progesterone"
        case .lh: alternatives = "luteinizing|luteinising|lh"
        case .fsh: alternatives = "follicle" + compoundSeparator + "stimulating|fsh"
        case .testosterone: alternatives = "testosterone"
        case .prolactin: alternatives = "prolactin"
        case .amh: alternatives = "anti" + compoundSeparator + "mullerian|amh"
        case .other: return { _ in false }
        }
        // Fragments are trusted internal role patterns, never user/model text.
        let pattern = precedingPattern + "(?<![\\p{L}\\p{N}])(?:" + alternatives + ")(?![\\p{L}\\p{N}])" + followingPattern
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
        // Estradiol is a specific estrogen. Prefer evidence that actually names
        // estradiol/E2 over class-level material such as a seed-cycling discussion.
        // Class context remains available when no specific candidate fits.
        let matchesSpecificHormone = FruitfolioHormoneResearchMatch.makeMatcher(for: hormone, includeClassAliases: false)
        let specificIDs = Set(candidates.filter { matchesSpecificHormone($0.note.text) }.map { $0.note.chunkID })
        var usedParagraphs: Set<Data> = []
        var excerpts: [FruitfolioHormoneLibraryExcerpt] = []
        for section in FruitfolioHormoneLibrarySection.retrievalOrder {
            try Task.checkCancellation()
            // The existing oogenesis evidence describes LH's function as its
            // surge triggering follicular rupture, not with the word "function".
            var sectionTerms = section.retrievalTerms
            if section == .functions {
                if hormone == .lh { sectionTerms += " surge" }
                if hormone == .estradiol { sectionTerms += " support follicular development" }
                if hormone == .progesterone { sectionTerms += " corpus luteum endometrium uterine lining" }
            }
            let terms = FruitfolioQueryNormalizer.tokens(sectionTerms)
            let question = aliases + " " + sectionTerms
            let queryTokens = FruitfolioQueryNormalizer.tokens(question)
            let normalizedQuestion = FruitfolioQueryNormalizer.normalize(question)
            let fitsRole = FruitfolioHormoneLibraryScope.makeMatcher(for: section, hormone: hormone)
            let hasExplicitScope = section == .overview || section == .measurementInfluences || section == .testingContext
            var ranked: [FruitfolioRankedNote] = []
            for candidate in candidates where (hasExplicitScope || !candidate.bodyTokens.intersection(terms).isEmpty) &&
                fitsRole(candidate.note.text) {
                let headingScore = 3 * candidate.headingTokens.intersection(queryTokens).count
                let bodyScore = candidate.bodyTokens.intersection(queryTokens).count
                let phraseScore = candidate.normalizedBody.contains(normalizedQuestion) ? 3 : 0
                ranked.append(.init(chunk: candidate.note, score: Double(headingScore + bodyScore + phraseScore)))
            }
            ranked.sort { lhs, rhs in
                let leftIsSpecific = specificIDs.contains(lhs.chunk.chunkID)
                let rightIsSpecific = specificIDs.contains(rhs.chunk.chunkID)
                if leftIsSpecific != rightIsSpecific { return leftIsSpecific }
                return lhs.score == rhs.score ? lhs.chunk.chunkID < rhs.chunk.chunkID : lhs.score > rhs.score
            }
            var sharedExcerptIndex: Int?
            var selectedNewParagraph = false
            for result in ranked {
                let note = result.chunk
                let identity = Data(note.text.utf8)
                if usedParagraphs.contains(identity) {
                    if sharedExcerptIndex == nil {
                        sharedExcerptIndex = excerpts.firstIndex { $0.originalText.utf8.elementsEqual(note.text.utf8) }
                    }
                    continue
                }
                guard !note.sourceIDs.isEmpty,
                      note.sourceIDs.allSatisfy({ approved[$0] != nil }),
                      let presentation = FruitfolioEvidenceCopyPolicy.validatedPresentation(note.text, original: note.text) else { continue }
                let sources = note.sourceIDs.compactMap { approved[$0] }.map {
                    AskSourceRecord(id: $0.sourceID, title: $0.apa7Reference ?? $0.title, sourceText: $0.apa7Reference,
                        urlString: $0.canonicalURL, doi: $0.doi, publicationData: $0.publicationDate, contentVersion: $0.contentVersion)
                }
                excerpts.append(.init(section: section, noteID: note.chunkID, heading: note.heading,
                    originalText: note.text, presentation: presentation, sources: sources))
                usedParagraphs.insert(identity)
                selectedNewParagraph = true
                break
            }
            // Retain existing unique-paragraph choices first. If a qualifying
            // source is already displayed, reference its actual citation owner
            // instead of inventing missing research or repeating the paragraph.
            if !selectedNewParagraph, let index = sharedExcerptIndex {
                excerpts[index].alsoCovers.append(section)
            }
        }
        try Task.checkCancellation()
        let article = FruitfolioHormoneLibraryArticle(hormone: hormone, excerpts: excerpts, contentVersion: package.contentVersion)
        cache[hormone] = article
        return article
    }
}
