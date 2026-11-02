import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class NativeActionLabelRuntimeTests: XCTestCase {
    func testLargestTypeRendersTheEntireLongHubLabelInsideItsActualNativeTextBounds() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let host = UIHostingController(rootView:
            FruitfolioNativeActionLabel(text: "ask the encyclopedia", lineBreakMode: .byCharWrapping)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 264)
                .environment(\.dynamicTypeSize, .accessibility5))
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 264, height: 600)
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKey() }
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        func labels(_ view: UIView) -> [UILabel] {
            (view as? UILabel).map { [$0] } ?? view.subviews.flatMap { labels($0) }
        }
        let label = try XCTUnwrap(labels(host.view).first)
        XCTAssertEqual(label.text, "ask the encyclopedia")
        XCTAssertGreaterThan(label.font.pointSize, 15)
        XCTAssertEqual(label.numberOfLines, 0)
        XCTAssertEqual(label.lineBreakMode, .byCharWrapping)
        let textBounds = label.textRect(forBounds: CGRect(x: 0, y: 0, width: label.bounds.width, height: 4000), limitedToNumberOfLines: 0)
        XCTAssertLessThanOrEqual(textBounds.width, label.bounds.width + 1)
        XCTAssertLessThanOrEqual(textBounds.height, label.bounds.height + 1)
        XCTAssertGreaterThanOrEqual(label.bounds.height, label.font.lineHeight * 2 - 1)
        let renderer = UIGraphicsImageRenderer(bounds: host.view.bounds)
        let screenshot = renderer.image { context in host.view.layer.render(in: context.cgContext) }
        let evidence = XCTAttachment(image: screenshot)
        evidence.name = "ActualNativeHubLabel_AccessibilityXXXL_264PointTextColumn"
        evidence.lifetime = .keepAlways; add(evidence)
    }
}
