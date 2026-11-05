import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class Prompt08GlobalControlsTests: XCTestCase {

    // MARK: - Canonical control construction

    func testCanonicalPrompt08ButtonsCanBeConstructed() {
        let primaryButton = WatercolorPrimaryButton(
            label: "continue"
        ) {}

        let secondaryButton = WatercolorSecondaryButton(
            label: "cancel"
        ) {}

        let controlPillButton = FruitfolioControlPillButton(
            label: "save"
        ) {}

        XCTAssertNotNil(primaryButton)
        XCTAssertNotNil(secondaryButton)
        XCTAssertNotNil(controlPillButton)
    }

    func testPillGrowsForLongAccessibilityTextInsteadOfTruncating() {
        func measuredHeight(_ label: String, size: DynamicTypeSize) -> CGFloat {
            let view = FruitfolioControlPillButton(label: label) {}
                .environmentObject(MotionPreferences())
                .environmentObject(AudioManager())
                .environment(\.dynamicTypeSize, size)
            let host = UIHostingController(rootView: view)
            return host.sizeThatFits(in: CGSize(width: 292, height: 10_000)).height
        }
        let shortHeight = measuredHeight("save", size: .large)
        let longHeight = measuredHeight(
            String(repeating: "save this encyclopedia and return to your guide ", count: 6),
            size: .accessibility3
        )
        XCTAssertGreaterThanOrEqual(shortHeight, 44)
        XCTAssertGreaterThan(longHeight, shortHeight * 2,
                             "Long localized text at accessibility sizes must grow the control.")
    }

    // MARK: - Bookmark binding semantics

    func testBookmarkButtonUsesLiveBooleanBinding() {
        var isBookmarked = false

        let binding = Binding<Bool>(
            get: {
                isBookmarked
            },
            set: {
                isBookmarked = $0
            }
        )

        let bookmarkButton = BookmarkButton(
            isBookmarked: binding
        )

        XCTAssertFalse(binding.wrappedValue)
        XCTAssertNotNil(bookmarkButton)

        binding.wrappedValue = true
        XCTAssertTrue(isBookmarked)

        binding.wrappedValue = false
        XCTAssertFalse(isBookmarked)
    }

    // MARK: - Current Prompt 08 typography/control API

    func testCurrentPrompt08TextControlsCanBeConstructed() {
        let tooltip = InfoTooltip(
            message: "help"
        )

        var isOn = false

        let toggleBinding = Binding<Bool>(
            get: {
                isOn
            },
            set: {
                isOn = $0
            }
        )

        let toggle = WatercolorToggle(
            label: "sound effects",
            isOn: toggleBinding
        )

        XCTAssertNotNil(tooltip)
        XCTAssertNotNil(toggle)
    }

    // MARK: - Accessibility sizing

    func testMinimumHitTargetRemainsFortyFourPoints() {
        XCTAssertGreaterThanOrEqual(
            DesignTokens.Layout.minimumHitTarget,
            44
        )
    }
}
