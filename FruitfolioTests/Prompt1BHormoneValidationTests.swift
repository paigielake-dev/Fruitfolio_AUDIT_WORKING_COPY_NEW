import XCTest
@testable import Fruitfolio

final class Prompt1BHormoneValidationTests: XCTestCase {
    func testValidationPreservesDecimalAndExactUnit() throws {
        var measurement = FruitfolioHormoneMeasurement()
        measurement.result = "12.50"
        measurement.unit = "pg/mL"
        try measurement.validate(locale: Locale(identifier: "en_US"))
        XCTAssertEqual(measurement.result, "12.50")
        XCTAssertEqual(measurement.unit, "pg/mL")
    }
    func testMalformedAndMissingRequiredFieldsAreRejected() {
        var measurement = FruitfolioHormoneMeasurement()
        measurement.unit = "ng/mL"
        for input in ["", "12invalid", "-1", "NaN", "infinity"] {
            measurement.result = input
            XCTAssertThrowsError(try measurement.validate(locale: Locale(identifier: "en_US")))
        }
        measurement.result = "1.25"
        measurement.unit = " "
        XCTAssertThrowsError(try measurement.validate())
    }
    func testOtherHormoneRequiresNameAndCycleDayMustBePositive() {
        var measurement = FruitfolioHormoneMeasurement()
        measurement.result = "1.25"; measurement.unit = "ng/mL"
        measurement.hormone = .other
        XCTAssertThrowsError(try measurement.validate(locale: Locale(identifier: "en_US")))
        measurement.otherHormoneName = "reported hormone"
        measurement.cycleDay = 0
        XCTAssertThrowsError(try measurement.validate(locale: Locale(identifier: "en_US")))
        measurement.cycleDay = nil
        XCTAssertNoThrow(try measurement.validate(locale: Locale(identifier: "en_US")))
    }
}
