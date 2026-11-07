import XCTest
@testable import Fruitfolio

final class Prompt1BLifeBridgeTests: XCTestCase {
    private func snapshot(id: String = "official", url: URL? = FruitfolioLifeBridgeInformation.officialURL,
        title: String = "nonclinical validation fixture", version: String = "fixture",
        text: String = "nonclinical URL validation only", retrieved: Date = Date(timeIntervalSince1970: 1_000),
        reviewed: Date = Date(timeIntervalSince1970: 2_000)) throws -> FruitfolioLifeBridgeSnapshot {
        .init(id: id, title: title, sourceURL: try XCTUnwrap(url), retrievedAt: retrieved,
            reviewedAt: reviewed, version: version, approvedText: text)
    }
    private func content(official: FruitfolioLifeBridgeSnapshot? = nil,
        founder: FruitfolioLifeBridgeSnapshot? = nil, application: URL? = nil) throws -> FruitfolioLifeBridgeContent {
        .init(snapshots: [try official ?? snapshot(),
            try founder ?? snapshot(id: "founder", url: FruitfolioLifeBridgeInformation.founderURL)],
            officialApplicationURL: application, relationshipDisclosure: nil)
    }
    func testSourceURLsRejectCredentialsAndNonOfficialServicePorts() throws {
        XCTAssertTrue(try content().validate())
        for raw in ["https://user:secret@lifebridgesurrogacy.com/", "https://lifebridgesurrogacy.com:8443/"] {
            XCTAssertFalse(try content(official: snapshot(url: URL(string: raw))).validate(), raw)
        }
        for raw in ["https://user@fruitsoflifexo.carrd.co/", "https://fruitsoflifexo.carrd.co:8443/"] {
            XCTAssertFalse(try content(founder: snapshot(id: "founder", url: URL(string: raw))).validate(), raw)
        }
    }
    func testApplicationURLRetainsApprovedReferenceButRejectsCredentialsAndOtherServices() throws {
        let allowed = try XCTUnwrap(URL(string: "https://lifebridgesurrogacy.com:443/apply?ref=approved-fixture#form"))
        let approved = try content(application: allowed)
        XCTAssertTrue(approved.validate())
        XCTAssertEqual(approved.officialApplicationURL, allowed)
        for raw in ["https://user:secret@lifebridgesurrogacy.com/apply", "https://lifebridgesurrogacy.com:8443/apply",
            "http://lifebridgesurrogacy.com/apply", "https://lifebridgesurrogacy.com.evil.example/apply"] {
            XCTAssertFalse(try content(application: URL(string: raw)).validate(), raw)
        }
    }
    func testBlankReviewMetadataAndNonfiniteDatesCannotMasqueradeAsReviewedContent() throws {
        let invalid = [try snapshot(id: " \n"), try snapshot(title: " \t"), try snapshot(version: "\n"),
            try snapshot(text: " \n"), try snapshot(retrieved: Date(timeIntervalSinceReferenceDate: -.infinity)),
            try snapshot(retrieved: Date(timeIntervalSinceReferenceDate: -.infinity), reviewed: Date(timeIntervalSinceReferenceDate: -.infinity))]
        for source in invalid { XCTAssertFalse(try content(official: source).validate()) }
        XCTAssertFalse(try content().validate(now: Date(timeIntervalSinceReferenceDate: .infinity)))
    }

    func testDiscoveryAndFounderSpecifiedDestinationsAreExact() {
        XCTAssertTrue(FruitfolioLifeBridgeInformation.isDiscoverable(for: "tell me about surrogacy support"))
        XCTAssertTrue(FruitfolioLifeBridgeInformation.isOrganizationQuestion("LifeBridge eligibility"))
        XCTAssertFalse(FruitfolioLifeBridgeInformation.isOrganizationQuestion("what is progesterone?"))
        XCTAssertEqual(FruitfolioLifeBridgeInformation.officialURL?.absoluteString, "https://lifebridgesurrogacy.com/")
        XCTAssertEqual(FruitfolioLifeBridgeInformation.founderURL?.absoluteString, "https://fruitsoflifexo.carrd.co/")
        XCTAssertEqual(FruitfolioLifeBridgeInformation.founderInstagramURL?.absoluteString, "https://www.instagram.com/fruitsoflife.xo/")
    }
    func testInstagramCannotReplaceRequiredLifeBridgeAndCarrdSnapshots() throws {
        let instagram = try snapshot(id: "instagram", url: FruitfolioLifeBridgeInformation.founderInstagramURL)
        for missing in [FruitfolioLifeBridgeContent(snapshots: [instagram], officialApplicationURL: nil, relationshipDisclosure: nil),
                        FruitfolioLifeBridgeContent(snapshots: [try snapshot(), instagram], officialApplicationURL: nil, relationshipDisclosure: nil),
                        FruitfolioLifeBridgeContent(snapshots: [try snapshot(id: "founder", url: FruitfolioLifeBridgeInformation.founderURL), instagram], officialApplicationURL: nil, relationshipDisclosure: nil)] {
            XCTAssertFalse(missing.validate(), "A first-party brand account is not either mandatory organization/source snapshot")
        }
    }

    func testOneWebsiteCannotStandInForBothRequiredSources() throws {
        let date = Date(timeIntervalSince1970: 1_000)
        let source = FruitfolioLifeBridgeSnapshot(id: "official", title: "fixture", sourceURL: try XCTUnwrap(FruitfolioLifeBridgeInformation.officialURL),
            retrievedAt: date, reviewedAt: date, version: "fixture", approvedText: "fixture only")
        XCTAssertFalse(FruitfolioLifeBridgeContent(snapshots: [source], officialApplicationURL: nil, relationshipDisclosure: nil).validate())
    }
}
