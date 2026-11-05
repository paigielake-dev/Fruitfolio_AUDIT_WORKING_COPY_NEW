import XCTest
@testable import Fruitfolio

final class Prompt1BLifeBridgeTests: XCTestCase {
    func testDiscoveryAndFounderSpecifiedDestinationsAreExact() {
        XCTAssertTrue(FruitfolioLifeBridgeInformation.isDiscoverable(for: "tell me about surrogacy support"))
        XCTAssertTrue(FruitfolioLifeBridgeInformation.isOrganizationQuestion("LifeBridge eligibility"))
        XCTAssertFalse(FruitfolioLifeBridgeInformation.isOrganizationQuestion("what is progesterone?"))
        XCTAssertEqual(FruitfolioLifeBridgeInformation.officialURL?.absoluteString, "https://lifebridgesurrogacy.com/")
        XCTAssertEqual(FruitfolioLifeBridgeInformation.founderURL?.absoluteString, "https://fruitsoflifexo.carrd.co/")
    }
    func testOneWebsiteCannotStandInForBothRequiredSources() throws {
        let date = Date(timeIntervalSince1970: 1_000)
        let source = FruitfolioLifeBridgeSnapshot(id: "official", title: "fixture", sourceURL: try XCTUnwrap(FruitfolioLifeBridgeInformation.officialURL),
            retrievedAt: date, reviewedAt: date, version: "fixture", approvedText: "fixture only")
        XCTAssertFalse(FruitfolioLifeBridgeContent(snapshots: [source], officialApplicationURL: nil, relationshipDisclosure: nil).validate())
    }
}
