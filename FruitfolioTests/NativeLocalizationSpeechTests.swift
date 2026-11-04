import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class NativeLocalizationSpeechTests: XCTestCase {
    private func labels(in view: UIView) -> [UILabel] {
        (view as? UILabel).map { [$0] } ?? view.subviews.flatMap { labels(in: $0) }
    }

    func testActualLocalizedNativeLabelRetainsItsVisibleTextAndMatchingSpeechLanguage() async throws {
        let host = UIHostingController(rootView: FruitfolioNativeActionLabel(text: "cancel", localizationKey: "cancel")
            .environment(\.locale, Locale(identifier: "es")).frame(width: 240))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 160))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<30 {
            if labels(in: host.view).contains(where: { $0.text == "cancelar" }) { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        window.layoutIfNeeded(); host.view.layoutIfNeeded()
        let label = try XCTUnwrap(labels(in: host.view).first { $0.text == "cancelar" })
        XCTAssertEqual(label.accessibilityLanguage, "es")
        XCTAssertTrue(label.isAccessibilityElement)
        XCTAssertTrue(label.accessibilityTraits.contains(.staticText))
        XCTAssertGreaterThan(label.bounds.height, 0)
    }

    func testSourceOnlyNativeLabelKeepsOriginalWordingAndEnglishSpeechUnderAnRTLLocale() async throws {
        let original = "Source-only immutable fixture wording."
        let host = UIHostingController(rootView: FruitfolioNativeActionLabel(text: original, localizationKey: original)
            .environment(\.locale, Locale(identifier: "ar")).environment(\.layoutDirection, .rightToLeft)
            .frame(width: 240))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 160))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<30 {
            if labels(in: host.view).contains(where: { $0.text == original }) { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        window.layoutIfNeeded(); host.view.layoutIfNeeded()
        let label = try XCTUnwrap(labels(in: host.view).first { $0.text == original })
        XCTAssertEqual(label.accessibilityLanguage, "en")
        XCTAssertEqual(label.text, original)
        XCTAssertTrue(label.isAccessibilityElement)
    }
    func testUnkeyedUserTextIsNotTranslatedMerelyBecauseItMatchesAnInterfaceKey() async throws {
        let host = UIHostingController(rootView: FruitfolioNativeActionLabel(text: "cancel")
            .environment(\.locale, Locale(identifier: "es")).frame(width: 240))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 160))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<30 {
            if labels(in: host.view).contains(where: { $0.text == "cancel" }) { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        let label = try XCTUnwrap(labels(in: host.view).first { $0.text == "cancel" })
        XCTAssertEqual(label.text, "cancel")
        XCTAssertNil(label.accessibilityLanguage)
        XCTAssertFalse(labels(in: host.view).contains { $0.text == "cancelar" })
    }

}
