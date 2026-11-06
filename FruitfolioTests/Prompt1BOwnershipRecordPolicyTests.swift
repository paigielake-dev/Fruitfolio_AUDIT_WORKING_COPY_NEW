import XCTest
@testable import Fruitfolio

final class Prompt1BOwnershipRecordPolicyTests: XCTestCase {
    func testProductionAndTestRecordsStayDistinctAndUnknownEnvironmentDoesNotGrantVerifiedStatus() {
        XCTAssertEqual(FruitfolioOwnershipRecordPolicy.evaluate(signatureVerified: true, bundleIdentifier: "test.app",
            expectedBundleIdentifier: "test.app", environment: .production), .verifiedProductionInstallation)
        XCTAssertEqual(FruitfolioOwnershipRecordPolicy.evaluate(signatureVerified: true, bundleIdentifier: "test.app",
            expectedBundleIdentifier: "test.app", environment: .test), .verifiedTestInstallation)
        XCTAssertEqual(FruitfolioOwnershipRecordPolicy.evaluate(signatureVerified: true, bundleIdentifier: "test.app",
            expectedBundleIdentifier: "test.app", environment: .unknown), .unavailable)
    }
    func testUnverifiedSignatureWrongAppAndMissingExpectedIdentityCannotBecomeOwnershipEvidence() {
        for (verified, bundle, expected) in [(false, "test.app", "test.app"), (true, "other.app", "test.app"), (true, "", "")] {
            XCTAssertEqual(FruitfolioOwnershipRecordPolicy.evaluate(signatureVerified: verified, bundleIdentifier: bundle,
                expectedBundleIdentifier: expected, environment: .production), .unverified)
        }
    }
    #if !canImport(StoreKit)
    func testActualUnavailablePlatformAdapterDoesNotFabricateAReceipt() async {
        let result = await FruitfolioStoreKitOwnershipVerifier().verify(expectedBundleIdentifier: "test.app")
        XCTAssertEqual(result, .unavailable)
    }
    #endif
}
