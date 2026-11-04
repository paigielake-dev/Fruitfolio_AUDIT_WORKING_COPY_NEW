import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class CyclePredictionPopupRuntimeTests: XCTestCase {
    func testLongPredictionExplanationKeepsFullSizeTextAndScrollableCloseAtNormalAndLargestType() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let suite = "Fruitfolio.CyclePopup.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); previous?.makeKey() }
        let settings = SettingsStore(defaults: defaults); settings.allAudioMuted = true
        let audio = AudioManager(settings: settings); defer { audio.resetAllAudio() }
        let motion = MotionPreferences()
        let info = Prompt16PredictionLearningInfo(title: "why an estimate may be limited",
            body: String(repeating: "fixture: recorded observations remain separate from estimates. ", count: 35),
            progress: "fixture: no recorded values are replaced.")
        for largest in [false, true] {
            let popup = Prompt15WoodenPredictionPopup(info: info, onDismiss: {})
                .environmentObject(audio).environmentObject(motion)
                .environment(\.locale, Locale(identifier: "en"))
                .environment(\.dynamicTypeSize, largest ? .accessibility5 : .large)
            let host = UIHostingController(rootView: popup)
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
            window.rootViewController = host; window.makeKeyAndVisible()
            defer { window.isHidden = true }
            func descendants<T: UIView>(_ view: UIView, as type: T.Type) -> [T] {
                (view as? T).map { [$0] } ?? view.subviews.flatMap { descendants($0, as: type) }
            }
            var scroll: UIScrollView?
            for _ in 0..<40 {
                host.view.setNeedsLayout(); host.view.layoutIfNeeded()
                scroll = descendants(host.view, as: UIScrollView.self).first
                if let scroll, scroll.contentSize.height > scroll.bounds.height { break }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            let actual = try XCTUnwrap(scroll)
            XCTAssertGreaterThan(actual.contentSize.height, actual.bounds.height,
                                 "Long disclosures must scroll instead of being capped at three lines")
            let first = UIGraphicsImageRenderer(bounds: host.view.bounds).image { host.view.layer.render(in: $0.cgContext) }
            let opening = XCTAttachment(image: first)
            opening.name = "CyclePredictionPopup_LongText_Initial_largest_\(largest)"
            opening.lifetime = .keepAlways; add(opening)
            actual.setContentOffset(CGPoint(x: 0, y: max(0, actual.contentSize.height - actual.bounds.height)), animated: false)
            host.view.layoutIfNeeded()
            let close = try XCTUnwrap(descendants(host.view, as: UILabel.self).first { $0.text == "got it ♡" })
            XCTAssertEqual(close.numberOfLines, 0)
            let needed = close.sizeThatFits(CGSize(width: close.bounds.width, height: 4000))
            XCTAssertLessThanOrEqual(needed.height, close.bounds.height + 1)
            XCTAssertTrue(actual.bounds.contains(close.convert(close.bounds, to: actual)),
                          "The real visible close label must be fully reachable within the writing viewport")
            let final = UIGraphicsImageRenderer(bounds: host.view.bounds).image { host.view.layer.render(in: $0.cgContext) }
            let evidence = XCTAttachment(image: final)
            evidence.name = "CyclePredictionPopup_LongText_ScrolledClose_largest_\(largest)"
            evidence.lifetime = .keepAlways; add(evidence)
            window.isHidden = true
        }
    }
}
