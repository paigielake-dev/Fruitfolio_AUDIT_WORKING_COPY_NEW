import Foundation

/// Intentional destinations inside existing Ask education access, never a
/// prediction-triggered navigation decision or another top-level Hub route.
enum FruitfolioEducationCollection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case fertilization, pregnancy, genetics, body, laboratory
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fertilization: return "fertilization education"
        case .pregnancy: return "pregnancy education"
        case .genetics: return "genetics and molecular biology"
        case .body: return "body and anatomy"
        case .laboratory: return "laboratory education"
        }
    }
}

struct FruitfolioEducationArticle: Sendable {
    let contentID: String
    let title: String
    let noteID: String
    let originalText: String
    let presentation: String
    let sources: [AskSourceRecord]
    let knowledgeBaseVersion: String

    var modulePresentation: String {
        "general reference illustration. the source excerpt may discuss a condition not depicted in this image.\n\n" + presentation
    }

    func prepareSave() throws -> Prompt10PendingSavedContent {
        guard let versions = Prompt09SaveSourceVersions.validated(sources) else {
            throw FruitfolioEducationResearchError.invalidSourceMetadata
        }
        return .init(question: title, answer: presentation, saveType: .fullAnswer,
            originalAnswerID: "education:" + contentID + ":" + noteID,
            sourceIDs: sources.map(\.id), sourceVersions: versions,
            knowledgeBaseVersion: knowledgeBaseVersion, sourceRecords: sources)
    }
}

enum FruitfolioEducationResearchError: Error, Equatable {
    case unknownContent, unavailable, invalidSourceMetadata
}

/// Fixed module content requests reuse the canonical local package/index and
/// full-paragraph/source gates. No generation, patient input or network access.
actor FruitfolioEducationResearch {
    static let shared = FruitfolioEducationResearch()
    private let packageStore: FruitfolioResearchPackageStore
    private var cache: [String: FruitfolioEducationArticle] = [:]

    init(packageStore: FruitfolioResearchPackageStore = .shared) { self.packageStore = packageStore }

    struct Request: Sendable {
        let id: String
        let title: String
        let query: String
        let requiredPattern: String
    }

    nonisolated static var requests: [Request] {
        let fertilization = Prompt25FertilizationSequence.stages.map { stage in
            let pattern: String
            switch stage.id {
            case .oocyte: pattern = #"\b(?:oocyte|oogenesis)\b"#
            case .fertilization: pattern = #"\b(?:fertilization|fertilisation|zygote)\b"#
            case .twoCell: pattern = #"\b(?:2|two)[\s-]*cell\b"#
            case .fourCell: pattern = #"\b(?:4|four)[\s-]*cell\b"#
            case .morula: pattern = #"\bmorula(?:e|s)?\b"#
            case .blastocyst: pattern = #"\bblastocysts?\b"#
            }
            return Request(id: stage.shortContentID, title: stage.title,
                query: stage.title + " female gametogenesis oogenesis fertilization sperm oocyte meiosis zygote",
                requiredPattern: pattern)
        }
        let pregnancy = Prompt26PregnancyEducationCatalog.topics.map { topic in
            let pattern: String
            let query: String
            switch topic.id {
            case .testing:
                pattern = #"\b(?:pregnancy tests?|hcg|human chorionic gonadotropin)\b"#
                query = "pregnancy tests hCG detection timing results home urine blood"
            case .earlyDevelopment:
                pattern = #"\b(?:embryo|embryonic|implantation)\b"#
                query = "female gametogenesis oogenesis fertilization embryo embryonic implantation development"
            case .fetalDevelopment:
                pattern = #"\b(?:fetal|foetal)\s+(?:development|growth)\b"#
                query = "fetal development growth gestation trimester organ development"
            case .placenta:
                pattern = #"\bplacent(?:a|al)\b"#
                query = "placenta function oxygen nutrients exchange circulation hormones"
            case .umbilicalCord:
                pattern = #"\bumbilical\s+cord\b"#
                query = "umbilical cord anatomy vessels blood circulation oxygen Wharton jelly"
            case .ultrasound:
                pattern = #"\bultrasound\b"#
                query = "ultrasound imaging sound waves transabdominal transvaginal"
            case .prenatalVitamins:
                pattern = #"\b(?:prenatal vitamins?|folate|folic acid)\b"#
                query = "prenatal vitamins folate folic acid safety pregnancy nutrition"
            }
            return Request(id: topic.shortContentID, title: topic.title,
                query: query, requiredPattern: pattern)
        }
        let science = Prompt27ScientificAssetCatalog.canonicalAssets.map { asset in
            let name = asset.concept.rawValue.replacingOccurrences(of: "_", with: " ")
            let pattern: String
            let query: String
            switch asset.concept {
            case .dna:
                pattern = #"\b(?:dna|deoxyribonucleic acid)\b"#
                query = "DNA chromosome replication genetic material meiosis"
            case .rna:
                pattern = #"\b(?:rna|mrna|trna|rrna|ribonucleic acid)\b"#
                query = "RNA ribonucleic messenger protein synthesis transcription translation"
            case .mitochondrion:
                pattern = #"\b(?:mitochondrion|mitochondria|mitochondrial)\b"#
                query = "mitochondria energy ATP cell function"
            case .nucleus:
                pattern = #"\b(?:nucleus|nuclei)\b"#
                query = "nucleus nuclei DNA cell genetic material"
            case .protein:
                pattern = #"(?s)^(?=.*\bproteins?\b)(?=.*\b(?:amino acids?|polypeptides?|peptides?|protein synthesis|protein structure)\b)"#
                query = "protein amino acids polypeptide molecule structure synthesis"
            case .receptor:
                pattern = #"\breceptors?\b[^.\n]{0,100}\b(?:bind\w*|signal\w*|receiv\w*|recogniz\w*|ligands?)\b|\bbind\w*\b[^.\n]{0,80}\breceptors?\b"#
                query = "receptor binding ligand cell signal hormone mechanism"
            case .cell, .cells:
                pattern = #"(?s)^(?=.*\bcells?\b)(?=.*\b(?:cytoplasm|cell membrane|nucleus|nuclei|organelles?|cell division|cellular structure)\b)"#
                query = "cell membrane cytoplasm nucleus organelle division structure"
            case .chromosome:
                pattern = #"\bchromosomes?\b"#
                query = "chromosomes DNA genes genetic material meiosis replication"
            case .culture:
                pattern = #"\b(?:agar|petri|culture plates?)\b"#
                query = "agar petri culture plate laboratory bacteria microbiology"
            case .kidneys:
                pattern = #"(?s)^(?=.*\b(?:kidneys?|renal)\b)(?=.*\b(?:filtration|filter\w*|kidney function|renal function|nephron\w*|urine production)\b)"#
                query = "kidney renal function filtration urine blood filter"
            case .stomach:
                pattern = #"(?s)^(?=.*\bstomach\b)(?=.*\b(?:stomach acid|gastric|stomach lining|digestion|digestive enzymes|stomach contents)\b)"#
                query = "stomach gastric acid lining digestion digestive enzymes"
            case .muscle:
                pattern = #"\b(?:skeletal muscle|muscle mass|muscle strength|muscle contraction|muscles contract|muscle tissue|muscle fibers)\b"#
                query = "skeletal muscle contraction mass strength function"
            case .bone:
                pattern = #"\b(?:bone remodeling|bone tissue|osteoblast\w*|osteoclast\w*|bone formation|bone density|skeleton)\b"#
                query = "bone remodeling density formation osteoblast osteoclast"
            case .heart:
                pattern = #"(?s)^(?=.*\bheart\b)(?=.*\b(?:pump\w*|beat\w*|blood flow|circulation)\b)"#
                query = "heart pumps blood circulation heart rate function"
            case .liver:
                pattern = #"(?s)^(?=.*\bliver\b)(?=.*\b(?:bile|metaboli\w*|process\w*|liver function)\b)"#
                query = "liver function bile metabolism nutrient processing"
            case .thyroid:
                pattern = #"\bthyroid gland\b|\bthyroid\b[^.\n]{0,80}\b(?:makes?|produces?|metabolism)\b"#
                query = "thyroid gland produces hormones metabolism T3 T4"
            case .sampleCollection:
                pattern = #"\b(?:swab|swabs|swabbing)\b"#
                query = "swab specimen sample collection testing laboratory"
            case .specimenCollection:
                pattern = #"\b(?:specimen cup|urine samples?|urine specimens?)\b"#
                query = "urine sample specimen cup collection testing"
            case .pcrReactionSetup:
                pattern = #"\b(?:pcr|polymerase chain reaction)\b"#
                query = "PCR polymerase chain reaction testing laboratory amplification"
            case .testTube:
                pattern = #"\btest[\s-]+tubes?\b"#
                query = "test tube laboratory sample collection"
            case .liquidTransfer:
                pattern = #"\b(?:pipettes?|pipets?|pipetting|pipeting)\b"#
                query = "pipette liquid transfer laboratory samples"
            case .microscopy:
                pattern = #"\b(?:microscope|microscopy)\b"#
                query = "microscope microscopy examination cells magnification"
            case .centrifugation:
                pattern = #"\b(?:centrifuge|centrifugation)\b"#
                query = "centrifuge centrifugation sample separation laboratory"
            default:
                pattern = "\\b" + NSRegularExpression.escapedPattern(for: name) + "\\b"
                query = name + " biology"
            }
            return Request(id: scienceID(for: asset), title: title(for: asset), query: query,
                requiredPattern: pattern)
        }
        return fertilization + pregnancy + science
    }

    nonisolated static func title(for asset: Prompt27ScientificAsset) -> String {
        switch asset.concept {
        case .dna: return "DNA"
        case .rna: return "RNA"
        case .pcrReactionSetup: return "PCR reaction setup"
        default: return asset.concept.rawValue.replacingOccurrences(of: "_", with: " ")
        }
    }

    nonisolated static func scienceID(for asset: Prompt27ScientificAsset) -> String {
        "education.science." + asset.concept.rawValue
    }

    func article(for contentID: String) async throws -> FruitfolioEducationArticle {
        try Task.checkCancellation()
        guard let request = Self.requests.first(where: { $0.id == contentID }) else {
            // Reference illustrations need their own reviewed source-to-period
            // mapping. Never reuse generic fetal prose as invented week content.
            if Prompt26PregnancyEducationCatalog.fetalReferencePeriods.contains(where: { $0.contentID == contentID }) {
                throw FruitfolioEducationResearchError.unavailable
            }
            throw FruitfolioEducationResearchError.unknownContent
        }
        if let cached = cache[contentID] { return cached }
        let retriever = try await packageStore.retriever()
        let package = retriever.package
        let records = package.sources.filter(\.isApprovedForDisplay)
        guard Set(records.map(\.sourceID)).count == records.count else {
            throw FruitfolioEducationResearchError.invalidSourceMetadata
        }
        let approved = Dictionary(uniqueKeysWithValues: records.map { ($0.sourceID, $0) })
        let matcher = try NSRegularExpression(pattern: request.requiredPattern, options: .caseInsensitive)
        let terms = FruitfolioQueryNormalizer.tokens(request.query)
        let eligible = package.researchNoteChunks.filter { $0.retrievalEligibility != false }
            .sorted { $0.chunkID < $1.chunkID }.map { FruitfolioRankedNote(chunk: $0, score: 0) }
        var best: (note: FruitfolioResearchNoteChunk, score: Int)?
        for note in retriever.contextualizedNotes(eligible) {
            try Task.checkCancellation()
            guard !note.sourceIDs.isEmpty, note.sourceIDs.allSatisfy({ approved[$0] != nil }),
                  matcher.firstMatch(in: note.text, range: NSRange(note.text.startIndex..., in: note.text)) != nil else { continue }
            let score = 3 * terms.intersection(FruitfolioQueryNormalizer.tokens(note.heading)).count
                + terms.intersection(FruitfolioQueryNormalizer.tokens(note.text)).count
            if best == nil || score > best!.score { best = (note, score) }
        }
        guard let selected = best?.note,
              let presentation = FruitfolioEvidenceCopyPolicy.validatedPresentation(selected.text, original: selected.text) else {
            throw FruitfolioEducationResearchError.unavailable
        }
        var seen: Set<String> = []
        let sources = selected.sourceIDs.filter { seen.insert($0).inserted }.compactMap { approved[$0] }.map {
            AskSourceRecord(id: $0.sourceID, title: $0.apa7Reference ?? $0.title, sourceText: $0.apa7Reference,
                urlString: $0.canonicalURL, doi: $0.doi, publicationData: $0.publicationDate, contentVersion: $0.contentVersion)
        }
        guard Prompt09SaveSourceVersions.validated(sources) != nil else {
            throw FruitfolioEducationResearchError.invalidSourceMetadata
        }
        let article = FruitfolioEducationArticle(contentID: contentID, title: request.title, noteID: selected.chunkID,
            originalText: selected.text,
            presentation: "original research context: " +
                FruitfolioSemanticMarkup.markdown([.init(text: selected.heading)]) + "\n\n" + presentation,
            sources: sources,
            knowledgeBaseVersion: package.contentVersion)
        cache[contentID] = article
        return article
    }

    func sourceRecords(ids: [String]) async throws -> [AskSourceRecord] {
        let package = try await packageStore.load()
        let records = package.sources.filter(\.isApprovedForDisplay)
        guard Set(records.map(\.sourceID)).count == records.count else {
            throw FruitfolioEducationResearchError.invalidSourceMetadata
        }
        let lookup = Dictionary(uniqueKeysWithValues: records.map { ($0.sourceID, $0) })
        var seen: Set<String> = []
        return try ids.filter { seen.insert($0).inserted }.map {
            try Task.checkCancellation()
            guard let source = lookup[$0] else { throw FruitfolioEducationResearchError.invalidSourceMetadata }
            return AskSourceRecord(id: source.sourceID, title: source.apa7Reference ?? source.title,
                sourceText: source.apa7Reference, urlString: source.canonicalURL, doi: source.doi,
                publicationData: source.publicationDate, contentVersion: source.contentVersion)
        }
    }
}

struct FruitfolioFertilizationResearchAdapter: Prompt25FertilizationContentProviding {
    let research: FruitfolioEducationResearch
    func content(for stage: Prompt25FertilizationStage) async -> Prompt25EducationalContent {
        guard let article = try? await research.article(for: stage.shortContentID) else { return .unavailable }
        return .init(shortText: article.modulePresentation, expandedSections: [],
            sourceCount: article.sources.count, isApproved: true)
    }
}

struct FruitfolioPregnancyResearchAdapter: Prompt26PregnancyResearchProviding {
    let research: FruitfolioEducationResearch
    func approvedContent(for contentID: String) async throws -> Prompt26ApprovedContent {
        let article = try await research.article(for: contentID)
        return .init(contentID: contentID, title: article.title, summary: article.modulePresentation,
            sections: [], sourceIDs: article.sources.map(\.id))
    }
}

struct FruitfolioScienceResearchAdapter: Prompt27ScienceResearchProviding {
    let research: FruitfolioEducationResearch
    func approvedContent(for contentID: String) async throws -> Prompt27ApprovedScienceContent {
        let article = try await research.article(for: contentID)
        return .init(contentID: contentID, title: article.title,
            body: article.modulePresentation, sourceIDs: article.sources.map(\.id))
    }
}
