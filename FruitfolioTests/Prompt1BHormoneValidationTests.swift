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
    func testLocaleSpecificDecimalAndDigitValidationNeverRewritesTheReportedValue() throws {
        for (input, locale) in [("12,50", "de_DE"), ("١٢٫٥٠", "ar_EG"), ("1.25e2", "en_US"), (".5", "en_US"), (",5", "de_DE")] {
            var measurement = FruitfolioHormoneMeasurement()
            measurement.result = input; measurement.unit = "µIU/mL"
            try measurement.validate(locale: Locale(identifier: locale))
            XCTAssertEqual(measurement.result, input)
            XCTAssertEqual(measurement.unit, "µIU/mL")
        }
        var measurement = FruitfolioHormoneMeasurement(); measurement.unit = "ng/mL"
        for input in ["1,234.5", "12,50", "12.5junk", "²"] {
            measurement.result = input
            XCTAssertThrowsError(try measurement.validate(locale: Locale(identifier: "en_US")))
        }
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
