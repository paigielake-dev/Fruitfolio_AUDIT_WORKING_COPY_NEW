import XCTest
@testable import Fruitfolio

final class Prompt1BHormoneLibraryTests: XCTestCase {
    func testActualCorpusUsesOnlyCompleteEligibleParagraphsAndTheirOwnSourceRecords() async throws {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        let store = FruitfolioResearchPackageStore(resourceURL: url)
        let package = try await store.load()
        let notes = Dictionary(uniqueKeysWithValues: package.researchNoteChunks.map { ($0.chunkID, $0) })
        let sources = Dictionary(uniqueKeysWithValues: package.sources.map { ($0.sourceID, $0) })
        let provider = FruitfolioHormoneLibraryProvider(packageStore: store)
        for hormone in FruitfolioMeasuredHormone.allCases where hormone != .other {
            let article = try await provider.article(for: hormone)
            XCTAssertEqual(article.hormone, hormone)
            XCTAssertEqual(article.contentVersion, package.contentVersion)
            if hormone == .progesterone {
                let functions = try XCTUnwrap(article.excerpts.first { $0.section == .functions })
                XCTAssertTrue(functions.originalText.contains("progesterone is made after ovulation by the corpus luteum"))
                XCTAssertTrue(functions.originalText.contains("helps prepare and support the uterine lining"))
                XCTAssertTrue(functions.originalText.contains("progesterone is not a pregnancy guarantee"))
            }

            // Retain exact actual-corpus coverage for requirement257 / SPEC4.9.7.
            // A matched excerpt is retrieval evidence, never clinical completeness.
            let coverage = article.excerpts.map { $0.section.rawValue + "=" + $0.noteID }.joined(separator: ";")
            let missing = FruitfolioHormoneLibrarySection.allCases.filter { section in
                !article.excerpts.contains(where: { $0.section == section })
            }.map(\.rawValue).joined(separator: ",")
            print("HORMONE_LIBRARY_SOURCE_COVERAGE|\(hormone.rawValue)|\(coverage)|missing=\(missing)")
            XCTAssertFalse(article.excerpts.isEmpty, "Actual approved corpus should supply at least one \(hormone) excerpt")
            XCTAssertEqual(Set(article.excerpts.map(\.originalText)).count, article.excerpts.count)
            if hormone == .estradiol {
                let functions = try XCTUnwrap(article.excerpts.first(where: { $0.section == .functions }))
                XCTAssertTrue(FruitfolioHormoneResearchMatch.makeMatcher(for: .estradiol, includeClassAliases: false)(functions.originalText),
                              "An available specific estradiol paragraph must outrank general estrogen seed-cycling material")
                XCTAssertTrue(functions.originalText.contains("these hormones support follicular development through local signaling."),
                              "The actual approved paragraph must explain a biological role, not merely list estradiol as a test")
            }
            if hormone == .lh {
                let functions = try XCTUnwrap(article.excerpts.first(where: { $0.section == .functions }))
                XCTAssertTrue(functions.originalText.contains("the lh surge causes the follicular wall to rupture."))
            }
            if hormone == .amh {
                let limitations = try XCTUnwrap(article.excerpts.first(where: { $0.section == .measurementLimitations }))
                // Both cautions are literal statements in the actual approved
                // source paragraph, not invented medical fixture content.
                XCTAssertTrue(limitations.originalText.contains("AMH does not guarantee IVF success."))
                XCTAssertTrue(limitations.originalText.contains("AMH does not confirm ovulation."))
            }
            for excerpt in article.excerpts {
                let note = try XCTUnwrap(notes[excerpt.noteID])
                XCTAssertNotEqual(note.retrievalEligibility, false)
                XCTAssertEqual(excerpt.originalText, note.sourceParagraphID.flatMap { package.sourceParagraphs?[$0] } ?? note.text)
                XCTAssertTrue(FruitfolioHormoneResearchMatch.contains(hormone, in: excerpt.originalText))
                XCTAssertEqual(Set(excerpt.sources.map(\.id)), Set(note.sourceIDs))
                for citation in excerpt.sources {
                    let source = try XCTUnwrap(sources[citation.id])
                    XCTAssertTrue(source.isApprovedForDisplay)
                    XCTAssertEqual(citation.title, source.apa7Reference ?? source.title)
                    XCTAssertEqual(citation.doi, source.doi)
                }
            }
        }
    }
    func testHormoneMatchRequiresActualNameOrAbbreviationRatherThanLooseAliasWords() {
        XCTAssertFalse(FruitfolioHormoneResearchMatch.contains(.fsh, in: "a follicle grows"))
        XCTAssertTrue(FruitfolioHormoneResearchMatch.contains(.fsh, in: "follicle-stimulating hormone"))
        XCTAssertFalse(FruitfolioHormoneResearchMatch.contains(.lh, in: "unrelated lhword"))
        XCTAssertTrue(FruitfolioHormoneResearchMatch.contains(.lh, in: "LH testing"))
        XCTAssertTrue(FruitfolioHormoneResearchMatch.contains(.amh, in: "anti-Müllerian hormone"))
    }
    func testUnrelatedHighRankedNotesCannotHideEligibleHormoneSectionBelowGlobalCutoff() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = FruitfolioResearchSource(sourceID: "ranking-fixture", title: "Nonclinical retrieval fixture",
            authors: nil, organization: nil, publicationDate: nil, publicationType: nil, canonicalURL: nil, doi: nil,
            apa7Reference: "Fixture citation, not medical evidence", verificationStatus: "verified", retrievalEligibility: true,
            sourceVersion: "fixture-v1", verifiedAt: nil, contentVersion: "fixture-v1")
        let target = FruitfolioResearchNoteChunk(chunkID: "target-prolactin-testing", researchTopicID: "fixture", heading: "Desired label",
            subheading: nil, text: "Prolactin testing fixture label. No medical assertion.", sourceIDs: [source.sourceID],
            semanticTags: [], domainTags: [], retrievalEligibility: true)
        let distractions = (0..<32).map { index in
            FruitfolioResearchNoteChunk(chunkID: "distractor-\(index)", researchTopicID: "fixture",
                heading: "prolactin testing test sample blood laboratory timing reference", subheading: nil,
                text: "Unrelated testing test sample blood laboratory timing reference fixture. No medical assertion.",
                sourceIDs: [source.sourceID], semanticTags: [], domainTags: [], retrievalEligibility: true)
        }
        let package = FruitfolioResearchPackage(schemaVersion: 1, contentVersion: "fixture-v1", generatedFrom: "test",
            generationNote: "Nonclinical ranking only", researchNoteChunks: distractions + [target], sources: [source], sourceChunks: [])
        let url = directory.appendingPathComponent("research.json")
        try JSONEncoder().encode(package).write(to: url)
        let store = FruitfolioResearchPackageStore(resourceURL: url)
        let retriever = try await store.retriever()
        let oldPool = retriever.searchNotes(question: "prolactin " + FruitfolioHormoneLibrarySection.testingContext.retrievalTerms, limit: 24)
        XCTAssertFalse(oldPool.contains(where: { $0.chunk.chunkID == target.chunkID }), "Demonstrate the former global cutoff loses the real candidate")
        let article = try await FruitfolioHormoneLibraryProvider(packageStore: store).article(for: .prolactin)
        let excerpt = try XCTUnwrap(article.excerpts.first(where: { $0.section == .testingContext }))
        XCTAssertEqual(excerpt.noteID, target.chunkID)
        XCTAssertEqual(excerpt.originalText, target.text)
        XCTAssertEqual(excerpt.sources.map(\.id), [source.sourceID])
        XCTAssertEqual(excerpt.sources.first?.title, source.apa7Reference)
        XCTAssertEqual(article.excerpts.count, 1)
    }

    func testMissingEvidenceStaysEmptyAndOtherHormoneCannotInventACard() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let package = FruitfolioResearchPackage(schemaVersion: 1, contentVersion: "empty-fixture", generatedFrom: "test",
            generationNote: "no medical facts", researchNoteChunks: [], sources: [], sourceChunks: [])
        let url = directory.appendingPathComponent("research.json")
        try JSONEncoder().encode(package).write(to: url)
        let provider = FruitfolioHormoneLibraryProvider(packageStore: .init(resourceURL: url))
        let article = try await provider.article(for: .prolactin)
        XCTAssertTrue(article.excerpts.isEmpty)
        do { _ = try await provider.article(for: .other); XCTFail("Other is not a specified educational hormone") }
        catch FruitfolioHormoneLibraryProvider.Failure.unspecifiedHormone { }
    }
    func testFullHormoneNamesAcceptUnicodeMedicalHyphensAndSpacing() {
        for separator in ["-", " ", "\u{2010}", "\u{2011}", "\u{2012}", "\u{2013}", "\u{2014}", "\u{00A0}", "\u{202F}", "\u{2009}"] {
            XCTAssertTrue(FruitfolioHormoneResearchMatch.contains(.amh, in: "Anti\(separator)Müllerian hormone testing context"), "Missed literal AMH name with separator \(separator.unicodeScalars.map(\.value))")
            XCTAssertTrue(FruitfolioHormoneResearchMatch.contains(.fsh, in: "follicle\(separator)stimulating hormone testing context"), "Missed literal FSH name with separator \(separator.unicodeScalars.map(\.value))")
        }
    }

    func testUnicodeNameSeparatorsDoNotRelaxClinicalWordBoundariesOrInventAliases() {
        for text in ["preanti–mullerian", "anti–mulleriansuffix", "mullerian development", "anti signal and mullerian mention", "anti/mullerian"] {
            XCTAssertFalse(FruitfolioHormoneResearchMatch.contains(.amh, in: text))
        }
        for text in ["prefollicle–stimulating", "follicle–stimulatingness", "a follicle grows", "follicle/stimulating", "FSHword"] {
            XCTAssertFalse(FruitfolioHormoneResearchMatch.contains(.fsh, in: text))
        }
        XCTAssertFalse(FruitfolioHormoneResearchMatch.contains(.other, in: "Anti–Müllerian hormone"))
    }

    func testActualProviderPreservesUnicodeParagraphBytesAndCannotBypassEligibilityOrApproval() async throws {
        for approved in [true, false] {
        for eligible in [true, false] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let paragraph = "Anti\u{2011}Müllerian hormone testing context fixture label. No medical assertion."
            let source = FruitfolioResearchSource(sourceID: "punctuation-fixture", title: "Nonclinical punctuation fixture", authors: nil, organization: nil,
                publicationDate: nil, publicationType: nil, canonicalURL: nil, doi: nil,
                apa7Reference: approved ? "Fixture reference, not medical evidence" : nil,
                verificationStatus: approved ? "verified" : "unresolved", retrievalEligibility: approved,
                sourceVersion: "fixture-v1", verifiedAt: nil, contentVersion: "fixture-v1")
            let note = FruitfolioResearchNoteChunk(chunkID: "punctuation-note", researchTopicID: "punctuation-fixture", heading: "Nonclinical punctuation label", subheading: nil,
                text: paragraph, sourceIDs: [source.sourceID], semanticTags: [], domainTags: [], retrievalEligibility: eligible, sourceParagraphID: "punctuation-paragraph")
            var package = FruitfolioResearchPackage(schemaVersion: 1, contentVersion: "fixture-v1", generatedFrom: "test", generationNote: "Synthetic punctuation/approval boundary only, not clinical evidence",
                researchNoteChunks: [note], sources: [source], sourceChunks: [])
            package.sourceParagraphs = ["punctuation-paragraph": paragraph]
            let url = directory.appendingPathComponent("research.json")
            try JSONEncoder().encode(package).write(to: url)
            let provider = FruitfolioHormoneLibraryProvider(packageStore: .init(resourceURL: url))
            let article = try await provider.article(for: .amh)
            XCTAssertEqual(article.excerpts.count, approved && eligible ? 1 : 0)
            if let excerpt = article.excerpts.first {
                XCTAssertEqual(Data(excerpt.originalText.utf8), Data(paragraph.utf8))
                XCTAssertEqual(excerpt.heading, note.heading)
                XCTAssertEqual(excerpt.sources.map(\.id), [source.sourceID])
                XCTAssertEqual(excerpt.sources.first?.title, source.apa7Reference)
                XCTAssertEqual(excerpt.section, .testingContext)
            }
        }
        }
    }

}
