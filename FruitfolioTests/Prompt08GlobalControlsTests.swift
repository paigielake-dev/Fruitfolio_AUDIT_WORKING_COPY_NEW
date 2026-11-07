import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class Prompt08GlobalControlsTests: XCTestCase {

    // Actual hosted SwiftUI geometry, not a copy of the animation constants.
    // Apple-only: not executed by the Linux portable suites.
    func testSharedButtonPopChangesGeometryOnlyWhenMotionIsAllowed() async throws {
        let rest = try await renderedPopBounds(pressed: false)
        let pressed = try await renderedPopBounds(pressed: true)
        XCTAssertNotEqual(pressed, rest)
        XCTAssertLessThan(pressed.width, rest.width)
        for flags in [(true, false, false), (false, true, false), (false, false, true)] {
            let reducedRest = try await renderedPopBounds(pressed: false, explicit: flags.0, system: flags.1, app: flags.2)
            let reducedPressed = try await renderedPopBounds(pressed: true, explicit: flags.0, system: flags.1, app: flags.2)
            XCTAssertEqual(reducedPressed, reducedRest,
                           "Explicit, OS and app Reduce Motion must each remove spatial press feedback")
            XCTAssertEqual(reducedRest, rest)
        }
    }

    private func renderedPopBounds(pressed: Bool, explicit: Bool = false,
                                   system: Bool = false, app: Bool = false) async throws -> CGRect {
        let view = Rectangle().fill(Color.red).frame(width: 80, height: 60)
            .modifier(FruitfolioButtonPopEffect(isPressed: pressed, reduceMotion: explicit))
            .frame(width: 160, height: 160).background(Color.white)
            .environment(\.accessibilityReduceMotion, system)
            .environment(\.fruitfolioAppReduceMotion, app)
        let host = UIHostingController(rootView: view)
        let originalKey = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; originalKey?.makeKeyAndVisible() }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(60))
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { _ in
            XCTAssertTrue(host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true))
        }
        let image = try XCTUnwrap(rendered.cgImage)
        let width = image.width, height = image.height
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        try rgba.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(data: bytes.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height { for x in 0..<width {
            let i = (y * width + x) * 4
            if rgba[i] > 150 && rgba[i + 1] < 80 && rgba[i + 2] < 80 && rgba[i + 3] > 200 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        } }
        XCTAssertGreaterThanOrEqual(maxX, minX, "The actual hosted control must be rendered")
        XCTAssertGreaterThanOrEqual(maxY, minY)
        return CGRect(x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(maxX - minX + 1), height: CGFloat(maxY - minY + 1))
    }

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
