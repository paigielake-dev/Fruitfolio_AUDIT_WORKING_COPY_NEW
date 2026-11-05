import XCTest
@testable import Fruitfolio

final class Prompt1BHormoneAdjustmentTests: XCTestCase {
    func testOptInCannotTurnMeasurementsIntoAnUnreviewedCurve() {
        let original = Prompt22HormoneRhythmEngine().presentation(for: .neutral)
        for requested in [false, true] {
            for count in [0, 1, 20] {
                for unreadable in [false, true] {
                    let decision = FruitfolioHormoneAdjustmentPolicy.decision(requested: requested,
                        measurementCount: count, storageUnreadable: unreadable)
                    XCTAssertFalse(decision.appliesAdjustment)
                    XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.presentation(preserving: original, decision: decision), original)
                }
            }
        }
    }
    func testMissingMeasurementsCorruptStorageAndMissingClinicalMethodStayDistinct() {
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: false, measurementCount: 1, storageUnreadable: false), .original)
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: true, measurementCount: 0, storageUnreadable: false), .noMeasurements)
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: true, measurementCount: 1, storageUnreadable: true), .measurementsUnavailable)
        XCTAssertEqual(FruitfolioHormoneAdjustmentPolicy.decision(requested: true, measurementCount: 20, storageUnreadable: false), .reviewedMethodUnavailable)
    }
}
