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

/// Composite of the same original-paragraph records, never synthesized chapter
/// prose. Repeated paragraphs are shown/saved once while all attribution stays.
struct FruitfolioEducationChapter: Sendable {
    let primary: FruitfolioEducationArticle
    let details: [FruitfolioEducationArticle]
    let unavailableDetailIDs: [String]

    var additionalExcerpts: [FruitfolioEducationArticle] {
        var seen: Set<Data> = [Data(primary.originalText.utf8)]
        return details.filter { seen.insert(Data($0.originalText.utf8)).inserted }
    }
    var sources: [AskSourceRecord] {
        var seen: Set<String> = []
        return ([primary] + details).flatMap(\.sources).filter { seen.insert($0.id).inserted }
    }
    var presentation: String {
        ([primary.presentation] + additionalExcerpts.map {
            FruitfolioSemanticMarkup.markdown([.init(text: $0.title, emphasis: .anchorBold)]) + "\n" + $0.presentation
        }).joined(separator: "\n\n")
    }
    func prepareSave() throws -> Prompt10PendingSavedContent {
        guard let versions = Prompt09SaveSourceVersions.validated(sources) else {
            throw FruitfolioEducationResearchError.invalidSourceMetadata
        }
        var seen: Set<String> = []
        let notes = ([primary] + details).map(\.noteID).filter { seen.insert($0).inserted }
        return .init(question: primary.title, answer: presentation, saveType: .fullAnswer,
            originalAnswerID: "education:" + primary.contentID + ":" + notes.joined(separator: ";"),
            sourceIDs: sources.map(\.id), sourceVersions: versions,
            knowledgeBaseVersion: primary.knowledgeBaseVersion, sourceRecords: sources)
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
    private var chapterCache: [String: FruitfolioEducationChapter] = [:]

    init(packageStore: FruitfolioResearchPackageStore = .shared) { self.packageStore = packageStore }

    struct Request: Sendable {
        let id: String
        let title: String
        let query: String
        let requiredPattern: String
        var additionalPattern: String? = nil
        var parentID: String? = nil
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
                pattern = #"\b(?:agar|petri|culture plates?|urine cultures?|bacterial cultures?)\b"#
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
        let core = fertilization + pregnancy + science
        return core + detailRequests(core: core)
    }

    private nonisolated static func detailRequests(core: [Request]) -> [Request] {
        var result: [Request] = []
        for topic in Prompt26PregnancyEducationCatalog.topics {
            guard let parent = core.first(where: { $0.id == topic.shortContentID }) else { continue }
            for id in topic.sectionIDs {
                let role = id.split(separator: ".").last.map(String.init) ?? ""
                let title: String, terms: String, pattern: String
                switch role {
                case "hcg":
                    title = "hCG"; terms = "hCG human chorionic gonadotropin pregnancy tests"
                    pattern = #"\b(?:hcg|human chorionic gonadotropin)\b"#
                case "timing":
                    title = "testing timing"; terms = "pregnancy tests timing implantation days early"
                    pattern = #"\b(?:timing|implantation|early|days|weeks)\b"#
                case "results":
                    title = "understanding results"; terms = "pregnancy tests positive negative results"
                    pattern = #"\b(?:positive|negative|results?)\b"#
                case "limitations":
                    title = "limitations"; terms = "limitations false negative false positive uncertainty"
                    pattern = #"\b(?:cannot|not always|false negative|false positive|does not|may not|varies)\b"#
                case "implantation":
                    title = "implantation"; terms = "implantation embryo uterine lining blastocyst"
                    pattern = #"\bimplant\w*\b"#
                case "terminology":
                    title = "biological terminology"; terms = "embryo fetus definition means terminology"
                    pattern = #"\b(?:means|called|defined|refers|embryo|fetus)\b"#
                case "transitions":
                    title = "developmental transitions"; terms = "fertilization blastocyst implantation embryo development"
                    pattern = #"\b(?:zygote|blastocysts?|implantation|fertilization|embryonic)\b"#
                case "variability":
                    title = "variation and uncertainty"; terms = "fetal growth variation varies ultrasound estimate"
                    pattern = #"\b(?:vary|varies|variation|different|estimate\w*|uncertain\w*)\b"#
                case "scale":
                    title = "interpreting developmental size"; terms = "fetal growth measurement size estimated weight"
                    pattern = #"\b(?:size|measurement\w*|weight|growth|ultrasound)\b"#
                case "development":
                    title = "developmental context"; terms = "placenta development implantation trophoblast"
                    pattern = #"\b(?:develop\w*|implant\w*|trophoblast\w*)\b"#
                case "anatomy":
                    title = "anatomy"; terms = "placenta umbilical cord vessels membrane anatomy"
                    pattern = #"\b(?:vessels?|membranes?|tissue|arteries|veins?|organ|cord)\b"#
                case "exchange":
                    title = "oxygen and nutrient exchange"; terms = "placenta oxygen nutrients exchange maternal fetal"
                    pattern = #"\b(?:oxygen|nutrients?|exchange|carbon dioxide)\b"#
                case "hormones":
                    title = "hormone production"; terms = "placenta hormones hCG progesterone estrogen"
                    pattern = #"\b(?:hormones?|hcg|progesterone|estrogen)\b"#
                case "circulation":
                    title = "circulation"; terms = "placenta umbilical cord blood circulation oxygen"
                    pattern = #"\b(?:blood|vessels?|circulation|oxygen)\b"#
                case "vessels":
                    title = "blood vessels"; terms = "umbilical cord arteries vein vessels"
                    pattern = #"\b(?:arteries|veins?|vessels?)\b"#
                case "whartons_jelly":
                    title = "Wharton’s jelly"; terms = "umbilical cord Wharton jelly vessels protection"
                    pattern = #"\bwharton['’]?s?\s+jelly\b"#
                case "sound_waves":
                    title = "sound-wave imaging"; terms = "ultrasound sound waves echo imaging"
                    pattern = #"\b(?:sound[\s-]+waves?|echo\w*)\b"#
                case "approaches":
                    title = "imaging approaches"; terms = "ultrasound transvaginal transabdominal Doppler"
                    pattern = #"\b(?:transvaginal|transabdominal|abdominal|doppler)\b"#
                case "professional_role":
                    title = "professional interpretation"; terms = "ultrasound clinician interpret provider monitoring"
                    pattern = #"\b(?:clinician|provider|doctor|interpret\w*|obstetric\w*)\b"#
                case "folate":
                    title = "folate"; terms = "prenatal folate folic acid neural tube"
                    pattern = #"\b(?:folate|folic acid)\b"#
                case "nutrients":
                    title = "nutrients"; terms = "prenatal vitamins folate iodine iron vitamin D calcium"
                    pattern = #"\b(?:folate|folic acid|iodine|iron|vitamin d|calcium)\b"#
                case "dosing":
                    title = "dose and safety considerations"; terms = "prenatal vitamins dose provider review too much safety"
                    pattern = #"(?s)^(?=.*\b(?:dose|dosage|doses|amount|too much)\b)(?=.*\b(?:clinician|provider|medical|harmful|safety|should not)\b)"#
                case "safety":
                    title = "safety"; terms = "prenatal vitamins safety harmful avoid interactions too much"
                    pattern = #"\b(?:harm\w*|safe\w*|avoid|interact\w*|too much|should not)\b"#
                case "preconception":
                    title = "preconception context"; terms = "prenatal vitamins before pregnancy preconception folate"
                    pattern = #"\b(?:preconception|before pregnancy|before conception|trying to conceive)\b"#
                default:
                    // New catalog roles require review, not an invented section.
                    continue
                }
                result.append(.init(id: id, title: title, query: parent.query + " " + terms,
                    requiredPattern: parent.requiredPattern, additionalPattern: pattern, parentID: parent.id))
            }
        }
        for stage in Prompt25FertilizationSequence.stages {
            guard let parent = core.first(where: { $0.id == stage.shortContentID }) else { continue }
            let terms: String, pattern: String
            switch stage.id {
            case .oocyte:
                terms = "mature oocyte cytoplasm polar bodies function"
                pattern = #"\b(?:cytoplasm|polar bodies|mature oocyte|haploid|meiosis)\b"#
            case .fertilization:
                terms = "sperm oocyte genetic material meiosis II zygote"
                pattern = #"\b(?:sperm|fertilization|fusion|zygote)\b"#
            case .twoCell, .fourCell:
                terms = "cleavage cell division blastomere"
                pattern = #"\b(?:cleavage|division|blastomeres?)\b"#
            case .morula:
                terms = "morula compaction blastomere cleavage"
                pattern = #"\b(?:morula\w*|compaction|blastomeres?|cleavage)\b"#
            case .blastocyst:
                terms = "blastocyst inner cell mass trophoblast blastocoel"
                pattern = #"\b(?:inner cell mass|trophoblast\w*|trophectoderm|blastocoel|blastocyst stage)\b"#
            }
            result.append(.init(id: stage.expandedContentID, title: "further " + stage.title + " context",
                query: parent.query + " " + terms, requiredPattern: parent.requiredPattern,
                additionalPattern: pattern, parentID: parent.id))
        }
        return result
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
        let additional = try request.additionalPattern.map {
            try NSRegularExpression(pattern: $0, options: .caseInsensitive)
        }
        let terms = FruitfolioQueryNormalizer.tokens(request.query)
        let eligible = package.researchNoteChunks.filter { $0.retrievalEligibility != false }
            .sorted { $0.chunkID < $1.chunkID }.map { FruitfolioRankedNote(chunk: $0, score: 0) }
        var best: (note: FruitfolioResearchNoteChunk, score: Int)?
        for note in retriever.contextualizedNotes(eligible) {
            try Task.checkCancellation()
            guard !note.sourceIDs.isEmpty, note.sourceIDs.allSatisfy({ approved[$0] != nil }),
                  matcher.firstMatch(in: note.text, range: NSRange(note.text.startIndex..., in: note.text)) != nil,
                  additional == nil || additional?.firstMatch(in: note.text,
                    range: NSRange(note.text.startIndex..., in: note.text)) != nil else { continue }
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

    func chapter(for contentID: String) async throws -> FruitfolioEducationChapter {
        try Task.checkCancellation()
        if let cached = chapterCache[contentID] { return cached }
        let primary = try await article(for: contentID)
        var details: [FruitfolioEducationArticle] = []
        var unavailable: [String] = []
        for request in Self.requests where request.parentID == contentID {
            try Task.checkCancellation()
            do { details.append(try await article(for: request.id)) }
            catch FruitfolioEducationResearchError.unavailable { unavailable.append(request.id) }
        }
        try Task.checkCancellation()
        let chapter = FruitfolioEducationChapter(primary: primary, details: details, unavailableDetailIDs: unavailable)
        chapterCache[contentID] = chapter
        return chapter
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
        guard let chapter = try? await research.chapter(for: stage.shortContentID) else { return .unavailable }
        return .init(shortText: chapter.primary.modulePresentation,
            expandedSections: chapter.additionalExcerpts.map {
                .init(id: $0.contentID, heading: $0.title, body: $0.presentation)
            }, sourceCount: chapter.sources.count, isApproved: true)
    }
}

struct FruitfolioPregnancyResearchAdapter: Prompt26PregnancyResearchProviding {
    let research: FruitfolioEducationResearch
    func approvedContent(for contentID: String) async throws -> Prompt26ApprovedContent {
        let chapter = try await research.chapter(for: contentID)
        return .init(contentID: contentID, title: chapter.primary.title, summary: chapter.primary.modulePresentation,
            sections: chapter.additionalExcerpts.map {
                .init(id: $0.contentID, heading: $0.title, body: $0.presentation, sourceIDs: $0.sources.map(\.id))
            }, sourceIDs: chapter.sources.map(\.id))
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
