import XCTest
@testable import Fruitfolio

final class Prompt1BCitationDestinationTests: XCTestCase {
    func testSuppliedHTTPSDestinationIsPreservedWithoutInventedLookup() {
        let supplied = "https://example.org/paper?id=42#results"
        XCTAssertEqual(Prompt09CitationDestination.url(sourceURL: supplied, doi: nil)?.absoluteString, supplied)
        for invalid in ["file:///private/record", "javascript:alert(1)", "https://name:secret@example.org/", "not a URL", "http://example.org/"] {
            XCTAssertNil(Prompt09CitationDestination.url(sourceURL: invalid, doi: nil))
        }
    }
    func testDOIResolutionPreservesIdentifierAndEncodesReservedSuffixCharacters() throws {
        for identifier in ["10.1000/ABC.def", "doi: 10.1000/ABC.def", "https://doi.org/10.1000/ABC.def"] {
            XCTAssertEqual(Prompt09CitationDestination.url(sourceURL: nil, doi: identifier)?.absoluteString,
                           "https://doi.org/10.1000/ABC.def")
        }
        let url = try XCTUnwrap(Prompt09CitationDestination.url(sourceURL: nil, doi: "10.1000/a?b#c"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/10.1000/a?b#c")
        XCTAssertNil(components.query)
        XCTAssertNil(components.fragment)
        for invalid in ["10.12/short", "10.1000/", "10.1000/white space", "a source title", "https://doi.org/10.1000/a?ambiguous"] {
            XCTAssertNil(Prompt09CitationDestination.url(sourceURL: nil, doi: invalid))
        }
    }
}
