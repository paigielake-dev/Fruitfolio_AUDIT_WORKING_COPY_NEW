import XCTest
@testable import Fruitfolio

final class Prompt1BDecorativeLayoutTests: XCTestCase {
    private func place(height: CGFloat = 200, protected: [FruitfolioProtectedRegion] = []) -> FruitfolioDecorativePlacement {
        FruitfolioDecorativeArtLayout.placement(
            intrinsicSize: CGSize(width: 100, height: 100), roleFraction: 0.2...0.8,
            anchor: .bottomTrailing, container: CGRect(x: 0, y: 0, width: 300, height: height),
            safeInsets: FruitfolioArtInsets(), protectedRegions: protected)
    }

    func testHeaderPalettesRetainApprovedSelectionsWithoutSubstitutingMissingFAQArt() {
        XCTAssertEqual(FruitfolioHeaderArtworkPalette.contact.items.map(\.id),
                       [.fruitbasket_plum, .cycledecor_green_flecks, .decor_sparkles_2])
        XCTAssertEqual(FruitfolioHeaderArtworkPalette.settings.items.map(\.id),
                       [.cycledecor_flower, .cycledecor_lavender_droplets, .decor_sparkles_2])
        XCTAssertEqual(FruitfolioHeaderArtworkPalette.faq.items.map(\.id), [.decor_sparkles_1])
        for palette in FruitfolioHeaderArtworkPalette.allCases {
            XCTAssertEqual(palette.placements(in: CGSize(width: 136, height: 128)).first?.id,
                           palette.items.first?.id)
        }
    }

    func testActualHeaderPalettesPreserveRolesAndSeparatePaintedFootprints() throws {
        for palette in FruitfolioHeaderArtworkPalette.allCases {
            let selected = Set(palette.items.map(\.id))
            for width: CGFloat in [0, 12, 60, 100, 136, 240, 320] {
                for height: CGFloat in [0, 30, 128, 240] {
                    let placements = palette.placements(in: CGSize(width: width, height: height))
                    XCTAssertEqual(Set(placements.map(\.id)).count, placements.count)
                    for (index, placement) in placements.enumerated() {
                        XCTAssertTrue(selected.contains(placement.id))
                        let item = try XCTUnwrap(palette.items.first { $0.id == placement.id })
                        XCTAssertEqual(placement.frame.width / placement.frame.height,
                                       item.pixels.width / item.pixels.height, accuracy: 0.00001)
                        XCTAssertEqual(placement.paintedFrame.width / placement.paintedFrame.height,
                                       item.paintedBounds.width / item.paintedBounds.height, accuracy: 0.00001)
                        XCTAssertTrue(CGRect(x: 16, y: 16, width: max(0, width - 32), height: max(0, height - 32))
                            .contains(placement.paintedFrame))
                        XCTAssertGreaterThanOrEqual(placement.frame.width + 0.00001, max(0, width - 32) * item.role.lowerBound)
                        for previous in placements.prefix(index) {
                            XCTAssertFalse(previous.paintedFrame.intersects(placement.paintedFrame.insetBy(dx: -6, dy: -6)))
                        }
                    }
                }
            }
        }
    }

    func testTransparentCanvasCanOverlapWithoutPaintedArtworkColliding() {
        let first = FruitfolioDecorativeArtLayout.placement(
            intrinsicSize: CGSize(width: 100, height: 100),
            visibleAlphaBounds: CGRect(x: 0, y: 0, width: 10, height: 10),
            roleFraction: 0.8...0.8, anchor: .topLeading,
            container: CGRect(x: 0, y: 0, width: 300, height: 300), safeInsets: .init(), protectedRegions: [])
        let second = FruitfolioDecorativeArtLayout.placement(
            intrinsicSize: CGSize(width: 100, height: 100),
            visibleAlphaBounds: CGRect(x: 90, y: 90, width: 10, height: 10),
            roleFraction: 0.8...0.8, anchor: .topLeading,
            container: CGRect(x: 0, y: 0, width: 300, height: 300), safeInsets: .init(),
            protectedRegions: [.init(rect: first.paintedFrame)])
        XCTAssertTrue(first.isVisible)
        XCTAssertTrue(second.isVisible)
        XCTAssertTrue(first.frame.intersects(second.frame))
        XCTAssertFalse(first.paintedFrame.intersects(second.paintedFrame))
    }

    func testHeightConstraintResizesWithinRoleAndRetainsAnchor() {
        let placement = place()
        XCTAssertTrue(placement.isVisible)
        XCTAssertEqual(placement.frame.maxX, 284, accuracy: 0.001)
        XCTAssertEqual(placement.frame.maxY, 184, accuracy: 0.001)
        XCTAssertEqual(placement.frame.width, placement.frame.height)
        XCTAssertGreaterThanOrEqual(placement.frame.width, 268 * 0.2)
    }

    func testFullyProtectedRegionOmitsArtInsteadOfCoveringText() {
        XCTAssertFalse(place(protected: [.init(rect: CGRect(x: 0, y: 0, width: 300, height: 200))]).isVisible)
    }

    func testTooSmallContainerOmitsInsteadOfShrinkingBelowApprovedRole() {
        XCTAssertFalse(place(height: 50).isVisible)
    }
}
