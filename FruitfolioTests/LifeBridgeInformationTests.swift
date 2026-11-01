import XCTest
@testable import Fruitfolio

final class LifeBridgeInformationTests: XCTestCase {
    func testOnlyTheExactFounderNamedDestinationsAreExposedWithoutUserOrReferralData() {
        XCTAssertEqual(LifeBridgeInformation.Destination.allCases.map(\.url.absoluteString), [
            "https://lifebridgesurrogacy.com/", "https://fruitsoflifexo.carrd.co/", "https://www.instagram.com/fruitsoflife.xo/"
        ])
        for destination in LifeBridgeInformation.Destination.allCases {
            XCTAssertEqual(destination.url.scheme, "https")
            XCTAssertNil(URLComponents(url: destination.url, resolvingAgainstBaseURL: false)?.query)
            XCTAssertNil(destination.url.user); XCTAssertNil(destination.url.password)
        }
    }
    func testUnavailableDetailsRemainExplicitAndCannotInventEligibilityOrRelationship() throws {
        XCTAssertEqual(LifeBridgeInformation.contentStatus, "awaiting_verified_lifebridge_content")
        XCTAssertEqual(LifeBridgeInformation.unavailable, "details not available in the approved library yet")
        XCTAssertEqual(Set(LifeBridgeInformation.ContentSlot.allCases.map(\.rawValue)),
                       Set(["overview", "services", "audience", "eligibilityAndProcess", "contact", "founderRelationship"]))
        let url = try XCTUnwrap(Bundle.main.url(forResource: "LifeBridgeApprovedSourceDirectory", withExtension: "json"))
        let directory = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        XCTAssertEqual(directory["status"] as? String, LifeBridgeInformation.contentStatus)
        XCTAssertEqual(directory["medicalRetrievalEligible"] as? Bool, false)
        let sources = try XCTUnwrap(directory["sources"] as? [[String: Any]])
        XCTAssertEqual(sources.count, 3)
        XCTAssertEqual(sources.compactMap { $0["url"] as? String }, LifeBridgeInformation.Destination.allCases.map(\.url.absoluteString))
        XCTAssertTrue(sources.allSatisfy { $0["snapshot"] is NSNull })
        let privacy = try XCTUnwrap(directory["privacy"] as? [String: Bool])
        XCTAssertEqual(privacy["inferenceNetworkFetch"], false)
        XCTAssertEqual(privacy["healthDataURLParameters"], false)
        XCTAssertEqual(privacy["automaticEnrollment"], false)
        XCTAssertEqual(privacy["externalNavigationRequiresUserConfirmation"], true)
    }
    func testDiscoveryDoesNotInterceptUnrelatedOrGeneralMedicalQuestions() {
        for q in ["What is LifeBridge?", "LIFEBRIDGE", "life-bridge information", "Where is surrogacy support?"] {
            XCTAssertTrue(LifeBridgeInformation.isDiscoveryQuery(q), q)
        }
        for q in ["", "How does implantation work?", "What are surrogacy risks?", "thyroid history", "ovulation"] {
            XCTAssertFalse(LifeBridgeInformation.isDiscoveryQuery(q), q)
        }
    }
}
