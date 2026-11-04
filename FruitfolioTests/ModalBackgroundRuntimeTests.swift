import XCTest
import SwiftUI
import UIKit
@testable import Fruitfolio

@MainActor
final class ModalBackgroundRuntimeTests: XCTestCase {
    private final class State: ObservableObject {
        @Published var outerActive = false
        @Published var innerActive = false
        var blocked: Bool?
    }

    private struct Probe: UIViewRepresentable {
        @Environment(\.fruitfolioModalBackgroundBlocked) private var blocked
        let state: State
        func makeUIView(context: Context) -> UIView { UIView() }
        func updateUIView(_ view: UIView, context: Context) { state.blocked = blocked }
    }

    private struct Fixture: View {
        @ObservedObject var state: State
        var body: some View {
            VStack {
                Probe(state: state)
                    .fruitfolioModalBlur(active: state.innerActive, reduceMotion: true)
            }
            .fruitfolioModalBlur(active: state.outerActive, reduceMotion: true)
        }
    }

    func testNestedModalRemainsBlockedUntilBothOwnersDismissAndResetsAfterReentry() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let state = State()
        let host = UIHostingController(rootView: Fixture(state: state))
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKey() }

        for (outer, inner, expected) in [
            (false, false, false), (true, false, true), (true, true, true),
            (false, true, true), (false, false, false), (true, false, true),
            (false, false, false)
        ] {
            state.blocked = nil
            state.outerActive = outer
            state.innerActive = inner
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            for _ in 0..<40 where state.blocked != expected {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            XCTAssertEqual(state.blocked, expected,
                "An inner dismissal must not re-enable a still-modal ancestor, and the last dismissal must restore interaction")
        }
    }
}
