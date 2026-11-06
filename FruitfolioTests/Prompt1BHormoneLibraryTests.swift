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
            XCTAssertFalse(article.excerpts.isEmpty, "Actual approved corpus should supply at least one \(hormone) excerpt")
            XCTAssertEqual(Set(article.excerpts.map(\.originalText)).count, article.excerpts.count)
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
