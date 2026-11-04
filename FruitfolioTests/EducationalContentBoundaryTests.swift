import XCTest
@testable import Fruitfolio

@MainActor
final class EducationalContentBoundaryTests: XCTestCase {
    private func pregnancy(id: String = "pregnancy.testing.core", title: String = "pregnancy testing",
                           summary: String = "Injected structural test fixture, not clinical evidence.",
                           sections: [Prompt26ApprovedSection] = [],
                           sources: [String] = ["fixture-source"]) -> Prompt26ApprovedContent {
        Prompt26ApprovedContent(contentID: id, title: title, summary: summary,
                                sections: sections, sourceIDs: sources)
    }

    func testPregnancyBridgeRejectsWrongTopicBlankContentAndUnassociatedSectionCitations() async {
        let section = Prompt26ApprovedSection(id: "timing", heading: "timing",
                                             body: "Fixture only.", sourceIDs: ["unassociated-source"])
        let invalid = [pregnancy(id: "pregnancy.placenta.core"), pregnancy(title: " \n"),
                       pregnancy(summary: "\t"), pregnancy(sources: []),
                       pregnancy(sources: [" "]), pregnancy(sources: ["fixture-source", "fixture-source"]),
                       pregnancy(sections: [section]),
                       pregnancy(sections: [.init(id: "blank", heading: "title", body: " ", sourceIDs: ["fixture-source"])])]
        for content in invalid {
            let provider = Prompt26ClosureResearchProvider { _ in content }
            do {
                _ = try await provider.approvedContent(for: "pregnancy.testing.core")
                XCTFail("Invalid or incorrectly associated content must not reach the view")
            } catch {
                XCTAssertEqual(error as? Prompt26ResearchBridgeError, .invalidApprovedContent)
            }
        }
    }

    func testPregnancyBridgePreservesValidSectionsAndSourceAssociationsVerbatim() async throws {
        let expected = pregnancy(sections: [.init(id: "testing.timing", heading: "timing",
                                                  body: "Fixture with 2.50 units and [fixture-source].",
                                                  sourceIDs: ["fixture-source"])])
        let provider = Prompt26ClosureResearchProvider { _ in expected }
        let actual = try await provider.approvedContent(for: expected.contentID)
        XCTAssertEqual(actual, expected)
    }

    func testScienceBridgeRejectsBlankAndDuplicateSourceIdentifiersAndWrongTopic() async {
        let invalid = [
            Prompt27ApprovedScienceContent(contentID: "other", title: "DNA", body: "Fixture.", sourceIDs: ["s"]),
            Prompt27ApprovedScienceContent(contentID: "dna", title: " ", body: "Fixture.", sourceIDs: ["s"]),
            Prompt27ApprovedScienceContent(contentID: "dna", title: "DNA", body: "\n", sourceIDs: ["s"]),
            Prompt27ApprovedScienceContent(contentID: "dna", title: "DNA", body: "Fixture.", sourceIDs: [" "]),
            Prompt27ApprovedScienceContent(contentID: "dna", title: "DNA", body: "Fixture.", sourceIDs: ["s", "s"])
        ]
        for content in invalid {
            let provider = Prompt27ClosureScienceResearchProvider { _ in content }
            do {
                _ = try await provider.approvedContent(for: "dna")
                XCTFail("Invalid research payload must fail closed")
            } catch {
                XCTAssertEqual(error as? Prompt27ScienceLoadFailure, .invalidApprovedContent)
            }
        }
    }

    func testPregnancyViewModelRevalidatesArbitraryProvidersBeforePublishing() async throws {
        let model = Prompt26PregnancyEducationViewModel(
            topic: Prompt26PregnancyEducationCatalog.topic(.testing),
            provider: UncheckedPregnancyProvider(content: pregnancy(id: "wrong-topic")))
        model.loadIfNeeded()
        for _ in 0..<100 {
            if case .unavailable = model.state { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(model.state, .unavailable)
        XCTAssertNil(model.loadedContent)
    }

    func testScienceViewModelRevalidatesArbitraryProvidersBeforePublishing() async throws {
        let section = Prompt27ContextualScienceSection(id: "dna", title: "DNA", bodyContentID: "dna",
                                                      primaryVisualFamily: .none,
                                                      primaryIllustrationAssetID: nil, altText: "")
        let content = Prompt27ApprovedScienceContent(contentID: "wrong-topic", title: "DNA",
                                                    body: "Fixture.", sourceIDs: ["s"])
        let model = Prompt27ScienceViewModel(section: section,
                                             provider: UncheckedScienceProvider(content: content))
        model.loadIfNeeded()
        for _ in 0..<100 {
            if case .unavailable = model.state { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(model.state, .unavailable)
        XCTAssertNil(model.loadedContent)
    }
}

private struct UncheckedPregnancyProvider: Prompt26PregnancyResearchProviding {
    let content: Prompt26ApprovedContent
    func approvedContent(for contentID: String) async throws -> Prompt26ApprovedContent { content }
}

private struct UncheckedScienceProvider: Prompt27ScienceResearchProviding {
    let content: Prompt27ApprovedScienceContent
    func approvedContent(for contentID: String) async throws -> Prompt27ApprovedScienceContent { content }
}
