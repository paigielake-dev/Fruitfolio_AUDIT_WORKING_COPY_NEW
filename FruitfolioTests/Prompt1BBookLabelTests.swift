import XCTest
@testable import Fruitfolio

final class Prompt1BBookLabelTests: XCTestCase {
    func testClinicalAndSexualHealthLabelsAreAllowedWithoutSubstringRejection() throws {
        for title in ["sexual health", "sex education", "consent after trauma", "rape recovery", "breast and cervical health", "assessment", "classical genetics"] {
            XCTAssertEqual(try Prompt10BookLabelPolicy.title(title), title)
        }
    }
    func testLimitsCountGraphemesAndNeverSilentlyTruncate() throws {
        let title = String(repeating: "👩🏽‍⚕️", count: 48)
        XCTAssertEqual(try Prompt10BookLabelPolicy.title(title), title)
        XCTAssertThrowsError(try Prompt10BookLabelPolicy.title(title + "a"))
        XCTAssertEqual(try Prompt10BookLabelPolicy.description(String(repeating: "é", count: 160)).count, 160)
        XCTAssertThrowsError(try Prompt10BookLabelPolicy.description(String(repeating: "é", count: 161)))
        XCTAssertThrowsError(try Prompt10BookLabelPolicy.title(" \n "))
    }
    func testExplicitLabelsAndThreatsRejectedWithCaseWidthNormalization() {
        for text in ["FUCK", "ｓｈｉｔ", "kill yourself", "I will murder you", "my asshole guide"] {
            XCTAssertThrowsError(try Prompt10BookLabelPolicy.title(text))
            XCTAssertThrowsError(try Prompt10BookLabelPolicy.description(text))
        }
    }
}
