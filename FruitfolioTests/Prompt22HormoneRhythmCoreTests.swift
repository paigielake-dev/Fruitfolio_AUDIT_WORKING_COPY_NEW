import XCTest
@testable import Fruitfolio

final class Prompt22CoreTests: XCTestCase {
    func testExactTitleAndSubtitle() {
        let presentation =
            Prompt22HormoneRhythmEngine()
                .presentation(for: .neutral)

        XCTAssertEqual(presentation.title, "hormone rhythm")
        XCTAssertEqual(
            presentation.subtitle,
            "general patterns, not measured hormone levels ♡"
        )
    }

    func testAllThreeHormonesAreDistinctAndPresent() {
        let presentation =
            Prompt22HormoneRhythmEngine()
                .presentation(for: .neutral)

        XCTAssertEqual(
            presentation.sections.map(\.hormone),
            [.estrogen, .progesterone, .testosterone]
        )
        XCTAssertEqual(
            Set(presentation.sections.map(\.assetName)).count,
            3
        )
    }

    func testTestosteroneUsesCanonicalAsset() {
        let section =
            Prompt22HormoneRhythmEngine()
                .presentation(for: .neutral)
                .sections
                .first { $0.hormone == .testosterone }

        XCTAssertEqual(
            section?.assetName,
            Prompt22HormoneAsset.testosterone
        )
    }

    func testAllSevenCanonicalHormoneAssetsAreRegistered() {
        XCTAssertEqual(
            Set(Prompt22HormoneAsset.allCanonicalAssetNames),
            Set([
                "hormone_estrogen",
                "hormone_decrease_arrow",
                "hormone_progesterone",
                "hormone_testosterone",
                "hormone_increase_arrow",
                "hormone_blood_cells",
                "hormone_accent_marks"
            ])
        )
    }

    func testInsufficientContextNeverGetsMarker() {
        let input = Prompt22HormoneRhythmInput(
            context: .insufficient,
            contextKind: .educational,
            cycleDay: nil,
            confidence: .unavailable,
            personalizationPermitted: true
        )

        XCTAssertNil(
            Prompt22HormoneRhythmEngine()
                .contextMarkerX(for: input)
        )
    }

    func testAlteredContextNeverGetsMarker() {
        let input = Prompt22HormoneRhythmInput(
            context: .alteredNaturalCycleContext,
            contextKind: .educational,
            cycleDay: 8,
            estimatedCycleLength: 28,
            estimatedCycleProgress: 0.26,
            confidence: .developing,
            personalizationPermitted: false
        )

        let presentation =
            Prompt22HormoneRhythmEngine()
                .presentation(for: input)

        XCTAssertFalse(presentation.showsContextMarker)
        XCTAssertTrue(
            presentation.contextNote?
                .contains("no current-position marker") == true
        )
    }

    func testPrompt17ProgressDrivesContinuousMarkerPosition() {
        let input = Prompt22HormoneRhythmInput(
            context: .follicularLater,
            contextKind: .calculated,
            cycleDay: 10,
            estimatedCycleLength: 31,
            estimatedCycleProgress: 0.30,
            confidence: .strong,
            personalizationPermitted: true
        )

        let markerX = Prompt22HormoneRhythmEngine()
            .contextMarkerX(for: input)

        XCTAssertNotNil(markerX)
        XCTAssertEqual(markerX ?? -1, 0.30, accuracy: 0.000_001)
    }

    func testCycleDayAndEstimatedLengthProvideContinuousFallback() {
        let input = Prompt22HormoneRhythmInput(
            context: .follicularEarly,
            contextKind: .calculated,
            cycleDay: 5,
            estimatedCycleLength: 29,
            confidence: .developing,
            personalizationPermitted: true
        )

        let markerX = Prompt22HormoneRhythmEngine()
            .contextMarkerX(for: input)

        XCTAssertNotNil(markerX)
        XCTAssertEqual(markerX ?? -1, 4.0 / 28.0, accuracy: 0.000_001)
    }

    func testEstimatedOvulationMarkerUsesSameTimelineXAcrossHormones() {
        let input = Prompt22HormoneRhythmInput(
            context: .estimatedOvulation,
            contextKind: .estimated,
            cycleDay: 15,
            estimatedCycleLength: 30,
            estimatedCycleProgress: 14.0 / 29.0,
            confidence: .developing,
            personalizationPermitted: true
        )

        let presentation =
            Prompt22HormoneRhythmEngine()
                .presentation(for: input)

        XCTAssertTrue(presentation.showsContextMarker)
        XCTAssertEqual(
            presentation.contextNote,
            "around where you may be in your cycle"
        )

        let markerXs = presentation.sections.compactMap { $0.marker?.x }
        XCTAssertEqual(markerXs.count, 3)
        XCTAssertEqual(Set(markerXs).count, 1)
    }

    func testMarkerYIsInterpolatedFromEachEducationalCurve() {
        let engine = Prompt22HormoneRhythmEngine()
        let x = 0.40

        let estrogenY = engine.educationalCurveY(
            at: x,
            in: engine.educationalPattern(for: .estrogen)
        )
        let progesteroneY = engine.educationalCurveY(
            at: x,
            in: engine.educationalPattern(for: .progesterone)
        )

        XCTAssertNotNil(estrogenY)
        XCTAssertNotNil(progesteroneY)
        XCTAssertNotEqual(estrogenY, progesteroneY)
        XCTAssertTrue((0 ... 1).contains(estrogenY ?? -1))
        XCTAssertTrue((0 ... 1).contains(progesteroneY ?? -1))
    }

    func testMarkerYMatchesKnownLinearInterpolation() {
        let points = [
            Prompt22NormalizedPoint(x: 0.0, y: 0.2),
            Prompt22NormalizedPoint(x: 1.0, y: 0.8)
        ]

        let y = Prompt22HormoneRhythmEngine()
            .educationalCurveY(at: 0.5, in: points)

        XCTAssertNotNil(y)
        XCTAssertEqual(y ?? -1, 0.5, accuracy: 0.000_001)
    }

    func testCoordinatesRemainNormalizedPresentationGeometry() {
        let engine = Prompt22HormoneRhythmEngine()

        for hormone in Prompt22Hormone.allCases {
            let points = engine.educationalPattern(for: hormone)
            XCTAssertFalse(points.isEmpty)

            for point in points {
                XCTAssertTrue((0 ... 1).contains(point.x))
                XCTAssertTrue((0 ... 1).contains(point.y))
            }
        }
    }

    func testContextMarkerCoordinatesRemainNormalized() {
        let input = Prompt22HormoneRhythmInput(
            context: .luteal,
            contextKind: .calculated,
            cycleDay: 24,
            estimatedCycleLength: 31,
            estimatedCycleProgress: 0.77,
            confidence: .strong,
            personalizationPermitted: true
        )

        let presentation = Prompt22HormoneRhythmEngine()
            .presentation(for: input)

        for section in presentation.sections {
            let marker = section.marker
            XCTAssertNotNil(marker)
            XCTAssertTrue((0 ... 1).contains(marker?.x ?? -1))
            XCTAssertTrue((0 ... 1).contains(marker?.y ?? -1))
            XCTAssertEqual(marker?.confidence, .strong)
        }
    }

    func testTestosteronePatternIsVisuallySubtler() {
        let engine = Prompt22HormoneRhythmEngine()
        let estrogen = engine.educationalPattern(for: .estrogen)
        let progesterone = engine.educationalPattern(for: .progesterone)
        let testosterone = engine.educationalPattern(for: .testosterone)

        func amplitude(
            _ values: [Prompt22NormalizedPoint]
        ) -> Double {
            let ys = values.map(\.y)
            return (ys.max() ?? 0) - (ys.min() ?? 0)
        }

        XCTAssertLessThan(
            amplitude(testosterone),
            amplitude(estrogen)
        )
        XCTAssertLessThan(
            amplitude(testosterone),
            amplitude(progesterone)
        )
    }

    func testApprovedResearchCopyOverridesNeutralFallback() {
        let copy = Prompt22HormoneEducationalCopy(
            summary: "approved local research copy",
            researchIDs: ["research-1"]
        )

        let input = Prompt22HormoneRhythmInput(
            context: .follicularEarly,
            contextKind: .calculated,
            cycleDay: 5,
            estimatedCycleLength: 29,
            estimatedCycleProgress: 4.0 / 28.0,
            confidence: .developing,
            personalizationPermitted: true,
            copyByHormone: [.estrogen: copy]
        )

        let estrogen =
            Prompt22HormoneRhythmEngine()
                .presentation(for: input)
                .sections
                .first { $0.hormone == .estrogen }

        XCTAssertEqual(
            estrogen?.summary,
            "approved local research copy"
        )
        XCTAssertEqual(
            estrogen?.researchIDs,
            ["research-1"]
        )
    }

    func testPresentationDoesNotContainFakeUnitsOrDiagnosticTerms() {
        let presentation =
            Prompt22HormoneRhythmEngine()
                .presentation(for: .neutral)

        let text = (
            [presentation.title, presentation.subtitle] +
            presentation.sections.flatMap {
                [$0.title, $0.summary, $0.accessibilitySummary]
            }
        )
        .joined(separator: " ")
        .lowercased()

        for forbidden in [
            "pg/ml",
            "ng/dl",
            "estrogen dominance",
            "progesterone deficiency",
            "testosterone deficiency",
            "hormonal imbalance",
            "your estrogen is",
            "your progesterone is",
            "your testosterone is"
        ] {
            XCTAssertFalse(
                text.contains(forbidden),
                "Unexpected forbidden language: \(forbidden)"
            )
        }
    }

    func testPrompt17TimelinePositionKeepsMarkerVisibleWhenSemanticContextIsNeutral() {
        let input = Prompt22HormoneRhythmInput(
            context: .insufficient,
            contextKind: .educational,
            cycleDay: 8,
            estimatedCycleLength: 28,
            estimatedCycleProgress: 7.0 / 27.0,
            confidence: .developing,
            personalizationPermitted: true
        )

        let presentation = Prompt22HormoneRhythmEngine()
            .presentation(for: input)

        XCTAssertTrue(presentation.showsContextMarker)
        XCTAssertEqual(
            presentation.sections.first?.marker?.x ?? -1,
            7.0 / 27.0,
            accuracy: 0.000_001
        )
        XCTAssertTrue(presentation.sections.allSatisfy { $0.marker != nil })
    }

    func testAlteredNaturalCycleContextStillSuppressesMarkerEvenWithTimelinePosition() {
        let input = Prompt22HormoneRhythmInput(
            context: .alteredNaturalCycleContext,
            contextKind: .educational,
            cycleDay: 8,
            estimatedCycleLength: 28,
            estimatedCycleProgress: 7.0 / 27.0,
            confidence: .developing,
            personalizationPermitted: true
        )

        let presentation = Prompt22HormoneRhythmEngine()
            .presentation(for: input)

        XCTAssertFalse(presentation.showsContextMarker)
        XCTAssertTrue(presentation.sections.allSatisfy { $0.marker == nil })
    }


    func testCurrentCycleDayKeepsMarkerAvailableWithoutEstimatedLength() {
        let input = Prompt22HormoneRhythmInput(
            context: .insufficient,
            contextKind: .calculated,
            cycleDay: 7,
            confidence: .limited,
            personalizationPermitted: true
        )
        let x = Prompt22HormoneRhythmEngine().contextMarkerX(for: input)
        XCTAssertNotNil(x)
        XCTAssertEqual(x ?? -1, 6.0 / 27.0, accuracy: 0.000_001)
    }

}
