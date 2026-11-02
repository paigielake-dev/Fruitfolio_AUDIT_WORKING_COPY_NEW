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
    func testLargestConfirmationActionsFitTheCalibratedWritingViewportAtNarrowAndWidePhoneWidthsWithoutShrinkingFonts() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let suite = "Fruitfolio.PopupTextFit.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); previous?.makeKey() }
        let settings = SettingsStore(defaults: defaults); settings.allAudioMuted = true
        let audio = AudioManager(settings: settings); defer { audio.resetAllAudio() }
        let motion = MotionPreferences()
        for width in [CGFloat(375), CGFloat(402), CGFloat(440)] {
            let popup = Prompt12ConfirmationPopup(assetName: "popup_warning",
                title: "delete all hormone measurements?",
                message: "this removes hormone results only. cycle logs, saved guides, and account information are unchanged.",
                primaryLabel: "cancel", secondaryLabel: nil, destructiveLabel: "delete hormone measurements",
                primaryAction: {}, secondaryAction: nil, destructiveAction: {})
                .environmentObject(audio).environmentObject(motion)
                .environment(\.dynamicTypeSize, .accessibility5)
            let host = UIHostingController(rootView: popup)
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: width, height: 667)
            window.rootViewController = host; window.makeKeyAndVisible()
            defer { window.isHidden = true }
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            func labels(_ view: UIView) -> [UILabel] {
                (view as? UILabel).map { [$0] } ?? view.subviews.flatMap { labels($0) }
            }
            let actualLabels = labels(host.view)
            let metadata = try XCTUnwrap(FruitfolioArtworkGeometryStore.geometry(named: "popup_notebook_paper"))
            let writing = FruitfolioPopupLayout.geometry(assetSize: CGSize(width: metadata.width, height: metadata.height),
                normalizedWriting: CGRect(x: 0.24, y: 0.14, width: 0.65, height: 0.76),
                available: host.view.safeAreaLayoutGuide.layoutFrame.size).writing
            for text in ["delete all hormone measurements?", "this removes hormone results only. cycle logs, saved guides, and account information are unchanged."] {
                let label = try XCTUnwrap(actualLabels.first { $0.text == text }, "The actual visible popup wording must remain a native readable label")
                XCTAssertTrue(label.isAccessibilityElement)
                XCTAssertEqual(label.textColor, UIColor(DesignTokens.ColorToken.primaryBurgundy))
                XCTAssertEqual(label.numberOfLines, 0)
                let full = label.sizeThatFits(CGSize(width: label.bounds.width, height: 4000))
                XCTAssertLessThanOrEqual(full.height, label.bounds.height + 1, "Keep every glyph; scrolling must not truncate the disclosure")
            }
            for text in ["cancel", "delete hormone measurements"] {
                let label = try XCTUnwrap(actualLabels.first { $0.text == text })
                let base = try XCTUnwrap(UIFont(name: "ChalkboardSE-Bold", size: 15))
                let requested = UIFontMetrics(forTextStyle: .headline).scaledFont(for: base,
                    compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
                XCTAssertEqual(label.font.pointSize, requested.pointSize, accuracy: 0.001, "Do not shrink the user's requested font")
                let fullText = label.textRect(forBounds: CGRect(x: 0, y: 0, width: label.bounds.width, height: 4000), limitedToNumberOfLines: 0)
                XCTAssertLessThanOrEqual(fullText.height, label.bounds.height + 1)
                XCTAssertLessThanOrEqual(max(82, label.bounds.height + 16), writing.height,
                    "The complete actual painted action must fit inside the artwork writing viewport after scrolling at width \(width)")
            }
            let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { host.view.layer.render(in: $0.cgContext) }
            let evidence = XCTAttachment(image: image)
            evidence.name = "ConfirmationPopup_Largest_FirstViewport_width\(Int(width))"
            evidence.lifetime = .keepAlways; add(evidence)
            window.isHidden = true
        }
    }

    func testAuthoredControlLocalizesItsRealVisibleLabelButUserAuthoredTextRemainsVerbatim() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let host = UIHostingController(rootView: VStack {
            FruitfolioNativeActionLabel(text: "save", localizationKey: "save")
            FruitfolioNativeActionLabel(text: "save")
        }.environment(\.locale, Locale(identifier: "es")))
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKey() }
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        func labels(_ view: UIView) -> [UILabel] {
            (view as? UILabel).map { [$0] } ?? view.subviews.flatMap { labels($0) }
        }
        let actual = labels(host.view)
        XCTAssertTrue(actual.contains { $0.text == "guardar" && $0.isAccessibilityElement })
        XCTAssertTrue(actual.contains { $0.text == "save" && $0.isAccessibilityElement },
                      "User-authored text is never passed through a UI-key translator")
    }

}
