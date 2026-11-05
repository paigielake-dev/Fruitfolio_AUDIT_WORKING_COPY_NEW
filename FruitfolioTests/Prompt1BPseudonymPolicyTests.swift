import XCTest
@testable import Fruitfolio

final class Prompt1BPseudonymPolicyTests: XCTestCase {
    func testRawNameIsRejectedRatherThanSilentlyRewritten() {
        XCTAssertNotNil(FruitfolioPseudonymPolicy.validationMessage(for: "Real Name", confirmedNonIdentifying: true))
        XCTAssertNotNil(FruitfolioPseudonymPolicy.validationMessage(for: "berry💜", confirmedNonIdentifying: true))
        XCTAssertNotNil(FruitfolioPseudonymPolicy.validationMessage(for: String(repeating: "b", count: 17), confirmedNonIdentifying: true))
        XCTAssertNotNil(FruitfolioPseudonymPolicy.validationMessage(for: "berry_12", confirmedNonIdentifying: false))
        XCTAssertNil(FruitfolioPseudonymPolicy.validationMessage(for: "berry_12", confirmedNonIdentifying: true))
    }
    func testKnownPrivateIdentityCannotBeUsedEvenWithConfirmation() {
        for name in ["Paige_22", "LAKE123", "ＰＡＩＧＥ22"] {
            XCTAssertNotNil(FruitfolioPseudonymPolicy.validationMessage(for: name, confirmedNonIdentifying: true,
                identifyingText: ["paige.lake@example.org"]))
        }
        XCTAssertNil(FruitfolioPseudonymPolicy.validationMessage(for: "berry_12", confirmedNonIdentifying: true,
            identifyingText: ["paige.lake@example.org"]))
    }
    func testExplicitNamesRemainRejectedAndUnknownIdentityCannotBeInferred() {
        XCTAssertNotNil(FruitfolioPseudonymPolicy.validationMessage(for: "f4ck", confirmedNonIdentifying: true))
        // Unknown legal names cannot be verified locally without collecting
        // additional identity data; confirmation is not proof of anonymity.
        XCTAssertNil(FruitfolioPseudonymPolicy.validationMessage(for: "arbitrary12", confirmedNonIdentifying: true))
    }
}
